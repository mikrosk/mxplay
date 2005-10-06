#include <stdio.h>
#include <string.h>
#include <cflib.h>
#include <mint/osbind.h>
#include <mint/mintbind.h>
#include <mint/falcon.h>

#include "skins/skin.h"
#include "mxplay.h"
#include "dialogs.h"
#include "audio_plugins.h"
#include "panel.h"
#include "misc.h"
#include "vaproto.h"
#include "playlist.h"
#include "av.h"
#include "dd.h"
#include "vbl_timer.h"
#include "module_info.h"

BOOL	g_quitApp = FALSE;
short	g_msgBuffer[8];
long	g_cpu = 0x00;
long	g_fpu = 0x00;
BOOL	g_hasDma = FALSE;
BOOL	g_hasDsp = FALSE;

static short	currMouseX;
static short	currMouseY;

#ifdef NO_MINT
static BOOL		isTimerInstalled = FALSE;
static BOOL		isVblInstalled = FALSE;
#endif

/*
 * Message-handling.
 */
void HandleMessage( short msg[8] )
{
	short obj;
	
	if( !message_wdial( msg ) )
	{
		switch( msg[0] )
		{
			case AP_TERM:
			case AP_RESCHG:
				g_quitApp = TRUE;
			break;

			case AP_DRAGDROP:
				g_playAfterAdd = FALSE;	//g_emptyPlayList;	/* play only if empty playlist */
				g_currFileUpdated = FALSE;	/* reset flag */
				DDParseArgs( msg );
				if( g_playAfterAdd == TRUE )
				{
					LoadAndPlay();
				}
			break;

			case VA_START:
				g_playAfterAdd = TRUE;	/* add to playlist and play */
				g_currFileUpdated = FALSE;	/* reset flag */
				VAParseArgs( msg );
				LoadAndPlay();
			break;

			case VA_PROTOSTATUS :
				AVSetStatus( msg );
			break;
		}
	}
	else
	{
		switch( msg[0] )
		{
			/* we don't need to top window since this was done in message_wdial() */
			case WM_TOPPED:
				obj = objc_find( g_winDialogs[WD_PANEL]->tree, PANEL_BACKGROUND, MAX_DEPTH, currMouseX, currMouseY );
				switch( obj )
				{
					case PANEL_EJECT:
						if( g_withShift == TRUE )
						{
							g_withShift = FALSE;
							PanelDirOpen();
						}
						else
						{
							PanelFileOpen();
						}
					break;
					
					/* objects on the panel are accessible even on untopped window */
					case PANEL_PLAY:
						PanelPlay();
					break;
					
					case PANEL_STOP:
						PanelStop();
					break;
					
					case PANEL_PAUSE:
						PanelPause();
					break;
					
					case PANEL_FWD:
						PanelFwd();
					break;
					
					case PANEL_RWD:
						PanelRwd();
					break;
					
					case PANEL_NEXT:
						PanelNext();
					break;
					
					case PANEL_PREV:
						PanelPrev();
					break;
					
					case PANEL_REPEAT:
						PanelRepeat();
					break;
					
					case PANEL_RANDOM:
						PanelRandom();
					break;
					
					case PANEL_PLAYLIST:
						PanelPlayList();
					break;
					
					case PANEL_INFO_MOD:
						PanelInfoModule();
					break;
					
					case PANEL_INFO_PLG:
						PanelInfoPlugin();
					break;
									
					case PANEL_INFO_APP:
						PanelInfoApp();
					break;
					
					case PANEL_MUTE:
						PanelMute();
					break;
					
					case PANEL_PLAYTIME:
						PanelPlayTime();
					break;
				}
			break;
		}
	}
}

/*
 * Message sending across GEM apps.
 */
int SendMessage( short recipientId )
{
	g_msgBuffer[1] = gl_apid;
	g_msgBuffer[2] = 0;
	return appl_write( recipientId, sizeof( g_msgBuffer ), g_msgBuffer );
}

/*
 * Safe exit from any code point.
 */
void ExitPlayer( int code )
{
#ifdef NO_MINT
	if( isTimerInstalled == TRUE )
	{
		if( Supexec( timer_stop_measure ) == FALSE )
		{
			ShowMeasureDeinitFailedDialog();
		}
		isTimerInstalled = FALSE;
	}
	
	if( isVblInstalled == TRUE )
	{
		if( Supexec( timer_uninstall ) == FALSE )
		{
			ShowMeasureDeinitFailedDialog();
		}
		isVblInstalled = FALSE;
	}
#endif

	exit_app( code );
}

/*
 * Here begins all that evil thing!
 */
int main( int argc, char* argv[] )
{
	short	event;
	short	key, kstate;
	short	mx, my, mb, mc;
	short	obj;
	long	temp;
	BOOL	inSlider = FALSE;
	BOOL	inUp = FALSE;
	BOOL	inDown = FALSE;
	BOOL	inVolume = FALSE;
	BOOL	inPlayListResize = FALSE;
	BOOL	inModuleInfoResize = FALSE;
	
#ifdef NO_MINT
	isTimerInstalled = TRUE;
	if( Supexec( timer_start_measure ) == FALSE )
	{
		ShowMeasureInitFailedDialog();
		ExitPlayer( 1 );
	}
#endif
	
	/* register MiNT domain */
	if( Pdomain( 1 ) != 1 )	/* MiNT domain */
	{
	}

	/* get global variables etc */
	init_app( NULL );

	// TODO: remove!!!
	if( strcmp( gl_appdir, "\\" ) == 0 )
	{
		strcpy( gl_appdir, "I:\\root\\projects\\mxPlay" );
	}
	/* alloc & create all dialogs */
	InitDialogs();
	
	/* show splash */
	ShowSplashImage();
	
	/* for N.AES, XaAES & MagiC install nice name */
	if( gl_gem >= 0x400 )
	{
		menu_register( gl_apid, "  mxPlay" );
	}

	/* get cookies & set flags */
	getcookie( "_CPU", &g_cpu );
	getcookie( "_FPU", &g_fpu );
	getcookie( "_SND", &temp );
	if( ( temp & SND_DMAREC ) != 0 )	/* DMA presence */
	{
		g_hasDma = TRUE;
	}
	if( ( temp & SND_DSP ) != 0 )	/* DSP presence */
	{
		g_hasDsp = TRUE;
	}
	
	/* find AV server etc */
	AVInit();
	
	/* set random seed */
	InitRandom();
	
	/* load & init all audio plugins */
	LoadAudioPlugins();
	
#ifdef NO_MINT
	/* check if we reached the end of time measuring */
	while( timer_is_finished() == FALSE );
	
	if( Supexec( timer_stop_measure ) == FALSE )
	{
		ShowMeasureDeinitFailedDialog();
		ExitPlayer( 1 );
	}
	isTimerInstalled = FALSE;
	
	/* install vbl-timer for correct time show */
	isVblInstalled = TRUE;
	if( Supexec( timer_install ) == FALSE )
	{
		ShowMeasureInitFailedDialog();
		ExitPlayer( 1 );
	}
#endif
	
	/* close splash */
	CloseSplashImage();
	
	/* open & init dialogs to open on startup */
	ShowDefaultDialogs();
	
	/* if there's some playlist in .inf file, load it */
	if( strcmp( g_playlistFile, "" ) != 0 )
	{
		g_playAfterAdd = FALSE;	/* we don't want to play everytime playlist is found on startup */
		g_currFileUpdated = FALSE;	/* reset flag */
		if( PlayListLoadFromFile( g_playlistFile ) == FALSE )
		{
			strcpy( g_playlistFile, "" );
		}
	}
	
	/* if there's some module/playlist dragged on startup, play it */
	g_playAfterAdd = TRUE;	/* playlist is empty for sure */
	g_currFileUpdated = FALSE;	/* reset flag */
	ARGVParseArgs( argc, argv );
	if( argc > 1 && g_emptyPlayList == FALSE )	/* only if some file was added */
	{
		LoadAndPlay();
	}
	
	/* Application mainloop */
	while( g_quitApp == FALSE )
	{
		event = evnt_multi( MU_KEYBD | MU_MESAG | MU_BUTTON | MU_TIMER,
							2, LEFT_BUTTON, 1,	/* bclicks, bmask, bstate -- not used */
							0, 0, 0, 0, 0,		/* m1flag, m1x, m1y, m1w, m1h -- not used */
							0, 0, 0, 0, 0,		/* m2flag, m2x, m2y, m2w, m2h -- not used */
							g_msgBuffer,
							250,				/* 250 ms = 0.25 second */
							&mx, &my, &mb,		/* mouse x, mouse y, mouse button */
							&kstate, &key,		/* shift state, key pressed */
							&mc );				/* how many mouse clicks occured */
		
		/* here we check if user pressed some shift key along with mouse/key */
		if( ( kstate & K_RSHIFT ) || ( kstate & K_LSHIFT ) )
		{
			g_withShift = TRUE;
		}
		else
		{
			g_withShift = FALSE;
		}
		
		/* if this event doesn't occur mc could be anything! */
		if( ( event & MU_BUTTON ) == 0 )
		{
			mc = 0;
		}
		
		/*
		 * this has to happen since no redraws will occur during
		 * realtime (re)sizing/moving of objects
		 */
		if( event & MU_MESAG )
		{
			HandleMessage( g_msgBuffer );
		}

		if( inSlider == TRUE )
		{
			if( mc == 1 )
			{
				if( my != currMouseY )
				{
					PlayListSlider( my - currMouseY );
				}
				currMouseY = my;
				continue;
			}
			else
			{
				PlayListSliderDeselect();
			
				/* reset the mouse cursor */
				graf_mouse( ARROW, NULL );
				inSlider = FALSE;
			}
		}
		else if( inVolume == TRUE )
		{
			if( mc == 1 )
			{
				if( mx != currMouseX )
				{
					PanelVolumeSlider( mx - currMouseX );
				}
				currMouseX = mx;
				continue;
			}
			else
			{
				DeselectObject( g_winDialogs[WD_PANEL], PANEL_VOLUME_SLIDER );
			
				/* reset the mouse cursor */
				graf_mouse( ARROW, NULL );
				inVolume = FALSE;
			}
		}
		#if 0
		else if( inPlayListResize == TRUE )
		{
			if( mc == 1 )
			{
				if( mx != currMouseX || my != currMouseY )
				{
					PlayListResize( mx, my );
				}
				currMouseX = mx;
				currMouseY = my;
				continue;
			}
			else
			{
				DeselectObject( g_winDialogs[WD_PANEL], PLAYLIST_RESIZE );
			
				/* reset the mouse cursor */
				graf_mouse( ARROW, NULL );
				inPlayListResize = FALSE;
			}
		}
		#endif
		else if( inModuleInfoResize == TRUE )
		{
			if( mc == 1 )
			{
				if( mx != currMouseX || my != currMouseY )
				{
					ModuleInfoResize( mx, my );
				}
				currMouseX = mx;
				currMouseY = my;
				continue;
			}
			else
			{
				DeselectObject( g_winDialogs[WD_MODULE], MODULE_RESIZE );
			
				/* reset the mouse cursor */
				graf_mouse( ARROW, NULL );
				inModuleInfoResize = FALSE;
			}
		}
		
		/* no click, no fun :) */
		if( mc == 0 )
		{
			inUp = FALSE;
			inDown = FALSE;
		}
		
		if( mc == 1 && inUp == TRUE )
		{
			PlayListUp();
			continue;
		}
		
		if( mc == 1 && inDown == TRUE )
		{
			PlayListDown();
			continue;
		}

		/*
		 * Watch for some realtime moveable objects.
		 */
		if( IsTopWindow( g_winDialogs[WD_PLAYLIST] ) == TRUE )
		{
			obj = objc_find( g_winDialogs[WD_PLAYLIST]->tree, PLAYLIST_BACKGROUND, MAX_DEPTH, mx, my );
			if( obj != -1 )
			{
				switch( obj )
				{
					case PLAYLIST_SLIDER:
						if( mc == 1 && inSlider == FALSE )
						{
							PlayListSliderSelect();
							graf_mouse( FLAT_HAND, NULL );
							inSlider = TRUE;
							continue;
						}
					break;
	
					case PLAYLIST_SLIDER_BOX:
						if( mc == 1 )
						{
							PlayListSliderBox( my );
						}
					break;
					
					case PLAYLIST_UP:
						if( mc == 1 && inUp == FALSE )
						{
							PlayListUp();
							inUp = TRUE;
							continue;
						}
					break;
					
					case PLAYLIST_DOWN:
						if( mc == 1 && inDown == FALSE )
						{
							PlayListDown();
							inDown = TRUE;
							continue;
						}
					break;
					
					#if 0
					case PLAYLIST_RESIZE:
						if( mc == 1 && inPlayListResize == FALSE )
						{
							SelectObject( g_winDialogs[WD_PLAYLIST], obj );
							graf_mouse( FLAT_HAND, NULL );
							inPlayListResize = TRUE;
							continue;
						}
					break;
					#endif
				}
			}
		}
		else if( IsTopWindow( g_winDialogs[WD_PANEL] ) == TRUE )
		{
			obj = objc_find( g_winDialogs[WD_PANEL]->tree, PANEL_BACKGROUND, MAX_DEPTH, mx, my );
			if( obj != -1 )
			{
				switch( obj )
				{
					case PANEL_VOLUME_SLIDER:
						if( mc == 1 && inVolume == FALSE )
						{
							SelectObject( g_winDialogs[WD_PANEL], obj );
							graf_mouse( FLAT_HAND, NULL );
							inVolume = TRUE;
							continue;
						}
					break;
					
					case PANEL_VOLUME_SLIDER_BOX:
						if( mc == 1 )
						{
							PanelVolumeSliderBox( mx );
						}
					break;
				}
			}
		}
		else if( IsTopWindow( g_winDialogs[WD_MODULE] ) == TRUE )
		{
			obj = objc_find( g_winDialogs[WD_MODULE]->tree, ROOT, MAX_DEPTH, mx, my );
			if( obj != -1 )
			{
				switch( obj )
				{
					case MODULE_RESIZE:
						if( mc == 1 && inModuleInfoResize == FALSE )
						{
							SelectObject( g_winDialogs[WD_MODULE], obj );
							graf_mouse( FLAT_HAND, NULL );
							inModuleInfoResize = TRUE;
							continue;
						}
					break;
				}
			}
		}

		currMouseX = mx;
		currMouseY = my;
		
		g_mouseClicks = mc;
		
		/* if we reached playtime */
		if( g_modulePlaying == TRUE && TimerGetSubTime() <= 0 )
		{
			PanelNext();
		}
		
		/* update volume slider */
		PanelVolumeSliderUpdate();
		
		/*
		 * Remaining event handlers
		 */
		if( event & MU_BUTTON )
		{
			if( !click_wdial( mc, mx, my, kstate, mb ) )
			{
			}
		}
		
		if( event & MU_TIMER )
		{
			PanelDialogRefresh();
		}

		if( event & MU_KEYBD )
		{
			key_wdial( key, kstate );
			switch( key )
			{
				/* (shift) control o */
				case 0x180f:
					if( IsTopWindow( g_winDialogs[WD_PANEL] ) == TRUE )
					{
						if( g_withShift == FALSE )
						{
							PanelFileOpen();
						}
						else
						{
							PanelDirOpen();
						}
					}
				break;

				/* control q */
				case 0x1011:
					g_quitApp = TRUE;
				break;

				/* space */
				case 0x3920:
					if( IsTopWindow( g_winDialogs[WD_PANEL] ) == TRUE )
					{
						PanelPause();
					}
				break;

				/* control p */
				case 0x1910:
					PanelPlay();
				break;

				/* control s */
				case 0x1f13:
					PanelStop();
				break;

				/* right arrow */
				case 0x4d00:
					PanelFwd();
				break;

				/* left arrow */
				case 0x4b00:
					PanelRwd();
				break;

				/* (shift) up arrow */
				case 0x4800:
				case 0x4838:
					if( IsTopWindow( g_winDialogs[WD_PANEL] ) == TRUE )
					{
						PanelVolumeUp();
					}
					else if( IsTopWindow( g_winDialogs[WD_PLAYLIST] ) == TRUE )
					{
						PlayListUp();
					}
				break;

				/* (shift) down arrow */
				case 0x5000:
				case 0x5032:
					if( IsTopWindow( g_winDialogs[WD_PANEL] ) == TRUE )
					{
						PanelVolumeDown();
					}
					else if( IsTopWindow( g_winDialogs[WD_PLAYLIST] ) == TRUE )
					{
						PlayListDown();
					}
				break;

				/* (shift) ctrl a */
				case 0x1e01:
					if( IsTopWindow( g_winDialogs[WD_PLAYLIST] ) == TRUE )
					{
						PlayListSelectAll();
					}
				break;

				/* del */
				case 0x537f:
					if( IsTopWindow( g_winDialogs[WD_PLAYLIST] ) == TRUE )
					{
						PlayListRemove();
					}
				break;

				/* num / */
				case 0x652f:
					PanelChangeSkin();
				break;

				/* insert */
				case 0x5200:
					PanelRepeat();
				break;

				/* clr home */
				case 0x4700:
					PanelRandom();
				break;

				/* num ( */
				case 0x6328:
					PanelPrev();
				break;

				/* num ) */
				case 0x6429:
					PanelNext();
				break;

				/* num * */
				case 0x662a:
					PanelPlayList();
				break;

				/* (shift) tab */
				case 0x0f09:
					if( g_withShift == FALSE )
					{
						PanelInfoModule();
					}
					else
					{
						PanelInfoPlugin();
					}
				break;

				/* help */
				case 0x6200:
					if( IsTopWindow( g_winDialogs[WD_PANEL] ) == TRUE )
					{
						PanelInfoApp();
					}
				break;

				/* undo */
				case 0x6100:
					PanelMute();
				break;
			}
		}
	}
	
	if( g_playlistNotActual == TRUE )
	{
		#if 0
		if( ShowPlayListNotActualDialog() == 1 )
		{
			/* save playlist */
			if( strcmp( g_playlistFile, "" ) == 0 )
			{
				/* show fileselector */
				PlayListSave();
			}
			else
			{
				PlayListSaveToFile( g_playlistFile );
			}
		}
		#endif
		strcpy( g_playlistFile, g_homePath );
		CombinePath( g_playlistFile, g_playlistFile, DEFAULT_M3U_FILE );
		PlayListSaveToFile( g_playlistFile );
	}

	PanelStop();
	
#ifdef NO_MINT
	if( Supexec( timer_uninstall ) == FALSE )
	{
		ShowMeasureDeinitFailedDialog();
		/* has exit some sense? */
	}
	isVblInstalled = FALSE;
#endif
	
	AVExit();

	WriteConfigFile();

	DeleteDialogs();

	ExitPlayer( 0 );

	return 0;	/* to be compiler happy :) */
}
