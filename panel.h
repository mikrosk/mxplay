/*
 * panel.h -- button handling for Panel dialog (definitions and external declarations)
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
extern BOOL			g_modulePlaying;
extern BOOL			g_modulePaused;

extern void	PanelPlayTime( void );
extern void	PanelPlay( void );
extern void	PanelStop( void );
extern void	PanelPause( void );
extern void	PanelNextSubSong( void );
extern void	PanelPrevSubSong( void );
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
extern void PanelVolumeSlider( short mx );
extern void	PanelVolumeSliderUpdate( void );
extern void LoadAndPlay( void );

#endif
