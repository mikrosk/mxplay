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
	"1.0",
	"Another Slight Atari Player",
	"Piotr Fusik",
	ASAPInfo_VERSION,
	MXP_FLG_USE_DMA|MXP_FLG_USE_020|MXP_FLG_USE_FPU|MXP_FLG_DONT_LOAD_MODULE|MXP_FLG_USER_CODE
};

struct SExtension		asap_extensions[] =
{
	{ "SAP", "Slight Atari Player" },
	{ "CMC", "Chaos Music Composer" },
	{ "CM3", "Chaos Music Composer \"3/4\"" },
	{ "CMR", "Chaos Music Composer \"Rzog\"" },
	{ "CMS", "Stereo Double Chaos Music Composer" },
	{ "DMC", "DoublePlay Chaos Music Composer" },
	{ "DLT", "Delta Music Composer" },
	{ "FC", "Future Composer" },
	{ "MPT", "Music ProTracker" },
	{ "MPD", "Music ProTracker DoublePlay" },
	{ "RMT", "Raster Music Tracker" },
	{ "TMC", "Theta Music Composer 1.x" },
	{ "TM8", "Theta Music Composer 1.x" },
	{ "TM2", "Theta Music Composer 2.x" }
};

//struct SParameter		xmp_settings[] =
//{
//}

static char* pPhysical;
static char* pLogical;
static ASAP* asap;
static ASAPInfo* info;
static size_t bufferSize;	// size of one buffer
static int channels;
static int loadNewSample;

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

static void __attribute__((interrupt)) timerA( void )
{
	// swap buffers (makes logical buffer physical)
	char* tmp = pPhysical;
	pPhysical = pLogical;
	pLogical = tmp;

	Setbuffer( SR_PLAY, pPhysical, pPhysical + bufferSize );

	loadNewSample = 1;

	*( (volatile unsigned char*)0xFFFFFA0FL ) &= ~( 1<<5 );	//	clear in service bit
}

static void enableTimerASei( void )
{
	*( (volatile unsigned char*)0xFFFFFA17L ) |= ( 1<<3 );	//	software end-of-interrupt mode
}

int asap_register_module( void )
{
	return MXP_OK;
}

int asap_get_playtime( void )
{
	int time = ASAPInfo_GetDuration( info, 0 );	// song 0
	return time != -1 ? time / 1000 : 300;	// return value is in seconds
}

int asap_init( void )
{
	asap = ASAP_New();

	return asap != NULL ? MXP_OK : MXP_ERROR;
}

int asap_set( void )
{
	char* pBuffer;

	FILE *fp = fopen( asap_parameter.pModule->p, "rb" );
	if( fp == NULL )
	{
		return MXP_ERROR;
	}

	static unsigned char module[ASAPInfo_MAX_MODULE_LENGTH];
	int module_len = fread( module, 1, sizeof( module ), fp );
	fclose( fp );

	if( !ASAP_Load( asap, asap_parameter.pModule->p, module, module_len ) )
	{
		// unsupported
		return MXP_ERROR;
	}

	if( !ASAP_PlaySong( asap, 0, -1 ) )	// song 0, unlimited time
	{
		return MXP_ERROR;
	}

	info = (ASAPInfo*)ASAP_GetInfo( asap );
	channels = ASAPInfo_GetChannels( info );

	bufferSize = 2 * 2 * ASAP_SAMPLE_RATE * 2;	// 2 channels * 16 bit * 49170 Hz * 2 seconds

	pBuffer = (char*)Mxalloc( 2 * bufferSize, MX_STRAM );
	if( pBuffer == NULL )
	{
		return MXP_ERROR;
	}
	pPhysical = pBuffer;
	pLogical = pBuffer + bufferSize;

	loadBuffer( pPhysical, bufferSize );
	loadBuffer( pLogical, bufferSize );

	Sndstatus( SND_RESET );

	if( Devconnect( DMAPLAY, DAC, CLK25M, CLK50K, NO_SHAKE ) != 0 )
	{
		return MXP_ERROR;
	}

	if( Setmode( MODE_STEREO16 ) != 0 )
	{
		return MXP_ERROR;
	}

	Soundcmd( ADDERIN, MATIN );

	// even if Setbuffer() is set in TimerA, Sndstatus() reset it
	if( Setbuffer( SR_PLAY, pPhysical, pPhysical + bufferSize ) != 0 )
	{
		return MXP_ERROR;
	}

	if( Setinterrupt( SI_TIMERA, SI_PLAY ) != 0 )
	{
		return MXP_ERROR;
	}

	Xbtimer( XB_TIMERA, 1<<3, 1, timerA );	// event count mode, count to '1'
	Supexec( enableTimerASei );
	Jenabint( MFP_TIMERA );

	// start playback!!!
	if( Buffoper( SB_PLA_ENA | SB_PLA_RPT ) != 0 )
	{
		return MXP_ERROR;
	}

	return MXP_OK;
}

void asap_feed( void )
{
	if( loadNewSample )
	{
		loadBuffer( pLogical, bufferSize );

		loadNewSample = 0;
	}
}

int asap_unset( void )
{
	Buffoper( 0x00 );	// disable playback
	Jdisint( MFP_TIMERA );
	Sndstatus( SND_RESET );

	ASAPInfo_Delete( info );

	return MXP_OK;
}

int asap_deinit( void )
{
	ASAP_Delete( asap );

	return MXP_OK;
}

int asap_fwd( void )
{
	return MXP_ERROR;
}

int asap_rwd( void )
{
	return MXP_ERROR;
}

int asap_pause( void )
{
	return MXP_ERROR;
}
