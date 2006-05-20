/*
 * av.c -- AV/VA communication
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

#include <cflib.h>
#include <string.h>
#include <mint/osbind.h>

#include "mxplay.h"
#include "vaproto.h"
#include "dialogs.h"
#include "filelist.h"
#include "misc.h"

static short avServerId = -1;
static short avServerStatus = 0;
static char* sharedString = NULL;

void AVSetStatus( short msg[8] )
{
	avServerStatus = msg[3];
}

void AVInit( void )
{
	char*	avServer;
	char	tempString[8+1];
	short	dummy;
	short	temp;
	short	appId;
	
	/* alloc global memory for AV protocol */
	sharedString = (char*)malloc_global( MXP_FILENAME_MAX+1 );
	if( VerifyAlloc( sharedString ) == FALSE )
	{
		ExitPlayer( 1 );
	}
	
	shel_envrn( &avServer, "AVSERVER=" );
	if( avServer != NULL )
	{
		/* get AV server ID */
		strncpy( tempString, avServer, 8 );
		tempString[8] = '\0';
		PadString( tempString, 8 );
		avServerId = appl_find( tempString );
		if( avServerId > 0 )
		{
			memset( g_msgBuffer, 0, sizeof( g_msgBuffer ) );
			g_msgBuffer[0] = AV_PROTOKOLL;
			g_msgBuffer[3] = 0x0002 | 0x0010;	/* VA_START and file name quoting */
			
			/* get application's name */
			if( appl_xgetinfo( AES_PROCESS, &dummy, &dummy, &temp, &dummy ) != FALSE
				&& temp == TRUE )	/* appl_search exists? */
			{
				temp = appl_search( APP_FIRST, tempString, &dummy, &appId );
				while( temp == TRUE )
				{
					if( appId == gl_apid )
					{
						break;
					}
					else
					{
						temp = appl_search( APP_NEXT, tempString, &dummy, &appId );
					}
				}
			
				if( temp == TRUE )	/* application was found */
				{
					strncpy( sharedString, tempString, 8 );
					sharedString[8] = '\0';
					PadString( sharedString, 8 );
					ol2ts( (long)sharedString, &g_msgBuffer[6], &g_msgBuffer[7] );
				}
			
				if( SendMessage( avServerId ) <= 0 )
				{
					ShowCommErrorDialog();
					return;
				}
			}
		}
	}
}

void AVExit( void )
{
	if( avServerId > 0 && ( avServerStatus & AV_EXIT ) != 0 )
	{
		memset( g_msgBuffer, 0, sizeof( g_msgBuffer ) );
		g_msgBuffer[0] = AV_EXIT;
		g_msgBuffer[3] = gl_apid;
		if( SendMessage( avServerId ) <= 0 )
		{
			ShowCommErrorDialog();
			return;
		}
	}
	
	Mfree( sharedString );
}

/*
 * VA_START argument parser
 */
BOOL VAParseArgs( short msg[8] )
{
	ParseArgs( (char*)ts2ol( msg[3], msg[4] ) );
	return TRUE;
}
