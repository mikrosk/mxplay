/*
 * filelist.h -- file operations - recursive searching, adding to file/playlist (definitions and external declarations)
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

#ifndef _FILELIST_H_
#define _FILELIST_H_

#include "mxplay.h"

#define MODULE_PARAMS_MAX	32
#define	MODULE_HISTORY_SIZE	128

struct SFileListFile
{
	BOOL					selected;
	BOOL					disabled;
	BOOL					current;
	long					number;
	char*					name;
	char*					path;
	struct SFileListFile*	pSPrev;
	struct SFileListFile*	pSNext;
};

extern BOOL						FileListAddFile( char* path, char* name );
extern BOOL						FileListAddDirectory( char* path, char* name );
extern BOOL						FileListSetNext( void );
extern void						FileListSetPrev( void );
extern struct SFileListFile*	FileListGetEntry( int fileNumber );
extern void						FileListSetCurrFile( struct SFileListFile* pSFile );
extern struct SFileListFile*	FileListGetFirstEntry( void );
extern void						FileListClear( struct SFileListFile* pSList );
extern struct SFileListFile*	FileListRemove( struct SFileListFile* pSFile );
extern void						FileListSaveToHistory( void );
extern long						FileListGetFileNumber( struct SFileListFile* pSFile );

extern BOOL	g_currFileUpdated;
extern char	g_lastUsedName[MXP_FILENAME_MAX+1];
extern char	g_lastUsedPath[MXP_PATH_MAX+1];
extern long	g_filesCount;

#endif
