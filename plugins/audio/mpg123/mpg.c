/*
 * mpg.c -- an mxPlay plugin based on asap.sourceforge.net
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
#include <string.h>
#include <unistd.h>
#include <stdint.h>

#include <mpg123.h>

#include "../plugin.h"

extern union UParameterBuffer mpg_parameter;

struct SInfo			mpg_info =
{
	"MiKRO / Mystic Bytes",
	"1.2",
	"mpg123",
	"Thomas Orgis",
	"1.15.1",
	MXP_FLG_USE_DMA|MXP_FLG_FAST_CPU|MXP_FLG_XBIOS|MXP_FLG_DONT_LOAD_MODULE|MXP_FLG_USER_CODE
};

struct SExtension		mpg_extensions[] =
{
	{ "MP1", NULL },
	{ "MP2", NULL },
	{ "MP3", NULL },
	{ NULL, NULL }
};

static mpg123_handle* mh;
static char* moduleFilePath;
static char* pBuffer;
static char* pPhysical;
static char* pLogical;
static size_t bufferSize;	// size of one buffer
#ifdef TIMER_A_HANDLER
static int loadNewSample;
#endif
static int mute;

typedef enum
{
	title,
	artist,
	album,
	year
} MetaParam;

static int getMetaParam( MetaParam param )
{
	static const char* na = "n/a";

	mpg123_id3v1* pV1;
	mpg123_id3v2* pV2;
	if( mpg123_id3( mh, &pV1, &pV2 ) == MPG123_OK )
	{
		switch( param )
		{
			// TODO: NULL termination check for ID3v1
			// TODO: handle encoding
			case title:
				if( pV2 != NULL && pV2->title != NULL )
					mpg_parameter.value = (long)pV2->title->p;
				else if( pV1 != NULL )
					mpg_parameter.value = (long)pV1->title;
				else
					mpg_parameter.value = (long)na;
				break;

			case artist:
				if( pV2 != NULL && pV2->artist != NULL )
					mpg_parameter.value = (long)pV2->artist->p;
				else if( pV1 != NULL )
					mpg_parameter.value = (long)pV1->artist;
				else
					mpg_parameter.value = (long)na;
				break;

			case album:
				if( pV2 != NULL && pV2->album != NULL )
					mpg_parameter.value = (long)pV2->album->p;
				else if( pV1 != NULL )
					mpg_parameter.value = (long)pV1->album;
				else
					mpg_parameter.value = (long)na;
				break;

			case year:
				if( pV2 != NULL && pV2->year != NULL )
					mpg_parameter.value = (long)pV2->year->p;
				else if( pV1 != NULL )
					mpg_parameter.value = (long)pV1->year;
				else
					mpg_parameter.value = (long)na;
				break;
		}

		return MXP_OK;
	}

	return MXP_ERROR;
}

static int getTitle( void )
{
	return getMetaParam( title );
}
static int getArtist( void )
{
	return getMetaParam( artist );
}
static int getAlbum( void )
{
	return getMetaParam( album );
}
static int getYear( void )
{
	return getMetaParam( year );
}

typedef enum
{
	layer,
	channels,
	sampleRate,
	bitrate
} Param;

static int getParam( Param param, char buf[] )
{
	struct mpg123_frameinfo mi;
	char* layers[] = { "I", "II", "III" };

	if( mpg123_info( mh, &mi ) == MPG123_OK )
	{
		switch( param )
		{
			case layer:
				sprintf( buf, "MPEG-1 Audio Layer %s", layers[mi.layer-1] );
				break;

			case channels:
				switch( mi.mode )
				{
					case MPG123_M_STEREO:
						sprintf( buf, "Stereo" );
						break;
					case MPG123_M_JOINT:
						sprintf( buf, "Joint Stereo" );
						break;
					case MPG123_M_DUAL:
						sprintf( buf, "Dual Channel" );
						break;
					case MPG123_M_MONO:
						sprintf( buf, "Mono" );
						break;
				}
				break;

			case sampleRate:
				sprintf( buf, "%ld Hz", mi.rate );
				break;

			case bitrate:
				switch( mi.vbr )
				{
					case MPG123_CBR:
						sprintf( buf, "%d kbps (CBR)", mi.bitrate );
						break;
					case MPG123_VBR:
						sprintf( buf, "%d kbps (VBR)", mi.bitrate );
						break;
					case MPG123_ABR:
						sprintf( buf, "%d kbps (ABR)", mi.bitrate );
						break;
				}
				break;
		}

		mpg_parameter.value = (long)buf;
		return MXP_OK;
	}

	return MXP_ERROR;
}

static int getLayer( void )
{
	static char buf[32];
	return getParam( layer, buf );
}
static int getChannels( void )
{
	static char buf[32];
	return getParam( channels, buf );
}
static int getSampleRate( void )
{
	static char buf[32];
	return getParam( sampleRate, buf );
}
static int getBitrate( void )
{
	static char buf[32];
	return getParam( bitrate, buf );
}

struct SParameter mpg_settings[] =
{
	{ "Title", MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM, NULL, getTitle },
	{ "Artist", MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM, NULL, getArtist },
	{ "Album", MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM, NULL, getAlbum },
	{ "Year", MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM, NULL, getYear },
	{ "Type", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getLayer },
	{ "Mode", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getChannels },
	{ "Sample rate", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getSampleRate },
	{ "Bitrate", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, getBitrate },
	{ NULL, 0, NULL, NULL }
};

static int loadBuffer( char* pBuffer, size_t bufferSize )
{
	size_t done;
	switch( mpg123_read( mh, (unsigned char*)pBuffer, bufferSize, &done ) )
	{
		case MPG123_OK:
			if( mute )
				memset( pBuffer, 0, bufferSize );
			return 0;

		case MPG123_NEW_FORMAT:
			return loadBuffer( pBuffer, bufferSize );

		case MPG123_DONE:
		case MPG123_NEED_MORE:
		default:
			return 1;
	}
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

int mpg_register_module( void )
{
	moduleFilePath = mpg_parameter.pModule->p;
	return MXP_OK;
}

int mpg_get_playtime( void )
{
	/** Get information about current and remaining frames/seconds.
	 *  WARNING: This function is there because of special usage by standalone mpg123 and may be removed in the final version of libmpg123!
	 *  You provide an offset (in frames) from now and a number of output bytes
	 *  served by libmpg123 but not yet played. You get the projected current frame
	 *  and seconds, as well as the remaining frames/seconds. This does _not_ care
	 *  about skipped samples due to gapless playback. */

    /** Alternate way:
     * mpg123_open();
     * mpg123_scan();
     * len = mpg123_length();
     * ...
     * pos = mpg123_position();
     * remain = len-pos;
     *
     * From the sample count you can compute seconds with the sampling rate,
     * of course integer seconds could use proper rounding, not just
     * truncation, so something like int(seconds_float+0.5). */
	off_t current_frame;
	off_t frames_left;
	double current_seconds;
	double seconds_left;
	if( mpg123_position( mh, 0, 0, &current_frame, &frames_left, &current_seconds, &seconds_left) != MPG123_OK )
	{
		return MXP_ERROR;
	}

	mpg_parameter.value = (int)( seconds_left * 1000.0 );
	return MXP_OK;
}

int mpg_init( void )
{
	if( mpg123_init() != MPG123_OK )
		goto error1;

	mh = mpg123_new( NULL, NULL );
	if( mh == NULL )
		goto error1;

	if( mpg123_param( mh, MPG123_FORCE_RATE, 49170, 0 ) != MPG123_OK )
		goto error;

	if( mpg123_param( mh, MPG123_FLAGS, MPG123_FORCE_STEREO | MPG123_QUIET, 0 ) != MPG123_OK )
		goto error;

	if( mpg123_format_none( mh ) != MPG123_OK )
		goto error;

	if( mpg123_format( mh, 49170, MPG123_STEREO, MPG123_ENC_SIGNED_16 ) != MPG123_OK )
		goto error;

	return MXP_OK;

error:
	mpg123_delete( mh );
error1:
	mpg123_exit();
	return MXP_ERROR;
}

int mpg_set( void )
{
	if( mpg123_open( mh, moduleFilePath ) != MPG123_OK )
		return MXP_ERROR;

	if( mpg123_scan( mh ) != MPG123_OK )
		return MXP_ERROR;

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
int mpg_feed( void )
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
int mpg_feed( void )
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

int mpg_unset( void )
{
	Buffoper( 0x00 );	// disable playback
#ifdef TIMER_A_HANDLER
	Jdisint( MFP_TIMERA );
#endif

	mpg123_close( mh );

	Mfree( pBuffer );
	pBuffer = NULL;

	return MXP_OK;
}

int mpg_pause( void )
{
	int pause = mpg_parameter.value;
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

int mpg_mute( void )
{
	mute = mpg_parameter.value;
	if( mute )
	{
		memset( pPhysical, 0, bufferSize );
		memset( pLogical, 0, bufferSize );
	}

	return MXP_OK;
}
