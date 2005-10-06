#ifndef _PANEL_FUNCTIONS_H_
#define _PANEL_FUNCTIONS_H_

#define TIME_MODE_ADD	0
#define TIME_MODE_SUB	1

#define	VOLUME_STAGES	16
#define	VOLUME_MAX		15
#define	VOLUME_MIN		0

struct SWinDialog
{
	short dialog;
	short mode;
	short x;
	short y;
	short selectedObj[32];
};

extern int			g_timeMode;
extern BOOL			g_repeat;
extern BOOL			g_random;
extern BOOL			g_mute;

extern void	PanelPlayTime( void );
extern void	PanelPlay( void );
extern void	PanelStop( void );
extern void	PanelPause( void );
extern void	PanelFwd( void );
extern void	PanelRwd( void );
extern void	PanelFileOpen( void );
extern void	PanelDirOpen( void );
extern void	PanelPrev( void );
extern void	PanelNext( void );
extern void	PanelInfoPlugin( void );
extern void	PanelInfoModule( void );
extern void	PanelInfoApp( void );
extern void	PanelPlayList( void );
extern void	PanelMute( void );
extern void	PanelRandom( void );
extern void	PanelRepeat( void );
extern void PanelChangeSkin( void );
extern void	PanelVolumeDown( void );
extern void	PanelVolumeUp( void );
extern void	PanelVolumeInit( void );
extern void PanelVolumeSlider( short deltaX );
extern void	PanelVolumeSliderBox( short mx );
extern void	PanelVolumeSliderUpdate( void );
extern void LoadAndPlay( void );

#endif