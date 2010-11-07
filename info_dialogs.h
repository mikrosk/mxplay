/*
 * info_dialogs.h -- shared code between module and plugin info (definitions and external declarations)
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

#ifndef _INFO_DIALOGS_H_
#define _INFO_DIALOGS_H_

#include <cflib.h>

#include "mxplay.h"
#include "audio_plugins.h"

struct SInfoParam
{
	short	stringObj;
	short	valueType;	// TODO: kill
	short	valueObj;
	short	leftObj;
	short	rightObj;
	BOOL	scrollable;
	short	scrolled;
};

extern short	CloneDialog( OBJECT oldTree[], OBJECT** ppNewTree, short objs );
extern void		ConvertMxpParamTypes( struct SAudioPlugin* plugin, struct SParameter* param, char* text );

#endif
