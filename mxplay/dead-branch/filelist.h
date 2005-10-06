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

extern BOOL	g_currFileUpdated;
extern char	g_lastUsedName[FILENAME_MAX+1];
extern char	g_lastUsedPath[PATH_MAX+1];
extern int	g_filesCount;

#endif
