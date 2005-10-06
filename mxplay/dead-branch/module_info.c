#include <cflib.h>
#include <sys/param.h>	/* MIN */

#include "skins/skin.h"
#include "audio_plugins.h"
#include "dialogs.h"
#include "misc.h"
#include "info_dialogs.h"

static struct SAudioPlugin*	pOldAudioPlugin = NULL;
static struct SInfoParam*	moduleParam = NULL;
static int		moduleParamCount = 0;	/* in the window */
static int		moduleParamCurrent = 0;

static OBJECT*	tempModuleTree = NULL;
static OBJECT*	origModuleTree;

static int		slotHzDelta1;	/* horizontal distance between description and left arrow */
static int		slotHzDelta2;	/* horizontal distance between left arrow and value */
static int		slotHzDelta3;	/* horizontal distance between value and right arrow */
static int		slotHeight;	/* common slot */
static int		currSlots;	/* number of up/common/down slots */
static int		origSlots;
static GRECT	slot0;		/* begin, not usable */
static GRECT	slotUp;		/* up/common slot */
static GRECT	slotGen;	/* common (general) slot */
static GRECT	slotDown;	/* down/common slot */
static GRECT	slotx;		/* end, not usable */

static short origWidth;		/* original width & height */
static short origHeight;	/* (could be modified by CreateDialog) */
static short prevWidth;
static short prevHeight;

static short valueObjTextLength;	/* this length will be used instead of the one in rsc */

/*
 * Get corresponding parameter for given gem object.
 */
static struct SInfoParam* ModuleInfoGetParam( short obj )
{
	int i;

	for( i = 0; i < moduleParamCount; i++ )
	{
		if( moduleParam[i].valueObj == obj || moduleParam[i].leftObj == obj || moduleParam[i].rightObj == obj )
		{
			return &moduleParam[i];
		}
	}

	return NULL;
}

/*
 * Get corresponding moduleParam index for given gem object (left/right arrow).
 */
static int ModuleInfoGetParamIndex( short obj )
{
	int i;

	for( i = 0; i < moduleParamCount; i++ )
	{
		if( moduleParam[i].leftObj == obj || moduleParam[i].rightObj == obj )
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
static BOOL ModuleInfoGetParamType( OBJECT* tree, short obj, short* type, struct SParameter** param )
{
	struct SParameter*	moduleAudioParam;
	struct SInfoParam*	moduleInfoParam;
	char text[256];

	if( g_pCurrAudioPlugin != NULL )
	{
		moduleInfoParam = ModuleInfoGetParam( obj );
		if( moduleInfoParam != NULL )
		{
			get_string( tree, moduleInfoParam->stringObj, text );
			if( text[strlen( text ) - 1] == ':'  )
			{
				/* if there was a space for colon, remove it */
				text[strlen( text ) - 1] = '\0';
			}

			moduleAudioParam = AudioPluginGetParam( g_pCurrAudioPlugin, text );
			if( moduleAudioParam != NULL )
			{
				if( type != NULL )
				{
					*type = moduleAudioParam->type & 0x7fff;
				}
				if( param != NULL )
				{
					*param = moduleAudioParam;
				}
				return TRUE;
			}
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
	long	value;
	char	text[255+1];
	OBJECT*	tree;
	
	tree = g_winDialogs[WD_MODULE]->tree;
	
	if( ModuleInfoGetParamType( tree, param->valueObj, NULL, &audioParam ) == TRUE )
	{
		if( param->scrollable == TRUE && param->scrolled > 0 )
		{
			AudioPluginGet( g_pCurrAudioPlugin, audioParam, &value );
			
			if( strcmp( (char*)value, "" ) == 0 )
			{
				strncpy( text, g_currModuleName, 255 );
			}
			else
			{
				strncpy( text, (char*)value, 255 );
			}
			text[255] = '\0';	/* for sure */

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
	long	value;
	char	text[255+1];
	OBJECT*	tree;
	int		delta;
	
	tree = g_winDialogs[WD_MODULE]->tree;
	
	if( ModuleInfoGetParamType( tree, param->valueObj, NULL, &audioParam ) == TRUE )
	{
		if( param->scrollable == TRUE )
		{
			AudioPluginGet( g_pCurrAudioPlugin, audioParam, &value );
			
			if( strcmp( (char*)value, "" ) == 0 )
			{
				strncpy( text, g_currModuleName, 255 );
			}
			else
			{
				strncpy( text, (char*)value, 255 );
			}
			text[255] = '\0';	/* for sure */
	
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
 * Expand current text field to the given length.
 */
static BOOL ModuleInfoExpandText( TEDINFO* pTed, int newTextLength )
{
	char* newText;
	
	newText = malloc( newTextLength );
	if( VerifyAlloc( newText ) == FALSE )
	{
		return FALSE;
	}
	
	memset( newText, '\0', newTextLength );
	free( pTed->te_ptext );	/* has to be allocated by us */
	pTed->te_ptext = newText;
	pTed->te_txtlen = newTextLength;
	valueObjTextLength = newTextLength;
	
	return TRUE;
}

/*
 * "Clone" given gem object (TEXT) - place at index 'dst' has to be allocated yet.
 */
static BOOL ModuleInfoCloneObject( OBJECT* tree, short dst, short src )
{
	char*	string;
	int		length;

	/* common for all objects */
	memcpy( &tree[dst], &tree[src], sizeof( OBJECT ) );

	tree[dst].ob_head = -1;
	tree[dst].ob_next = 0;
	tree[dst].ob_tail = -1;

	set_flag( tree, dst, OF_HIDETREE, FALSE );
	objc_add( tree, ROOT, dst );

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
			length = valueObjTextLength;
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
static void ModuleInfoAddParams( OBJECT* tree, short freeObj, GRECT* pos, short freeObjs )
{
	struct SParameter* param;
	GRECT	currSlot;
	char	text[255+1];
	int		len;
	int		skip;

	currSlot = *pos;
	skip = moduleParamCurrent;

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
				if( ModuleInfoCloneObject( tree, freeObj, MODULE_OPT_DESC ) == FALSE )
				{
					return;
				}

				currSlot.g_x += tree[MODULE_OPT_DESC].ob_width;	/* length of string in rsc(!) */
				currSlot.g_x += slotHzDelta1;
				freeObj++;
				
				/* left arrow */
				tree[MODULE_OPT_LEFT].ob_x = currSlot.g_x;
				tree[MODULE_OPT_LEFT].ob_y = currSlot.g_y;
				if( ModuleInfoCloneObject( tree, freeObj, MODULE_OPT_LEFT ) == FALSE )
				{
					return;
				}
				
				currSlot.g_x += tree[MODULE_OPT_LEFT].ob_width;
				currSlot.g_x += slotHzDelta2;
				freeObj++;
				
				/* value will be added in CheckParams() */
				tree[MODULE_OPT_VALUE].ob_x = currSlot.g_x;
				tree[MODULE_OPT_VALUE].ob_y = currSlot.g_y;
				if( ModuleInfoCloneObject( tree, freeObj, MODULE_OPT_VALUE ) == FALSE )
				{
					return;
				}
				
				currSlot.g_x += tree[MODULE_OPT_VALUE].ob_width;
				currSlot.g_x += slotHzDelta3;
				freeObj++;
				
				/* right arrow */
				tree[MODULE_OPT_RIGHT].ob_x = currSlot.g_x;
				tree[MODULE_OPT_RIGHT].ob_y = currSlot.g_y;
				if( ModuleInfoCloneObject( tree, freeObj, MODULE_OPT_RIGHT ) == FALSE )
				{
					return;
				}
				
				currSlot.g_x += tree[MODULE_OPT_RIGHT].ob_width;	/* not really neccessary */
				freeObj++;

				moduleParam[moduleParamCount].stringObj = freeObj - 4;	/* description */
				moduleParam[moduleParamCount].leftObj = freeObj - 3;	/* left arrow */
				moduleParam[moduleParamCount].valueObj = freeObj - 2;	/* value */
				moduleParam[moduleParamCount].rightObj = freeObj - 1;	/* right arrow */
				moduleParam[moduleParamCount].scrolled = -1;
				moduleParam[moduleParamCount].scrollable = FALSE;
				
				set_state( tree, moduleParam[moduleParamCount].leftObj, OS_DISABLED, TRUE );
				set_state( tree, moduleParam[moduleParamCount].rightObj, OS_DISABLED, TRUE );
				
				moduleParamCount++;

				currSlot.g_y += slotHeight;
			}
			else
			{
				skip--;
			}
		}
		param++;
	}
}

/*
 * Check values of all parameters in dialog - set the corresponding state
 * of gem object and redraw both object and its description.
 */
static void ModuleInfoCheckParams( void )
{
	struct SParameter* param;
	long	value;
	short	type;
	int		i;
	short	obj;
	OBJECT*	tree;
	char	text[255+1];
	
	tree = g_winDialogs[WD_MODULE]->tree;

	for( i = 0; i < moduleParamCount; i++ )
	{
		obj = moduleParam[i].valueObj;

		if( ModuleInfoGetParamType( tree, obj, &type, &param ) == TRUE )
		{
			/* this should always happen */
			AudioPluginGet( g_pCurrAudioPlugin, param, &value );

			switch( type )
			{
				case MXP_PAR_TYPE_BOOL:
					if( value == TRUE )
					{
						set_string( tree, obj, "Yes" );
					}
					else
					{
						set_string( tree, obj, "No" );
					}
				break;

				case MXP_PAR_TYPE_INT:
					/* i hope int-string length is ok :) */
					set_long( tree, obj, value );
				break;

				case MXP_PAR_TYPE_CHAR:
					if( strcmp( (char*)value, "" ) == 0 )
					{
						strncpy( text, g_currModuleName, 255 );
					}
					else
					{
						strncpy( text, (char*)value, 255 );
					}
					text[255] = '\0';	/* for sure */
					
					set_string( tree, obj, text );
					if( tree[obj].ob_spec.tedinfo->te_txtlen < strlen( text ) + 1 )
					{
						set_state( tree, moduleParam[i].leftObj, OS_DISABLED, TRUE );
						set_state( tree, moduleParam[i].rightObj, OS_DISABLED, FALSE );
						moduleParam[i].scrolled = 0;
						moduleParam[i].scrollable = TRUE;
					}
					else
					{
						set_state( tree, moduleParam[i].leftObj, OS_DISABLED, TRUE );
						set_state( tree, moduleParam[i].rightObj, OS_DISABLED, TRUE );
						moduleParam[i].scrolled = -1;
						moduleParam[i].scrollable = FALSE;
					}
				break;
			}
		}
	}
}

/*
 * Delete tree (i.e. copy of our dialog)
 */
static void ModuleInfoDestroyTree( OBJECT* tree )
{
	short obj;
	short objects;

	origModuleTree[ROOT].ob_x = tree[ROOT].ob_x;
	origModuleTree[ROOT].ob_y = tree[ROOT].ob_y;

	obj = GetObjectCount( origModuleTree );	/* number of old objects */
	objects = GetObjectCount( tree );	/* number of old+new objects */

	for( ; obj < objects; obj++ )
	{
		if( get_obtype( tree, obj, NULL ) == G_TEXT )
		{
			free( tree[obj].ob_spec.tedinfo->te_ptext );
			tree[obj].ob_spec.tedinfo->te_ptext = NULL;
			free( tree[obj].ob_spec.tedinfo );
			tree[obj].ob_spec.tedinfo = NULL;
		}
	}

	free( tree );
}

/*
 * Reset the dialog into the default state and (re-)create dialog from scratch.
 */
static void ModuleInfoCreateDialog( BOOL resize )
{
	short	offset = 0;
	short	obj;
	short	params = 0;
	short	freeObj;
	OBJECT*	tree;
	short	objects;
	GRECT	r;

	/* reset the tree */
	if( tempModuleTree != NULL )
	{
		g_winDialogs[WD_MODULE]->tree = origModuleTree;
		
		ModuleInfoDestroyTree( tempModuleTree );
		tempModuleTree = NULL;

		free( moduleParam );
		moduleParam = NULL;
		moduleParamCount = 0;
	}

	if( g_pCurrAudioPlugin != NULL )
	{
		tree = g_winDialogs[WD_MODULE]->tree;
		
		params = ModuleInfoGetParamsCount( g_pCurrAudioPlugin );
		if( params > 0 )
		{
			moduleParam = (struct SInfoParam*)malloc( params * sizeof( struct SInfoParam ) );
			if( VerifyAlloc( moduleParam ) == FALSE )
			{
				return;
			}
			moduleParamCount = 0;
			
			/* allocate space for the new dialog - for each slot four objects - desc, value and arrows */
			//freeObj = CloneDialog( origModuleTree, &tempModuleTree, MIN( params, currSlots ) * 4 );
			freeObj = CloneDialog( origModuleTree, &tempModuleTree, currSlots * 4 );
			if( freeObj == -1 )
			{
				return;
			}

			tree = tempModuleTree;
			//offset = MIN( params, currSlots ) * slotHeight;
			offset = currSlots * slotHeight;

			objects = GetObjectCount( tree );
			for( obj = 1; obj < objects; obj++ )
			{
				/* correct y for remaining objects */
				if( tree[obj].ob_y > slot0.g_y
					&& get_flag( tree, obj, OF_HIDETREE ) == FALSE )
				{
					tree[obj].ob_y += offset;
				}
			}
			
			if( params <= currSlots )
			{
				ModuleInfoAddParams( tree, freeObj, &slotUp, freeObj + currSlots * 4 );
			}
			else
			{
				/* up button */
				tree[MODULE_OPT_UP].ob_x = slotUp.g_x + slotUp.g_w / 2 - tree[MODULE_OPT_UP].ob_width / 2;
				tree[MODULE_OPT_UP].ob_y = slotUp.g_y;
				set_flag( tree, MODULE_OPT_UP, OF_HIDETREE, FALSE );
				freeObj++;

				/* params - there have to be at least three free slots at all! */
				ModuleInfoAddParams( tree, freeObj, &slotGen, freeObj + ( currSlots - 2 ) * 4 );
				freeObj += ( currSlots - 2 ) * 4;

				/* down button */
				tree[MODULE_OPT_DOWN].ob_x = slotDown.g_x + slotDown.g_w / 2 - tree[MODULE_OPT_DOWN].ob_width / 2;
				/* move down according to number of used slots */
				tree[MODULE_OPT_DOWN].ob_y = slotGen.g_y + ( currSlots - 2 ) * slotHeight;
				set_flag( tree, MODULE_OPT_DOWN, OF_HIDETREE, FALSE );
				freeObj++;
			}
		}

		g_winDialogs[WD_MODULE]->tree = tree;

		if( resize == TRUE )
		{
			/* dialog box */
			tree[ROOT].ob_height = origModuleTree[ROOT].ob_height + offset;
	
			/* internal cflib value */
			memcpy( &g_winDialogs[WD_MODULE]->work, &tree[ROOT].ob_x, 4 * sizeof( short ) );
			g_winDialogs[WD_MODULE]->work.g_y += g_winDialogs[WD_MODULE]->delta_y;
			g_winDialogs[WD_MODULE]->work.g_h -= g_winDialogs[WD_MODULE]->delta_y;
			
			/* set new window */
			wind_calc_grect( WC_BORDER, g_winDialogs[WD_MODULE]->win_kind, &g_winDialogs[WD_MODULE]->work, &r );
			wind_set_grect( g_winDialogs[WD_MODULE]->win_handle, WF_CURRXYWH, &r );
		}
	}
}

/*
 * Init dialog. Place it in the default state (no params), save important values, resize.
 */
void ModuleInfoInit( void )
{
	short	obj;
	short	cut;
	OBJECT*	tree;
	short	objects;

	origModuleTree = g_winDialogs[WD_MODULE]->tree;
	tree = origModuleTree;
	
	currSlots = 0;
	
	objects = GetObjectCount( tree );
	
	for( obj = 1; obj < objects; obj++ )
	{
		if( get_state( tree, obj, OS_DISABLED ) == TRUE )
		{
			currSlots++;
		}
	}
	
	objects = GetObjectCount( tree );
	
	/* bounding slots */
	set_flag( tree, MODULE_POS_START, OF_HIDETREE, TRUE );
	set_flag( tree, MODULE_POS_END, OF_HIDETREE, TRUE );
	memcpy( &slot0.g_x, &tree[MODULE_POS_START].ob_x, 4 * sizeof( short ) );
	memcpy( &slotx.g_x, &tree[MODULE_POS_END].ob_x, 4 * sizeof( short ) );
	
	for( obj = 1; obj < objects; obj++ )
	{
		/* move up & hide everything between bounding slots */
		if( tree[obj].ob_y >= slot0.g_y && tree[obj].ob_y <= slotx.g_y + slotx.g_h )
		{
			tree[obj].ob_y -= slot0.g_h;
			set_flag( tree, obj, OF_HIDETREE, TRUE );
		}
	}
	
	/* slots for module parameters */
	memcpy( &slotUp.g_x, &tree[MODULE_POS_FIRST].ob_x, 4 * sizeof( short ) );
	memcpy( &slotGen.g_x, &tree[MODULE_POS_GEN].ob_x, 4 * sizeof( short ) );
	memcpy( &slotDown.g_x, &tree[MODULE_POS_LAST].ob_x, 4 * sizeof( short ) );
	
	cut = slotx.g_y + slotx.g_h - slot0.g_y;

	for( obj = 1; obj < objects; obj++ )
	{
		/* correct y for remaining objects */
		if( tree[obj].ob_y > slotx.g_y + slotx.g_h
			&& get_flag( tree, obj, OF_HIDETREE ) == FALSE )
		{
			tree[obj].ob_y -= cut;
		}
	}

	/* correct dialog's height */
	tree[ROOT].ob_height -= cut;
	g_winDialogs[WD_MODULE]->work.g_h -= cut;
	
	/* remember some deltas */
	slotHzDelta1 = tree[MODULE_OPT_LEFT].ob_x - ( tree[MODULE_OPT_DESC].ob_x + tree[MODULE_OPT_DESC].ob_width );
	slotHzDelta2 = tree[MODULE_OPT_VALUE].ob_x - ( tree[MODULE_OPT_LEFT].ob_x + tree[MODULE_OPT_LEFT].ob_width );
	slotHzDelta3 = tree[MODULE_OPT_RIGHT].ob_x - ( tree[MODULE_OPT_VALUE].ob_x + tree[MODULE_OPT_VALUE].ob_width );

	slotHeight = slotGen.g_h + ( slotGen.g_y - ( slotUp.g_y + slotUp.g_h ) );	/* with "border" */
	
	/* for ModuleInfoResize() */
	origSlots = currSlots;
	
	origWidth = tree[ROOT].ob_width;	/* equivalent to work.g_w */
	origHeight = slot0.g_y														/* area between y = 0 and the first slot */
				+ currSlots * slotHeight										/* min. number of slots */
				+ ( tree[ROOT].ob_height + cut - ( slotx.g_y + slotx.g_h ) );	/* area between last slot and end of tree */
	
	prevWidth = origWidth;
	prevHeight = origHeight;

	valueObjTextLength = tree[MODULE_OPT_VALUE].ob_spec.tedinfo->te_txtlen;
}

/*
 * Dialog reinitialization. Called only by
 * PanelChangeSkin() in panel.c
 */
void ModuleInfoReinit( void )
{
	ModuleInfoCreateDialog( TRUE );
	ModuleInfoCheckParams();	/* here are params already redrawn but who cares ;-) */
	redraw_wdobj( g_winDialogs[WD_MODULE], ROOT );
}

/*
 * Resize button.
 */
void ModuleInfoResize( short mx, short my )
{
	GRECT		r;
	BOOL		redrawX = FALSE;
	BOOL		redrawY = FALSE;
	short		width;
	short		height;
	int			i;
	TEDINFO*	pTed;
	OBJECT*		tree;
	short		fontSize;
	int			newTextLength;
	short		newSlots;
	short		deltaX;
	//short		deltaY;
	
	/* only in the case resizing has some sense */
	if( g_pCurrAudioPlugin != NULL )
	{
		width = mx - g_winDialogs[WD_MODULE]->work.g_x;
		height = my - g_winDialogs[WD_MODULE]->work.g_y;
		tree = g_winDialogs[WD_MODULE]->tree;
		
		if( ( width <= origWidth && prevWidth == origWidth )
			&& ( height <= origHeight && prevHeight == origHeight ) )
		{
			return;
		}
		else
		{
			/* only if bigger than original */
			if( width >= origWidth )
			{
				deltaX = width - g_winDialogs[WD_MODULE]->work.g_w;
				
				g_winDialogs[WD_MODULE]->work.g_w = width;
				tree[ROOT].ob_width += deltaX;
				tree[MODULE_RESIZE].ob_x += deltaX;
				
				/* don't forget original tree */
				origModuleTree[ROOT].ob_width += deltaX;
				origModuleTree[MODULE_OPT_VALUE].ob_width += deltaX;
				origModuleTree[MODULE_RESIZE].ob_x += deltaX;
				
				prevWidth = width;
				redrawX = TRUE;
			}
			
			/* only if bigger than original */
			if( height >= origHeight )
			{
				//deltaY = height - g_winDialogs[WD_MODULE]->work.g_h;
				
				//g_winDialogs[WD_MODULE]->work.g_h = height;
				//tree[ROOT].ob_height += deltaY;
				//tree[MODULE_RESIZE].ob_y += deltaY;
				
				/* don't forget original tree */
				//origModuleTree[ROOT].ob_height += deltaY;
				//origModuleTree[MODULE_RESIZE].ob_y += deltaY;
				
				prevHeight = height;
				redrawY = TRUE;
				
				newSlots = Round( (float)( (float)( height - origHeight ) / (float)slotHeight ) );
			}
		}
		
		if( redrawX == TRUE || redrawY == TRUE )
		{
			/* move some objects */
			if( redrawX == TRUE )
			{
				wind_calc_grect( WC_BORDER, g_winDialogs[WD_MODULE]->win_kind, &g_winDialogs[WD_MODULE]->work, &r );
				wind_set_grect( g_winDialogs[WD_MODULE]->win_handle, WF_CURRXYWH, &r );
			
				for( i = 0; i < moduleParamCount; i++ )
				{
					pTed = tree[moduleParam[i].valueObj].ob_spec.tedinfo;
					
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
					
					/* expand width + text */
					tree[moduleParam[i].valueObj].ob_width += deltaX;
					
					newTextLength = tree[moduleParam[i].valueObj].ob_width / fontSize + 1;	/* incl. NULL terminator */
					ModuleInfoExpandText( pTed, newTextLength );
					
					/* object position */
					tree[moduleParam[i].rightObj].ob_x += deltaX;
				}
			}
			
			if( redrawY == TRUE && origSlots + newSlots != currSlots )
			{
				currSlots = origSlots + newSlots;
				moduleParamCurrent = 0;	/* show first param */
				ModuleInfoCreateDialog( TRUE );
			}
			
			/* refresh */
			ModuleInfoCheckParams();
			redraw_wdobj( g_winDialogs[WD_MODULE], ROOT );
		}
	}
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
	else if( g_pCurrAudioPlugin != NULL && g_pCurrAudioPlugin == pOldAudioPlugin )
	{
		ModuleInfoCheckParams();	/* some parameters could be changed */
		redraw_wdobj( g_winDialogs[WD_MODULE], ROOT );
		return;
	}
	else
	{
		pOldAudioPlugin = g_pCurrAudioPlugin;
		moduleParamCurrent = 0;	/* show first param */
		ModuleInfoCreateDialog( TRUE );
		ModuleInfoCheckParams();
		redraw_wdobj( g_winDialogs[WD_MODULE], ROOT );
	}
}

/*
 * Callback function for up/down/param button press.
 */
void ModuleInfoButton( short obj )
{
	short params;
	short paramIndex;
	
	if( g_pCurrAudioPlugin != NULL )
	{
		params = ModuleInfoGetParamsCount( g_pCurrAudioPlugin );

		switch( obj )
		{
			case MODULE_OPT_UP:
				DeselectObject( g_winDialogs[WD_MODULE], obj );

				if( moduleParamCurrent > 0 )
				{
					moduleParamCurrent--;
					ModuleInfoCreateDialog( FALSE );
					ModuleInfoCheckParams();
					redraw_wdobj( g_winDialogs[WD_MODULE], ROOT );	// TODO: solution?
				}
			break;

			case MODULE_OPT_DOWN:
				DeselectObject( g_winDialogs[WD_MODULE], obj );

				if( moduleParamCurrent < params - 1 )
				{
					moduleParamCurrent++;
					ModuleInfoCreateDialog( FALSE );
					ModuleInfoCheckParams();
					redraw_wdobj( g_winDialogs[WD_MODULE], ROOT );	// TODO: solution?
				}
			break;
			
			default:
				SelectObject( g_winDialogs[WD_MODULE], obj );
				
				paramIndex = ModuleInfoGetParamIndex( obj );
				if( paramIndex != -1 && get_state( g_winDialogs[WD_MODULE]->tree, obj, OS_DISABLED ) == FALSE )
				{
					if( obj == moduleParam[paramIndex].leftObj )
					{
						ModuleInfoLeft( &moduleParam[paramIndex] );
					}
					else if( obj == moduleParam[paramIndex].rightObj )
					{
						ModuleInfoRight( &moduleParam[paramIndex] );
					}
				}
				
				DeselectObject( g_winDialogs[WD_MODULE], obj );
			break;
		}
	}
}
