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
	void*	Set;
	void*	Get;
};

struct SExtension
{
	char*	ext;
	char*	name;
};

struct SAudioPlugin
{
	char				header[4];
	long				inBuffer;
	void*				RegisterModule;
	void*				PlayTime;
	void*				Init;
	void*				Set;
	void*				Unset;
	void*				Deinit;
	void*				ModuleFwd;
	void*				ModuleRwd;
	void*				ModulePause;
	struct SInfo*		pSInfo;
	struct SExtension*	pSExtension;
	struct SParameter*	pSParameter;
};

extern struct SAudioPlugin*	g_pCurrAudioPlugin;
extern BOOL					g_modulePlaying;
extern BOOL					g_modulePaused;
extern char					g_currModuleName[PATH_MAX+1];

extern void					LoadAudioPlugins( void );
extern struct SAudioPlugin*	LookForAudioPlugin( char* extension );
extern BOOL					LoadAudioModule( char* path, char* filename );
extern int					AudioPluginModulePlay( void );
extern int					AudioPluginModuleStop( void );
extern int					AudioPluginModulePause( void );
extern BOOL					AudioPluginLockResources( void );
extern BOOL					AudioPluginFreeResources( void );
extern void					AudioPluginGetBaseInfo( struct SAudioPlugin* plugin, char** pluginAuthor, char** pluginVersion, char** replayName, char** replayAuthor, char** replayVersion, long* flags );
extern unsigned long		AudioPluginGetPlayTime( void );
extern int					AudioPluginSet( struct SAudioPlugin* plugin, struct SParameter* param, long value );
extern int					AudioPluginGet( struct SAudioPlugin* plugin, struct SParameter* param, long* value );
extern struct SParameter*	AudioPluginGetParam( struct SAudioPlugin* plugin, char* name );
extern void					AudioPluginGetInfoLine( struct SParameter* param );

#endif
