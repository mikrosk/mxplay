/*
 * system.h -- cookie-based system check (definitions and external declarations)
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

#ifndef _SYSTEM_H_
#define _SYSTEM_H_

#include "mxplay.h"

extern BOOL	g_fastCpu;	// 030/50 MHz, 040, 060
extern BOOL	g_tosClone;	// Hades, Milan, ARAnyM, ...
extern BOOL	g_hasDma;	// 16-bit CODEC
extern BOOL	g_hasDsp;	// DSP56001

extern void CheckSystem( void );

#endif
