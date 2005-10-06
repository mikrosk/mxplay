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
extern void	PlayListUp( void );
extern void	PlayListDown( void );
extern void	PlayListSlider( short deltaY );
extern void	PlayListSliderBox( short my );
extern void	PlayListResize( short mx, short my );

extern BOOL	PlayListAdd( char* path, char* name );
extern void PlayListInit( void );
extern void	PlayListUpdate( struct SFileListFile* pSFile );
extern void PlayListSelectFile( short obj );
extern void	PlayListSliderDeselect( void );
extern void	PlayListSliderSelect( void );
extern void	PlayListSetCurrFile( struct SFileListFile* pSFile );
extern BOOL	PlayListLoadFromFile( char* filename );
extern BOOL	PlayListSaveToFile( char* filename );
extern void PlayListReinit( void );
extern void	PlayListPlayFromFirstFile( void );

extern char*	g_currName;
extern char*	g_currPath;
extern BOOL		g_playAfterAdd;
extern BOOL		g_emptyPlayList;
extern BOOL		g_playlistNotActual;

#endif
