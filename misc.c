/*
 * misc.h -- shared code, various topics
 *
 * Copyright (c) 2005-2013 Miro Kropacek; miro.kropacek@gmail.com
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

#include <string.h>
#include <cflib.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <mint/osbind.h>

#include <sys/stat.h>
#include <fcntl.h>

#include "dialogs.h"
#include "misc.h"
#include "mxplay.h"
#include "playlist.h"
#include "skins/skin.h"
#include "file_select.h"
#include "panel.h"

char	g_homePath[MXP_PATH_MAX+1];
char	g_rscName[MXP_FILENAME_MAX+1];
char	g_playlistFilePath[MXP_PATH_MAX+1] = "";
int		g_panelX = -1;
int		g_panelY = -1;
int		g_playlistX = -1;
int		g_playlistY = -1;
int		g_openPlayList = TRUE;

static long	randomSeed = 0x12345678L;

/*
 * Initialize random function
 */
void InitRandom( void )
{
	srandom( randomSeed );
}

/*
 * Add trailing spaces into string
 */
void PadString( char* string, int newLength )
{
	int origLength = strlen( string );

	while( origLength < newLength )	/* there MUST be allocated space for 'newLength' + 1 bytes! */
	{
		string[origLength++] = ' ';
	}
	string[newLength] = '\0';
}

/*
 * Delete trailing spaces from string
 */
void TrimString( char* string )
{
	while( string[strlen( string ) - 1] == ' ' )
	{
		string[strlen( string ) - 1] = '\0';
	}
}

/*
 * Open file function for various callers
 */
void SharedFileOpen( WDIALOG* wd, short obj )
{
	char	path[MXP_PATH_MAX+1] = "";
	char	name[MXP_FILENAME_MAX+1] = "";

	SelectObject( wd, obj );

	/* copy last used ones */
	strcpy( path, g_lastUsedPath );
	strcpy( name, g_lastUsedName );

	if( obj == PANEL_EJECT )
	{
		g_playAfterAdd = TRUE;
	}
	else if( obj == PLAYLIST_ADD_FILE )
	{
		g_playAfterAdd = FALSE;
	}
	g_currFileUpdated = FALSE;	/* reset flag */

	if( select_file( path, name, "", "Select music file(s)", CB_ModuleFileSelect ) == TRUE )
	{
		/* Classic fileselector protocol? */
		if( strcmp( name, "" ) != 0 && strcmp( path, "" ) != 0 )
		{
			if( PlayListAdd( path, name ) == FALSE )
			{
				DeselectObject( wd, obj );
				return;
			}
		}

		if( g_playAfterAdd == TRUE )
		{
			LoadAndPlay();
		}
	}

	DeselectObject( wd, obj );
}

/*
 * Open dir function for various callers
 */
void SharedDirOpen( WDIALOG* wd, short obj )
{
	char	path[MXP_PATH_MAX+1] = "";
	char	name[MXP_FILENAME_MAX+1] = "";

	SelectObject( wd, obj );

	/* copy the last used path */
	strcpy( path, g_lastUsedPath );
	/* we don't care about name */
	strcpy( name, "" );

	if( obj == PANEL_EJECT )
	{
		g_playAfterAdd = g_emptyPlayList;	/* play only if empty playlist */
	}
	else if( obj == PLAYLIST_ADD_DIR )
	{
		g_playAfterAdd = FALSE;
	}
	g_currFileUpdated = FALSE;	/* reset flag */

	if( select_file( path, name, "", "Select music directory", CB_ModuleDirSelect ) == TRUE )
	{
		/* Classic fileselector protocol? */
		if( strcmp( name, "" ) != 0 && strcmp( path, "" ) != 0 )
		{
			/* we haven't that opportunity to select directory */
			if( PlayListAdd( path, "" ) == FALSE )
			{
				DeselectObject( wd, obj );
				return;
			}
		}

		if( g_playAfterAdd == TRUE )
		{
			LoadAndPlay();
		}
	}

	DeselectObject( wd, obj );
}

/*
 * Return WF_TOP status
 */
BOOL IsTopWindow( WDIALOG* wd )
{
	short	winParam[4];

	wind_get( wd->win_handle, WF_TOP, &winParam[0], &winParam[1], &winParam[2], &winParam[3] );

	return winParam[0] == wd->win_handle;
}

/*
 * Count all objects in dialog
 */
short GetObjectCount( OBJECT tree[] )
{
	short count;

	for( count = 0; get_flag( tree, count, OF_LASTOB ) == FALSE; count++ );
	count++;	/* the last one (with OF_LASTOB == TRUE */

	return count;
}

/*
 * Simple round function
 */
short Round( float value )
{
	if( value > 0 )
	{
		value += 0.5;
	}
	else if( value < 0 )
	{
		value -= 0.5;
	}

	return (short)value;
}

/*
 * Disable and redraw wdialog object
 */
void EnableObject( WDIALOG* wd, short obj )
{
	if( get_state( wd->tree, obj, OS_DISABLED ) == TRUE )
	{
		set_state( wd->tree, obj, OS_DISABLED, FALSE );
		redraw_wdobj( wd, obj );
	}
}

/*
 * Enable and redraw wdialog object
 */

void DisableObject( WDIALOG* wd, short obj )
{
	if( get_state( wd->tree, obj, OS_DISABLED ) == FALSE )
	{
		set_state( wd->tree, obj, OS_DISABLED, TRUE );
		redraw_wdobj( wd, obj );
	}
}

/*
 * Deselect and redraw wdialog object
 */
void DeselectObject( WDIALOG* wd, short obj )
{
	if( get_state( wd->tree, obj, OS_SELECTED ) == TRUE )
	{
		set_state( wd->tree, obj, OS_SELECTED, FALSE );
		redraw_wdobj( wd, obj );
	}
}

/*
 * Select and redraw wdialog object
 */
void SelectObject( WDIALOG* wd, short obj )
{
	if( get_state( wd->tree, obj, OS_SELECTED ) == FALSE )
	{
		set_state( wd->tree, obj, OS_SELECTED, TRUE );
		redraw_wdobj( wd, obj );
	}
}

/*
 * Verify the allocation
 */
BOOL VerifyAlloc( void* pointer )
{
	if( pointer == NULL )
	{
		ShowNotEnoughMemoryDialog();
		return FALSE;
	}
	else
	{
		return TRUE;
	}
}

/*
 * Get length in bytes for specified file
 */
unsigned long GetFileNameSize( char* filename )
{
	struct stat	SFileStat;

	if( stat( filename, &SFileStat ) == E_OK )
	{
		return SFileStat.st_size;
	}
	else
	{
		return 0;
	}
}

/*
 * Get directory flag
 */
BOOL IsDirectory( char* path, char* name )
{
	char tempString[MXP_PATH_MAX+MXP_FILENAME_MAX+1];

	CombinePath( tempString, path, name );

	return ( Fattrib( tempString, 0, 0 ) & FA_DIR ) != 0;
}

/* Parse arguments from
 * commandline or ARGV
 */
void ARGVParseArgs( int argc, char* argv[] )
{
	int i;
	char	tempPath[MXP_PATH_MAX+MXP_FILENAME_MAX+1];
	char	tempName[MXP_FILENAME_MAX+1];
	//FILE* fs = fopen("u:\\ram\\log.txt", "a");
	//fprintf( fs, "ARGV:\n" );
	//fprintf( fs, "%s\n", argv[0] );
	//fclose(fs);

	for( i = 1; i < argc; i++ )
	{
		//fs = fopen("u:\\ram\\log.txt", "a");
		//fprintf( fs, "%s\n", argv[i] );
		//fclose(fs);
		if( file_exists( argv[i] ) == TRUE || path_exists( argv[i] ) == TRUE )
		{
			//fs = fopen("u:\\ram\\log.txt", "a");
			//fprintf( fs, "%s: za exists\n", argv[i] );
			//fclose(fs);
			if( strchr( argv[i], '\\' ) == NULL && strchr( argv[i], '/' ) == NULL )
			{

				get_path( tempPath, 0 );	/* we've got just filename without path */
				strcpy( tempName, argv[i] );
				//fs = fopen("u:\\ram\\log.txt", "a");
			//fprintf( fs, "%s: za getpath\n", argv[i] );
			//fclose(fs);
			}
			else
			{
				split_filename( argv[i], tempPath, tempName );
				//fs = fopen("u:\\ram\\log.txt", "a");
			//fprintf( fs, "%s: za splitname\n", argv[i] );
			//fclose(fs);
			}

			if( PlayListAdd( tempPath,tempName ) == FALSE )
			{
				//fs = fopen("u:\\ram\\log.txt", "a");
			//fprintf( fs, "%s: za playlistadd\n", argv[i] );
			//fclose(fs);
				break;
			}
		}
		else
		{
			//split_filename( argv[i], NULL, tempName );
			//ShowLoadErrorDialog( tempName );
			ShowLoadErrorDialog( argv[i] );
		}
	}
	//fclose(fs);
}

/*
 * Parse arguments from
 * d&d and va start
 */
void ParseArgs( char* cmdline )
{
	BOOL	inQuote = FALSE;
	int		i = 0;
	int		j = 0;
	char	path[MXP_PATH_MAX+1];
	char	name[MXP_FILENAME_MAX+1];
	char	all[MXP_PATH_MAX+MXP_FILENAME_MAX+1];
	//	FILE* fs = fopen("u:\\ram\\log.txt", "a");
	//fprintf( fs, "d&d/va cmdline:\n" );
	//fprintf( fs, "%s\n", cmdline );
	//fclose( fs );
	//return;

	while( cmdline[i] != '\0' )
	{
		if( cmdline[i] != '\'' && cmdline[i] != ' ' && inQuote == FALSE )
		{
			/* simple file (not in quotes) */
			while( cmdline[i] != '\0' && cmdline[i] != ' ' )
			{
				all[j++] = cmdline[i++];
			}

			all[j++] = '\0';
			split_filename( all, path, name );
			PlayListAdd( path, name );

			j = 0;
			continue;
		}

		switch( cmdline[i] )
		{
			case '\'':
				i++;
				if( inQuote == TRUE )
				{
					if( cmdline[i] == '\'' )					/* '' -> ' */
					{
						all[j++] = '\'';
						i++;
					}
					else
					{
						inQuote = FALSE;
						all[j++] = '\0';
						split_filename( all, path, name );
						PlayListAdd( path, name );

						j = 0;
					}
				}
				else
				{
					inQuote = TRUE;
				}
			break;

			case ' ':
				if( inQuote == TRUE )
				{
					all[j++] = cmdline[i++];
				}
				else
				{
					i++;
				}
			break;

			default:
				all[j++] = cmdline[i++];
			break;

		}
	}

	//fs = fopen("u:\\ram\\log.txt", "a");
	//fprintf( fs, "d&d/va cmdline:\n" );
	//fprintf( fs, "%s\n", all );
	//fclose( fs );
	//return;
}

/*
 * Combine path and name in one filename
 */
void CombinePath( char* fullpath, char* path, char* name )
{
	if( fullpath != path )	/* this is right, we compare pointers */
	{
		strcpy( fullpath, path );
	}

	if( fullpath[strlen( fullpath ) - 1] != '\\' && fullpath[strlen( fullpath ) - 1] != '/' )
	{
		strcat( fullpath, "\\" );
	}
	if( strcmp( name, "" ) != 0 )
	{
		strcat( fullpath, name );
		if( fullpath[strlen( fullpath ) - 1] == '\\' || fullpath[strlen( fullpath ) - 1] == '/' )
		{
			fullpath[strlen( fullpath ) - 1]  = '\0';	/* we don't want path/name.ext/ */
		}
	}
}

void GetHomePath( void )
{
	char	temp[MXP_PATH_MAX+1];
	char*	path = NULL;

	shel_envrn( &path, "HOME=" );
	if( path != NULL && strlen( path ) > 0 )
	{
		strcpy( temp, path );
		strcat( temp, "\\defaults" );
		if( path_exists( temp ) )
		{
			/* $HOME/defaults */
			strcpy( g_homePath, temp );
		}
		else
		{
			/* $HOME */
			strcpy( g_homePath, path );
		}
	}
	else
	{
		/* application dir */
		strcpy( g_homePath, gl_appdir );
	}
}

void ReadConfigFile( void )
{
	char	temp[MXP_FILENAME_MAX+1];
	FILE*	fs;

	strcpy( g_rscName, DEFAULT_RSC_FILE );	/* as default */

	CombinePath( temp, g_homePath, CNF_FILE );

	if( file_exists( temp ) == TRUE )
	{
		fs = fopen( temp, "r" );

		while( fscanf( fs, "%s", temp ) != EOF )
		{
			if( strcmp( temp, "rsc" ) == 0 )
			{
				fgetc( fs );	/* TAB */
				fgets( g_rscName, MXP_FILENAME_MAX+1, fs );
				g_rscName[strlen( g_rscName ) - 1] = '\0';	/* ignore newline char */
			}
			else if( strcmp( temp, "panelX" ) == 0 )
			{
				fscanf( fs, "%d", &g_panelX );
			}
			else if( strcmp( temp, "panelY" ) == 0 )
			{
				fscanf( fs, "%d", &g_panelY );
			}
			else if( strcmp( temp, "playlistX" ) == 0 )
			{
				fscanf( fs, "%d", &g_playlistX );
			}
			else if( strcmp( temp, "playlistY" ) == 0 )
			{
				fscanf( fs, "%d", &g_playlistY );
			}
			else if( strcmp( temp, "playlistFile" ) == 0 )
			{
				fgetc( fs );	/* TAB */
				fgets( g_playlistFilePath, MXP_PATH_MAX+1, fs );
				g_playlistFilePath[strlen( g_playlistFilePath ) - 1] = '\0';	/* ignore newline char */
			}
			else if( strcmp( temp, "randomSeed" ) == 0 )
			{
				fscanf( fs, "%ld", &randomSeed );
			}
			else if( strcmp( temp, "timeMode" ) == 0 )
			{
				fscanf( fs, "%d", &g_timeMode );
			}
			else if( strcmp( temp, "repeat" ) == 0 )
			{
				fscanf( fs, "%d", &g_repeat );
			}
			else if( strcmp( temp, "random" ) == 0 )
			{
				fscanf( fs, "%d", &g_random );
			}
			else if( strcmp( temp, "openPlayList" ) == 0 )
			{
				fscanf( fs, "%d", &g_openPlayList );
			}
		}

		fclose( fs );
	}
}

void WriteConfigFile( void )
{
	char	temp[MXP_PATH_MAX+1];
	FILE*	fs;

	CombinePath( temp, g_homePath, CNF_FILE );
	fs = fopen( temp, "w" );

	/* name of resource file */
	fprintf( fs, "%s", "rsc" );
	fprintf( fs, "%s", "\t" );
	fprintf( fs, "%s", g_rscName );
	fprintf( fs, "%s", "\n" );

	/* x position of panel */
	fprintf( fs, "%s", "panelX" );
	fprintf( fs, "%s", "\t" );
	fprintf( fs, "%d", g_winDialogs[WD_PANEL]->work.g_x );
	fprintf( fs, "%s", "\n" );

	/* y position of panel */
	fprintf( fs, "%s", "panelY" );
	fprintf( fs, "%s", "\t" );
	fprintf( fs, "%d", g_winDialogs[WD_PANEL]->work.g_y );
	fprintf( fs, "%s", "\n" );

	/* x position of playlist */
	fprintf( fs, "%s", "playlistX" );
	fprintf( fs, "%s", "\t" );
	fprintf( fs, "%d", g_winDialogs[WD_PLAYLIST]->work.g_x );
	fprintf( fs, "%s", "\n" );

	/* y position of playlist */
	fprintf( fs, "%s", "playlistY" );
	fprintf( fs, "%s", "\t" );
	fprintf( fs, "%d", g_winDialogs[WD_PLAYLIST]->work.g_y );
	fprintf( fs, "%s", "\n" );

	/* playlist file */
	if( strcmp( g_playlistFilePath, "" ) != 0 )
	{
		fprintf( fs, "%s", "playlistFile" );
		fprintf( fs, "%s", "\t" );
		fprintf( fs, "%s", g_playlistFilePath );
		fprintf( fs, "%s", "\n" );
	}

	/* new random seed */
	randomSeed = random();
	fprintf( fs, "%s", "randomSeed" );
	fprintf( fs, "%s", "\t" );
	fprintf( fs, "%ld", randomSeed );
	fprintf( fs, "%s", "\n" );

	/* playtime mode */
	fprintf( fs, "%s", "timeMode" );
	fprintf( fs, "%s", "\t" );
	fprintf( fs, "%d", g_timeMode );
	fprintf( fs, "%s", "\n" );

	/* repeat on/off */
	fprintf( fs, "%s", "repeat" );
	fprintf( fs, "%s", "\t" );
	fprintf( fs, "%d", g_repeat );
	fprintf( fs, "%s", "\n" );

	/* random on/off */
	fprintf( fs, "%s", "random" );
	fprintf( fs, "%s", "\t" );
	fprintf( fs, "%d", g_random );
	fprintf( fs, "%s", "\n" );

	/* opened playlist? */
	fprintf( fs, "%s", "openPlayList" );
	fprintf( fs, "%s", "\t" );
	fprintf( fs, "%d", ( g_winDialogs[WD_PLAYLIST]->mode & WD_OPEN ) ? TRUE : FALSE );
	fprintf( fs, "%s", "\n" );

	fclose( fs );
}
