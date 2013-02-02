/*
 * filelist.c -- file operations - recursive searching, adding to file/playlist
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

#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <stdio.h>
#include <cflib.h>

#include <fcntl.h>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>

#include "filelist.h"
#include "mxplay.h"
#include "audio_plugins.h"
#include "misc.h"
#include "dialogs.h"
#include "playlist.h"
#include "panel.h"

char	g_lastUsedName[MXP_FILENAME_MAX+1] = "";
char	g_lastUsedPath[MXP_PATH_MAX+1] = "";
BOOL	g_currFileUpdated = FALSE;
long	g_filesCount = 0;

static struct	SFileListFile* pFileListFile = NULL;
static struct	SFileListFile* pCurrFileListFile = NULL;
static long		moduleCounter = 0;
static long		moduleHistory[MODULE_HISTORY_SIZE];
static long		moduleHistoryUsed = 0;

static struct SFileListFile* FileListGetLastEntry( void )
{
	struct SFileListFile* pSList = FileListGetFirstEntry();

	if( pSList != NULL )
	{
		while( pSList->pSNext != NULL )
		{
			pSList = pSList->pSNext;
		}
	}
	return pSList;
}

/*
 * return the first entry in the filelist
 */
struct SFileListFile* FileListGetFirstEntry( void )
{
	return pFileListFile;
}

/*
 * Return file number in range 1 - g_filesCount for given file structure.
 */
long FileListGetFileNumber( struct SFileListFile* pSFile )
{
	struct SFileListFile* pSTempFile;
	struct SFileListFile* pSInputFile;

	long number = 0;

	if( pSFile == NULL )
	{
		pSInputFile = pCurrFileListFile;
	}
	else
	{
		pSInputFile = pSFile;
	}

	if( pSInputFile == NULL )
	{
		// current file deleted
		return -1;
	}

	pSTempFile = FileListGetFirstEntry();

	while( pSTempFile != NULL )
	{
		number++;

		if( pSTempFile->number == pSInputFile->number )	/* faster than comparing strings... */
		{
			return number;
		}

		pSTempFile = pSTempFile->pSNext;
	}

	return -1;
}

/*
 * Return file structure for given number.
 */
struct SFileListFile* FileListGetEntry( int fileNumber )
{
	struct SFileListFile* pSFile = FileListGetFirstEntry();

	while( pSFile != NULL )
	{
		if( pSFile->number == fileNumber )
		{
			return pSFile;
		}
		pSFile = pSFile->pSNext;
	}

	return NULL;
}

void FileListSetCurrFile( struct SFileListFile* pSFile )
{
	char tempString[MXP_PATH_MAX+1];

	pCurrFileListFile = pSFile;

	CombinePath( tempString, pSFile->path, pSFile->name );

	if( file_exists( tempString ) == TRUE )
	{
		g_currPath = pCurrFileListFile->path;
		g_currName = pCurrFileListFile->name;
	}
	else
	{
		g_currPath = NULL;
		g_currName = NULL;
	}
}

void FileListSaveToHistory( void )
{
	if( moduleHistoryUsed < MODULE_HISTORY_SIZE )
	{
		moduleHistory[moduleHistoryUsed++] = pCurrFileListFile->number;
	}
	else
	{
		memcpy( &moduleHistory[0], &moduleHistory[1], ( MODULE_HISTORY_SIZE - 1 ) * sizeof( long ) );
		moduleHistory[MODULE_HISTORY_SIZE - 1] = pCurrFileListFile->number;
	}
}

BOOL FileListSetNext( void )
{
	long	fileNumber = -1;
	int		i;
	struct SFileListFile* pSFile;

	if( g_random == FALSE )
	{
		if( pCurrFileListFile != NULL && pCurrFileListFile->pSNext != NULL )
		{
			fileNumber = pCurrFileListFile->pSNext->number;
		}
		else if( pCurrFileListFile != NULL && g_repeat == TRUE )
		{
			/* if there's some (current) file, we are sure there's the first file */
			fileNumber = pFileListFile->number;
		}
	}
	else if( g_filesCount > 0 )
	{
		fileNumber = random() % g_filesCount;

		/* find the 'fileNumber'-th entry; this is not the same as file number! */
		pSFile = FileListGetFirstEntry();
		for( i = 0; i != fileNumber; i++ )
		{
			/* fileNumber is always in range from 0 to g_filesCount - 1 */
			pSFile = pSFile->pSNext;
		}

		fileNumber = pSFile->number;
	}

	if( fileNumber == -1 )
	{
		return FALSE;
	}
	else
	{
		pSFile = FileListGetEntry( fileNumber );
		FileListSetCurrFile( pSFile );
		PlayListSetCurrFile( pCurrFileListFile );
		FileListSaveToHistory();
		return TRUE;
	}
}

void FileListSetPrev( void )
{
	int						fileNumber;
	struct SFileListFile*	pSFile;

	if( moduleHistoryUsed - 1 > 0 )
	{
		moduleHistoryUsed--;
		fileNumber = moduleHistory[moduleHistoryUsed - 1];
		pSFile = FileListGetEntry( fileNumber );
		FileListSetCurrFile( pSFile );
		PlayListSetCurrFile( pCurrFileListFile );
	}
	else
	{
		/* no previous selection or user reached buffer limit */
		if( g_random == FALSE )
		{
			if( pCurrFileListFile != NULL && pCurrFileListFile->pSPrev != NULL )
			{
				FileListSetCurrFile( pCurrFileListFile->pSPrev );
				PlayListSetCurrFile( pCurrFileListFile );
			}
		}
		else
		{
			/* take some random file */
			FileListSetNext();
		}
	}
}

BOOL FileListAddFile( char* path, char* name )
{
	struct SFileListFile*	pSListFile;
	struct SFileListFile*	pSListPrevFile;
	struct SAudioPlugin*	pSPlugin;

	pSPlugin = LookForAudioPlugin( path, name );
	if( pSPlugin != NULL )	/* add supported files only */
	{
		strcpy( g_lastUsedName, name );
		strcpy( g_lastUsedPath, path );

		pSListFile = FileListGetLastEntry();
		if( pSListFile == NULL )
		{
			pFileListFile = (struct SFileListFile*)malloc( sizeof( struct SFileListFile ) );
			if( VerifyAlloc( pFileListFile ) == FALSE )
			{
				return FALSE;
			}
			else
			{
				pSListPrevFile = NULL;	/* no previous entry */
				pSListFile = pFileListFile;
			}
		}
		else
		{
			pSListFile->pSNext = (struct SFileListFile*)malloc( sizeof( struct SFileListFile ) );
			if( VerifyAlloc( pSListFile->pSNext ) == FALSE )
			{
				return FALSE;
			}
			else
			{
				pSListPrevFile = pSListFile;
				pSListFile = pSListFile->pSNext;
			}
		}

		pSListFile->name = (char*)malloc( strlen( name ) + 1 );
		pSListFile->path = (char*)malloc( strlen( path ) + 1 );
		pSListFile->pSPrev = pSListPrevFile;
		pSListFile->pSNext = NULL;

		if( VerifyAlloc( pSListFile->name ) == FALSE )
		{
			free( pSListFile );
			pSListFile = NULL;
			return FALSE;
		}
		else if( VerifyAlloc( pSListFile->path ) == FALSE )
		{
			free( pSListFile->name );
			pSListFile->name = NULL;
			free( pSListFile );
			pSListFile = NULL;
			return FALSE;
		}

		strcpy( pSListFile->name, name );
		strcpy( pSListFile->path, path );
		pSListFile->selected = FALSE;
		pSListFile->current = FALSE;
		pSListFile->disabled = FALSE;
		pSListFile->number = moduleCounter++;
		g_filesCount++;

		PlayListUpdate( pSListFile );

		if( g_playAfterAdd == TRUE && g_currFileUpdated == FALSE )
		{
			FileListSetCurrFile( pSListFile );	/* change of global variables */
			PlayListSetCurrFile( pSListFile );	/* highlite */
			g_currFileUpdated = TRUE;
		}
	}
	return TRUE;
}

BOOL FileListAddDirectory( char* path, char* name )
{
	char*			tempPath;
	char*			tempName;
	DIR*			pDirStream;
	struct dirent*	pDirEntry;

	if( strcmp( name, "." ) == 0 || strcmp( name, ".." ) == 0 )
	{
		return TRUE;
	}

	tempPath = (char*)malloc( MXP_FILENAME_MAX + MXP_PATH_MAX + 1 );
	tempName = (char*)malloc( MXP_FILENAME_MAX + 1 );
	if( VerifyAlloc( tempPath ) == FALSE )
	{
		return FALSE;
	}
	else if( VerifyAlloc( tempName ) == FALSE )
	{
		free( tempPath );
		return FALSE;
	}
	else
	{
		CombinePath( tempPath, path, name );

		pDirStream = opendir( tempPath );
		if( pDirStream == NULL )
		{
			ShowLoadErrorDialog( name );
			free( tempPath );
			free( tempName );
			return FALSE;
		}

		while( ( pDirEntry = readdir( pDirStream ) ) != NULL )
		{
			if( IsDirectory( tempPath, pDirEntry->d_name ) == TRUE )
			{
				if( FileListAddDirectory( tempPath, pDirEntry->d_name ) == FALSE )
				{
					free( tempPath );
					free( tempName );
					closedir( pDirStream );
					return FALSE;
				}
			}
			else
			{
				if( FileListAddFile( tempPath, pDirEntry->d_name ) == FALSE )
				{
					free( tempPath );
					free( tempName );
					closedir( pDirStream );
					return FALSE;
				}
			}
		}

		free( tempPath );
		free( tempName );
		closedir( pDirStream );
		return TRUE;
	}
}

void FileListClear( struct SFileListFile* pSList )
{
	if( pSList != NULL )
	{
		FileListClear( pSList->pSNext );
		pSList->pSNext = NULL;
		pSList->pSPrev = NULL;

		free( pSList->name );
		pSList->name = NULL;
		free( pSList->path );
		pSList->path = NULL;
		free( pSList );
		if( pSList == pCurrFileListFile )
		{
			pCurrFileListFile = NULL;
			g_currName = NULL;
			g_currPath = NULL;
		}
		if( pSList == pFileListFile )	/* last file */
		{
			pFileListFile = NULL;
			g_filesCount = 0;
		}
	}
}

struct SFileListFile* FileListRemove( struct SFileListFile* pSFile )
{
	struct SFileListFile* pSPrev;
	struct SFileListFile* pSNext;

	pSPrev = pSFile->pSPrev;
	pSNext = pSFile->pSNext;

	pSFile->pSPrev = NULL;
	pSFile->pSNext = NULL;

	free( pSFile->name );
	pSFile->name = NULL;
	free( pSFile->path );
	pSFile->path = NULL;
	free( pSFile );
	if( pSFile == pCurrFileListFile )
	{
		pCurrFileListFile = NULL;
		g_currName = NULL;
		g_currPath = NULL;
	}
	if( pSFile == pFileListFile )
	{
		pFileListFile = pSNext;
	}
	if( pFileListFile == NULL )
	{
		g_filesCount = 0;
		return NULL;
	}

	if( pSPrev != NULL )
	{
		pSPrev->pSNext = pSNext;
	}
	if( pSNext != NULL )
	{
		pSNext->pSPrev = pSPrev;
	}

	g_filesCount--;

	return pSNext;
}
