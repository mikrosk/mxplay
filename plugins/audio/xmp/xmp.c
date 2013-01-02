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

#define SAMPLE_RATE	49170
#define MODULE_FPS	50

extern void asm_install_timer_a();
extern void asm_uninstall_timer_a();

struct
{
	char* pModule;
	size_t moduleSize;
} xmp_parameter;
#define MXP_OK		0
#define MXP_ERROR	1

static char* pPhysical;
static char* pLogical;
static xmp_context c;
static size_t bufferSize;	// size of one buffer

static char* pModule;	// either buffer or path
static size_t moduleSize;

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

void timerA( void )
{
	// swap buffers (makes logical buffer physical)
	char* tmp = pPhysical;
	pPhysical = pLogical;
	pLogical = tmp;

	Setbuffer( SR_PLAY, pPhysical, pPhysical + bufferSize );

	// somehow this works, no clue why
	loadBuffer( pPhysical, bufferSize );
}

int xmp_register_module( void )
{
	pModule = xmp_parameter.pModule;
	moduleSize = xmp_parameter.moduleSize;

	struct xmp_test_info ti;	// name and extension
	return xmp_test_module( pModule, &ti ) == 0 ? MXP_OK : MXP_ERROR;
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

	if( xmp_load_module( c, pModule ) != 0 )
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

	//Xbtimer( XB_TIMERA, 1<<4, 1, timerA );	// event count mode, count to '1'
	//Jenabint( MFP_TIMERA );
	Supexec( asm_install_timer_a );

	// start playback!!!
	if( Buffoper( SB_PLA_ENA | SB_PLA_RPT ) != 0 )
	{
		return MXP_ERROR;
	}

	return MXP_OK;
}

int xmp_unset( void )
{
	Buffoper( 0x00 );	// disable playback
	Sndstatus( SND_RESET );

	Supexec( asm_uninstall_timer_a );

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
