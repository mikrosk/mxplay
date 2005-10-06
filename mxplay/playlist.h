#ifndef _PLAYLIST_H_
#define _PLAYLIST_H_

#define PL_WINDOW_ENTRIES_MAX	1024

#include "filelist.h"
#include "mxplay.h"

struct SPlayListWindowEntry
{
	short	obj;
	long	fileNumber;
};

extern void	PlayListLoad( void );
extern void	PlayListSave( void );
extern void	PlayListAddFile( void );
extern void	PlayListAddDir( void );
extern void	PlayListSelectAll( void );
extern void	PlayListRemove( void );
extern void	PlayListScroll( short direction );
extern void	PlayListSlider( short deltaY );
extern void	PlayListResize( GRECT* r );

extern BOOL	PlayListAdd( char* path, char* name );
extern void	PlayListInit( void );
extern void	PlayListUpdate( struct SFileListFile* pSFile );
extern void	PlayListSelectFile( short obj );
extern void	PlayListSetCurrFile( struct SFileListFile* pSFile );
extern BOOL	PlayListLoadFromFile( char* filename );
extern BOOL	PlayListSaveToFile( char* filename );
extern void	PlayListReinit( void );
extern void	PlayListDisplayTrackNumber( void );
extern void	PlayListRefresh( BOOL redraw );

extern char*	g_currName;
extern char*	g_currPath;
extern BOOL		g_playAfterAdd;
extern BOOL		g_emptyPlayList;
extern BOOL		g_playlistNotActual;

#endif
