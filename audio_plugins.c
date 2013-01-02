/*
 * audio_plugins.c -- the low-level communication with audio plugin
 *
 * Copyright (c) 2005-2013 Miro Kropacek; miro.kropacek@gmail.com
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
#include <mint/basepage.h>
#include <cflib.h>
#include <stdio.h>
#include <string.h>

#include <fcntl.h>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>

#include "mxplay.h"
#include "dialogs.h"
#include "audio_plugins.h"
#include "dsp_fix.h"
#include "skins/skin.h"
#include "misc.h"
#include "info_dialogs.h"

struct SAudioPlugin*		g_pCurrAudioPlugin = NULL;
BOOL						g_modulePlaying = FALSE;
BOOL						g_modulePaused = FALSE;
char						g_currModuleName[MXP_PATH_MAX+1] = "-";

static struct SAudioPlugin*	pSAudioPlugin[MAX_AUDIO_PLUGINS];
static int					audioPluginsCount;
static char*				pCurrModule;
static int					dspLocked = FALSE;
static int					dmaLocked = FALSE;
static char**				pInputArray;

static int AudioPluginInit( struct SAudioPlugin* plugin )
{
	if( plugin->Init != NULL )
	{
		return Supexec( &plugin->Init );
	}
	else
	{
		return MXP_ERROR;
	}
}

static int AudioPluginRegisterModule( struct SAudioPlugin* plugin, char* module, unsigned int length )
{
	pInputArray[0] = (char*)module;
	pInputArray[1] = (char*)length;

	plugin->inBuffer = (long)pInputArray;
	if( plugin->RegisterModule != NULL )
	{
		return Supexec( &plugin->RegisterModule );
	}
	else
	{
		return MXP_ERROR;
	}
}

static struct SAudioPlugin* AudioPluginLoad( char* filename )
{
	BASEPAGE*	bp;
	char*		cmdline[128];
	struct SAudioPlugin* p;

	cmdline[0] = 0;	/* 0 bytes long */
	cmdline[1] = '\0';	/* terminate it */

	bp = (BASEPAGE*)Pexec( PE_LOAD, filename, cmdline, NULL );
	if( (long)bp <= 0 )
	{
		return NULL;
	}
	else
	{
		Mshrink( bp->p_lowtpa,		/* basepage address */
		0x100 +						/* length of basepage */
		bp->p_tlen +				/* length of text segment */
		bp->p_dlen +				/* length of data segment */
		bp->p_blen +				/* length of BSS segment */
		4096 );						/* length of stack */

		memset( bp->p_bbase, bp->p_blen, 0 );

		// text segment
		p = (struct SAudioPlugin*)bp->p_tbase;
		if( strncmp( p->header, "MXP1", 4 ) == 0 )
		{
			return p;
		}

		// MiNT executables need this hack...
		p = (struct SAudioPlugin*)( bp->p_tbase + 228 );
		if( strncmp( p->header, "MXP1", 4 ) == 0 )
		{
			return p;
		}

		return NULL;
	}
}

/*
 * Fill scrollable infoline in the main panel.
 */
void AudioPluginGetInfoLine( struct SParameter* param )
{
	char	infoLine[1023+1];
	int		i;
	char	tempString[255+1];

	strcpy( infoLine, "" );

	for( i = 0; param[i].pName != NULL; i++ )
	{
		if( ( param[i].type & MXP_FLG_INFOLINE ) != 0 )
		{
			strcat( infoLine, param[i].pName );	/* i.e. "Songname" */
			strcat( infoLine, ": " );

			ConvertMxpParamTypes( g_pCurrAudioPlugin, &param[i], tempString );
			strcat( infoLine, tempString );

			strcat( infoLine, "  " );	/* delimiter */
		}
	}

	strcpy( g_panelInfoLine, infoLine );	/* update the real one */
}

/*
 * Load music file
 */
BOOL LoadAudioModule( char* path, char* name )
{
	char			tempString[MXP_PATH_MAX+MXP_FILENAME_MAX+1];
	unsigned long	length;
	char*			pTempModule = NULL;

	/* no more available */
	if( pCurrModule != NULL )
	{
		Mfree( pCurrModule );
		pCurrModule = NULL;
	}

	CombinePath( tempString, path, name );

	if( g_pCurrAudioPlugin != NULL && g_pCurrAudioPlugin->pSInfo->flags & MXP_FLG_DONT_LOAD_MODULE )
	{
		pTempModule = tempString;	// buffer is now a path pointer
		length = 0;	// for sure
	}
	else
	{
		int	handle = open( tempString, O_RDONLY );
		if( handle < 0 )
		{
			ShowLoadErrorDialog( name );
			return FALSE;
		}
		else
		{
			length = GetFileNameSize( tempString );
			if( length == 0 )
			{
				return FALSE;
			}

			/* Global ST RAM */
			if( getcookie( "MiNT", NULL ) == TRUE )
			{
				pTempModule = (char*)Mxalloc( length, MX_STRAM | 0x0008 | MX_GLOBAL );
			}
			else
			{
				pTempModule = (char*)Mxalloc( length, MX_STRAM );
			}
			if( VerifyAlloc( pTempModule ) == FALSE )
			{
				return FALSE;
			}

			if( read( (short)handle, pTempModule, length ) < 0 )
			{
				ShowLoadErrorDialog( name );
				Mfree( pTempModule );
				pTempModule = NULL;
				close( handle );
				return FALSE;
			}
			else
			{
				close( handle );
			}
		}
	}

	if( AudioPluginRegisterModule( g_pCurrAudioPlugin, pTempModule, length ) != MXP_OK )
	{
		ShowBadHeaderDialog();
		strcpy( g_panelInfoLine, "" );	/* infoline is no more actual */
		strcpy( g_currModuleName, "-" );	/* this is even more critical */
		Mfree( pTempModule );
		pTempModule = NULL;
		return FALSE;
	}

	strcpy( g_currModuleName, tempString );
	pCurrModule = pTempModule;
	return TRUE;
}

/*
 * Return pointer to the plugin able to replay
 * current mod or NULL
 */
struct SAudioPlugin* LookForAudioPlugin( char* extension )
{
	int 				i, j;
	struct SExtension*	ext;
	char				tempString[MXP_FILENAME_MAX+1];

	strcpy( tempString, extension );
	str_toupper( tempString );

	for( i = 0; i < audioPluginsCount; i++ )
	{
		ext = pSAudioPlugin[i]->pSExtension;
		for( j = 0; ; j++ )
		{
			/* end of extension list? */
			if( ext[j].ext == NULL )
			{
				break;
			}
			/* nope, continue searching for the supported extension */
			else if( strcmp( ext[j].ext, "*" ) == 0
					 || strcmp( ext[j].ext, tempString ) == 0 )
			{
				return pSAudioPlugin[i];
			}
		}
	}
	return NULL;
}

/*
 * Search for all audio plugins
 * in ./plugins/audio directory
 */

void LoadAudioPlugins( void )
{
	DIR*			pDirStream;
	struct dirent*	pDirEntry;
	char			tempString[MXP_PATH_MAX+1];
	char			ext[MXP_FILENAME_MAX+1];

	/* Global ST/TT RAM */
	pInputArray = (char**)malloc_global( 2 * sizeof( char* ) );
	if( VerifyAlloc( pInputArray ) == FALSE )
	{
		ExitPlayer( 1 );
	}

	pDirStream = opendir( AUDIO_PLUGINS_PATH );
	if( pDirStream != NULL )
	{
		while( ( pDirEntry = readdir( pDirStream ) ) != NULL )
		{
			if( IsDirectory( AUDIO_PLUGINS_PATH, pDirEntry->d_name ) == FALSE )
			{
				split_extension( pDirEntry->d_name, NULL, ext );
				if( strcmp( ext, "mxp" ) == 0 || strcmp( ext, "MXP" ) == 0 )
				{
					strcpy( tempString, gl_appdir );
					CombinePath( tempString, tempString, AUDIO_PLUGINS_PATH );	/* path\plugins\audio */
					CombinePath( tempString, tempString, pDirEntry->d_name );	/* path\plugins\audio\plugin.mxp */

					pSAudioPlugin[audioPluginsCount] = AudioPluginLoad( tempString );
					if( pSAudioPlugin[audioPluginsCount] != NULL )
					{
						if( AudioPluginInit( pSAudioPlugin[audioPluginsCount] ) != MXP_OK )
						{
							ShowAudioInitErrorDialog( pDirEntry->d_name );
							Mfree( pSAudioPlugin[audioPluginsCount] );
						}
						else
						{
							audioPluginsCount++;
						}
					}
				}
			}
		}

		if( audioPluginsCount == 0 )
		{
			ShowNoAudioFoundDialog();
		}
	}
	else
	{
		ShowNoAudioFoundDialog();
	}

	closedir( pDirStream );
}

/*
 * Play current module
 */
int AudioPluginModulePlay( void )
{
	if( g_pCurrAudioPlugin != NULL && g_pCurrAudioPlugin->Set != NULL )
	{
		g_modulePlaying = TRUE;
#ifndef DISABLE_PLUGINS
		return Supexec( &g_pCurrAudioPlugin->Set );
#else
		return MXP_OK;
#endif
	}

	return MXP_OK;
}

/*
 * Stop current module playback
 */
int AudioPluginModuleStop( void )
{
	int ret;

	if( g_pCurrAudioPlugin != NULL && g_pCurrAudioPlugin->Unset != NULL )
	{
		g_modulePaused = FALSE;
		g_modulePlaying = FALSE;
#ifndef DISABLE_PLUGINS
		ret = Supexec( &g_pCurrAudioPlugin->Unset );
		// TODO: only if dsp is used by mxPlay (+ sound reset implementation?)
		dsp_load_program( NULL, 0 );	/* reset DSP */
		return ret;
#else
		return MXP_OK;
#endif
	}

	return MXP_OK;
}

/*
 * Pause current module playback
 */
int AudioPluginModulePause( void )
{
	if( g_pCurrAudioPlugin != NULL && g_pCurrAudioPlugin->ModulePause != NULL )
	{
		g_modulePaused = !g_modulePaused;
#ifndef DISABLE_PLUGINS
		return Supexec( &g_pCurrAudioPlugin->ModulePause );
#else
		return MXP_OK;
#endif
	}

	return MXP_UNIMPLEMENTED;
}

/*
 * Forward module. Still very simple implementation,
 * 'bigStep' is ignored for this moment.
 */
int AudioPluginModuleFwd( BOOL bigStep )
{
	if( g_pCurrAudioPlugin != NULL && g_pCurrAudioPlugin->ModuleFwd != NULL )
	{
#ifndef DISABLE_PLUGINS
		return Supexec( &g_pCurrAudioPlugin->ModuleFwd );
#else
		return MXP_OK;
#endif
	}

	return MXP_UNIMPLEMENTED;
}

/*
 * Rewind module. Still very simple implementation,
 * 'bigStep' is ignored for this moment.
 */
int AudioPluginModuleRwd( BOOL bigStep )
{
	if( g_pCurrAudioPlugin != NULL && g_pCurrAudioPlugin->ModuleRwd != NULL )
	{
#ifndef DISABLE_PLUGINS
		return Supexec( &g_pCurrAudioPlugin->ModuleRwd );
#else
		return MXP_OK;
#endif
	}

	return MXP_UNIMPLEMENTED;
}

BOOL AudioPluginLockResources( void )
{
	long flags;

	if( g_pCurrAudioPlugin != NULL )
	{
		flags = g_pCurrAudioPlugin->pSInfo->flags;
		if( flags & MXP_FLG_USE_DSP )
		{
			if( g_hasDsp == TRUE )
			{
				if( Dsp_Lock() != E_OK )
				{
					if( ShowDspLockedDialog() == 1 )
					{
						dspLocked = FALSE;
						return FALSE;
					}
					else
					{
						Dsp_Unlock();
						if( Dsp_Lock() != E_OK )
						{
							/* gcc complains here */
						}
						dspLocked = TRUE;
					}
				}
				else
				{
					dspLocked = TRUE;
				}
			}
			else
			{
				ShowDspRequiredDialog();
				return FALSE;
			}
		}
		if( flags & MXP_FLG_USE_DMA )
		{
			if( g_hasDma == TRUE )
			{
				if( Locksnd() == -129 )
				{
					if( ShowDmaLockedDialog() == 1 )
					{
						dmaLocked = FALSE;
						return FALSE;
					}
					else
					{
						Unlocksnd();
						Locksnd();
						dmaLocked = TRUE;
					}
				}
				else
				{
					dmaLocked = TRUE;
				}
			}
			else
			{
				ShowDmaRequiredDialog();
				return FALSE;
			}
		}
		if( flags & MXP_FLG_USE_020 )
		{
			if( g_cpu < 20 )
			{
				Show020RequiredDialog();
				return FALSE;
			}
		}
		if( flags & MXP_FLG_USE_FPU )
		{
			if( g_fpu == 0 )
			{
				ShowFpuRequiredDialog();
				return FALSE;
			}
		}

	}
	return TRUE;
}

BOOL AudioPluginFreeResources( void )
{
	long flags;

	if( g_pCurrAudioPlugin != NULL )
	{
		flags = g_pCurrAudioPlugin->pSInfo->flags;
		if( ( flags & MXP_FLG_USE_DSP ) && dspLocked )
		{
			Dsp_Unlock();
			dspLocked = FALSE;
		}
		if( ( flags & MXP_FLG_USE_DMA ) && dmaLocked )
		{
			if( Unlocksnd() == -128 )
			{
				dmaLocked = FALSE;
				ShowDmaNotLockedDialog();
				return FALSE;
			}
		}
	}
	return TRUE;
}

/*
 * Get basic information about plugin
 */
void AudioPluginGetBaseInfo( struct SAudioPlugin* plugin,
							 char** pluginAuthor, char** pluginVersion,
							 char** replayName, char** replayAuthor, char** replayVersion,
							 long* flags )
{
	struct SInfo* info = plugin->pSInfo;

	*pluginAuthor = info->pPluginAuthor;
	*pluginVersion = info->pPluginVersion;
	*replayName = info->pReplayName;
	*replayAuthor = info->pReplayAuthor;
	*replayVersion = info->pReplayVersion;
	*flags = info->flags;
}

/*
 * Get playtime of current module
 */
unsigned long AudioPluginGetPlayTime( void )
{
	if( g_pCurrAudioPlugin != NULL )
	{
#ifndef DISABLE_PLUGINS
		return Supexec( &g_pCurrAudioPlugin->PlayTime );
#else
		return 300;
#endif
	}

	return 0;
}

/*
 * Get parameter pointer for the given name
 */
struct SParameter* AudioPluginGetParam( struct SAudioPlugin* plugin, char* name )
{
	struct SParameter* param = plugin->pSParameter;

	while( param->pName != NULL )
	{
		if( strncmp( param->pName, name, strlen( name ) ) == 0 )
		{
			return param;
		}
		param++;
	}

	return NULL;
}

/*
 * Set given parameter to value on input
 */
int AudioPluginSet( struct SAudioPlugin* plugin, struct SParameter* param, long value )
{
	int ret;

	plugin->inBuffer = value;
	ret = Supexec( param->Set );
	AudioPluginGetInfoLine( plugin->pSParameter );	/* start from the first parameter */
	return ret;
}

/*
 * Get given parameter's value
 */
int AudioPluginGet( struct SAudioPlugin* plugin, struct SParameter* param, long* value )
{
	int ret;

	ret = Supexec( param->Get );
	*value = plugin->inBuffer;
	return ret;
}
