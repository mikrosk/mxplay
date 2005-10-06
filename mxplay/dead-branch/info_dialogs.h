#ifndef _INFO_DIALOGS_H_
#define _INFO_DIALOGS_H_

#include <cflib.h>

#include "mxplay.h"

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

extern short	GetObjectCount( OBJECT tree[] );
extern short	CloneDialog( OBJECT oldTree[], OBJECT** ppNewTree, short objs );

#endif
