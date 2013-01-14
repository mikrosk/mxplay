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
char						g_currModuleFilePath[MXP_PATH_MAX+MXP_FILENAME_MAX+1] = "-";

static struct SAudioPlugin*	pSAudioPlugin[MAX_AUDIO_PLUGINS];
static int					audioPluginsCount;
static int					dspLocked = FALSE;
static int					dmaLocked = FALSE;
static struct SModuleParameter moduleParameter;

static int					moduleSongNumber;
static int					moduleSongs;

static BOOL AudioPluginIsFlagSet( int flag )
{
	if( g_pCurrAudioPlugin != NULL && g_pCurrAudioPlugin->pSInfo != NULL )
	{
		return ( g_pCurrAudioPlugin->pSInfo->flags & flag ) != 0 ? TRUE : FALSE;
	}
	return FALSE;
}

static int AudioPluginInit( struct SAudioPlugin* plugin )
{
	if( plugin->Init != NULL )
	{
#ifndef DISABLE_PLUGINS
		return AudioPluginIsFlagSet( MXP_FLG_USER_CODE ) ? plugin->Init() : Supexec( plugin->Init );
#else
		return MXP_OK;
#endif
	}
	else
	{
		return MXP_ERROR;
	}
}

static int AudioPluginRegisterModule( struct SAudioPlugin* plugin, char* module, size_t length )
{
	moduleParameter.p = module;
	moduleParameter.size = length;

	plugin->inBuffer.pModule = &moduleParameter;
	if( plugin->RegisterModule != NULL )
	{
#ifndef DISABLE_PLUGINS
		return AudioPluginIsFlagSet( MXP_FLG_USER_CODE ) ? plugin->RegisterModule() : Supexec( plugin->RegisterModule );
#else
	return MXP_OK;
#endif
	}
	else
	{
		return MXP_ERROR;
	}
}

static struct SAudioPlugin* AudioPluginLoad( char* filename )
{
	BASEPAGE*	bp;
	char		cmdline[128];
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
		memset( bp->p_bbase, bp->p_blen, 0 );	// clear the BSS segment

		// text segment
		p = (struct SAudioPlugin*)bp->p_tbase;
		if( strncmp( p->header, "MXP2", 4 ) == 0 )
		{
			return p;
		}

		// MiNT executables need this hack...
		p = (struct SAudioPlugin*)( bp->p_tbase + 228 );
		if( strncmp( p->header, "MXP2", 4 ) == 0 )
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
	static char*	pModule;

	/* no more available */
	if( pModule != NULL )
	{
		free( pModule );
		pModule = NULL;
	}

	CombinePath( tempString, path, name );

	if( AudioPluginIsFlagSet( MXP_FLG_DONT_LOAD_MODULE ) )
	{
		// buffer serves now as a path
		length = strlen( tempString ) + 1;
		pModule = strdup( tempString );
		if( VerifyAlloc( pModule ) == FALSE )
		{
			return FALSE;
		}
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

			pModule = (char*)malloc( length );
			if( VerifyAlloc( pModule ) == FALSE )
			{
				return FALSE;
			}

			if( read( (short)handle, pModule, length ) < 0 )
			{
				ShowLoadErrorDialog( name );
				free( pModule );
				pModule = NULL;
				close( handle );
				return FALSE;
			}
			else
			{
				close( handle );
			}
		}
	}

	if( AudioPluginRegisterModule( g_pCurrAudioPlugin, pModule, length ) != MXP_OK )
	{
		ShowBadHeaderDialog();
		strcpy( g_panelInfoLine, "" );	/* infoline is no more actual */
		strcpy( g_currModuleFilePath, "-" );	/* this is even more critical */
		free( pModule );
		pModule = NULL;
		return FALSE;
	}

	strcpy( g_currModuleFilePath, tempString );
	return TRUE;
}

/*
 * Return pointer to the plugin able to replay
 * current mod or NULL
 */
struct SAudioPlugin* LookForAudioPlugin( char* path, char* name )
{
	int 				i, j;
	struct SExtension*	ext;
	char				extension[MXP_FILENAME_MAX+1];
	char				filePath[MXP_PATH_MAX+MXP_FILENAME_MAX+1];

	split_extension( name, NULL, extension );
	str_toupper( extension );

	CombinePath( filePath, path, name );

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
			else if( strcmp( ext[j].ext, "*" ) == 0 )
			{
				// ok, a wildcard, let's try to Register() it
				// TODO: now we pass only file path!
				if( AudioPluginRegisterModule( pSAudioPlugin[i], filePath, strlen( filePath ) ) == MXP_OK )
				{
					return pSAudioPlugin[i];
				}
			}
			else if( strcmp( ext[j].ext, extension ) == 0 )
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
#ifndef DISABLE_PLUGINS
		g_pCurrAudioPlugin->inBuffer.value = moduleSongNumber = 0;	// first song
		int ret = AudioPluginIsFlagSet( MXP_FLG_USER_CODE ) ? g_pCurrAudioPlugin->Set() : Supexec( g_pCurrAudioPlugin->Set );
		if( ret == MXP_OK && g_pCurrAudioPlugin->Songs != NULL )
		{
			moduleSongs = AudioPluginIsFlagSet( MXP_FLG_USER_CODE ) ? g_pCurrAudioPlugin->Songs() : Supexec( g_pCurrAudioPlugin->Songs );
		}
		else
		{
			moduleSongs = 1;
		}
		return ret;
#else
		return MXP_OK;
#endif
	}

	return MXP_UNIMPLEMENTED;
}

/*
 * Update play buffers, if necessary.
 */
void AudioPluginModuleFeed( void )
{
	if( g_pCurrAudioPlugin != NULL && g_pCurrAudioPlugin->Feed != NULL )
	{
#ifndef DISABLE_PLUGINS
		AudioPluginIsFlagSet( MXP_FLG_USER_CODE ) ? g_pCurrAudioPlugin->Feed() : Supexec( g_pCurrAudioPlugin->Feed );
#endif
	}
}

/*
 * Stop current module playback
 */
int AudioPluginModuleStop( void )
{
	if( g_pCurrAudioPlugin != NULL && g_pCurrAudioPlugin->Unset != NULL )
	{
#ifndef DISABLE_PLUGINS
		return AudioPluginIsFlagSet( MXP_FLG_USER_CODE ) ? g_pCurrAudioPlugin->Unset() : Supexec( g_pCurrAudioPlugin->Unset );
#else
		return MXP_OK;
#endif
	}

	return MXP_UNIMPLEMENTED;
}

/*
 * Pause current module playback
 */
int AudioPluginModulePause( BOOL pause )
{
	if( g_pCurrAudioPlugin != NULL && g_pCurrAudioPlugin->ModulePause != NULL )
	{
#ifndef DISABLE_PLUGINS
		g_pCurrAudioPlugin->inBuffer.value = pause;
		return AudioPluginIsFlagSet( MXP_FLG_USER_CODE ) ? g_pCurrAudioPlugin->ModulePause() : Supexec( g_pCurrAudioPlugin->ModulePause );
#else
		return MXP_OK;
#endif
	}

	return MXP_UNIMPLEMENTED;
}

/*
 * Mute current module playback
 */
int AudioPluginModuleMute( BOOL mute )
{
	if( g_pCurrAudioPlugin != NULL && g_pCurrAudioPlugin->ModulePause != NULL )
	{
#ifndef DISABLE_PLUGINS
		g_pCurrAudioPlugin->inBuffer.value = mute;
		return AudioPluginIsFlagSet( MXP_FLG_USER_CODE ) ? g_pCurrAudioPlugin->ModuleMute() : Supexec( g_pCurrAudioPlugin->ModuleMute );
#else
		return MXP_OK;
#endif
	}

	return MXP_UNIMPLEMENTED;
}

/*
 * Next subsong, if available.
 */
int AudioPluginModuleNextSubSong( void )
{
	if( g_pCurrAudioPlugin != NULL && g_pCurrAudioPlugin->Set != NULL )
	{
#ifndef DISABLE_PLUGINS
		if( moduleSongNumber + 1 < moduleSongs )
		{
			AudioPluginModuleStop();
			g_pCurrAudioPlugin->inBuffer.value = ++moduleSongNumber;
			return AudioPluginIsFlagSet( MXP_FLG_USER_CODE ) ? g_pCurrAudioPlugin->Set() : Supexec( g_pCurrAudioPlugin->Set );
		}
#else
		return MXP_OK;
#endif
	}

	return MXP_UNIMPLEMENTED;
}

/*
 * Previous subsong, if available.
 */
int AudioPluginModulePrevSubSong( void )
{
	if( g_pCurrAudioPlugin != NULL && g_pCurrAudioPlugin->Set != NULL )
	{
#ifndef DISABLE_PLUGINS
		if( moduleSongNumber - 1 >= 0 )
		{
			AudioPluginModuleStop();
			g_pCurrAudioPlugin->inBuffer.value = --moduleSongNumber;
			return AudioPluginIsFlagSet( MXP_FLG_USER_CODE ) ? g_pCurrAudioPlugin->Set() : Supexec( g_pCurrAudioPlugin->Set );
		}
#else
		return MXP_OK;
#endif
	}

	return MXP_UNIMPLEMENTED;
}

BOOL AudioPluginLockResources( void )
{
	if( g_pCurrAudioPlugin != NULL )
	{
		if( AudioPluginIsFlagSet( MXP_FLG_USE_DSP ) )
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
		if( AudioPluginIsFlagSet( MXP_FLG_USE_DMA ) )
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
		if( AudioPluginIsFlagSet( MXP_FLG_USE_020 ) )
		{
			if( g_cpu < 20 )
			{
				Show020RequiredDialog();
				return FALSE;
			}
		}
		if( AudioPluginIsFlagSet( MXP_FLG_USE_FPU ) )
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
	if( g_pCurrAudioPlugin != NULL )
	{
		if( AudioPluginIsFlagSet( MXP_FLG_USE_DSP ) && dspLocked )
		{
			dsp_load_program( NULL, 0 );	/* reset DSP */
			Dsp_Unlock();
			dspLocked = FALSE;
		}
		if( AudioPluginIsFlagSet( MXP_FLG_USE_DMA ) && dmaLocked )
		{
			Sndstatus( SND_RESET );
			dmaLocked = FALSE;
			if( Unlocksnd() == -128 )
			{
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
		return AudioPluginIsFlagSet( MXP_FLG_USER_CODE ) ? g_pCurrAudioPlugin->PlayTime() : Supexec( g_pCurrAudioPlugin->PlayTime );
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
#ifndef DISABLE_PLUGINS
	int ret;

	plugin->inBuffer.value = value;
	ret = AudioPluginIsFlagSet( MXP_FLG_USER_CODE ) ? param->Set() : Supexec( param->Set );
	AudioPluginGetInfoLine( plugin->pSParameter );	/* start from the first parameter */
	return ret;
#else
	return MXP_OK;
#endif
}

/*
 * Get given parameter's value
 */
int AudioPluginGet( struct SAudioPlugin* plugin, struct SParameter* param, long* value )
{
#ifndef DISABLE_PLUGINS
	int ret;

	ret = AudioPluginIsFlagSet( MXP_FLG_USER_CODE ) ? param->Get() : Supexec( param->Get );
	*value = plugin->inBuffer.value;
	return ret;
#else
	return MXP_ERROR;
#endif
}
