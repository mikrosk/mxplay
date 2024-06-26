/*
 * asap.c -- an mxPlay plugin based on asap.sourceforge.net
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
#include <string.h>
#include <unistd.h>
#include <stdint.h>

#include <asap.h>

#include "../plugin.h"

extern union UParameterBuffer asap_parameter;

struct SInfo			asap_info =
{
	"MiKRO / Mystic Bytes",
	"1.1",
	"Another Slight Atari Player",
	"Piotr Fusik",
	ASAPInfo_VERSION,
	MXP_FLG_USE_DMA|MXP_FLG_FAST_CPU|MXP_FLG_XBIOS|MXP_FLG_DONT_LOAD_MODULE|MXP_FLG_USER_CODE
};

struct SExtension		asap_extensions[] =
{
	{ "SAP", NULL },
	{ "CMC", NULL },
	{ "CM3", NULL },
	{ "CMR", NULL },
	{ "CMS", NULL },
	{ "DMC", NULL },
	{ "DLT", NULL },
	{ "FC", NULL },
	{ "MPT", NULL },
	{ "MPD", NULL },
	{ "RMT", NULL },
	{ "TMC", NULL },
	{ "TM8", NULL },
	{ "TM2", NULL },
	{ NULL, NULL }
};

static ASAP* asap;
static ASAPInfo* info;
static int channels;
static unsigned char moduleBuffer[ASAPInfo_MAX_MODULE_LENGTH];
static int moduleLength;
static int moduleSong;
static char* moduleFilePath;
static char* pBuffer;

static const char* na = "n/a";

static int getSongName( void )
{
	const char* name = ASAPInfo_GetTitleOrFilename( info );
	asap_parameter.value = (long)name;

	return MXP_OK;
}

static int getChannels( void )
{
	asap_parameter.value = (long)( channels == 2 ? 1 : 0 );

	return MXP_OK;
}

static int getSongDate( void )
{
	const char* date = ASAPInfo_GetDate( info );
	if( date != NULL && strlen( date ) > 0 )
	{
		asap_parameter.value = (long)date;
	}
	else
	{
		asap_parameter.value = (long)na;
	}

	return MXP_OK;
}

static int getSongAuthor( void )
{
	const char* author = ASAPInfo_GetAuthor( info );
	if( author != NULL && strlen( author ) > 0 )
	{
		asap_parameter.value = (long)author;
	}
	else
	{
		asap_parameter.value = (long)na;
	}

	return MXP_OK;
}

static int getSongType( void )
{
	static char* sap = "Slight Atari Player";
	const char* ext = ASAPInfo_GetOriginalModuleExt( info, moduleBuffer, moduleLength );
	if( ext != NULL && strlen( ext ) > 0 )
	{
		const char* desc = ASAPInfo_GetExtDescription( ext );
		if( desc != NULL && strlen( desc ) > 0 )
		{
			asap_parameter.value = (long)desc;
			return MXP_OK;
		}
	}

	asap_parameter.value = (long)sap;
	return MXP_OK;
}

struct SParameter		asap_settings[] =
{
	{ "Name", MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM, NULL, getSongName },
	{ "Author", MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM, NULL, getSongAuthor },
	{ "Type", MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM, NULL, getSongType },
	{ "Date", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSongDate },
	{ "Stereo", MXP_PAR_TYPE_BOOL|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM, NULL, getChannels },
	{ NULL, 0, NULL, NULL }
};

static char* pPhysical;
static char* pLogical;
static size_t bufferSize;	// size of one buffer
#ifdef TIMER_A_HANDLER
static int loadNewSample;
#endif

static int loadBuffer( char* pBuffer, size_t bufferSize )
{
	int bytes = ASAP_Generate( asap, (unsigned char*)pBuffer, channels == 1 ? bufferSize / 2 : bufferSize, ASAPSampleFormat_S16_B_E );
	if( channels == 1 )
	{
		signed short* p1 = (signed short*)( pBuffer + bufferSize/2 );	// point past the last used word
		signed short* p2 = (signed short*)( pBuffer + bufferSize );	// point past the last word
		while( p1 != (signed short*)pBuffer )
		{
			*--p2 = *--p1;
			*--p2 = *p1;
		}
		bytes *= 2;
	}
	return bytes == bufferSize ? 0 : 1;
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

int asap_register_module( void )
{
	// TODO: same as XMP, now we loads it everytime play/stop is issued
	moduleFilePath = asap_parameter.pModule->p;
	return ASAPInfo_IsOurFile( moduleFilePath ) == 1 ? MXP_OK : MXP_ERROR;
}

int asap_get_playtime( void )
{
	int time = ASAPInfo_GetDuration( info, moduleSong );
	if( time == -1 )
	{
		return MXP_ERROR;
	}
	else
	{
		asap_parameter.value = time;	// return value is in miliseconds
		return MXP_OK;
	}
}

int asap_get_songs( void )
{
	asap_parameter.value = ASAPInfo_GetSongs( info );
	return MXP_OK;
}

int asap_init( void )
{
	asap = ASAP_New();

	return asap != NULL ? MXP_OK : MXP_ERROR;
}

int asap_set( void )
{
	FILE *fp = fopen( moduleFilePath, "rb" );
	if( fp == NULL )
	{
		return MXP_ERROR;
	}

	moduleLength = fread( moduleBuffer, 1, sizeof( moduleBuffer ), fp );
	fclose( fp );

	if( !ASAP_Load( asap, moduleFilePath, moduleBuffer, moduleLength ) )
	{
		return MXP_ERROR;
	}

	info = (ASAPInfo*)ASAP_GetInfo( asap );
	channels = ASAPInfo_GetChannels( info );

	moduleSong = (int)asap_parameter.value;

	if( !ASAP_PlaySong( asap, moduleSong, -1 ) )	// unlimited time
	{
		return MXP_ERROR;
	}

	bufferSize = 2 * 2 * ASAP_SAMPLE_RATE * 1;	// 2 channels * 16 bit * 49170 Hz * 1 second

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
int asap_feed( void )
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
int asap_feed( void )
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

int asap_unset( void )
{
	Buffoper( 0x00 );	// disable playback
#ifdef TIMER_A_HANDLER
	Jdisint( MFP_TIMERA );
#endif

	ASAPInfo_Delete( info );

	Mfree( pBuffer );
	pBuffer = NULL;

	return MXP_OK;
}

int asap_pause( void )
{
	int pause = asap_parameter.value;
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

int asap_mute( void )
{
	int mute = asap_parameter.value;
	if( mute )
	{
		memset( pPhysical, 0, bufferSize );
		memset( pLogical, 0, bufferSize );
	}

	char mask = channels == 2 ? 0xff : 0x0f;
	ASAP_MutePokeyChannels( asap, mute ? mask : ~mask );

	return MXP_OK;
}
