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
