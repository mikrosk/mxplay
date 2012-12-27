/*
 * file_select.h -- file selector callbacks (definitions and external declarations)
 *
 * Copyright (c) 2005 Miro Kropacek; miro.kropacek@gmail.com
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

#ifndef _FILE_SELECT_H_
#define _FILE_SELECT_H_

#include "mxplay.h"

BOOL CB_ModuleFileSelect( char* path, char* name );
BOOL CB_ModuleDirSelect( char* path, char* name );
BOOL CB_RscFileSelect( char* path, char* name );
BOOL CB_PlayListFileSelect( char* path, char* name );

#endif
