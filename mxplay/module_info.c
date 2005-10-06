#include <cflib.h>
#include <sys/param.h>	/* MIN */

#include "skins/skin.h"
#include "audio_plugins.h"
#include "dialogs.h"
#include "misc.h"
#include "info_dialogs.h"

static struct SInfoParam*	moduleInfoParam = NULL;
static int		moduleInfoParamCount = 0;	/* in the window !!! */
static int		moduleInfoParamCurrent = 0;

static int		moduleParamCount = 0;	/* module parameter count in the current plugin */

static OBJECT*	tempModuleTree = NULL;
static OBJECT*	origModuleTree;

static int		slotHzDelta1;	/* horizontal distance between description and left arrow */
static int		slotHzDelta2;	/* horizontal distance between left arrow and value */
static int		slotHzDelta3;	/* horizontal distance between value and right arrow */
static int		currSlots;	/* number of up/common/down slots */

static short	origWidth;
static short	origHeight;
static char*	pOrigModuleText;

/*
 * Get corresponding parameter for given gem object.
 */
static struct SInfoParam* ModuleInfoGetInfoParam( short obj )
{
	int i;

	for( i = 0; i < moduleInfoParamCount; i++ )
	{
		if( moduleInfoParam[i].valueObj == obj || moduleInfoParam[i].leftObj == obj || moduleInfoParam[i].rightObj == obj )
		{
			return &moduleInfoParam[i];
		}
	}

	return NULL;
}

/*
 * Get corresponding moduleInfoParam index for given gem object (left/right arrow).
 */
static int ModuleInfoGetInfoParamIndex( short obj )
{
	int i;

	for( i = 0; i < moduleInfoParamCount; i++ )
	{
		if( moduleInfoParam[i].leftObj == obj || moduleInfoParam[i].rightObj == obj )
		{
			return i;
		}
	}

	return -1;
}

/*
 * Get MXP type (BOOL, INT, CHAR) and param pointer from audio plugin for given gem object.
 * Returns TRUE if ok or FALSE if not found.
 */
static BOOL ModuleInfoGetModuleParam( struct SAudioPlugin* plugin, OBJECT* tree, short obj, short* type, struct SParameter** param )
{
	struct SParameter*	pModuleAudioParam;
	struct SInfoParam*	pModuleInfoParam;
	char text[256];

	pModuleInfoParam = ModuleInfoGetInfoParam( obj );
	if( pModuleInfoParam != NULL )
	{
		get_string( tree, pModuleInfoParam->stringObj, text );
		if( text[strlen( text ) - 1] == ':'  )
		{
			/* if there was a space for colon, remove it */
			text[strlen( text ) - 1] = '\0';
		}

		pModuleAudioParam = AudioPluginGetParam( plugin, text );
		if( pModuleAudioParam != NULL )
		{
			if( type != NULL )
			{
				*type = pModuleAudioParam->type & 0x7fff;
			}
			if( param != NULL )
			{
				*param = pModuleAudioParam;
			}
			return TRUE;
		}
	}

	return FALSE;
}

/*
 * Scroll given info object to the left
 */
static void ModuleInfoLeft( struct SInfoParam* param )
{
	struct SParameter* audioParam;
	char	text[255+1];
	OBJECT*	tree;
	
	tree = g_winDialogs[WD_MODULE]->tree;
	
	if( ModuleInfoGetModuleParam( g_pCurrAudioPlugin, tree, param->valueObj, NULL, &audioParam ) == TRUE )
	{
		if( param->scrollable == TRUE && param->scrolled > 0 )
		{
			ConvertMxpParamTypes( g_pCurrAudioPlugin, audioParam, text );

			set_string( tree, param->valueObj, &text[--param->scrolled] );
			redraw_wdobj( g_winDialogs[WD_MODULE], param->valueObj );
		}
		
		if( param->scrolled > 0 )
		{
			EnableObject( g_winDialogs[WD_MODULE], param->leftObj );
		}
		else
		{
			DisableObject( g_winDialogs[WD_MODULE], param->leftObj );
		}
		/* right arrow could be disabled (end of text) */
		EnableObject( g_winDialogs[WD_MODULE], param->rightObj );
	}
}

/*
 * Scroll given info object to the right
 */
static void ModuleInfoRight( struct SInfoParam* param )
{
	struct SParameter* audioParam;
	char	text[255+1];
	OBJECT*	tree;
	int		delta;
	
	tree = g_winDialogs[WD_MODULE]->tree;
	
	if( ModuleInfoGetModuleParam( g_pCurrAudioPlugin, tree, param->valueObj, NULL, &audioParam ) == TRUE )
	{
		if( param->scrollable == TRUE )
		{
			ConvertMxpParamTypes( g_pCurrAudioPlugin, audioParam, text );
	
			delta = strlen( text ) + 1 - tree[param->valueObj].ob_spec.tedinfo->te_txtlen;

			if( param->scrolled < delta )
			{
				set_string( tree, param->valueObj, &text[++param->scrolled] );
				redraw_wdobj( g_winDialogs[WD_MODULE], param->valueObj );
			}
			
			if( param->scrolled < delta )
			{
				EnableObject( g_winDialogs[WD_MODULE], param->rightObj );
			}
			else
			{
				DisableObject( g_winDialogs[WD_MODULE], param->rightObj );
			}
			/* left arrow could be disabled (start of text) */
			EnableObject( g_winDialogs[WD_MODULE], param->leftObj );
		}
	}
}

/*
 * Get number of module-parameters in given plugin
 */
static short ModuleInfoGetParamsCount( struct SAudioPlugin* plugin )
{
	struct SParameter*	param = plugin->pSParameter;
	short				count = 0;

	while( param->pName != NULL )
	{
		if( ( param->type & MXP_FLG_MOD_PARAM ) != 0 )
		{
			/* module parameters only */
			count++;
		}
		param++;
	}

	return count;
}

/*
 * "Clone" given gem object - place at index 'dst' has to be allocated yet.
 */
static BOOL ModuleInfoCloneObject( OBJECT* tree, short dst, short src, int textLength )
{
	char*	string;
	int		length;

	/* common for all objects */
	memcpy( &tree[dst], &tree[src], sizeof( OBJECT ) );

	tree[dst].ob_head = -1;
	tree[dst].ob_next = 0;
	tree[dst].ob_tail = -1;

	set_flag( tree, dst, OF_HIDETREE, FALSE );
	objc_add( tree, MODULE_BACKGROUND, dst );
	
	if( get_obtype( tree, dst, NULL ) == G_TEXT )
	{
		/* new tedinfo */
		tree[dst].ob_spec.tedinfo = (TEDINFO*)malloc( sizeof( TEDINFO ) );
		if( VerifyAlloc( tree[dst].ob_spec.tedinfo ) == FALSE )
		{
			return FALSE;
		}
		memcpy( tree[dst].ob_spec.tedinfo, tree[src].ob_spec.tedinfo, sizeof( TEDINFO ) );
	
		/* text */
		if( src == MODULE_OPT_VALUE )	/* special case of text object */
		{
			length = textLength;
		}
		else
		{
			length = tree[src].ob_spec.tedinfo->te_txtlen;
		}
		string = (char*)malloc( length );
		if( VerifyAlloc( string ) == FALSE )
		{
			return FALSE;
		}
		tree[dst].ob_spec.tedinfo->te_ptext = string;
		tree[dst].ob_spec.tedinfo->te_txtlen = length;
		set_string( tree, dst, tree[src].ob_spec.tedinfo->te_ptext );
	}
	
	return TRUE;
}

/*
 * Add parameters to the dialog. BOOLs and INTs are converted to CHARs.
 * Add colons after parameter names.
 */
static void ModuleInfoAddParams( OBJECT* tree, short freeObj, short freeObjs )
{
	struct SParameter* param;
	GRECT		currSlot;
	char		text[255+1];
	int			len;
	int			skip;
	TEDINFO*	pTed;
	int			newTextSize;
	short		fontSize;

	/* uses y and height only */
	currSlot.g_y = tree[MODULE_OPT_DESC].ob_y;
	currSlot.g_h = tree[MODULE_OPT_DESC].ob_height;
	
	/* calculate new text size */
	pTed = tree[MODULE_OPT_VALUE].ob_spec.tedinfo;	/* every text field must have the same size */
	switch( pTed->te_font )
	{
		case 3:
			/* system font */
			fontSize = 8;
		break;
		
		case 5:
			/* small system font */
			fontSize = 6;
		break;
		
		default:
			/* GDOS font */
			fontSize = pTed->te_fontsize;
		break;
	}
	newTextSize = tree[MODULE_OPT_VALUE].ob_width / fontSize + 1;	/* incl. '\0' */
	
	skip = moduleInfoParamCurrent;

	param = g_pCurrAudioPlugin->pSParameter;
	while( param->pName != NULL && freeObj < freeObjs )
	{
		if( ( param->type & MXP_FLG_MOD_PARAM ) != 0 )
		{
			if( skip == 0 )
			{
				currSlot.g_x = tree[MODULE_OPT_DESC].ob_x;	/* description as first */
				
				/* description */
				len = MIN( 255, strlen( param->pName ) );
				strncpy( text, param->pName, len );
				text[len] = '\0';
				if( strlen( text ) < 255 )
				{
					strcat( text, ":" );
				}
				set_string( tree, MODULE_OPT_DESC, text );
				tree[MODULE_OPT_DESC].ob_x = currSlot.g_x;
				tree[MODULE_OPT_DESC].ob_y = currSlot.g_y;
				if( ModuleInfoCloneObject( tree, freeObj, MODULE_OPT_DESC, -1 ) == FALSE )
				{
					return;
				}

				currSlot.g_x += tree[MODULE_OPT_DESC].ob_width;	/* length of string in rsc(!) */
				currSlot.g_x += slotHzDelta1;
				freeObj++;
				
				/* left arrow */
				tree[MODULE_OPT_LEFT].ob_x = currSlot.g_x;
				tree[MODULE_OPT_LEFT].ob_y = currSlot.g_y;
				if( ModuleInfoCloneObject( tree, freeObj, MODULE_OPT_LEFT, -1 ) == FALSE )
				{
					return;
				}
				
				currSlot.g_x += tree[MODULE_OPT_LEFT].ob_width;
				currSlot.g_x += slotHzDelta2;
				freeObj++;
				
				/* value will be added in CheckParams() */
				tree[MODULE_OPT_VALUE].ob_x = currSlot.g_x;
				tree[MODULE_OPT_VALUE].ob_y = currSlot.g_y;
				if( ModuleInfoCloneObject( tree, freeObj, MODULE_OPT_VALUE, newTextSize ) == FALSE )
				{
					return;
				}
				
				currSlot.g_x += tree[MODULE_OPT_VALUE].ob_width;
				currSlot.g_x += slotHzDelta3;
				freeObj++;
				
				/* right arrow */
				tree[MODULE_OPT_RIGHT].ob_x = currSlot.g_x;
				tree[MODULE_OPT_RIGHT].ob_y = currSlot.g_y;
				if( ModuleInfoCloneObject( tree, freeObj, MODULE_OPT_RIGHT, -1 ) == FALSE )
				{
					return;
				}
				
				currSlot.g_x += tree[MODULE_OPT_RIGHT].ob_width;	/* not really neccessary */
				freeObj++;

				moduleInfoParam[moduleInfoParamCount].stringObj = freeObj - 4;	/* description */
				moduleInfoParam[moduleInfoParamCount].leftObj = freeObj - 3;	/* left arrow */
				moduleInfoParam[moduleInfoParamCount].valueObj = freeObj - 2;	/* value */
				moduleInfoParam[moduleInfoParamCount].rightObj = freeObj - 1;	/* right arrow */
				moduleInfoParam[moduleInfoParamCount].scrolled = -1;
				moduleInfoParam[moduleInfoParamCount].scrollable = FALSE;
				
				set_state( tree, moduleInfoParam[moduleInfoParamCount].leftObj, OS_DISABLED, TRUE );
				set_state( tree, moduleInfoParam[moduleInfoParamCount].rightObj, OS_DISABLED, TRUE );
				
				moduleInfoParamCount++;

				currSlot.g_y += currSlot.g_h;
			}
			else
			{
				skip--;
			}
		}
		param++;
	}
	
	/* special object */
	newTextSize = tree[MODULE_FILENAME].ob_width / fontSize + 1;	/* incl. '\0' */
	
	tree[MODULE_FILENAME].ob_spec.tedinfo->te_ptext = (char*)malloc( newTextSize );
	if( VerifyAlloc( tree[MODULE_FILENAME].ob_spec.tedinfo->te_ptext ) == FALSE )
	{
		return;
	}
	tree[MODULE_FILENAME].ob_spec.tedinfo->te_txtlen = newTextSize;
	set_string( tree, MODULE_FILENAME, "-" );
}

/*
 * Check values of all parameters in dialog - set the corresponding state
 * of gem object and redraw both object and its description.
 */
static void ModuleInfoCheckParams( void )
{
	struct SParameter* param;
	int		i;
	short	obj;
	OBJECT*	tree;
	char	text[255+1];
	short	objStringLength;
	int		modStringLength;
	
	tree = g_winDialogs[WD_MODULE]->tree;
	
	objStringLength = tree[MODULE_FILENAME].ob_spec.tedinfo->te_txtlen - 1;
	modStringLength = strlen( g_currModuleName );
	
	if( objStringLength >= modStringLength )
	{
		set_string( tree, MODULE_FILENAME, g_currModuleName );
	}
	else
	{
		strncpy( text, g_currModuleName, ( objStringLength / 2 ) - 1 );
		text[( objStringLength / 2 ) - 2] = '.';
		text[( objStringLength / 2 ) - 1] = '.';
		text[( objStringLength / 2 ) - 0] = '.';
		text[( objStringLength / 2 ) + 1] = '\0';
		strcat( text, &g_currModuleName[modStringLength - ( ( objStringLength / 2 ) - 1 )] );
		set_string( tree, MODULE_FILENAME, text );
	}
	
	redraw_wdobj( g_winDialogs[WD_MODULE], MODULE_FILENAME );

	for( i = 0; i < moduleInfoParamCount; i++ )
	{
		obj = moduleInfoParam[i].valueObj;

		if( ModuleInfoGetModuleParam( g_pCurrAudioPlugin, tree, obj, NULL, &param ) == TRUE )
		{
			ConvertMxpParamTypes( g_pCurrAudioPlugin, param, text );
			
			set_string( tree, obj, text );
			if( tree[obj].ob_spec.tedinfo->te_txtlen < strlen( text ) + 1 )
			{
				set_state( tree, moduleInfoParam[i].leftObj, OS_DISABLED, TRUE );
				set_state( tree, moduleInfoParam[i].rightObj, OS_DISABLED, FALSE );
				moduleInfoParam[i].scrolled = 0;
				moduleInfoParam[i].scrollable = TRUE;
			}
			else
			{
				set_state( tree, moduleInfoParam[i].leftObj, OS_DISABLED, TRUE );
				set_state( tree, moduleInfoParam[i].rightObj, OS_DISABLED, TRUE );
				moduleInfoParam[i].scrolled = -1;
				moduleInfoParam[i].scrollable = FALSE;
			}

			redraw_wdobj( g_winDialogs[WD_MODULE], obj );	/* valueObj */
			redraw_wdobj( g_winDialogs[WD_MODULE], moduleInfoParam[i].stringObj );
			redraw_wdobj( g_winDialogs[WD_MODULE], moduleInfoParam[i].leftObj );
			redraw_wdobj( g_winDialogs[WD_MODULE], moduleInfoParam[i].rightObj );
			
		}
	}
}

/*
 * Reset whole dialog.
 */
static void ModuleInfoResetDialog( void )
{
	short obj;
	short objects;

	if( tempModuleTree != NULL )
	{
		g_winDialogs[WD_MODULE]->tree = origModuleTree;
		
		origModuleTree[ROOT].ob_x = tempModuleTree[ROOT].ob_x;
		origModuleTree[ROOT].ob_y = tempModuleTree[ROOT].ob_y;
	
		obj = GetObjectCount( origModuleTree );	/* number of old objects */
		objects = GetObjectCount( tempModuleTree );	/* number of old+new objects */
	
		for( ; obj < objects; obj++ )
		{
			if( get_obtype( tempModuleTree, obj, NULL ) == G_TEXT )
			{
				free( tempModuleTree[obj].ob_spec.tedinfo->te_ptext );
				tempModuleTree[obj].ob_spec.tedinfo->te_ptext = NULL;
				free( tempModuleTree[obj].ob_spec.tedinfo );
				tempModuleTree[obj].ob_spec.tedinfo = NULL;
			}
		}
		
		/* this objects isn't created from scratch */
		free( tempModuleTree[MODULE_FILENAME].ob_spec.tedinfo->te_ptext );
		tempModuleTree[MODULE_FILENAME].ob_spec.tedinfo->te_ptext = pOrigModuleText;
	
		free( tempModuleTree );
		tempModuleTree = NULL;

		free( moduleInfoParam );
		moduleInfoParam = NULL;
		moduleInfoParamCount = 0;
		
		moduleParamCount = 0;
	}
}

/*
 * (Re-)create dialog.
 */
static void ModuleInfoCreateDialog( void )
{
	short	params = 0;
	short	freeObj;
	OBJECT*	tree;
	short	oldObjects;
	short	newObjects;

	if( g_pCurrAudioPlugin != NULL )
	{
		tree = g_winDialogs[WD_MODULE]->tree;
		oldObjects = GetObjectCount( tree );
		
		params = ModuleInfoGetParamsCount( g_pCurrAudioPlugin );
		if( params > 0 )
		{
			moduleParamCount = params;
			
			moduleInfoParam = (struct SInfoParam*)malloc( params * sizeof( struct SInfoParam ) );
			if( VerifyAlloc( moduleInfoParam ) == FALSE )
			{
				return;
			}
			moduleInfoParamCount = 0;
			
			currSlots = tree[MODULE_BACKGROUND].ob_height / tree[MODULE_OPT_DESC].ob_height;
			
			/* allocate space for the new dialog - for each slot four objects - desc, value and arrows */
			freeObj = CloneDialog( origModuleTree, &tempModuleTree, currSlots * 4 );
			if( freeObj == -1 )
			{
				return;
			}
			
			tree = tempModuleTree;
			
			ModuleInfoAddParams( tree, freeObj, freeObj + MIN( currSlots, params ) * 4 );
			
			newObjects = GetObjectCount( tree );	/* must be after add params */
			
			set_flag( tree, oldObjects - 1, OF_LASTOB, FALSE );	/* kill flag from the last object */
			set_flag( tree, newObjects - 1, OF_LASTOB, TRUE );	/* set flag on the last object */
		}

		g_winDialogs[WD_MODULE]->tree = tree;
	}
}

/*
 * Set slider according to size of module info window
 * and number of params available
 */
static void ModuleInfoSliderSet( void )
{
	short size;
	short pos;
	short old;
	short dummy;
	
	if( moduleParamCount != 0 )
	{
		size = MIN( 1000, Round( 1000.0 * (float)currSlots / (float)moduleParamCount ) );
		if( size <= 0 )
		{
			size = 1;
		}
		
		pos = Round( (float)( 1000 * moduleInfoParamCurrent ) / (float)( moduleParamCount - currSlots ) );
		if( pos < 0 )
		{
			pos = 0;
		}
	}
	else
	{
		pos = 0;
		size = 1000;
	}
	
	wind_get( g_winDialogs[WD_MODULE]->win_handle, WF_VSLSIZE, &old, &dummy, &dummy, &dummy );
	if( old != size )
	{
		wind_set( g_winDialogs[WD_MODULE]->win_handle, WF_VSLSIZE, size, 0, 0, 0 );
	}
	
	wind_get( g_winDialogs[WD_MODULE]->win_handle, WF_VSLIDE, &old, &dummy, &dummy, &dummy );
	if( old != pos )
	{
		wind_set( g_winDialogs[WD_MODULE]->win_handle, WF_VSLIDE, pos, 0, 0, 0 );
	}
}

static void ModuleInfoUpCommon( int count )
{
	if( moduleInfoParamCurrent > 0 )
	{
		if( moduleInfoParamCurrent - count > 0 )
		{
			moduleInfoParamCurrent -= count;
		}
		else
		{
			moduleInfoParamCurrent = 0;
		}
		
		ModuleInfoResetDialog();
		ModuleInfoCreateDialog();
		ModuleInfoCheckParams();
		ModuleInfoSliderSet();
	}
}

static void ModuleInfoDownCommon( int count )
{
	if( moduleInfoParamCurrent + currSlots < moduleParamCount )
	{
		if( moduleInfoParamCurrent + currSlots + count < moduleParamCount )
		{
			moduleInfoParamCurrent += count;
		}
		else
		{
			moduleInfoParamCurrent = moduleParamCount - currSlots;
		}
		
		ModuleInfoCreateDialog();
		ModuleInfoCheckParams();
		ModuleInfoSliderSet();
	}
}

static void ModuleInfoResizeObjects( deltaX, deltaY )
{
	OBJECT*	tree;
	short	objects;
	short	obj;
	short	rightBound;
	short	bottomBound;
	
	tree = g_winDialogs[WD_MODULE]->tree;
	
	objects = GetObjectCount( tree );
	
	if( deltaX != 0 )
	{
		tree[ROOT].ob_width += deltaX;
	
		rightBound = tree[MODULE_BACKGROUND].ob_x + tree[MODULE_BACKGROUND].ob_width;
		
		for( obj = 1; obj < objects; obj++ )
		{
			if( tree[obj].ob_x > rightBound )
			{
				tree[obj].ob_x += deltaX;
			}
		}
		
		tree[MODULE_OPT_VALUE].ob_width += deltaX;
		tree[MODULE_BACKGROUND].ob_width += deltaX;
		tree[MODULE_FILENAME].ob_width += deltaX;
		
		/* center */
		tree[MODULE_TITLE].ob_x = tree[ROOT].ob_width / 2 - tree[MODULE_TITLE].ob_width / 2;
		tree[MODULE_OK].ob_x = tree[ROOT].ob_width / 2 - tree[MODULE_OK].ob_width / 2;
	}
	
	if( deltaY != 0 )
	{
		tree[ROOT].ob_height += deltaY;
		
		bottomBound = tree[MODULE_BACKGROUND].ob_y + tree[MODULE_BACKGROUND].ob_height;
		
		for( obj = 1; obj < objects; obj++ )
		{
			if( tree[obj].ob_y > bottomBound )
			{
				tree[obj].ob_y += deltaY;
			}
		}
		
		tree[MODULE_BACKGROUND].ob_height += deltaY;
	}
}

/*
 * Dialog initialization. Called only once from
 * InitRsc() in dialogs.c
 */
void ModuleInfoInit( void )
{
	OBJECT* tree;
	
	origModuleTree = g_winDialogs[WD_MODULE]->tree;
	tree = origModuleTree;

	/* remember some deltas */
	slotHzDelta1 = tree[MODULE_OPT_LEFT].ob_x - ( tree[MODULE_OPT_DESC].ob_x + tree[MODULE_OPT_DESC].ob_width );
	slotHzDelta2 = tree[MODULE_OPT_VALUE].ob_x - ( tree[MODULE_OPT_LEFT].ob_x + tree[MODULE_OPT_LEFT].ob_width );
	slotHzDelta3 = tree[MODULE_OPT_RIGHT].ob_x - ( tree[MODULE_OPT_VALUE].ob_x + tree[MODULE_OPT_VALUE].ob_width );

	/* for ModuleInfoResize() */
	origWidth = tree[ROOT].ob_width;	/* equivalent to work.g_w (which is still empty) */
	origHeight = tree[ROOT].ob_height;	/* equivalent to work.g_h */
	
	set_string( tree, MODULE_FILENAME, "-" );	/* point to some reasonable value */
	pOrigModuleText = tree[MODULE_FILENAME].ob_spec.tedinfo->te_ptext;
	
	/* center */
	tree[MODULE_TITLE].ob_x = tree[ROOT].ob_width / 2 - tree[MODULE_TITLE].ob_width / 2;
	tree[MODULE_OK].ob_x = tree[ROOT].ob_width / 2 - tree[MODULE_OK].ob_width / 2;
	
	set_flag( origModuleTree, MODULE_OPT_DESC, OF_HIDETREE, TRUE );
	set_flag( origModuleTree, MODULE_OPT_VALUE, OF_HIDETREE, TRUE );
	set_flag( origModuleTree, MODULE_OPT_LEFT, OF_HIDETREE, TRUE );
	set_flag( origModuleTree, MODULE_OPT_RIGHT, OF_HIDETREE, TRUE );
}

/*
 * Dialog reinitialization. Called only by
 * PanelChangeSkin() in panel.c (after PlayListInit)
 */
void ModuleInfoReinit( void )
{
	ModuleInfoResetDialog();
	moduleInfoParamCurrent = 0;	/* show first param */
	ModuleInfoCreateDialog();
	ModuleInfoCheckParams();	/* here are params already redrawn but who cares ;-) */
	ModuleInfoSliderSet();
	redraw_wdobj( g_winDialogs[WD_MODULE], ROOT );
}

/*
 * Resize dialog.
 */
void ModuleInfoResize( GRECT* pNewR )
{
	int		count;
	short	deltaX;
	short	deltaY;
	short	objWidth;
	short	objHeight;
	int		oldSlots;
	GRECT	oldR;
	GRECT	tempR;
	
	/* get area of old window */
	wind_get_grect( g_winDialogs[WD_MODULE]->win_handle, WF_CURRXYWH, &oldR );
	
	objWidth = g_winDialogs[WD_MODULE]->tree[ROOT].ob_width;
	objHeight = g_winDialogs[WD_MODULE]->tree[ROOT].ob_height;
	
	tempR = *pNewR;
	
	deltaX = tempR.g_w - oldR.g_w;
	deltaY = tempR.g_h - oldR.g_h;
	
	if( objWidth + deltaX < origWidth )
	{
		tempR.g_w += ( origWidth - ( objWidth + deltaX ) );
		deltaX += ( origWidth - ( objWidth + deltaX ) );
	}
	
	if( objHeight + deltaY < origHeight )
	{
		tempR.g_h += ( origHeight - ( objHeight + deltaY ) );
		deltaY += ( origHeight - ( objHeight + deltaY ) );
	}
	
	if( tempR.g_w == oldR.g_w && tempR.g_h == oldR.g_h )
	{
		return;
	}
	
	ModuleInfoResetDialog();

	ModuleInfoResizeObjects( deltaX, deltaY );
	
	oldSlots = currSlots;
	currSlots = g_winDialogs[WD_MODULE]->tree[MODULE_BACKGROUND].ob_height / g_winDialogs[WD_MODULE]->tree[MODULE_OPT_DESC].ob_height;
	
	count = currSlots - oldSlots;
	
	/* dialog grows up */
	if( count > 0 && moduleInfoParamCurrent + oldSlots >= moduleParamCount - 1 )
	{
		/* if we are exactly on the bottom, "emulate" moving up */
		if( moduleInfoParamCurrent > 0 )
		{
			if( moduleInfoParamCurrent - count > 0 )
			{
				moduleInfoParamCurrent -= count;
			}
			else
			{
				moduleInfoParamCurrent = 0;
			}
		}
	}

	ModuleInfoCreateDialog();
	
	ModuleInfoCheckParams();
	
	ModuleInfoSliderSet();
	
	redraw_wdobj( g_winDialogs[WD_MODULE], ROOT );
	
	wind_set_grect( g_winDialogs[WD_MODULE]->win_handle, WF_CURRXYWH, &tempR );
	wind_calc_grect( WC_WORK, g_winDialogs[WD_MODULE]->win_kind, &tempR, &g_winDialogs[WD_MODULE]->work );
}

/*
 * Update dialog if neccessary.
 */
void ModuleInfoUpdate( void )
{
	if( ( g_winDialogs[WD_MODULE]->mode & WD_OPEN ) == 0 )
	{
		return;
	}
	else
	{
		moduleInfoParamCurrent = 0;	/* show first param */
		ModuleInfoResetDialog();
		ModuleInfoCreateDialog();
		ModuleInfoCheckParams();
		ModuleInfoSliderSet();
		redraw_wdobj( g_winDialogs[WD_MODULE], ROOT );
	}
}

/*
 * Callback function for up/down/param button press.
 */
void ModuleInfoButton( short obj )
{
	short paramIndex;
	
	SelectObject( g_winDialogs[WD_MODULE], obj );
	
	paramIndex = ModuleInfoGetInfoParamIndex( obj );
	if( paramIndex != -1 && get_state( g_winDialogs[WD_MODULE]->tree, obj, OS_DISABLED ) == FALSE )
	{
		if( obj == moduleInfoParam[paramIndex].leftObj )
		{
			ModuleInfoLeft( &moduleInfoParam[paramIndex] );
		}
		else if( obj == moduleInfoParam[paramIndex].rightObj )
		{
			ModuleInfoRight( &moduleInfoParam[paramIndex] );
		}
	}
	
	DeselectObject( g_winDialogs[WD_MODULE], obj );
}

void ModuleInfoScroll( short direction )
{
	if( g_pCurrAudioPlugin != NULL )
	{
		switch( direction )
		{
			case WA_UPPAGE:
				ModuleInfoUpCommon( currSlots );
			break;
			
			case WA_UPLINE:
				ModuleInfoUpCommon( 1 );
			break;
			
			case WA_DNPAGE:
				ModuleInfoDownCommon( currSlots );
			break;
			
			case WA_DNLINE:
				ModuleInfoDownCommon( 1 );
			break;
		}
	}
}

void ModuleInfoSlider( short deltaY )
{
	short oldDeltaY;
	float delta;
	short value;
	short dummy;
	
	if( g_pCurrAudioPlugin != NULL )
	{
		wind_get( g_winDialogs[WD_MODULE]->win_handle, WF_VSLIDE, &oldDeltaY, &dummy, &dummy, &dummy );
		
		delta = ( deltaY - oldDeltaY ) * ( (float)( moduleParamCount - currSlots ) / 1000.0 );
		value = Round( delta );
		
		if( value > 0 )
		{
			ModuleInfoDownCommon( value );
		}
		else if( value < 0 )
		{
			ModuleInfoUpCommon( -value );
		}
	}
}
