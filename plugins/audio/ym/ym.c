/*
 * ym.c -- an mxPlay plugin based on ST-Sound by Arnaud Carré
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

#include <mint/osbind.h>
#include <mint/ostruct.h>
#include <mint/falcon.h>

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <unistd.h>
#include <stdint.h>

#include "StSoundLibrary/StSoundLibrary.h"

#include "../plugin.h"

extern union UParameterBuffer ym_parameter;

// typedef struct
// {
// 	ymchar	*	pSongName;
// 	ymchar	*	pSongAuthor;
// 	ymchar	*	pSongComment;
// 	ymchar	*	pSongType;
// 	ymchar	*	pSongPlayer;
// 	yms32		musicTimeInSec;		// keep for compatibility
// 	yms32		musicTimeInMs;
// } ymMusicInfo_t;
// ymMusicInfo_t info;
// ymMusicGetInfo(pMusic,&info);

struct SInfo			ym_info =
{
	"MiKRO / Mystic Bytes",
	"1.0",
	"ST-Sound",
	"Arnaud Carre",
	"1.42",
	MXP_FLG_USE_DMA|MXP_FLG_FAST_CPU|MXP_FLG_XBIOS|MXP_FLG_DONT_LOAD_MODULE|MXP_FLG_USER_CODE
};

struct SExtension		ym_extensions[] =
{
	{ "YM", NULL },
	{ NULL, NULL }
};

#define SAMPLE_RATE	49170

static YMMUSIC* pMusic;
static char* pPhysical;
static char* pLogical;
static size_t bufferSize;	// size of one buffer
#ifdef TIMER_A_HANDLER
static int loadNewSample;
#endif
static char* moduleFilePath;
static char* pBuffer;

static int loadBuffer( char* pBuffer, size_t bufferSize )
{
	if( ymMusicCompute( pMusic, (ymsample*)pBuffer, bufferSize ) )
	{
		return 0;
	}

	return 1;
}

#ifdef TIMER_A_HANDLER
static void __attribute__((interrupt)) timerA( void )
{
	loadNewSample = 1;

	*( (volatile unsigned char*)0xFFFFFA0FL ) &= ~( 1<<5 );	//	clear in service bit
}

static void enableTimerASei( void )
{
	*( (volatile unsigned char*)0xFFFFFA17L ) |= ( 1<<3 );	//	software end-of-interrupt mode
}
#endif

///////////////////////////////////////////////////////////////////////////////

int ym_register_module( void )
{
	moduleFilePath = ym_parameter.pModule->p;

 	return MXP_OK;
}

int ym_init( void )
{
	pMusic = ymMusicCreate();

	return pMusic != NULL ? MXP_OK : MXP_ERROR;
}

int ym_set( void )
{
	if( !ymMusicLoad( pMusic, moduleFilePath ) )
		return MXP_ERROR;

	ymMusicSetLoopMode( pMusic,YMFALSE );

	ymMusicPlay( pMusic );

	bufferSize = 2 * 2 * 49170 * 1;	// 2 channels * 16 bit * 49170 Hz * 1 second

	pBuffer = (char*)Mxalloc( 2 * bufferSize, MX_STRAM );
	if( pBuffer == NULL )
	{
		return MXP_ERROR;
	}
	pPhysical = pBuffer;
	pLogical = pBuffer + bufferSize;

	loadBuffer( pPhysical, bufferSize );
#ifndef TIMER_A_HANDLER
	loadBuffer( pLogical, bufferSize );
#endif

	Sndstatus( SND_RESET );

	if( Devconnect( DMAPLAY, DAC, CLK25M, CLK50K, NO_SHAKE ) != 0 )
	{
		// for some reason, Devconnect() returns error in memory protection mode...
		//return MXP_ERROR;
	}

	if( Setmode( MODE_STEREO16 ) != 0 )
	{
		goto error;
	}

	Soundcmd( ADDERIN, MATIN );

#ifdef TIMER_A_HANDLER
	if( Setbuffer( SR_PLAY, pPhysical, pPhysical + bufferSize ) != 0 )
#else
	if( Setbuffer( SR_PLAY, pBuffer, pBuffer + 2*bufferSize ) != 0 )
#endif
	{
		goto error;
	}

#ifdef TIMER_A_HANDLER
	if( Setinterrupt( SI_TIMERA, SI_PLAY ) != 0 )
	{
		goto error;
	}

	Xbtimer( XB_TIMERA, 1<<3, 1, timerA );	// event count mode, count to '1'
	Supexec( enableTimerASei );
	Jenabint( MFP_TIMERA );
#endif

	// start playback!!!
	if( Buffoper( SB_PLA_ENA | SB_PLA_RPT ) != 0 )
	{
		goto error;
	}

#ifdef TIMER_A_HANDLER
	// fix for ARAnyM/zmagxsnd -- it doesn't emit Timer A interrupt at the beginning
	loadNewSample = 1;
#endif

	return MXP_OK;

error:
	Mfree( pBuffer );
	pBuffer = NULL;

	return MXP_ERROR;
}

#ifdef TIMER_A_HANDLER
int ym_feed( void )
{
	if( loadNewSample )
	{
		// fill in logical buffer
		loadBuffer( pLogical, bufferSize );

		// swap buffers (makes logical buffer physical)
		char* tmp = pPhysical;
		pPhysical = pLogical;
		pLogical = tmp;

		// set physical buffer for the next frame
		Setbuffer( SR_PLAY, pPhysical, pPhysical + bufferSize );

		loadNewSample = 0;
	}

	return MXP_OK;
}
#else
int ym_feed( void )
{
	static int loadSampleFlag = 1;

	SndBufPtr sPtr;
	if( Buffptr( &sPtr ) != 0 )
	{
		return MXP_ERROR;
	}

	if( loadSampleFlag == 0 )
	{
		// we play from pPhysical (1st buffer)
		if( sPtr.play < pLogical )
		{
			loadBuffer( pLogical, bufferSize );
			loadSampleFlag = !loadSampleFlag;
		}
	}
	else
	{
		// we play from pLogical (2nd buffer)
		if( sPtr.play >= pLogical )
		{
			loadBuffer( pPhysical, bufferSize );
			loadSampleFlag = !loadSampleFlag;
		}
	}

	return MXP_OK;
}
#endif

int ym_unset( void )
{
	Buffoper( 0x00 );	// disable playback
#ifdef TIMER_A_HANDLER
	Jdisint( MFP_TIMERA );
#endif

	ymMusicStop( pMusic );

	Mfree( pBuffer );
	pBuffer = NULL;

	return MXP_OK;
}

int ym_pause( void )
{
	int pause = ym_parameter.value;
	static SndBufPtr ptr;

	if( pause )
	{
		Buffptr( &ptr );
		Buffoper( 0x00 );	// disable playback
	}
	else
	{
#ifdef TIMER_A_HANDLER
		Setbuffer( SR_PLAY, ptr.play, pPhysical + bufferSize );
#endif
		Buffoper( SB_PLA_ENA | SB_PLA_RPT );
	}

	// TODO
	//extern	void			ymMusicPlay(YMMUSIC *pMusic);
	//extern	void			ymMusicPause(YMMUSIC *pMusic);

	return MXP_OK;
}

int ym_mute( void )
{
	int mute = ym_parameter.value;
	if( mute )
	{
		memset( pPhysical, 0, bufferSize );
		memset( pLogical, 0, bufferSize );
	}

	// TODO: mute here

	return MXP_OK;
}
