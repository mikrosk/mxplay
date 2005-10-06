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
