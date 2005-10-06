#include <cflib.h>
#include <string.h>
#include <stdlib.h>
#include <osbind.h>

#include "mxplay.h"
#include "filelist.h"
#include "misc.h"

/*
 * Drag&drop argument parser
 */
BOOL DDParseArgs( short msg[8] )
{
	short	fd;
	char	supportedExts[DD_EXTSIZE];
	char 	returnedExt[5];
	char	returnedName[DD_NAMEMAX];
	long	returnedSize;
	char*	pReturnedCmdline;
	
	memset( supportedExts, 0, DD_EXTSIZE );
	strcpy( supportedExts, "ARGS" );

	fd = dd_open( msg[7], supportedExts );
	if( fd < 0 )
	{
		return FALSE;
	}
	else
	{
		do
		{
			if( dd_rtry( fd, returnedName, returnedExt, &returnedSize ) != TRUE )
			{
				dd_close( fd );
				return FALSE;
			}
			if( strncmp( returnedExt, "ARGS", 4 ) == 0 )	/* OK, some commandline found */
			{
				pReturnedCmdline = (char*)malloc( returnedSize + 1 );
				if( pReturnedCmdline == NULL )
				{
					dd_reply( fd, DD_LEN );	/* reply: not enough memory for data */
					continue;
				}
	
				dd_reply( fd, DD_OK );
				Fread( fd, returnedSize, pReturnedCmdline );
				dd_close( fd );
				
				pReturnedCmdline[returnedSize] = '\0';
				ParseArgs( pReturnedCmdline );
				free( pReturnedCmdline );
			}
		}
		while( dd_reply( fd, DD_EXT ) == TRUE );
		
		return TRUE;
	}
}
