#include <mint/osbind.h>
#include <mint/ostruct.h>
#include <mint/falcon.h>
#include <stdio.h>

#include "../plugin.h"
#include "mgt-play.h"

#define MAXSIZE 1200000

extern union UParameterBuffer mgt_parameter;

char* g_moduleBuffer;
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

extern int mgt_settings_name_get( void );
extern int mgt_settings_channels_get( void );
extern int mgt_settings_sample1_get( void );
extern int mgt_settings_sample2_get( void );
extern int mgt_settings_sample3_get( void );
extern int mgt_settings_sample4_get( void );
extern int mgt_settings_sample5_get( void );
extern int mgt_settings_sample6_get( void );
extern int mgt_settings_sample7_get( void );
extern int mgt_settings_sample8_get( void );
extern int mgt_settings_sample9_get( void );
extern int mgt_settings_sample10_get( void );
extern int mgt_settings_sample11_get( void );
extern int mgt_settings_sample12_get( void );
extern int mgt_settings_sample13_get( void );
extern int mgt_settings_sample14_get( void );
extern int mgt_settings_sample15_get( void );
extern int mgt_settings_sample16_get( void );
extern int mgt_settings_sample17_get( void );
extern int mgt_settings_sample18_get( void );
extern int mgt_settings_sample19_get( void );
extern int mgt_settings_sample20_get( void );
extern int mgt_settings_sample21_get( void );
extern int mgt_settings_sample22_get( void );
extern int mgt_settings_sample23_get( void );
extern int mgt_settings_sample24_get( void );
extern int mgt_settings_sample25_get( void );
extern int mgt_settings_sample26_get( void );
extern int mgt_settings_sample27_get( void );
extern int mgt_settings_sample28_get( void );
extern int mgt_settings_sample29_get( void );
extern int mgt_settings_sample30_get( void );
extern int mgt_settings_sample31_get( void );

struct SParameter		mgt_settings[] =
{
	{ "Channels", MXP_PAR_TYPE_INT|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM, NULL, mgt_settings_channels_get },
	{ "Song name", MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM, NULL, mgt_settings_name_get },
	{ "Sample #0", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample1_get },
	{ "Sample #1", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample2_get },
	{ "Sample #2", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample3_get },
	{ "Sample #3", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample4_get },
	{ "Sample #4", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample5_get },
	{ "Sample #5", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample6_get },
	{ "Sample #6", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample7_get },
	{ "Sample #7", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample8_get },
	{ "Sample #8", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample9_get },
	{ "Sample #9", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample10_get },
	{ "Sample #10", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample11_get },
	{ "Sample #11", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample12_get },
	{ "Sample #12", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample13_get },
	{ "Sample #13", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample14_get },
	{ "Sample #14", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample15_get },
	{ "Sample #15", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample16_get },
	{ "Sample #16", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample17_get },
	{ "Sample #17", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample18_get },
	{ "Sample #18", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample19_get },
	{ "Sample #19", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample20_get },
	{ "Sample #20", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample21_get },
	{ "Sample #21", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample22_get },
	{ "Sample #22", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample23_get },
	{ "Sample #23", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample24_get },
	{ "Sample #24", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample25_get },
	{ "Sample #25", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample26_get },
	{ "Sample #26", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample27_get },
	{ "Sample #27", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample28_get },
	{ "Sample #28", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample29_get },
	{ "Sample #29", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample30_get },
	{ "Sample #30", MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM, NULL, mgt_settings_sample31_get },
	{ NULL, 0, NULL, NULL }
};

int mgt_register_module( void )
{
	g_moduleBuffer = (char*)Mxalloc( MAXSIZE, MX_STRAM );
	if( g_moduleBuffer == NULL )
	{
		return MXP_ERROR;
	}

	FILE *fp = fopen( mgt_parameter.pModule->p, "rb" );
	if( fp == NULL )
	{
		Mfree( g_moduleBuffer );
		g_moduleBuffer = NULL;
		return MXP_ERROR;
	}

	moduleLength = fread( g_moduleBuffer, 1, MAXSIZE, fp );
	fclose( fp );

	if( MGTK_Init_Module_Samples( g_moduleBuffer, g_moduleBuffer+MAXSIZE ) != 0 )
	{
		/*
		 *	case -1:	Cconws("This is not a MegaTracker module!\r\n");break;
		 *	case -2:	Cconws("Not enough workspace to depack tracks!\r\n");break;
		 *	case -3:	Cconws("Not enough workspace to prepare samples!\r\n");break;
		 *	case -4:	Cconws("No samples in this module!\r\n");break;
		 */
		Mfree( g_moduleBuffer );
		g_moduleBuffer = NULL;
		return MXP_ERROR;
	}

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

int mgt_pause( void )
{
	static int paused;

	if( paused != (int)mgt_parameter.value )
	{
		MGTK_Pause_Music();
		paused = !paused;
	}

	return MXP_OK;
}

int mgt_unset( void )
{
	MGTK_Stop_Music();
	MGTK_Restore_Sound();
	Mfree( g_moduleBuffer );
	g_moduleBuffer = NULL;

	return MXP_OK;
}

int mgt_deinit( void )
{
	return MXP_OK;
}
