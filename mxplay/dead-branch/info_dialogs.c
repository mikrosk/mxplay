#include <stdlib.h>
#include <cflib.h>

#include "misc.h"


/*
 * Count all objects in dialog
 */
short GetObjectCount( OBJECT tree[] )
{
	short count;
	
	for( count = 0; get_flag( tree, count, OF_LASTOB ) == FALSE; count++ );
	count++;	/* the last one (with OF_LASTOB == TRUE */
	
	return count;
}

short CloneDialog( OBJECT oldTree[], OBJECT** ppNewTree, short objs )
{
	short count;
	short i;
	
	count = GetObjectCount( oldTree );
	
	*ppNewTree = (OBJECT*)malloc( ( count + objs ) * sizeof( OBJECT ) );	/* + new objs */
	if( VerifyAlloc( *ppNewTree ) == FALSE )
	{
		return -1;
	}
	else
	{
		/* copy old objects */
		for( i = 0; i < count; i++ )
		{
			memcpy( &(*ppNewTree)[i], &oldTree[i], sizeof( OBJECT ) );
		}
		
		/* init new objects */
		for( i = count; i < count + objs; i++ )
		{
			memset( &(*ppNewTree)[i], 0, sizeof( OBJECT ) );
		}
		
		/* this is a number for the first new object */
		return count;
	}
}
