/*
 * vbl_timer.c -- VBL counter for one-second-exact time measure
 *
 * Copyright (c) 2005 Miro Kropacek; miro.kropacek@gmail.com
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

#ifndef NO_MINT

/*
 * This is a little bit tricky. In the case we aren't under MiNT kernel
 * we haven't chance to measure one-second-exact time for our playtime
 * so we install custom VBL timer for doing that job. However, I don't
 * want to make two separate applications (for the MiNT and the others)
 * nor flood the source with a lot of #ifdefs so this functions "emulates"
 * VBL timer behavior under MiNT.
 */

#include <mint/mintbind.h>
#include <stdio.h>

#include "mxplay.h"
#include "audio_plugins.h"
#include "misc.h"

static unsigned long pauseConst;
static unsigned long pausedTime;
static unsigned long playTime;
static unsigned long referenceTime;

void timer_reset( unsigned long time )
{
	referenceTime = GetCurrentTime();
	playTime = time;
	pauseConst = 0;
}

void timer_pause( void )
{
	if( g_modulePaused == TRUE )
	{
		/* module is paused just since now */
		pausedTime = GetCurrentTime();
	}
	else
	{
		pauseConst += GetCurrentTime() - pausedTime;
	}
}

#else	/* NO_MINT true */

#include "vbl_timer.h"

#endif

unsigned long TimerGetSubTime( void )
{
#ifdef NO_MINT
	return timer_subtime;
#else
	return playTime - ( GetCurrentTime() - ( referenceTime + pauseConst ) );	/* playtime - passed */
#endif
}

unsigned long TimerGetAddTime( void )
{
#ifdef NO_MINT
	return timer_addtime;
#else
	return GetCurrentTime() - ( referenceTime + pauseConst );	/* current - starting */
#endif
}
