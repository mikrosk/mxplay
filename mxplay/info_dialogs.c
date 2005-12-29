/*
 * info_dialogs.c -- shared code between module and plugin info
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

#include <stdlib.h>
#include <cflib.h>

#include "audio_plugins.h"
#include "misc.h"

/*
 * This should be the example of re-using the code for both plugin_info.c and
 * module_info.c but you see the result ;-) In fact, these two files are fantastic
 * example why OOP isn't total crap - if mxPlay would be in C++ I could just define
 * InfoDialog class with some virtual methods and then inherite both ModuleInfo and
 * PluginInfo...
 */

short CloneDialog( OBJECT oldTree[], OBJECT** ppNewTree, short objs )
{
	short count;
	short i;
	
	count = GetObjectCount( oldTree );
	
	*ppNewTree = (OBJECT*)malloc( ( count + objs ) * sizeof( OBJECT ) );	/* + new objs */
	if( VerifyAlloc( *ppNewTree ) == FALSE )
	{
		return -1;
	}
	else
	{
		/* copy old objects */
		for( i = 0; i < count; i++ )
		{
			memcpy( &(*ppNewTree)[i], &oldTree[i], sizeof( OBJECT ) );
		}
		
		/* init new objects */
		for( i = count; i < count + objs; i++ )
		{
			memset( &(*ppNewTree)[i], 0, sizeof( OBJECT ) );
		}
		
		/* this is a number for the first new object */
		return count;
	}
}

/*
 * Convert MXP_PAR_TYPE_* to the string from given plugin & parameter
 */
void ConvertMxpParamTypes( struct SAudioPlugin* plugin, struct SParameter* param, char* text )
{
	long	value;
	
	AudioPluginGet( plugin, param, &value );	/* call param->Get() */

	switch( param->type & 0x7fff )
	{
		case MXP_PAR_TYPE_BOOL:
			if( (BOOL)value == TRUE )
			{
				strcpy( text, "Yes" );
			}
			else
			{
				strcpy( text, "No" );
			}
		break;
		
		case MXP_PAR_TYPE_INT:
			sprintf( text, "%ld", value );
		break;
		
		case MXP_PAR_TYPE_CHAR:
			if( strcmp( (char*)value, "" ) == 0 )
			{
				/* use filename as value */
				split_filename( g_currModuleName, NULL, text );	/* i.e. "TeXmas II.mp3" */
			}
			else
			{
				strcpy( text, (char*)value );
				UnpadString( text );	/* "TeXmas II     " -> "TeXmas II" */
			}
		break;
	}

}
