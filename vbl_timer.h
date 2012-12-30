/*
 * vbl_timer.h -- VBL counter for one-second-exact time measure (definitions and external declarations)
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

#ifndef _VLB_TIMER_H_
#define _VLB_TIMER_H_

#include "mxplay.h"

#ifdef NO_MINT
extern long	timer_start_measure( void );
extern long	timer_stop_measure( void );

extern BOOL	timer_is_finished( void );
extern long	timer_install( void );
extern long	timer_uninstall( void );

extern unsigned long timer_addtime;
extern unsigned long timer_subtime;

#endif	/* NO_MINT */

extern void	timer_reset( unsigned long time );
extern void	timer_pause( void );

extern unsigned long TimerGetSubTime( void );
extern unsigned long TimerGetAddTime( void );

#endif
