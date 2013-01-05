/*
 * audio_plugins.h -- the low-level communication with audio plugin (definitions and external declarations)
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

#ifndef _AUDIO_PLUGINS_H_
#define _AUDIO_PLUGINS_H_

#include "mxplay.h"

#define MAX_AUDIO_PLUGINS		256
#define AUDIO_PLUGINS_PATH		"plugins\\audio"

#define MXP_ERROR				0
#define MXP_OK					1
#define MXP_UNIMPLEMENTED		2

#define MXP_FLG_INFOLINE		(1<<29)			/* show on infoline, too */
#define MXP_FLG_MOD_PARAM		(1<<30)			/* module parameter */
#define MXP_FLG_PLG_PARAM		(1<<31)			/* plugin parameter */

#define MXP_FLG_USE_DSP			(1<<0)			/* plugin uses DSP */
#define MXP_FLG_USE_DMA			(1<<1)			/* plugin uses DMA sound system */
#define MXP_FLG_USE_020			(1<<2)			/* plugin uses 020+ CPU */
#define MXP_FLG_USE_FPU			(1<<3)			/* plugin uses FPU */
#define MXP_FLG_DONT_LOAD_MODULE	(1<<4)			/* plugins loads modules by itself */
#define MXP_FLG_USER_CODE 		(1<<5)			/* plugin handles supervisor calls by itself */

#define MXP_PAR_TYPE_BOOL		0				/* bool value (on/off) */
#define MXP_PAR_TYPE_CHAR		1				/* character field as string */
#define MXP_PAR_TYPE_INT		2				/* integer as string */

struct SInfo
{
	char*	pPluginAuthor;
	char*	pPluginVersion;
	char*	pReplayName;
	char*	pReplayAuthor;
	char*	pReplayVersion;
	long	flags;
};

struct SParameter
{
	char*	pName;
	long	type;
	int (*Set)( void );
	int (*Get)( void );
};

struct SExtension
{
	char*	ext;
	char*	name;
};

struct SModuleParameter
{
	char*	p;	// path or buffer
	size_t	size;
};
union UParameterBuffer
{
	struct SModuleParameter* pModule;
	long	value;
};

struct SAudioPlugin
{
	char				header[4];
	union UParameterBuffer inBuffer;
	int (*RegisterModule)( void );
	int (*PlayTime)( void );
	int (*Init)( void );
	int (*Set)( void );
	int (*Feed)( void );
	int (*Unset)( void );
	int (*Deinit)( void );
	int (*ModuleFwd)( void );
	int (*ModuleRwd)( void );
	int (*ModulePause)( void );
	struct SInfo*		pSInfo;
	struct SExtension*	pSExtension;
	struct SParameter*	pSParameter;
};

extern struct SAudioPlugin*	g_pCurrAudioPlugin;
extern BOOL					g_modulePlaying;
extern BOOL					g_modulePaused;
extern char					g_currModuleFilePath[MXP_PATH_MAX+MXP_FILENAME_MAX+1];

extern void					LoadAudioPlugins( void );
extern struct SAudioPlugin*	LookForAudioPlugin( char* path, char* name );
extern BOOL					LoadAudioModule( char* path, char* filename );
extern int					AudioPluginModulePlay( void );
extern void					AudioPluginModuleFeed( void );
extern int					AudioPluginModuleStop( void );
extern int					AudioPluginModulePause( void );
extern int					AudioPluginModuleFwd( BOOL bigStep );
extern int					AudioPluginModuleRwd( BOOL bigStep );
extern BOOL					AudioPluginLockResources( void );
extern BOOL					AudioPluginFreeResources( void );
extern void					AudioPluginGetBaseInfo( struct SAudioPlugin* plugin, char** pluginAuthor, char** pluginVersion, char** replayName, char** replayAuthor, char** replayVersion, long* flags );
extern unsigned long		AudioPluginGetPlayTime( void );
extern int					AudioPluginSet( struct SAudioPlugin* plugin, struct SParameter* param, long value );
extern int					AudioPluginGet( struct SAudioPlugin* plugin, struct SParameter* param, long* value );
extern struct SParameter*	AudioPluginGetParam( struct SAudioPlugin* plugin, char* name );
extern void					AudioPluginGetInfoLine( struct SParameter* param );

#endif
