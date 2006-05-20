/*
 * dialogs.c -- AES dialogs - init, deinit, errors, ...
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

#include <cflib.h>
#include <stdio.h>
#include <string.h>
#include <osbind.h>
#include <sys/param.h>

#include "skins/skin.h"
#include "mxplay.h"
#include "dialogs.h"
#include "audio_plugins.h"
#include "panel.h"
#include "filelist.h"
#include "misc.h"
#include "playlist.h"
#include "plugin_info.h"
#include "vbl_timer.h"
#include "module_info.h"

WDIALOG*	g_winDialogs[WD_LIST_SIZE];

BOOL		g_withShift = FALSE;
int			g_mouseClicks = 0;
char		g_panelInfoLine[1023+1] = "";	/* hope it's enough */

static short	winDialogList[] = { ABOUT, PANEL, PLAYLIST, PLUGIN, MODULE };	/* numbers from rsc */
static OBJECT*	winIcons[WD_LIST_SIZE];
static OBJECT*	licenseDialog;
static OBJECT*	splashImage;
static short	splashImageHandle;

static char		welcomeString[sizeof( VERSION ) + sizeof( WELCOME_MESSAGE )] = "";
static int		stringIndex = 0;
static BOOL		canRefresh = FALSE;

static void	CB_OpenWDialog( WDIALOG* wd );
static BOOL	CB_ExitObject( WDIALOG* wd, short obj );

void InitRsc( void )
{
	OBJECT*	tempDialog;
	char	tempPath[MXP_PATH_MAX+1];
	BOOL	rscLoaded = FALSE;
	int		i;
	
	while( rscLoaded == FALSE )
	{
		strcpy( tempPath, gl_appdir );
		CombinePath( tempPath, tempPath, "skins" );		/* path\skins */
		CombinePath( tempPath, tempPath, g_rscName );	/* path\skins\filename.rsc */
		
		if( rsrc_load( tempPath ) == FALSE )
		{
			strcpy( g_rscName, "" );	/* no rsc in memory */
			
			if( ShowRsrcLoadFailedDialog() == 1 )	/* "Choose" */
			{
				PanelChangeSkin();
			}
			else
			{
				ExitPlayer( 1 );
			}
		}
		else
		{
			rscLoaded = TRUE;
		}
	}
	
	/* find & init non-windialogs objects */
	if( rsrc_gaddr( R_TREE, WICON, &tempDialog ) == FALSE
		|| rsrc_gaddr( R_TREE, GPL, &licenseDialog ) == FALSE
		|| rsrc_gaddr( R_TREE, SPLASH, &splashImage ) == FALSE )
	{
		ShowRsrcAddrFailedDialog();
		ExitPlayer( 1 );
	}
	else
	{
		/* simple_mdial() needs this */
		licenseDialog->ob_x = 0;
		licenseDialog->ob_y = 0;
		fix_dial( licenseDialog );
		
		fix_dial( splashImage );
	}
	
	/* make new instances of win-icons */
	for( i = 0; i < WD_LIST_SIZE; i++ )
	{
		memcpy( winIcons[i], tempDialog, 2 * sizeof( OBJECT ) );	/* ROOT + WICON */
	}
	
	/* find & init windialogs */
	for( i = 0; i < WD_LIST_SIZE; i++ )
	{
		if( rsrc_gaddr( R_TREE, winDialogList[i], &tempDialog ) == FALSE )
		{
			ShowRsrcAddrFailedDialog();
			ExitPlayer( 1 );
		}
		else
		{
			fix_dial( tempDialog );
			if( i == WD_MODULE || i == WD_PLAYLIST )
			{
				g_winDialogs[i] = create_custom_wdial( tempDialog, winIcons[i], 0, CB_OpenWDialog, CB_ExitObject,
													   NAME | MOVER | CLOSER | SMALLER |
													   SIZER | UPARROW | DNARROW | VSLIDE );
			}
			else
			{
				/* if edit_obj == 0 and there's some one, it will be found & set */
				g_winDialogs[i] = create_wdial( tempDialog, winIcons[i], 0, CB_OpenWDialog, CB_ExitObject );
			}
		}
	}
	
	set_string( g_winDialogs[WD_ABOUT]->tree, ABOUT_VERSION, VERSION );
	
	strcpy( g_winDialogs[WD_ABOUT]->win_name, "About" );
	strcpy( g_winDialogs[WD_PLAYLIST]->win_name, "Playlist" );
	strcpy( g_winDialogs[WD_PANEL]->win_name, "Panel" );
	strcpy( g_winDialogs[WD_PLUGIN]->win_name, "Plugin" );
	strcpy( g_winDialogs[WD_MODULE]->win_name, "Module" );
	
	sprintf( welcomeString, WELCOME_MESSAGE, VERSION );
	set_string( g_winDialogs[WD_PANEL]->tree, PANEL_SONGNAME, welcomeString );
	
	canRefresh = TRUE;	/* for timer */
}

void InitDialogs( void )
{
	int i;
	
	/* used for also for alerts! */
	set_mdial_wincb( HandleMessage );
	
	GetHomePath();
	ReadConfigFile();
	
	for( i = 0; i < WD_LIST_SIZE; i++ )
	{
		g_winDialogs[i] = (WDIALOG*)malloc( sizeof( WDIALOG ) );
		if( VerifyAlloc( g_winDialogs[i] ) == FALSE )
		{
			ExitPlayer( 1 );
		}
	}
	
	for( i = 0; i < WD_LIST_SIZE; i++ )
	{
		winIcons[i] = (OBJECT*)malloc( 2 * sizeof( OBJECT ) );	/* ROOT + WICON */
		if( VerifyAlloc( winIcons[i] ) == FALSE )
		{
			ExitPlayer( 1 );
		}
	}
	
	InitRsc();
	PluginInfoInit();
	ModuleInfoInit();
	PlayListInit();
}

void ShowDefaultDialogs( void )
{
	/* open the main panel */
	open_wdial( g_winDialogs[WD_PANEL], g_panelX, g_panelY );
	PanelVolumeInit();
	
	if( g_repeat == TRUE )
	{
		SelectObject( g_winDialogs[WD_PANEL], PANEL_REPEAT );
	}
	if( g_random == TRUE )
	{
		SelectObject( g_winDialogs[WD_PANEL], PANEL_RANDOM );
	}
	if( g_mute == TRUE )
	{
		SelectObject( g_winDialogs[WD_PANEL], PANEL_MUTE );
	}
	if( g_openPlayList == TRUE )
	{
		PanelPlayList();
	}
}

void ShowSplashImage( void )
{
	GRECT r1, r2;
	
	form_center( splashImage, &r1.g_x, &r1.g_y, &r1.g_w, &r1.g_h );
	
	r1.g_x = splashImage[0].ob_x + splashImage[1].ob_x;
	r1.g_y = splashImage[0].ob_y + splashImage[1].ob_y;
	r1.g_w = splashImage[1].ob_width;
	r1.g_h = splashImage[1].ob_height;
	
	/* r1 is working area, r2 will be complete window size */
	wind_calc_grect( WC_BORDER, 0, &r1, &r2 );
	
	splashImageHandle = wind_create_grect( 0, &r2 );
	if( splashImageHandle > 0 )
	{
		wind_open_grect( splashImageHandle, &r2 );
		objc_draw( splashImage, 1, 0, r1.g_x, r1.g_y, r1.g_w, r1.g_h );
	}
}

void CloseSplashImage( void )
{
	if( splashImageHandle > 0 )
	{
		wind_close( splashImageHandle );
		wind_delete( splashImageHandle );
		splashImageHandle = -1;
	}
}

void DeleteDialogs( void )
{
	int i;
	
	canRefresh = FALSE;
	
	for( i = 0; i < WD_LIST_SIZE; i++ )
	{
		delete_wdial( g_winDialogs[i] );
	}
}

/*
 * Application dialogs and alerts
 */

#ifdef NO_MINT
int ShowMeasureInitFailedDialog( void )
{
	return do_walert( 1, TRUE, "[3][VBL handler installation failed.][Many apps]", "Fatal Error" );
}

int ShowMeasureDeinitFailedDialog( void )
{
	return do_walert( 1, TRUE, "[3][VBL handler deinstallation failed.][Should reboot]", "Fatal Error" );
}
#endif	/* NO_MINT */

int ShowRsrcAddrFailedDialog( void )
{
	return do_walert( 1, TRUE, "[3][rsrc_gaddr() failed.][Bug!]", "Fatal Error" );
}

int ShowRsrcLoadFailedDialog( void )
{
	return do_walert( 1, TRUE, "[3][Couldn't load resource file.][Choose|Abort]", "Error" );
}

int ShowNoAudioFoundDialog( void )
{
	return do_walert( 1, TRUE, "[1][No audio plugin loaded!][Hmm]", "Message" );
}

int ShowNoReplayFoundDialog( void )
{
	return do_walert( 1, TRUE, "[3][No audio plugin supports this format!][Pity]", "Message" );
}

int ShowLoadErrorDialog( char* filename )
{
	char tempString[MXP_FILENAME_MAX+1];
	sprintf( tempString, "[3][Failed to load file|%s|File is probably in use.][WTF?!]", filename );
	return do_walert( 1, TRUE, tempString, "Error" );
}

int ShowOverwriteFileDialog( void )
{
	return do_walert( 1, TRUE, "[1][Do you wish to overwrite|the current file?][Yes|No]", "Message" );
}

int ShowPlayListNotActualDialog( void )
{
	return do_walert( 1, TRUE, "[1][Playlist is not saved!|Do you wish to save it now?][Yes|No]", "Message" );
}

int ShowPluginErrorDialog( int error )
{
	if( error == MXP_UNIMPLEMENTED )
	{
		return do_walert( 1, TRUE, "[1][Unimplemented plugin function!][Next time]", "Message" );
	}
	else
	{
		return do_walert( 1, TRUE, "[1][Plugin returned error code!][Ouch]", "Message" );
	}
}

int ShowAudioInitErrorDialog( char* filename )
{
	char tempString[MXP_FILENAME_MAX+1];
	sprintf( tempString, "[1][Failed to initialize plugin %s.][Skip]", filename );
	return do_walert( 1, TRUE, tempString, "Error" );
}

int ShowBadHeaderDialog( void )
{
	return do_walert( 1, TRUE, "[3][Error in Register()!|mxPlay cannot play this file.][Bad header?]", "Error" );
}

int ShowBadPluginDialog( char* filename )
{
	char tempString[MXP_FILENAME_MAX+1];
	sprintf( tempString, "[3][Bad file header!|\"%s\"|doesn't seem as mxPlay plugin.][Skip]", filename );
	return do_walert( 1, TRUE, tempString, "Error" );
}

int ShowNotEnoughMemoryDialog( void )
{
	return do_walert( 1, TRUE, "[3][Not enough memory|for requested operation.][Damned malloc]", "Message" );
}

int ShowDspLockedDialog( void )
{
	return do_walert( 1, TRUE, "[3][Couldn't lock DSP since it's locked|by another application.][OK|Force]", "Message" );
}

int ShowDmaLockedDialog( void )
{
	return do_walert( 1, TRUE, "[3][Couldn't lock DMA since it's locked|by another application.][OK|Force]", "Message" );
}

int ShowDmaNotLockedDialog( void )
{
	return do_walert( 1, TRUE, "[1][Sound system was not locked!][Impossible!]", "Error" );
}

int ShowCommErrorDialog( void )
{
	return do_walert( 1, TRUE, "[3][Application <-> AES communication failed.][Report it]", "Error" );
}

int Show020RequiredDialog()
{
	return do_walert( 1, TRUE, "[3][Plugin requires at least 68020 CPU!][Falcon?]", "Message" );
}

int ShowFpuRequiredDialog()
{
	return do_walert( 1, TRUE, "[3][Plugin requires at least 68881 FPU!][CT60!]", "Message" );
}

int ShowDspRequiredDialog()
{
	return do_walert( 1, TRUE, "[3][Plugin requires DSP56001!][Falcon?]", "Message" );
}

int ShowDmaRequiredDialog()
{
	return do_walert( 1, TRUE, "[3][Plugin requires DMA sound system!][Falcon?]", "Message" );
}

/*
 * Gigantic (but universal and easy-to-expand)
 * callback functions
 */

static void CB_OpenWDialog( WDIALOG* wd )
{
	if( wd == g_winDialogs[WD_PANEL] )
	{
		set_string( wd->tree, PANEL_PLAYTIME, "00:00" );
	}
}

static BOOL CB_ExitObject( WDIALOG* wd, short obj ) 
{
	short close = FALSE;
	
	obj &= 0x7fff;	/* kill double-click flag */
	
	if( wd == g_winDialogs[WD_PANEL] )
	{
		/*
		 * Panel windialog
		 */
		switch( obj )
		{
			case WD_CLOSER:
				close = TRUE;
				g_quitApp = TRUE;
			break;
			
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
	}
	
	else if( wd == g_winDialogs[WD_ABOUT] )
	{
		/*
		 * About windialog
		 */
		switch( obj )
		{
			case ABOUT_OK:
			case WD_CLOSER:
				PanelInfoApp();
				close = TRUE;
			break;
			
			case ABOUT_LICENSE:
				simple_mdial( licenseDialog, 0 );
			break;
		}
		
		set_state( wd->tree, obj, OS_SELECTED, FALSE );
		redraw_wdobj( wd, obj );
	}
	
	else if( wd == g_winDialogs[WD_PLAYLIST] )
	{
		/*
		 * Playlist windialog
		 */
		switch( obj )
		{
			case WD_CLOSER:
				PanelPlayList();
				close = TRUE;
			break;
			
			case PLAYLIST_LOAD:
				PlayListLoad();
			break;
			
			case PLAYLIST_SAVE:
				PlayListSave();
			break;
			
			case PLAYLIST_ADD_FILE:
				PlayListAddFile();
			break;
			
			case PLAYLIST_ADD_DIR:
				PlayListAddDir();
			break;
			
			case PLAYLIST_SELECT_ALL:
				PlayListSelectAll();
			break;
			
			case PLAYLIST_REMOVE:
				PlayListRemove();
			break;
			
			default:
				/* selected playlist entry? */
				if( wd->tree[obj].ob_type == G_TEXT && get_flag( wd->tree, obj, OF_SELECTABLE ) == TRUE )
				{
					PlayListSelectFile( obj );
				}
			break;
		}
	}
	
	else if( wd == g_winDialogs[WD_PLUGIN] )
	{
		/*
		 * Plugin windialog
		 */
		switch( obj )
		{
			case WD_CLOSER:
				PanelInfoPlugin();
				close = TRUE;
			break;
			
			default:
				PluginInfoButton( obj );
				if( obj == PLUGIN_OK )
				{
					PanelInfoPlugin();
					close = TRUE;
				}
				else
				{
					return FALSE;
				}
			break;
		}
		
		set_state( wd->tree, obj, OS_SELECTED, FALSE );
		redraw_wdobj( wd, obj );
	}
	
	else if( wd == g_winDialogs[WD_MODULE] )
	{
		/*
		 * Module windialog
		 */
		switch( obj )
		{
			case MODULE_OK:
			case WD_CLOSER:
				PanelInfoModule();
				close = TRUE;
			break;
			
			default:
				ModuleInfoButton( obj );
				return FALSE;
			break;
		}
		
		set_state( wd->tree, obj, OS_SELECTED, FALSE );
		redraw_wdobj( wd, obj );
	}

	return close;
}

/*
 * Scroll infoLine and update play time
 */
void PanelDialogRefresh( void )
{
	TEDINFO*		pTed;
	char*			field;
	int				fieldLength;
	char*			infoLine;
	int				infoLineLength;
	int				freeSpace;
	int				stringIndexRev;
	int				sec;
	int				min;
	char			time[10];
	unsigned int	currTime;
	
	/* we are changing resource file */
	if( canRefresh == FALSE )
	{
		return;
	}
	
	/* update time first */
	Vsync();
	redraw_wdobj( g_winDialogs[WD_PANEL], PANEL_PLAYTIME );
	redraw_wdobj( g_winDialogs[WD_PANEL], PANEL_SONGNAME );
	
	/* Update scrolling infoline */
	pTed = (TEDINFO*)get_obspec( g_winDialogs[WD_PANEL]->tree, PANEL_SONGNAME );
	field = pTed->te_ptext;
	fieldLength = pTed->te_txtlen - 1;	/* including terminator '\0' */
	
	if( strcmp( g_panelInfoLine, "" ) == 0 )
	{
		infoLine = welcomeString;
	}
	else
	{
		infoLine = g_panelInfoLine;
	}
	infoLineLength = strlen( infoLine );
	
	if( infoLineLength <= fieldLength )
	{
		/* for the case we used long songname before */
		if( stringIndex > fieldLength )
		{
			stringIndex = 0;
		}

		/* ngname........so */
		memset( field, ' ', fieldLength );
		field[fieldLength] = '\0';
		
		stringIndexRev = fieldLength - stringIndex;
		
		/* place the first character & (possible) remaining ones */
		strncpy( &field[stringIndex], infoLine, MIN( stringIndexRev, infoLineLength ) );
		
		
		/* are there some remaining characters? */
		if( stringIndexRev < infoLineLength )
		{
			strncpy( field, &infoLine[stringIndexRev], infoLineLength - stringIndexRev );
		}

		if( --stringIndex < 0 )
		{
			stringIndex = fieldLength - 1;
		}
	}
	else
	{
		/* _long_ends.start */
		strncpy( field, &infoLine[stringIndex], fieldLength );
		field[fieldLength] = '\0';
		
		/* wrap text */
		freeSpace = stringIndex + fieldLength - infoLineLength;
		if( freeSpace > 0 )
		{
			strncpy( &field[fieldLength - freeSpace], infoLine, freeSpace );
		}
		
		stringIndex++;
		if( stringIndex >= infoLineLength )
		{
			stringIndex = 0;
		}
	}
	
	if( g_modulePlaying == TRUE && g_modulePaused == FALSE )
	{
		if( g_timeMode == TIME_MODE_ADD )
		{
			currTime = TimerGetAddTime();
		}
		else
		{
			currTime = TimerGetSubTime();
		}

		min = currTime / 60;
		sec = currTime % 60;
		sprintf( time, "%02d:%02d", min, sec );
		set_string( g_winDialogs[WD_PANEL]->tree, PANEL_PLAYTIME, time );
	}
	else if( g_modulePlaying == FALSE )
	{
		strcpy( time, "00:00" );
		set_string( g_winDialogs[WD_PANEL]->tree, PANEL_PLAYTIME, time );
	}
}
