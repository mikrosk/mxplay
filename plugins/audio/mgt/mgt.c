#include <mint/osbind.h>
#include <mint/ostruct.h>
#include <mint/falcon.h>
#include <stdio.h>

#include "../plugin.h"
#include "mgt-play.h"

#define MAXSIZE 1200000

extern union UParameterBuffer mgt_parameter;

static char* moduleBuffer;
static size_t moduleLength;

struct SInfo			mgt_info =
{
	"MiKRO / Mystic Bytes",
	"1.0",
	"DSP-Replay MegaTracker",
	"Simplet / Fatal Design",
	"1.1 16/09/1995",
	MXP_FLG_USE_DSP|MXP_FLG_USE_DMA|MXP_FLG_USE_020|MXP_FLG_DONT_LOAD_MODULE|MXP_FLG_USER_CODE
};

struct SExtension		mgt_extensions[] =
{
	{ "MGT", "MegaTracker module" },
	{ NULL, NULL }
};

struct SParameter		mgt_settings[] =
{
	//{ "Song name", MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM, NULL, getSongName },
	//{ "Channels", MXP_PAR_TYPE_INT|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM, NULL, getChannels },
	{ NULL, 0, NULL, NULL }
};

int mgt_register_module( void )
{
	moduleBuffer = (char*)Mxalloc( MAXSIZE, MX_STRAM );
	if( moduleBuffer == NULL )
	{
		return MXP_ERROR;
	}

	FILE *fp = fopen( mgt_parameter.pModule->p, "rb" );
	if( fp == NULL )
	{
		return MXP_ERROR;
	}

	moduleLength = fread( moduleBuffer, 1, MAXSIZE, fp );
	fclose( fp );

	if( MGTK_Init_Module_Samples( moduleBuffer, moduleBuffer+MAXSIZE ) != 0 )
	{
		/*
		 *	case -1:	Cconws("This is not a MegaTracker module!\r\n");break;
		 *	case -2:	Cconws("Not enough workspace to depack tracks!\r\n");break;
		 *	case -3:	Cconws("Not enough workspace to prepare samples!\r\n");break;
		 *	case -4:	Cconws("No samples in this module!\r\n");break;
		 */
		Mfree( moduleBuffer );
		moduleBuffer = NULL;
		return MXP_ERROR;
	}

 	return MXP_OK;
}

int mgt_get_playtime( void )
{
	mgt_parameter.value = 5 * 60;	// TODO
	return MXP_OK;
}

int mgt_init( void )
{
	return MXP_OK;
}

int mgt_set( void )
{
	if( MGTK_Init_DSP() != 0 )
	{
		return MXP_ERROR;
	}

	MGTK_Save_Sound();
	MGTK_Init_Sound();
	MGTK_Set_Replay_Frequency( 1 );	// 49170 Hz
	MGTK_Restart_Loop= -1;	// no loop
	MGTK_Play_Music( 0 );	// song 0

	return MXP_OK;
}

int mgt_unset( void )
{
	MGTK_Stop_Music();
	MGTK_Restore_Sound();
	Mfree( moduleBuffer );
	moduleBuffer = NULL;

	return MXP_OK;
}

int mgt_deinit( void )
{
	return MXP_OK;
}
