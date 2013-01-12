/*
 * debug.h -- debug module (definitions and external declarations)
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

#ifndef _DEBUG_H_
#define _DEBUG_H_

#ifdef DEBUG

extern void	debugMessage( const char* file, int line, const char* func, const char* fmt, ... );

#if __STDC_VERSION__ < 199901L	// C99
	#if __GNUC__ >= 2 || defined WIN32
		#define __func__ __FUNCTION__
	#else	// __GNUC__ >= 2 || defined _MSC_VER
		#define __func__ "<unknown>"
	#endif	// __GNUC__ >= 2
#endif	// __STDC_VERSION__ < 199901L

#define debug(...) \
	DebugMessage( __FILE__, __LINE__, __func__, __VA_ARGS__ )

#else

#define debug(...)
#endif

#endif
