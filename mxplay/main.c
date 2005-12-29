/*
 * main.c -- event mainloop, global init, deinit, exit
 *
 * Copyright (c) 2005 Miro Kropacek; mikro@hysteria.sk
 * 
 * This file is part of the mxPlay project, multiformat audio player for
 * Atari TT/Falcon computers.
 *
 * mxPlay is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * mxPlay is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with mxPlay; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

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
			
			/*
			 * Events for custom window dialogs.
			 */
			
			/* SIZER */
			case WM_SIZED:
				if( msg[3] == g_winDialogs[WD_PLAYLIST]->win_handle )
				{
					PlayListResize( (GRECT*)&msg[4] );
				}
				else if( msg[3] == g_winDialogs[WD_MODULE]->win_handle )
				{
					ModuleInfoResize( (GRECT*)&msg[4] );
				}
			break;
			
			/* xxARROW */
			case WM_ARROWED:
				if( msg[3] == g_winDialogs[WD_PLAYLIST]->win_handle )
				{
					PlayListScroll( msg[4] );
				}
				else if( msg[3] == g_winDialogs[WD_MODULE]->win_handle )
				{
					ModuleInfoScroll( msg[4] );
				}
			break;
			
			/* VSLIDER */
			case WM_VSLID:
				if( msg[3] == g_winDialogs[WD_PLAYLIST]->win_handle )
				{
					PlayListSlider( msg[4] );
				}
				else if( msg[3] == g_winDialogs[WD_MODULE]->win_handle )
				{
					ModuleInfoSlider( msg[4] );
				}
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
	BOOL	inVolume = FALSE;
	
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
		
		if( inVolume == TRUE )
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
		
		/*
		 * Watch for some realtime moveable objects.
		 */
		if( IsTopWindow( g_winDialogs[WD_PANEL] ) == TRUE )
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
		
		currMouseX = mx;
		currMouseY = my;
		
		g_mouseClicks = mc;
		
		DeselectObject( g_winDialogs[WD_PANEL], PANEL_VOLUME_SLIDER );	/* yes, it has some sense :) */
		
		/* if we reached playtime */
		if( g_modulePlaying == TRUE && g_modulePaused == FALSE && TimerGetSubTime() <= 0 )
		{
			PanelNext();
		}
		
		/* update volume slider */
		PanelVolumeSliderUpdate();
		
		/*
		 * Event handlers
		 */
		 
		if( event & MU_MESAG )
		{
			HandleMessage( g_msgBuffer );
		}
				
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
						if( g_withShift == FALSE )
						{
							PlayListScroll( WA_UPLINE );
						}
						else
						{
							PlayListScroll( WA_UPPAGE );
						}
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
						if( g_withShift == FALSE )
						{
							PlayListScroll( WA_DNLINE );
						}
						else
						{
							PlayListScroll( WA_DNPAGE );
						}
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
