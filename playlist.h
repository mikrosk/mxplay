/*
 * playlist.h -- Playlist dialog and all around it (definitions and external declarations)
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
