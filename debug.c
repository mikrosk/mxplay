/*
 * debug.c -- debug module
 *
 * Copyright (c) 2013 Miro Kropacek; miro.kropacek@gmail.com
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

#ifdef DEBUG

#include <stdio.h>
#include <stdarg.h>

void DebugMessage( const char* file, int line, const char* func, const char* fmt, ... )
{
	va_list argptr;

	printf( "%s:%d[%s]: ", file, line, func );

	va_start( argptr, fmt );
	vprintf( fmt, argptr );
	va_end( argptr );

	printf( ".\n" );
}

#endif
