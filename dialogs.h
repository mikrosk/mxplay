/*
 * dialogs.h -- AES dialogs - init, deinit, errors, ... (definitions and external declarations)
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

#ifndef _DIALOGS_H_
#define _DIALOGS_H_

#include <cflib.h>
#include "mxplay.h"
#include "skins/skin.h"

#ifndef ROOT
#define ROOT				0
#endif
#ifndef MAX_DEPTH
#define MAX_DEPTH			1
#endif

extern void	InitDialogs( void );
extern void	ShowDefaultDialogs( void );
extern void	DeleteDialogs( void );
extern void	ShowSplashImage( void );
extern void	CloseSplashImage( void );
extern void	InitRsc( void );

extern int	ShowAudioInitErrorDialog( char* filename );
extern int	ShowRsrcAddrFailedDialog( void );
extern int	ShowRsrcLoadFailedDialog( void );
extern int	ShowNoAudioFoundDialog( void );
extern int	ShowNoReplayFoundDialog( void );
extern int	ShowLoadErrorDialog( char* filename );
extern int	ShowPluginErrorDialog( int error );
extern int	ShowNotEnoughMemoryDialog( void );
extern int	ShowDspLockedDialog( void );
extern int	ShowDmaLockedDialog( void );
extern int	ShowDmaNotLockedDialog( void );
extern int	ShowCommErrorDialog( void );
extern int	ShowBadHeaderDialog( void );
extern int	Show020RequiredDialog( void );
extern int	ShowFpuRequiredDialog( void );
extern int	ShowDspRequiredDialog( void );
extern int	ShowDmaRequiredDialog( void );
extern int	ShowOverwriteFileDialog( void );
extern int	ShowPlayListNotActualDialog( void );
extern int	ShowBadPluginDialog( char* filename );
extern int	ShowMeasureInitFailedDialog( void );
extern int	ShowMeasureDeinitFailedDialog( void );

extern void	PanelDialogRefresh( void );

/*
 * if you want to add new windialog, add index here,
 * fill g_winDialogList and add proper callback functions
 */
#define	WD_ABOUT			0
#define WD_PANEL			1
#define	WD_PLAYLIST			2
#define WD_PLUGIN			3
#define WD_MODULE			4
#define WD_LIST_SIZE		(WD_MODULE - WD_ABOUT + 1)

extern WDIALOG*		g_winDialogs[WD_LIST_SIZE];
extern BOOL			g_withShift;
extern int			g_mouseClicks;
extern unsigned int	g_playTime;
extern char			g_panelInfoLine[1023+1];

#endif
