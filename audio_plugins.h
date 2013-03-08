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
#include "plugins/audio/plugin.h"

#define MAX_AUDIO_PLUGINS		256

extern char					g_sAudioPluginPath[];
extern struct SAudioPlugin*	g_pCurrAudioPlugin;
extern char					g_currModuleFilePath[MXP_PATH_MAX+1];
extern long					g_defaultPlayTime;

extern void					LoadAudioPlugins( void );
extern struct SAudioPlugin*	LookForAudioPlugin( char* path, char* name );
extern BOOL					LoadAudioModule( char* path, char* filename );

extern long					AudioPluginGetPlayTime( struct SAudioPlugin* plugin );
extern int					AudioPluginModulePlay( struct SAudioPlugin* plugin );
extern int					AudioPluginModuleFeed( struct SAudioPlugin* plugin );
extern int					AudioPluginModuleStop( struct SAudioPlugin* plugin );
extern int					AudioPluginModulePause( struct SAudioPlugin* plugin, BOOL pause );
extern int					AudioPluginModuleMute( struct SAudioPlugin* plugin, BOOL mute );
extern int					AudioPluginModuleNextSubSong( struct SAudioPlugin* plugin );
extern int					AudioPluginModulePrevSubSong( struct SAudioPlugin* plugin );
extern int					AudioPluginSet( struct SAudioPlugin* plugin, struct SParameter* param, long value );
extern int					AudioPluginGet( struct SAudioPlugin* plugin, struct SParameter* param, long* value );

extern BOOL					AudioPluginLockResources( void );
extern BOOL					AudioPluginFreeResources( void );
extern void					AudioPluginGetBaseInfo( struct SAudioPlugin* plugin, char** pluginAuthor, char** pluginVersion, char** replayName, char** replayAuthor, char** replayVersion, long* flags );
extern struct SParameter*	AudioPluginGetParam( struct SAudioPlugin* plugin, char* name );
extern void					AudioPluginGetInfoLine( struct SAudioPlugin* plugin );

#endif
