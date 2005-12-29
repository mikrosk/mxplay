/*
 * misc.h -- shared code, various topics (definitions and external declarations)
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

#ifndef _MISC_H_
#define _MISC_H_

#include <cflib.h>
#include "mxplay.h"

#define CNF_FILE			"mxplay.inf"
#define DEFAULT_RSC_FILE	"default.rsc"
#define DEFAULT_M3U_FILE	"default.m3u"

extern void			WriteConfigFile( void );
extern void			ReadConfigFile( void );
extern void			GetHomePath( void );
extern unsigned long GetCurrentTime( void );
extern void			CombinePath( char* fullpath, char* path, char* name );
extern BOOL			VerifyAlloc( void* pointer );
extern void			ParseArgs( char* cmdline );
extern unsigned long GetFileNameSize( char* filename );
extern BOOL			IsDirectory( char* path, char* name );
extern void			DeselectObject( WDIALOG* wd, short obj );
extern void			SelectObject( WDIALOG* wd, short obj );
extern void			ARGVParseArgs( int argc, char* argv[] );
extern short		Round( float value );
extern BOOL			IsTopWindow( WDIALOG* wd );
extern void			SharedFileOpen( WDIALOG* wd, short obj );
extern void			SharedDirOpen( WDIALOG* wd, short obj );
extern void			UnpadString( char* string );
extern void			PadString( char* string, int newLength );
extern void			InitRandom( void );
extern void			EnableObject( WDIALOG* wd, short obj );
extern void			DisableObject( WDIALOG* wd, short obj );
extern short		GetObjectCount( OBJECT tree[] );

extern char		g_homePath[PATH_MAX+1];
extern char		g_rscName[FILENAME_MAX+1];
extern char		g_playlistFile[PATH_MAX+1];
extern int		g_panelX;
extern int		g_panelY;
extern int		g_playlistX;
extern int		g_playlistY;
extern int		g_openPlayList;

#endif
