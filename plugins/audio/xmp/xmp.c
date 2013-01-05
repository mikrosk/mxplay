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
	"1.0",
	"Extended Module Player",
	"C.Matsuoka & H.Carraro Jr",
	XMP_VERSION,
	MXP_FLG_USE_DMA|MXP_FLG_USE_020|MXP_FLG_USE_FPU|MXP_FLG_DONT_LOAD_MODULE|MXP_FLG_USER_CODE
};

struct SExtension		xmp_extensions[] =
{
	{ "*", "Module" }
};

//struct SParameter		xmp_settings[] =
//{
//}

#define SAMPLE_RATE	49170
#define MODULE_FPS	50

static char* pPhysical;
static char* pLogical;
static xmp_context c;
static size_t bufferSize;	// size of one buffer
static int loadNewSample;

static int loadBuffer( char* pBuffer, size_t bufferSize )
{
	int rc = 0;
	size_t loaded = 0;
	memset( pBuffer, 0, bufferSize );

	while( loaded < bufferSize && xmp_play_frame( c ) == 0 )
	{
		struct xmp_frame_info fi;
		xmp_get_frame_info( c, &fi );

		if( fi.loop_count > 0 )    /* exit before looping */
		{
			rc = 1;	// end of module
			break;
		}

		memcpy( pBuffer, fi.buffer, fi.buffer_size );
		pBuffer += fi.buffer_size;
		loaded += fi.buffer_size;
	}

	return rc;
}

double round(double number)
{
	return number < 0.0 ? ceil(number - 0.5) : floor(number + 0.5);
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

///////////////////////////////////////////////////////////////////////////////

int xmp_register_module( void )
{
	struct xmp_test_info ti;	// name and extension
 	return xmp_test_module( xmp_parameter.pModule->p, &ti ) == 0 ? MXP_OK : MXP_ERROR;
}

int xmp_get_playtime( void )
{
	struct xmp_frame_info fi;
	xmp_get_frame_info( c, &fi );
	return fi.total_time / 1000;	// return value is in seconds
}

int xmp_init( void )
{
	c = xmp_create_context();

	return MXP_OK;
}

int xmp_set( void )
{
	char* pBuffer;
	struct xmp_frame_info fi;

	if( xmp_load_module( c, xmp_parameter.pModule->p ) != 0 )
	{
		return MXP_ERROR;
	}

	xmp_start_player( c, SAMPLE_RATE, 0 );	// 0: stereo 16bit signed (default)

	// decode one frame, to get idea about needed buffer size
	if( xmp_play_frame( c ) != 0 )
	{
		return MXP_ERROR;
	}

	xmp_get_frame_info( c, &fi );

	// now we know how much we need for one frame
	// the frame is defined as: ( SAMPLE_RATE / 50 ) * 2 channels * 16 bit (approx.)
	bufferSize = fi.buffer_size * MODULE_FPS * 5;	// 5 seconds

	pBuffer = (char*)Mxalloc( 2 * bufferSize, MX_STRAM );
	if( pBuffer == NULL )
	{
		return MXP_ERROR;
	}
	pPhysical = pBuffer;
	pLogical = pBuffer + bufferSize;

	// one frame is already decoded
	memcpy( pLogical, fi.buffer, fi.buffer_size );
	loadBuffer( pLogical + fi.buffer_size, bufferSize - fi.buffer_size );
	// logical buffer is ready to use!
	char* tmp = pPhysical;
	pPhysical = pLogical;
	pLogical = tmp;

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

void xmp_feed( void )
{
	if( loadNewSample )
	{
		loadBuffer( pPhysical, bufferSize );

		loadNewSample = 0;
	}
}

int xmp_unset( void )
{
	Buffoper( 0x00 );	// disable playback
	Jdisint( MFP_TIMERA );
	Sndstatus( SND_RESET );

	xmp_stop_module( c );
	xmp_end_player( c );
	xmp_release_module( c );        /* unload module */

	return MXP_OK;
}

int xmp_deinit( void )
{
	xmp_free_context( c );          /* destroy the player context */

	return MXP_OK;
}

int xmp_fwd( void )
{
	return MXP_ERROR;
}

int xmp_rwd( void )
{
	return MXP_ERROR;
}

int xmp_pause( void )
{
	return MXP_ERROR;
}
