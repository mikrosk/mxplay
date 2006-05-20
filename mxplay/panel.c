/*
 * panel.c -- button handling for Panel dialog
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
#include <string.h>
#include <mint/falcon.h>

#include <stdio.h>

#include "dialogs.h"
#include "skins/skin.h"
#include "mxplay.h"
#include "audio_plugins.h"
#include "panel.h"
#include "misc.h"
#include "av.h"
#include "file_select.h"
#include "filelist.h"
#include "playlist.h"
#include "plugin_info.h"
#include "vbl_timer.h"
#include "module_info.h"

//#define xxx	/* fast hack for debug outputs */

int				g_timeMode = TIME_MODE_ADD;
BOOL			g_repeat = FALSE;
BOOL			g_random = FALSE;
BOOL			g_mute = FALSE;

static BOOL		playlistOpened = FALSE;
static BOOL		infoAppOpened = FALSE;
static BOOL		infoModOpened = FALSE;
static BOOL		infoPlgOpened = FALSE;
static float	volumeSliderX;
static short	oldVolumeData;

/*
 * Select chosen object on panel, deselect all the others
 * and redraw everything.
 */
static void PanelActivateObject( WDIALOG* wd, short selectedObj )
{
	short obj;

	obj = wd->tree[PANEL_BACKGROUND].ob_head;
	
	/* go trought all panel objects */
	while( obj != PANEL_BACKGROUND && obj != -1 )
	{
		/* change only these objects */
		if( obj != selectedObj
			&& ( obj == PANEL_EJECT
				 || obj == PANEL_PLAY
				 || obj == PANEL_FWD
				 || obj == PANEL_RWD
				 || obj == PANEL_PAUSE
				 || obj == PANEL_NEXT
				 || obj == PANEL_PREV
				 || obj == PANEL_STOP ) )
		{
			DeselectObject( wd, obj );
		}
		else if( obj == selectedObj )
		{
			SelectObject( wd, obj );
		}
		
		obj = wd->tree[obj].ob_next;
	}
}

/*
 * Set current volume as attenuation
 */
static void PanelVolumeSet( short mode, short volume )
{
	volume &= ( VOLUME_STAGES - 1 );
	volume = VOLUME_MAX - volume;
	
	Soundcmd( mode, volume << 4 );
	oldVolumeData = volume << 4;
}

/*
 * Get volume from the current attenuation
 */
static short PanelVolumeGet( short mode )
{
	short att;
	
	att = (short)Soundcmd( mode, -1 );	/* SND_INQUIRE */
	
	att >>= 4;
	att &= ( VOLUME_STAGES - 1 );
	
	return VOLUME_MAX - att;
}

/*
 * Increase volume by 'count'
 */
static void PanelVolumeUpCommon( int count )
{
	short vol;
	
	vol = PanelVolumeGet( LTATTEN );
	if( vol + count > VOLUME_MAX )
	{
		vol = VOLUME_MAX;
	}
	else
	{
		vol += count;
	}
	PanelVolumeSet( LTATTEN, vol );
	
	vol = PanelVolumeGet( RTATTEN );
	if( vol + count > VOLUME_MAX )
	{
		vol = VOLUME_MAX;
	}
	else
	{
		vol += count;
	}
	PanelVolumeSet( RTATTEN, vol );
}

/*
 * Decrease volume by 'count'
 */
static void PanelVolumeDownCommon( int count )
{
	short vol;
	
	vol = PanelVolumeGet( LTATTEN );
	if( vol - count < VOLUME_MIN )
	{
		vol = VOLUME_MIN;
	}
	else
	{
		vol -= count;
	}
	PanelVolumeSet( LTATTEN, vol );
	
	vol = PanelVolumeGet( RTATTEN );
	if( vol - count < VOLUME_MIN )
	{
		vol = VOLUME_MIN;
	}
	else
	{
		vol -= count;
	}
	PanelVolumeSet( RTATTEN, vol );
}

/*
 * Set the position of volume slider according to the current volume
 */
static void PanelVolumeSliderSet( void )
{
	short boxWidth;
	short sliderX;
	short sliderWidth;
	float delta;
	short vol;
	
	vol = PanelVolumeGet( LTATTEN );	/* we care about left channel only */
	
	boxWidth = g_winDialogs[WD_PANEL]->tree[PANEL_VOLUME_SLIDER_BOX].ob_width;
	sliderX = g_winDialogs[WD_PANEL]->tree[PANEL_VOLUME_SLIDER].ob_x;
	sliderWidth = g_winDialogs[WD_PANEL]->tree[PANEL_VOLUME_SLIDER].ob_width;
	
	delta = (float)( boxWidth - sliderWidth ) / (float)VOLUME_MAX;

	g_winDialogs[WD_PANEL]->tree[PANEL_VOLUME_SLIDER].ob_x = (short)( vol * delta );
	redraw_wdobj( g_winDialogs[WD_PANEL], PANEL_VOLUME_SLIDER );
	redraw_wdobj( g_winDialogs[WD_PANEL], PANEL_VOLUME_SLIDER_BOX );
}

/*
 * Set the same attenuation for both left and right channel
 */
void PanelVolumeInit( void )
{
	short data;

	data = (short)Soundcmd( LTATTEN, -1 );	/* SND_INQUIRE */
	Soundcmd( RTATTEN, data );	/* right channel must have the same value */
	oldVolumeData = data;
	
	PanelVolumeSliderSet();
	
	volumeSliderX = g_winDialogs[WD_PANEL]->tree[PANEL_VOLUME_SLIDER].ob_x;
}

/*
 * Update volume slider (only if needed)
 */
void PanelVolumeSliderUpdate( void )
{
	short data;

	data = (short)Soundcmd( LTATTEN, -1 );	/* SND_INQUIRE */
	
	if( data != oldVolumeData )
	{
		PanelVolumeSliderSet();
		volumeSliderX = g_winDialogs[WD_PANEL]->tree[PANEL_VOLUME_SLIDER].ob_x;
		
		oldVolumeData = data;
	}
}

/*
 * Functions for each object (cicon)
 */

void PanelPlayTime( void )
{
	if( g_timeMode == TIME_MODE_ADD )
	{
		g_timeMode = TIME_MODE_SUB;
	}
	else
	{
		g_timeMode = TIME_MODE_ADD;
	}
}

void PanelFileOpen( void )
{
	SharedFileOpen( g_winDialogs[WD_PANEL], PANEL_EJECT );
}

void PanelDirOpen( void )
{
	SharedDirOpen( g_winDialogs[WD_PANEL], PANEL_EJECT );
}

void PanelPlay( void )
{
	int ret;
	
	PanelActivateObject( g_winDialogs[WD_PANEL], PANEL_PLAY );
	
	/* no file loaded yet */
	if( strcmp( g_currModuleName, "-" ) == 0 )
	{
		DeselectObject( g_winDialogs[WD_PANEL], PANEL_PLAY );
		return;
	}
	else
	{
		if( g_modulePlaying == FALSE )
		{
			if( AudioPluginLockResources() == TRUE )
			{
				if( ( ret = AudioPluginModulePlay() ) == MXP_OK )
				{
					timer_reset( AudioPluginGetPlayTime() );	/* get playtime */
				}
				else
				{
					ShowPluginErrorDialog( ret );
					/* most probably some HW registers were changed -> stop, unset and free */
					PanelStop();
				}
			}
			else
			{
				/* some could be already locked, some not */
				AudioPluginFreeResources();
				DeselectObject( g_winDialogs[WD_PANEL], PANEL_PLAY );
			}
		}
		else
		{
			PanelStop();
			PanelPlay();
		}
	}
}

void PanelStop( void )
{
	int ret;
	
	PanelActivateObject( g_winDialogs[WD_PANEL], PANEL_STOP );
	
	if( g_modulePlaying == TRUE )
	{
		if( ( ret = AudioPluginModuleStop() ) != MXP_OK )
		{
			ShowPluginErrorDialog( ret );
		}
		AudioPluginFreeResources();
	}
	
	DeselectObject( g_winDialogs[WD_PANEL], PANEL_STOP );
}

void PanelPause( void )
{
	int ret;
	
	if( g_modulePlaying == TRUE )
	{
		if( g_modulePaused == FALSE )
		{
			PanelActivateObject( g_winDialogs[WD_PANEL], PANEL_PAUSE );
		}
		else
		{
			PanelActivateObject( g_winDialogs[WD_PANEL], PANEL_PLAY );
		}
		
		if( ( ret = AudioPluginModulePause() ) != MXP_OK )
		{
			ShowPluginErrorDialog( ret );
			g_modulePaused = FALSE;
			PanelActivateObject( g_winDialogs[WD_PANEL], PANEL_PLAY );
		}
		else
		{
			timer_pause();
		}
	}
}

void PanelFwd( void )
{
	int ret;
	
	if( g_modulePlaying == TRUE )
	{
	
		PanelActivateObject( g_winDialogs[WD_PANEL], PANEL_FWD );
	
		if( ( ret = AudioPluginModuleFwd( g_withShift ) ) != MXP_OK )
		{
			ShowPluginErrorDialog( ret );
			PanelActivateObject( g_winDialogs[WD_PANEL], PANEL_PLAY );
		}
		
		/* was big forward-step */
		g_withShift = FALSE;
		
		DeselectObject( g_winDialogs[WD_PANEL], PANEL_FWD );
	}
}

void PanelRwd( void )
{
	int ret;
	
	if( g_modulePlaying == TRUE )
	{
	
		PanelActivateObject( g_winDialogs[WD_PANEL], PANEL_RWD );
	
		if( ( ret = AudioPluginModuleRwd( g_withShift ) ) != MXP_OK )
		{
			ShowPluginErrorDialog( ret );
			PanelActivateObject( g_winDialogs[WD_PANEL], PANEL_PLAY );
		}
		
		/* was big rewind-step */
		g_withShift = FALSE;
		
		DeselectObject( g_winDialogs[WD_PANEL], PANEL_RWD );
	}
}

void PanelPrev( void )
{
	PanelActivateObject( g_winDialogs[WD_PANEL], PANEL_PREV );
	
	FileListSetPrev();
	LoadAndPlay();

	DeselectObject( g_winDialogs[WD_PANEL], PANEL_PREV );
}

void PanelNext( void )
{
	FILE* fs;
	PanelActivateObject( g_winDialogs[WD_PANEL], PANEL_NEXT );
	
	if( FileListSetNext() == TRUE )
	{
		#ifdef xxx
		fs = fopen("d:\\log.txt", "a");
		fprintf( fs, "pred load and play, g_currfile: %s\n", g_currName );
		fclose( fs );
		#endif
		
		LoadAndPlay();
		
		#ifdef xxx
		fs = fopen("d:\\log.txt", "a");
		fprintf( fs, "za load and play, g_currfile: %s\n", g_currName );
		fclose( fs );
		#endif
	}
	else if( g_modulePlaying == TRUE )
	{
		PanelStop();
	}
	
	DeselectObject( g_winDialogs[WD_PANEL], PANEL_NEXT );
}

void PanelInfoPlugin( void )
{
	if( infoPlgOpened == TRUE )
	{
		DeselectObject( g_winDialogs[WD_PANEL], PANEL_INFO_PLG );
		close_wdial( g_winDialogs[WD_PLUGIN] );
		infoPlgOpened = FALSE;
	}
	else
	{
		SelectObject( g_winDialogs[WD_PANEL], PANEL_INFO_PLG );
		open_wdial( g_winDialogs[WD_PLUGIN], -1, -1 );
		PluginInfoUpdate();
		infoPlgOpened = TRUE;
	}
}

void PanelInfoModule( void )
{
	if( infoModOpened == TRUE )
	{
		DeselectObject( g_winDialogs[WD_PANEL], PANEL_INFO_MOD );
		close_wdial( g_winDialogs[WD_MODULE] );
		infoModOpened = FALSE;
	}
	else
	{
		SelectObject( g_winDialogs[WD_PANEL], PANEL_INFO_MOD );
		open_wdial( g_winDialogs[WD_MODULE], -1, -1 );
		ModuleInfoUpdate();
		infoModOpened = TRUE;
	}
}

void PanelInfoApp( void )
{
	if( infoAppOpened == TRUE )
	{
		DeselectObject( g_winDialogs[WD_PANEL], PANEL_INFO_APP );
		close_wdial( g_winDialogs[WD_ABOUT] );
		infoAppOpened = FALSE;
	}
	else
	{
		SelectObject( g_winDialogs[WD_PANEL], PANEL_INFO_APP );
		open_wdial( g_winDialogs[WD_ABOUT], -1, -1 );
		infoAppOpened = TRUE;
	}
}

void PanelPlayList( void )
{
	if( playlistOpened == TRUE )
	{
		DeselectObject( g_winDialogs[WD_PANEL], PANEL_PLAYLIST );
		close_wdial( g_winDialogs[WD_PLAYLIST] );
		playlistOpened = FALSE;
	}
	else
	{
		SelectObject( g_winDialogs[WD_PANEL], PANEL_PLAYLIST );
		
		if( g_playlistX == -1 || g_playlistY == -1 )
		{
			open_wdial( g_winDialogs[WD_PLAYLIST], -1, -1 );
		}
		else
		{
			open_wdial( g_winDialogs[WD_PLAYLIST], g_playlistX, g_playlistY );
			g_playlistX = -1;
			g_playlistY = -1;
			
		}
		
		PlayListRefresh( TRUE );
		
		playlistOpened = TRUE;
	}
}

void PanelMute( void )
{
	if( g_mute == FALSE )
	{
		/* illegal connection */
		if( g_hasDma == TRUE )
		{
			Devconnect( DMAPLAY, DAC, CLK25M, CLKOLD, NO_SHAKE );
		}
		else /* yamaha */
		{
			Devconnect( ADC, DAC, CLK25M, CLKOLD, NO_SHAKE );
		}
		Soundcmd( SETPRESCALE, 0 );	/* CCLK_6K */
		
		g_mute = TRUE;
		SelectObject( g_winDialogs[WD_PANEL], PANEL_MUTE );
	}
	else
	{
		g_mute = FALSE;
		DeselectObject( g_winDialogs[WD_PANEL], PANEL_MUTE );
	}
}

void PanelRandom( void )
{
	if( g_random == FALSE )
	{
		g_random = TRUE;
		SelectObject( g_winDialogs[WD_PANEL], PANEL_RANDOM );
	}
	else
	{
		g_random = FALSE;
		DeselectObject( g_winDialogs[WD_PANEL], PANEL_RANDOM );
	}

}

void PanelRepeat( void )
{
	if( g_repeat == FALSE )
	{
		g_repeat = TRUE;
		SelectObject( g_winDialogs[WD_PANEL], PANEL_REPEAT );
	}
	else
	{
		g_repeat = FALSE;
		DeselectObject( g_winDialogs[WD_PANEL], PANEL_REPEAT );
	}
	
}

void PanelVolumeUp( void )
{
	if( g_withShift == TRUE )
	{
		PanelVolumeUpCommon( VOLUME_STAGES / 4 );	/* 1/4 of all stages */
	}
	else
	{
		PanelVolumeUpCommon( 1 );	/* one stage */
	}

	PanelVolumeSliderSet();
}

void PanelVolumeDown( void )
{
	if( g_withShift == TRUE )
	{
		PanelVolumeDownCommon( VOLUME_STAGES / 4 );	/* 1/4 of all stages */
	}
	else
	{
		PanelVolumeDownCommon( 1 );	/* one stage */
	}

	PanelVolumeSliderSet();
}

void PanelVolumeSlider( short deltaX )
{
	short sliderX;
	short sliderWidth;
	short boxWidth;
	short delta;
	
	sliderX = g_winDialogs[WD_PANEL]->tree[PANEL_VOLUME_SLIDER].ob_x;
	sliderWidth = g_winDialogs[WD_PANEL]->tree[PANEL_VOLUME_SLIDER].ob_width;
	boxWidth = g_winDialogs[WD_PANEL]->tree[PANEL_VOLUME_SLIDER_BOX].ob_width;
	
	volumeSliderX += deltaX;
	if( volumeSliderX < 0.0 )
	{
		volumeSliderX = 0.0;
	}
	else if( volumeSliderX > boxWidth - sliderWidth )
	{
		volumeSliderX = boxWidth - sliderWidth;
	}
	
	delta = Round( (float)( volumeSliderX - sliderX ) / ( (float)( boxWidth - sliderWidth ) / (float)VOLUME_MAX ) );
	
	if( delta > 0 )
	{
		PanelVolumeUpCommon( delta );
	}
	else if( delta < 0 )
	{
		PanelVolumeDownCommon( -delta );
	}
	
	if( delta != 0 )
	{
		PanelVolumeSliderSet();
	}
}

void PanelVolumeSliderBox( short mx )
{
	short sliderWidth;
	short ox, oy;
	
	sliderWidth = g_winDialogs[WD_PANEL]->tree[PANEL_VOLUME_SLIDER].ob_width;
	
	objc_offset( g_winDialogs[WD_PANEL]->tree, PANEL_VOLUME_SLIDER, &ox, &oy );
	
	if( mx < ox )
	{
		PanelVolumeSlider( mx - sliderWidth / 2 - ox );
	}
	else if( mx > ox + sliderWidth )
	{
		PanelVolumeSlider( mx + sliderWidth / 2 - ( ox + sliderWidth ) );
	}
	
	DeselectObject( g_winDialogs[WD_PANEL], PANEL_VOLUME_SLIDER );
}

void PanelChangeSkin( void )
{
	char				path[MXP_PATH_MAX+1] = "skins";
	char				name[MXP_FILENAME_MAX+1] = "";
	struct SWinDialog	SDialog[WD_LIST_SIZE];
	short				obj;
	short				parent;
	int					i, j;
	BOOL				rscInMemory = FALSE;
	
	if( strcmp( g_rscName, "" ) != 0 )
	{
		rscInMemory = TRUE;
	}
	
	strcpy( name, g_rscName );	/* as default last (current) rsc file */

	if( select_file( path, name, "*.RSC", "Select skin resource", CB_RscFileSelect ) == TRUE )
	{
		/* Classic fileselector protocol? */
		if( strcmp( name, "" ) != 0 && strcmp( path, "" ) != 0 )
		{
			strcpy( g_rscName, name );
		}
		
		if( rscInMemory == TRUE )
		{
			for( i = 0; i < WD_LIST_SIZE; i++ )
			{
				SDialog[i].mode = g_winDialogs[i]->mode;
				SDialog[i].x = g_winDialogs[i]->work.g_x;
				SDialog[i].y = g_winDialogs[i]->work.g_y;
				
				for( j = 0; j < 32; j++ )
				{
					SDialog[i].selectedObj[j] = -1;
				}
				
				parent = ROOT;
				obj = g_winDialogs[i]->tree[parent].ob_head;
				
				if( g_winDialogs[i]->tree[obj].ob_head != -1 )
				{
					/* there's some child as background (cicon) */
					parent = obj;
					obj = g_winDialogs[i]->tree[parent].ob_head;
				}
								
				/*
				 * go trought all panel objects (other objects have no chance
				 * to be selected or selectable at all
				 */
				j = 0;
				while( obj != parent && obj != -1 )
				{
					/* check selected objects only */
					if( get_state( g_winDialogs[i]->tree, obj, OS_SELECTED ) == TRUE )
					{
						SDialog[i].selectedObj[j++] = obj;
					}
					
					obj = g_winDialogs[i]->tree[obj].ob_next;
				}
			}
			
			DeleteDialogs();
			rsrc_free();
		}
		
		InitRsc();
		
		if( rscInMemory == TRUE )
		{
			PluginInfoInit();
			ModuleInfoInit();
			
			for( i = 0; i < WD_LIST_SIZE; i++ )
			{
				j = 0;
				while( SDialog[i].selectedObj[j] != -1 )
				{
					set_state( g_winDialogs[i]->tree, SDialog[i].selectedObj[j], OS_SELECTED, TRUE );
					redraw_wdobj( g_winDialogs[i], SDialog[i].selectedObj[j] );
					j++;
				}
				
				if( ( SDialog[i].mode & WD_OPEN ) != 0 )
				{
					open_wdial( g_winDialogs[i], SDialog[i].x, SDialog[i].y );
				}
			}
			
			PanelVolumeInit();
			PlayListReinit();
			PluginInfoReinit();
			ModuleInfoReinit();
		}
	}
}

/*
 * Load and play last used module.
 * Beware, all files have to be in file list yet!!!
 */
void LoadAndPlay( void )
{
	char ext[MXP_FILENAME_MAX+1];
	FILE* fs;

	if( g_currPath != NULL && g_currName != NULL )	/* only if some file in playlist */
	{
		if( g_modulePlaying == TRUE )
		{
			#ifdef xxx
			fs = fopen("d:\\log.txt", "a");
			fprintf( fs, "pred panel stop, g_currfile: %s\n", g_currName );
			fclose( fs );
			#endif
		
			PanelStop();
		
			#ifdef xxx
			fs = fopen("d:\\log.txt", "a");
			fprintf( fs, "za stop, g_currfile: %s\n", g_currName );
			fclose( fs );
			#endif
		}
		
		split_extension( g_currName, NULL, ext );
		
		#ifdef xxx
		fs = fopen("d:\\log.txt", "a");
		fprintf( fs, "hladam plugin, g_currfile: %s\n", g_currName );
		fclose( fs );
		#endif
		
		g_pCurrAudioPlugin = LookForAudioPlugin( ext );
		
		#ifdef xxx
		fs = fopen("d:\\log.txt", "a");
		fprintf( fs, "nasiel plugin, g_currfile: %s\n", g_currName );
		fclose( fs );
		#endif
		
		if( g_pCurrAudioPlugin == NULL )	/* this should be impossible */
		{
			ShowNoReplayFoundDialog();
		}
		else
		{
			#ifdef xxx
			fs = fopen("d:\\log.txt", "a");
			fprintf( fs, "ide nahrat module, g_currfile: %s\n", g_currName );
			fclose( fs );
			#endif
			
			if( LoadAudioModule( g_currPath, g_currName ) == TRUE )
			{
				#ifdef xxx
				fs = fopen("d:\\log.txt", "a");
				fprintf( fs, "nahral module, g_currfile: %s\n", g_currName );
				fclose( fs );
				#endif
				
				AudioPluginGetInfoLine( g_pCurrAudioPlugin->pSParameter );
				
				#ifdef xxx
				fs = fopen("d:\\log.txt", "a");
				fprintf( fs, "za infoline, g_currfile: %s\n", g_currName );
				fclose( fs );
				#endif
				
				PluginInfoUpdate();
				
				#ifdef xxx
				fs = fopen("d:\\log.txt", "a");
				fprintf( fs, "za infoupdate, g_currfile: %s\n", g_currName );
				fclose( fs );
				#endif
				
				PanelPlay();
				
				#ifdef xxx
				fs = fopen("d:\\log.txt", "a");
				fprintf( fs, "za play, g_currfile: %s\n", g_currName );
				fclose( fs );
				#endif
				
				ModuleInfoUpdate();
				
				#ifdef xxx
				fs = fopen("d:\\log.txt", "a");
				fprintf( fs, "za infoupdate 2, g_currfile: %s\n", g_currName );
				fclose( fs );
				#endif
				
				PlayListDisplayTrackNumber();
			}
			else
			{
				#ifdef xxx
				fs = fopen("d:\\log.txt", "a");
				fprintf( fs, "load module hodil error!, g_currfile: %s\n", g_currName );
				fclose( fs );
				#endif
			}
		}
	}
}
