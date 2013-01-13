/*
 * timer.c -- counter for one-second-exact time measure
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

#include <mint/mintbind.h>
#include <stdio.h>
#include <time.h>

#include "mxplay.h"
#include "panel.h"

static clock_t pauseConst;
static clock_t pausedTime;
static clock_t playTime;
static clock_t referenceTime;

void TimerReset( unsigned long seconds )
{
	referenceTime = clock();
	playTime = seconds * CLOCKS_PER_SEC;
	pauseConst = 0;
}

void TimerPause( void )
{
	if( g_modulePaused == TRUE )
	{
		/* module is paused just since now */
		pausedTime = clock();
	}
	else
	{
		pauseConst += clock() - pausedTime;
	}
}

unsigned long TimerGetSubTime( void )
{
	return ( playTime - ( clock() - ( referenceTime + pauseConst ) ) ) / CLOCKS_PER_SEC;	/* playtime - passed */
}

unsigned long TimerGetAddTime( void )
{
	return ( clock() - ( referenceTime + pauseConst ) ) / CLOCKS_PER_SEC;	/* current - starting */
}
