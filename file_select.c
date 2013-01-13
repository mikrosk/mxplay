/*
 * file_select.c -- file selector callbacks
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

#include "mxplay.h"
#include "misc.h"
#include "playlist.h"

/*
 * Callback functions for file selection
 * ...damn it! why couldn't CFLib alloc space for filenames by itself???
 */
BOOL CB_ModuleFileSelect( char* path, char* name )
{
	if( strcmp( name, "" ) != 0 && strcmp( path, "" ) != 0 && IsDirectory( path, name ) == FALSE )
	{
		return PlayListAdd( path, name );
	}
	else
	{
		return FALSE;
	}
}

BOOL CB_ModuleDirSelect( char* path, char* name )
{
	if( strcmp( path, "" ) != 0 )
	{
		return PlayListAdd( path, name );
	}
	else
	{
		return FALSE;
	}
}

BOOL CB_RscFileSelect( char* path, char* name )
{
	if( strcmp( name, "" ) != 0 && strcmp( path, "" ) != 0 )
	{
		strcpy( g_rscName, name );
		return TRUE;
	}
	else
	{
		return FALSE;
	}
}

BOOL CB_PlayListFileSelect( char* path, char* name )
{
	if( strcmp( name, "" ) != 0 && strcmp( path, "" ) != 0 )
	{
		CombinePath( g_playlistFilePath, path, name );
		return TRUE;
	}
	else
	{
		return FALSE;
	}
}

