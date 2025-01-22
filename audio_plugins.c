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
#include "system.h"
#include "debug.h"

char						g_sAudioPluginPath[32] = "plugins\\audio";
struct SAudioPlugin*		g_pCurrAudioPlugin = NULL;
char						g_currModuleFilePath[MXP_PATH_MAX+1] = "-";
long						g_defaultPlayTime = 3 * 60;	// 3 minutes by default

static struct SAudioPlugin*	pSAudioPlugin[MAX_AUDIO_PLUGINS];
static int					audioPluginsCount;
static int					dspLocked = FALSE;
static int					dmaLocked = FALSE;
static struct SModuleParameter moduleParameter;

static int					moduleSongNumber;
static int					moduleSongs;
static char*				moduleExtName;

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
		Mshrink( bp->p_lowtpa,		/* basepage address */
		0x100 +						/* length of basepage */
		bp->p_tlen +				/* length of text segment */
		bp->p_dlen +				/* length of data segment */
		bp->p_blen +				/* length of BSS segment */
		128*1024 );					/* length of stack */

		// PE_LOAD doesn't guarantee flushing the data cache and invalidation of the instruction cache
		extern void asm_invalidate_cache( void );
		Supexec( asm_invalidate_cache );

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

static void SortPlugins( void )
{
	int newn;
	for( int n = audioPluginsCount; n != 0; n = newn )
	{
		newn = 0;
		for( int i = 1; i < n; ++i )
		{
			if( strcmp( pSAudioPlugin[i-1]->pSExtension[0].ext, pSAudioPlugin[i]->pSExtension[0].ext ) > 0 )
			{
				struct SAudioPlugin* tmp = pSAudioPlugin[i-1];
				pSAudioPlugin[i-1] = pSAudioPlugin[i];
				pSAudioPlugin[i] = tmp;
				newn = i;
			}
		}
	}
}

//////////////////////////////////////////////////////////////////////////////

inline static BOOL AudioPluginIsFlagSet( int flag )
{
	if( g_pCurrAudioPlugin != NULL && g_pCurrAudioPlugin->pSInfo != NULL )
	{
		return ( g_pCurrAudioPlugin->pSInfo->flags & flag ) != 0 ? TRUE : FALSE;
	}
	return FALSE;
}

inline static int AudioPluginCallFunction( int (*f)( void ) )
{
	extern long asm_safe_pointer;
	extern int asm_safe_call( void );

	int ret = MXP_UNIMPLEMENTED;
#ifndef DISABLE_PLUGINS
	if( f != NULL )
	{
		asm_safe_pointer = (long)f;
		ret = AudioPluginIsFlagSet( MXP_FLG_USER_CODE ) ? asm_safe_call() : Supexec( asm_safe_call );
	}
#else
	ret = MXP_OK;
#endif

	return ret;
}

//
// In the following functions we expect that 'plugin' is never NULL!
//

static int AudioPluginRegisterModule( struct SAudioPlugin* plugin, char* module, size_t length )
{
	moduleParameter.p = module;
	moduleParameter.size = length;

	plugin->inBuffer.pModule = &moduleParameter;
	return AudioPluginCallFunction( plugin->RegisterModule );
}

static int AudioPluginUnregisterModule( struct SAudioPlugin* plugin )
{
	return AudioPluginCallFunction( plugin->UnregisterModule );
}

static int AudioPluginInit( struct SAudioPlugin* plugin )
{
	g_pCurrAudioPlugin = plugin;	// LookForAudioPlugin hasn't been called yet
	return AudioPluginCallFunction( plugin->Init );
}

long AudioPluginGetPlayTime( struct SAudioPlugin* plugin )
{
	plugin->inBuffer.value = g_defaultPlayTime * 1000;
	AudioPluginCallFunction( plugin->PlayTime );
	return plugin->inBuffer.value;
}

int AudioPluginModulePlay( struct SAudioPlugin* plugin )
{
	int ret;
	short attl = (short)Soundcmd( LTATTEN, SND_INQUIRE );
	short attr = (short)Soundcmd( RTATTEN, SND_INQUIRE );

	plugin->inBuffer.value = moduleSongNumber = 0;	// first song
	if( ( ret = AudioPluginCallFunction( plugin->Set ) ) == MXP_OK
		&& AudioPluginCallFunction( plugin->Songs ) == MXP_OK )
	{
		moduleSongs = plugin->inBuffer.value;
	}
	else
	{
		moduleSongs = 1;
	}

	Soundcmd( LTATTEN, attl );
	Soundcmd( RTATTEN, attr );

	return ret;
}

int AudioPluginModuleFeed( struct SAudioPlugin* plugin )
{
	return AudioPluginCallFunction( plugin->Feed );
}

int AudioPluginModuleStop( struct SAudioPlugin* plugin )
{
	return AudioPluginCallFunction( plugin->Unset );
}

int AudioPluginModulePause( struct SAudioPlugin* plugin, BOOL pause )
{
	plugin->inBuffer.value = pause;
	return AudioPluginCallFunction( plugin->Pause );
}

int AudioPluginModuleMute( struct SAudioPlugin* plugin, BOOL mute )
{
	plugin->inBuffer.value = mute;
	return AudioPluginCallFunction( plugin->Mute );
}

int AudioPluginModuleNextSubSong( struct SAudioPlugin* plugin )
{
	if( moduleSongNumber + 1 < moduleSongs )
	{
		AudioPluginModuleStop( plugin );
		plugin->inBuffer.value = ++moduleSongNumber;
		return AudioPluginCallFunction( plugin->Set );
	}

	return MXP_OK;
}

int AudioPluginModulePrevSubSong( struct SAudioPlugin* plugin )
{
	if( moduleSongNumber - 1 >= 0 )
	{
		AudioPluginModuleStop( plugin );
		plugin->inBuffer.value = --moduleSongNumber;
		return AudioPluginCallFunction( plugin->Set );
	}

	return MXP_OK;
}

int AudioPluginSet( struct SAudioPlugin* plugin, struct SParameter* param, long value )
{
	int ret = MXP_UNIMPLEMENTED;

	plugin->inBuffer.value = value;
	// always user mode (changes are supposed to take effect on the next playback) TODO (why info line then?)
	if( param->Set != NULL && ( ret = param->Set() ) == MXP_OK )
	{
		AudioPluginGetInfoLine( plugin );	/* start from the first parameter */
	}

	return ret;
}

int AudioPluginGet( struct SAudioPlugin* plugin, struct SParameter* param, long* value )
{
	int ret = MXP_UNIMPLEMENTED;

	if( param->Get != NULL && ( ret = param->Get() ) == MXP_OK )
	{
		*value = plugin->inBuffer.value;
	}

	return ret;
}

//////////////////////////////////////////////////////////////////////////////

/*
 * Fill scrollable infoline in the main panel.
 */
void AudioPluginGetInfoLine( struct SAudioPlugin* plugin )
{
	char	infoLine[1023+1];
	int		i;
	char	tempString[255+1];
	struct SParameter* param = plugin->pSParameter;

	// this function is called after AudioPluginModulePlay()
	strcpy( infoLine, "" );

	if( moduleSongs > 1 )
	{
		sprintf( tempString, "# %d / %d  ", moduleSongNumber + 1, moduleSongs );
		strcat( infoLine, tempString );
	}

	if( param == NULL )
	{
		// no params, fill in at least a fake title
		split_filename( g_currModuleFilePath, NULL, tempString );
		strcat( infoLine, "Name: " );
		strcat( infoLine, tempString );
		strcat( infoLine, "  " );
	}
	else
	{
		for( i = 0; param[i].pName != NULL; i++ )
		{
			if( ( param[i].type & MXP_FLG_INFOLINE ) != 0 )
			{
				strcat( infoLine, param[i].pName );	/* i.e. "Songname" */
				strcat( infoLine, ": " );

				ConvertMxpParamTypes( plugin, &param[i], tempString );
				strcat( infoLine, tempString );

				strcat( infoLine, "  " );	/* delimiter */
			}
		}
	}

	if( moduleExtName != NULL )
	{
		strcat( infoLine, "Type: " );
		strcat( infoLine, moduleExtName );
		strcat( infoLine, "  " );
	}

	strcpy( g_panelInfoLine, infoLine );	/* update the real one */
}

/*
 * Load music file
 */
BOOL LoadAudioModule( char* path, char* name )
{
	char			tempString[MXP_PATH_MAX+1];
	unsigned long	length;
	static char*	pModule;
	static struct SAudioPlugin* pLastUsedPlugin;

	/* no more available */
	if( pModule != NULL )
	{
		if( pLastUsedPlugin != NULL )
		{
			AudioPluginUnregisterModule( pLastUsedPlugin );
		}

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

	// no error => it's used
	pLastUsedPlugin = g_pCurrAudioPlugin;

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
	char				filePath[MXP_PATH_MAX+1];

	split_extension( name, NULL, extension );
	str_toupper( extension );

	CombinePath( filePath, path, name );

	for( i = audioPluginsCount - 1; i >= 0 ; --i )
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
				// the fact that with '*' we accept only a file path is OK else
				// loading time of the modules while starting would be super slow!
				if( AudioPluginRegisterModule( pSAudioPlugin[i], filePath, strlen( filePath ) ) == MXP_OK )
				{
					// ok, registration successful but now we have to unregister it as we might be in the
					// middle of playlist populating or so. actually, we hope Unregister is NULL in this case.
					AudioPluginUnregisterModule( pSAudioPlugin[i] );

					moduleExtName = ext[j].name;
					return pSAudioPlugin[i];
				}
			}
			else if( strcmp( ext[j].ext, extension ) == 0 )
			{
				moduleExtName = ext[j].name;
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
	int				leftOut = 0;

	pDirStream = opendir( g_sAudioPluginPath );
	if( pDirStream != NULL )
	{
		while( ( pDirEntry = readdir( pDirStream ) ) != NULL )
		{
			if( IsDirectory( g_sAudioPluginPath, pDirEntry->d_name ) == FALSE )
			{
				split_extension( pDirEntry->d_name, NULL, ext );
				if( strcmp( ext, "mxp" ) == 0 || strcmp( ext, "MXP" ) == 0 )
				{
					strcpy( tempString, gl_appdir );
					CombinePath( tempString, tempString, g_sAudioPluginPath );	/* path\plugins\audio */
					CombinePath( tempString, tempString, pDirEntry->d_name );	/* path\plugins\audio\plugin.mxp */

					pSAudioPlugin[audioPluginsCount] = AudioPluginLoad( tempString );
					if( pSAudioPlugin[audioPluginsCount] != NULL )
					{
						g_pCurrAudioPlugin = pSAudioPlugin[audioPluginsCount];
						if( !AudioPluginIsFlagSet( MXP_FLG_XBIOS ) && g_tosClone )
						{
							debug( "Leaving out %s (reason: TOS clone)", pDirEntry->d_name );
							Mfree( pSAudioPlugin[audioPluginsCount] );
							leftOut++;
							continue;
						}
#ifndef	__mcoldfire__
						else if( AudioPluginIsFlagSet( MXP_FLG_ONLY_030 ) && g_cpu > 30 )
						{
							debug( "Leaving out %s (reason: 040+ CPU)", pDirEntry->d_name );
							Mfree( pSAudioPlugin[audioPluginsCount] );
							leftOut++;
							continue;
						}
#endif

						if( AudioPluginInit( pSAudioPlugin[audioPluginsCount] ) == MXP_ERROR )
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

		SortPlugins();

		closedir( pDirStream );

		if( audioPluginsCount == 0 )
		{
			ShowNoAudioFoundDialog();
		}
		if( leftOut > 0 )
		{
			ShowTosCloneDialog( leftOut );
		}
	}
	else
	{
		ShowNoAudioFoundDialog();
	}

	g_pCurrAudioPlugin = NULL;	// none
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
		if( AudioPluginIsFlagSet( MXP_FLG_FAST_CPU ) && !g_fastCpu )
		{
			ShowFastCpuRequiredDialog();
		}

		if( dmaLocked )
		{
			extern void asm_save_audio( void );
			Supexec( asm_save_audio );
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
			short attl = (short)Soundcmd( LTATTEN, SND_INQUIRE );
			short attr = (short)Soundcmd( RTATTEN, SND_INQUIRE );

			Sndstatus( SND_RESET );

			extern void asm_restore_audio( void );
			Supexec( asm_restore_audio );

			Soundcmd( LTATTEN, attl );
			Soundcmd( RTATTEN, attr );

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
