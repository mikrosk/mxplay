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
		CombinePath( g_playlistFile, path, name );
		return TRUE;
	}
	else
	{
		return FALSE;
	}
}

