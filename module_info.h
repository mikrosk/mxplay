/*
 * module_info.h -- code for Module Info dialog (definitions and external declarations)
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

#ifndef _MODULE_INFO_H_
#define _MODULE_INFO_H_

extern void	ModuleInfoInit( void );
extern void	ModuleInfoReinit( void );
extern void	ModuleInfoUpdate( void );
extern void	ModuleInfoButton( short obj );
extern void ModuleInfoResize( GRECT* pR );
extern void ModuleInfoScroll( short direction );
extern void ModuleInfoSlider( short deltaY );

#endif
