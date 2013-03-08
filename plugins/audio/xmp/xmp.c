/*
 * xmp.c -- an mxPlay plugin based on xmp.sourceforge.net
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

#include <mint/osbind.h>
#include <mint/ostruct.h>
#include <mint/falcon.h>

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <unistd.h>
#include <stdint.h>

#include <xmp.h>

#include "../plugin.h"

extern union UParameterBuffer xmp_parameter;

struct SInfo			xmp_info =
{
	"MiKRO / Mystic Bytes",
	"1.2",
	"Extended Module Player",
	"C.Matsuoka & H.Carraro Jr",
	XMP_VERSION,
	MXP_FLG_USE_DMA|MXP_FLG_FAST_CPU|MXP_FLG_XBIOS|MXP_FLG_DONT_LOAD_MODULE|MXP_FLG_USER_CODE
};

/*
 * .DMF
 * .DTM
 * .FLX
 * .GTK
 * .IT
 * .MED
 * .MGT
 * .MOD
 * .MTM
 * .S3M
 * .XM
 */
struct SExtension		xmp_extensions[] =
{
	{ "*", NULL },
	{ NULL, NULL }
};

static xmp_context c;

static int getSongName( void )
{
	struct xmp_module_info mi;
	xmp_get_module_info( c, &mi );
	xmp_parameter.value = (long)mi.mod->name;

	return MXP_OK;
}

static int getChannels( void )
{
	struct xmp_module_info mi;
	xmp_get_module_info( c, &mi );
	xmp_parameter.value = (long)mi.mod->chn;

	return MXP_OK;
}

static int getModuleType( void )
{
	struct xmp_module_info mi;
	xmp_get_module_info( c, &mi );
	xmp_parameter.value = (long)mi.mod->type;

	return MXP_OK;
}

static const char* na = "n/a";

#define define_getSample( num )								\
static int getSample##num( void )							\
{															\
	struct xmp_module_info mi;								\
	xmp_get_module_info( c, &mi );							\
	if( mi.mod->ins > num )									\
	{														\
		xmp_parameter.value = (long)mi.mod->xxi[num].name;	\
	}														\
	else													\
	{														\
		xmp_parameter.value = (long)na;						\
	}														\
															\
	return MXP_OK;											\
}
define_getSample( 0 );
define_getSample( 1 );
define_getSample( 2 );
define_getSample( 3 );
define_getSample( 4 );
define_getSample( 5 );
define_getSample( 6 );
define_getSample( 7 );
define_getSample( 8 );
define_getSample( 9 );
define_getSample( 10 );
define_getSample( 11 );
define_getSample( 12 );
define_getSample( 13 );
define_getSample( 14 );
define_getSample( 15 );
define_getSample( 16 );
define_getSample( 17 );
define_getSample( 18 );
define_getSample( 19 );
define_getSample( 20 );
define_getSample( 21 );
define_getSample( 22 );
define_getSample( 23 );
define_getSample( 24 );
define_getSample( 25 );
define_getSample( 26 );
define_getSample( 27 );
define_getSample( 28 );
define_getSample( 29 );
define_getSample( 30 );

struct SParameter		xmp_settings[] =
{
	{ "Song name", MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM, NULL, getSongName },
	{ "Channels", MXP_PAR_TYPE_INT|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM, NULL, getChannels },
	{ "Module type", MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM, NULL, getModuleType },
	{ "#0", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample0 },
	{ "#1", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample1 },
	{ "#2", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample2 },
	{ "#3", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample3 },
	{ "#4", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample4 },
	{ "#5", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample5 },
	{ "#6", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample6 },
	{ "#7", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample7 },
	{ "#8", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample8 },
	{ "#9", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample9 },
	{ "#10", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample10 },
	{ "#11", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample11 },
	{ "#12", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample12 },
	{ "#13", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample13 },
	{ "#14", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample14 },
	{ "#15", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample15 },
	{ "#16", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample16 },
	{ "#17", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample17 },
	{ "#18", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample18 },
	{ "#19", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample19 },
	{ "#20", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample20 },
	{ "#21", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample21 },
	{ "#22", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample22 },
	{ "#23", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample23 },
	{ "#24", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample24 },
	{ "#25", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample25 },
	{ "#26", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample26 },
	{ "#27", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample27 },
	{ "#28", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample28 },
	{ "#29", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample29 },
	{ "#30", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSample30 },
	{ NULL, 0, NULL, NULL }
};

#define SAMPLE_RATE	49170
#define MIN(x, y) (((x) < (y)) ? (x) : (y))

static char* pPhysical;
static char* pLogical;
static size_t bufferSize;	// size of one buffer
#ifdef TIMER_A_HANDLER
static int loadNewSample;
#endif
static char* moduleFilePath;
static char* pBuffer;
static size_t left;

static int loadBuffer( char* pBuffer, size_t bufferSize )
{
	int rc = 0;
	size_t loaded = 0;
	struct xmp_frame_info fi;

	if( left > 0 )
	{
		loaded = left;
		left = 0;

		xmp_get_frame_info( c, &fi );

		memcpy( pBuffer, fi.buffer + ( fi.buffer_size - loaded ), loaded );
		pBuffer += loaded;
	}

	while( loaded < bufferSize && xmp_play_frame( c ) == 0 )
	{
		xmp_get_frame_info( c, &fi );

		if( fi.loop_count > 0 )    /* exit before looping */
		{
			rc = 1;	// end of module
			break;
		}

		size_t size = MIN( bufferSize - loaded, fi.buffer_size );
		left = fi.buffer_size - size;

		memcpy( pBuffer, fi.buffer, size );
		pBuffer += size;
		loaded += size;
	}

	return rc;
}

double round(double number)
{
	return number < 0.0 ? ceil(number - 0.5) : floor(number + 0.5);
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

int xmp_register_module( void )
{
	// TODO: maybe we could load the module right here. now with every play/stop
	// we load the file again and again...
	// (but beware, while LookForAudioPlugin(), this register/unregister with malloc/load
	// would be called many times, too! it's just the play/stop would be fast)
	moduleFilePath = xmp_parameter.pModule->p;

	struct xmp_test_info ti;
 	return xmp_test_module( moduleFilePath, &ti ) == 0 ? MXP_OK : MXP_ERROR;
}

int xmp_get_playtime( void )
{
	struct xmp_frame_info fi;
	xmp_get_frame_info( c, &fi );
	xmp_parameter.value = fi.total_time;	// return value is in miliseconds
	return MXP_OK;
}

int xmp_init( void )
{
	c = xmp_create_context();

	return MXP_OK;
}

int xmp_set( void )
{
	left = 0;

	if( xmp_load_module( c, moduleFilePath ) != 0 )
	{
		return MXP_ERROR;
	}

	xmp_start_player( c, SAMPLE_RATE, 0 );	// 0: stereo 16bit signed (default)

	bufferSize = 2 * 2 * SAMPLE_RATE * 1;	// 2 channels * 16 bit * 49170 Hz * 1 second

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
int xmp_feed( void )
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
int xmp_feed( void )
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

int xmp_unset( void )
{
	Buffoper( 0x00 );	// disable playback
#ifdef TIMER_A_HANDLER
	Jdisint( MFP_TIMERA );
#endif

	xmp_stop_module( c );
	xmp_end_player( c );
	xmp_release_module( c );        /* unload module */

	Mfree( pBuffer );
	pBuffer = NULL;

	return MXP_OK;
}

int xmp_pause( void )
{
	int pause = xmp_parameter.value;
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

	return MXP_OK;
}

int xmp_mute( void )
{
	struct xmp_module_info mi;
	xmp_get_module_info( c, &mi );

	int mute = xmp_parameter.value;
	if( mute )
	{
		memset( pPhysical, 0, bufferSize );
		memset( pLogical, 0, bufferSize );
	}

	for( int i = 0; i < mi.mod->chn; ++i )
	{
		xmp_channel_mute( c, i, mute );
	}

	return MXP_OK;
}
