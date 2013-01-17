/*
 * system.c -- cookie-based system check
 *
 * Copyright (c) 2012-2013 Miro Kropacek; miro.kropacek@gmail.com
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

#include <mint/cookie.h>
#include <mint/falcon.h>

#include "debug.h"
#include "system.h"

BOOL  g_fastCpu = FALSE;
BOOL g_tosClone = FALSE;
BOOL   g_hasDma = FALSE;
BOOL   g_hasDsp = FALSE;

void CheckSystem( void )
{
	long val;

	// some of the values are set more than once, as a failsafe mechanism
	// if a cookie is missing/misleading

	if( Getcookie( '_CPU', &val ) == C_FOUND )
	{
		if( val >= 40 )
		{
			debug( "040+ CPU" );
			g_fastCpu = TRUE;
		}
	}

	if( Getcookie( '_CT2', &val ) == C_FOUND )
	{
		debug( "CT2" );
		if( Getcookie( '_FPU', &val ) == C_FOUND && val != 0 )
		{
			debug( "FPU" );
			// fast cpu implies fpu (at least software emulated in case of 68[EL]C0[46]0)
			g_fastCpu = TRUE;
		}
	}

	if( Getcookie( 'CT60', &val ) == C_FOUND )
	{
		debug( "CT60" );
		g_fastCpu = TRUE;
	}

	if( Getcookie( '_SND', &val ) == C_FOUND )
	{
		if( ( val & SND_16BIT ) != 0 )	/* CODEC presence */
		{
			debug( "CODEC" );
			g_hasDma = TRUE;
		}
		if( ( val & SND_DSP ) != 0 )	/* DSP presence */
		{
			debug( "DSP" );
			g_hasDsp = TRUE;
		}
	}

	if( Getcookie( '_MCH', &val ) == C_FOUND )
	{
		if( val == 0x00004D34L		// Medusa T40 without SCSI
			|| val == 0x00024D34L	// Medusa T40 with SCSI
			|| val == 0x00040000L	// Milan
			|| val == 0x00050000L )	// ARAnyM
		{
			debug( "TOS clone" );
			g_tosClone = TRUE;
		}
	}

	if( Getcookie( '_MIL', &val ) == C_FOUND )	// Milan
	{
		debug( "Milan" );
		g_tosClone = TRUE;
	}

	if( Getcookie( 'hade', &val ) == C_FOUND )	// Hades
	{
		debug( "Hades" );
		g_tosClone = TRUE;
	}
}
