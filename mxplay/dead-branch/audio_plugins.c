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

struct SAudioPlugin*		g_pCurrAudioPlugin = NULL;
BOOL						g_modulePlaying = FALSE;
BOOL						g_modulePaused = FALSE;
char						g_currModuleName[FILENAME_MAX] = "";

static struct SAudioPlugin*	pSAudioPlugin[MAX_AUDIO_PLUGINS];
static int					audioPluginsCount;
static char*				pCurrModule;
static int					dspLocked = FALSE;
static int					dmaLocked = FALSE;
static char					infoLine[1023+1];	/* hope it's enough */
static BOOL					isLoaded = FALSE;
static char**				pInputArray;

static int AudioPluginInit( struct SAudioPlugin* plugin )
{
	return Supexec( &plugin->Init );
}

static int AudioPluginRegisterModule( struct SAudioPlugin* plugin, char* module, unsigned int length )
{
	pInputArray[0] = (char*)module;
	pInputArray[1] = (char*)length;
	
	plugin->inBuffer = (long)pInputArray;
	return Supexec( &plugin->RegisterModule );
}

static struct SAudioPlugin* AudioPluginLoad( char* filename )
{
	BASEPAGE*	bp;
	char*		cmdline[128];

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
		
		return (struct SAudioPlugin*)bp->p_tbase;	/* text segment address */
	}
}

/*
 * Load music file
 */
BOOL LoadAudioModule( char* path, char* name )
{
	char			tempString[PATH_MAX+FILENAME_MAX+1];
	int				handle;
	unsigned int	length;
	
	CombinePath( tempString, path, name );
	
	handle = open( tempString, O_RDONLY );
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

		if( pCurrModule != NULL )
		{
			Mfree( pCurrModule );
			pCurrModule = NULL;
			strcpy( g_currModuleName, "" );
			isLoaded = FALSE;
		}
		/* Global ST RAM */
		if( getcookie( "MiNT", NULL ) == TRUE )
		{
			pCurrModule = (char*)Mxalloc( length, MX_STRAM | 0x0008 | MX_GLOBAL );
		}
		else
		{
			pCurrModule = (char*)Mxalloc( length, MX_STRAM );
		}
		if( VerifyAlloc( pCurrModule ) == FALSE )
		{
			return FALSE;
		}

		if( read( (short)handle, pCurrModule, length ) < 0 )
		{
			ShowLoadErrorDialog( name );
			Mfree( pCurrModule );
			pCurrModule = NULL;
			close( handle );
			return FALSE;
		}
		else
		{
			close( handle );
			
			if( g_pCurrAudioPlugin != NULL )
			{
				AudioPluginRegisterModule( g_pCurrAudioPlugin, pCurrModule, length );
				strcpy( g_currModuleName, name );
			}
			return TRUE;
		}
	}
}

/*
 * Return pointer to the plugin able to replay
 * current mod or NULL
 */
struct SAudioPlugin* LookForAudioPlugin( char* extension )
{
	int 				i, j;
	struct SExtension*	ext;
	char				tempString[FILENAME_MAX+1];
	
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
			/* nope, continue with finding supported extension */
			else if( strcmp( ext[j].ext, tempString ) == 0 )
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
	char			tempString[PATH_MAX+1];
	char			ext[FILENAME_MAX+1];
	
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
	if( g_pCurrAudioPlugin != NULL )
	{
		isLoaded = TRUE;
		g_modulePlaying = TRUE;
		return Supexec( &g_pCurrAudioPlugin->Set );
		//return MXP_OK;
	}
	
	return MXP_OK;
}

/*
 * Stop current module playback
 */
int AudioPluginModuleStop( void )
{
	int ret;
	
	if( g_pCurrAudioPlugin != NULL )
	{
		g_modulePaused = FALSE;
		g_modulePlaying = FALSE;
		ret = Supexec( &g_pCurrAudioPlugin->Unset );
		dsp_load_program( NULL, 0 );	/* reset DSP */
		return ret;
		//return MXP_OK;
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
		return Supexec( &g_pCurrAudioPlugin->ModulePause );
		//return MXP_OK;
	}
	
	return MXP_OK;
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
				ShowDmaRequiredDialog();
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
 * Fill scrollable infoline in
 * the main panel
 */
char* AudioPluginGetInfoLine( void )
{
	struct SParameter*	param;
	int					i;
	char	tempString[255+1];
	
	if( g_pCurrAudioPlugin != NULL && isLoaded == TRUE )
	{
		strcpy( infoLine, "" );
		
		param = g_pCurrAudioPlugin->pSParameter;
		
		for( i = 0; param[i].pName != NULL; i++ )
		{
			if( ( param[i].type & MXP_FLG_INFOLINE ) != 0 )
			{
				strcat( infoLine, param[i].pName );	/* i.e. "Songname" */
				Supexec( param[i].Get );
				strcat( infoLine, ": " );
				if( strcmp( (char*)g_pCurrAudioPlugin->inBuffer, "" ) == 0 )
				{
					/* use filename as value */
					strcat( infoLine, g_currModuleName );	/* i.e. "TeXmas II.mp3" */
				}
				else
				{
					strcpy( tempString, (char*)g_pCurrAudioPlugin->inBuffer );
					UnpadString( tempString );	/* "TeXmas II     " -> "TeXmas II" */
					strcat( infoLine, tempString );
				}
				strcat( infoLine, "  " );	/* delimiter */
			}
		}
		return infoLine;
	}
	else
	{
		return NULL;
	}
}

/*
 * Determine which functions are available in the plugin.
 */
void AudioPluginCheckFunctions( struct SAudioPlugin* plugin )
{
	if( plugin->ModuleFwd == NULL )
	{
		DisableObject( g_winDialogs[WD_PANEL], PANEL_FWD );
	}
	else
	{
		EnableObject( g_winDialogs[WD_PANEL], PANEL_FWD );
	}
	
	if( plugin->ModuleRwd == NULL )
	{
		DisableObject( g_winDialogs[WD_PANEL], PANEL_RWD );
	}
	else
	{
		EnableObject( g_winDialogs[WD_PANEL], PANEL_RWD );
	}
	
	if( plugin->ModulePause == NULL )
	{
		DisableObject( g_winDialogs[WD_PANEL], PANEL_PAUSE );
	}
	else
	{
		EnableObject( g_winDialogs[WD_PANEL], PANEL_PAUSE );
	}

}

/*
 * Check if the current plugin
 * knows the current module format
 */
BOOL AudioPluginCheckHeader( void )
{
	if( g_pCurrAudioPlugin != NULL && Supexec( &g_pCurrAudioPlugin->CheckModule ) == MXP_OK )
	{
		return TRUE;
	}
	else
	{
		return FALSE;
	}
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
		return Supexec( &g_pCurrAudioPlugin->PlayTime );
		//return 300;
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
	plugin->inBuffer = value;
	return Supexec( param->Set );
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
