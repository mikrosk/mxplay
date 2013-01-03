#include <mint/osbind.h>
#include <mint/ostruct.h>
#include <mint/falcon.h>

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdint.h>

#include <asap.h>

extern void asm_install_timer_a();
extern void asm_uninstall_timer_a();
extern struct
{
	char* pModule;
	size_t moduleSize;
} *asap_parameter;

#define MXP_ERROR	0
#define MXP_OK		1

static char* pPhysical;
static char* pLogical;
static ASAP* asap;
static ASAPInfo* info;
static size_t bufferSize;	// size of one buffer
static int channels;

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

	FILE *fp = fopen( asap_parameter->pModule, "rb" );
	if( fp == NULL )
	{
		return MXP_ERROR;
	}

	static unsigned char module[ASAPInfo_MAX_MODULE_LENGTH];
	int module_len = fread( module, 1, sizeof( module ), fp );
	fclose( fp );

	if( !ASAP_Load( asap, asap_parameter->pModule, module, module_len ) )
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

	loadBuffer( pLogical, bufferSize );
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

	Supexec( asm_install_timer_a );

	// start playback!!!
	if( Buffoper( SB_PLA_ENA | SB_PLA_RPT ) != 0 )
	{
		return MXP_ERROR;
	}

	return MXP_OK;
}

int asap_unset( void )
{
	Buffoper( 0x00 );	// disable playback
	Sndstatus( SND_RESET );

	Supexec( asm_uninstall_timer_a );

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
