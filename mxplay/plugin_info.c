/*
 * plugin_info.c -- Plugin Info dialog and all around it
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

#include <cflib.h>
#include <sys/param.h>	/* MIN */

#include "skins/skin.h"
#include "audio_plugins.h"
#include "dialogs.h"
#include "misc.h"
#include "info_dialogs.h"

static struct SAudioPlugin*	pOldAudioPlugin = NULL;
static struct SInfoParam*	pluginParam = NULL;
static int		pluginParamCount = 0;
static int		pluginParamCurrent = 0;

static OBJECT*	tempPluginTree = NULL;
static OBJECT*	origPluginTree;

static int		slotHeight;	/* common slot */
static int		slots;		/* number of common slots */
static GRECT	slotUp;		/* up/common */
static GRECT	slotGen;		/* common */
static GRECT	slotDown;		/* down/common */
static GRECT	slot0;		/* begin, not usable */
static GRECT	slotx;		/* end, not usable */

/*
 * Get corresponding parameter for given gem object.
 */
static struct SInfoParam* PluginInfoGetParam( short obj )
{
	int i;
	
	for( i = 0; i < pluginParamCount; i++ )
	{
		if( pluginParam[i].valueObj == obj )
		{
			return &pluginParam[i];
		}
	}
	
	return NULL;
}

/*
 * Get MXP type (BOOL, INT, CHAR) and value from audio plugin for given gem object.
 * Returns TRUE if ok or FALSE if not found.
 */
static BOOL PluginInfoGetParamType( OBJECT* tree, short obj, short* type, struct SParameter** param )
{
	struct SParameter*		pluginAudioParam;
	struct SInfoParam*	pluginInfoParam;
	char text[256];
	
	if( g_pCurrAudioPlugin != NULL )
	{
		pluginInfoParam = PluginInfoGetParam( obj );
		if( pluginInfoParam != NULL )
		{
			get_string( tree, pluginInfoParam->stringObj, text );
			if( text[strlen( text ) - 1] == ':'  )
			{
				/* if there was a space for colon, remove it */
				text[strlen( text ) - 1] = '\0';
			}
			
			pluginAudioParam = AudioPluginGetParam( g_pCurrAudioPlugin, text );
			if( pluginAudioParam != NULL )
			{
				if( type != NULL )
				{
					*type = pluginAudioParam->type & 0x7fff;
				}
				if( param != NULL )
				{
					*param = pluginAudioParam;
				}
				return TRUE;
			}
		}
	}
	
	return FALSE;
}

/*
 * Get number of plugin-parameters in given plugin
 */
static short PluginInfoGetParamsCount( struct SAudioPlugin* plugin )
{
	struct SParameter*	param = plugin->pSParameter;
	short				count = 0;
	
	while( param->pName != NULL )
	{
		if( ( param->type & MXP_FLG_PLG_PARAM ) != 0 )
		{
			/* plugin parameters only */
			count++;
		}
		param++;
	}

	return count;
}

/*
 * "Clone" given gem object - place at index 'dst' has to be allocated yet.
 */
static BOOL PluginInfoCloneObject( OBJECT* tree, short dst, short src )
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
		
		/* descriptive string */
		length = tree[src].ob_spec.tedinfo->te_txtlen;
		string = (char*)malloc( length );
		if( VerifyAlloc( string ) == FALSE )
		{
			return FALSE;
		}
		tree[dst].ob_spec.tedinfo->te_ptext = string;
		set_string( tree, dst, tree[src].ob_spec.tedinfo->te_ptext );
	}
	else if( get_obtype( tree, dst, NULL ) == G_FTEXT )
	{
		/* new tedinfo */
		tree[dst].ob_spec.tedinfo = (TEDINFO*)malloc( sizeof( TEDINFO ) );
		if( VerifyAlloc( tree[dst].ob_spec.tedinfo ) == FALSE )
		{
			return FALSE;
		}
		memcpy( tree[dst].ob_spec.tedinfo, tree[src].ob_spec.tedinfo, sizeof( TEDINFO ) );
		
		/* text */
		length = tree[src].ob_spec.tedinfo->te_txtlen;

		string = (char*)malloc( length );
		if( VerifyAlloc( string ) == FALSE )
		{
			return FALSE;
		}
		strcpy( string, "" );
		tree[dst].ob_spec.tedinfo->te_ptext = string;
				
		/* template */
		string = (char*)malloc( length );
		if( VerifyAlloc( string ) == FALSE )
		{
			return FALSE;
		}
		memset( string, '_', length - 1 );
		string[length - 1] = '\0';
		tree[dst].ob_spec.tedinfo->te_ptmplt = string;
		
		/* validation */
		string = (char*)malloc( length );
		if( VerifyAlloc( string ) == FALSE )
		{
			return FALSE;
		}
		if( src == PLUGIN_OPT_INT )
		{
			memset( string, '9', length - 1 );
		}
		else
		{
			memset( string, 'X', length - 1 );
		}
		string[length - 1] = '\0';
		tree[dst].ob_spec.tedinfo->te_pvalid = string;
	}
	
	return TRUE;
}

/*
 * Add parameter to the dialog window.
 */
static void PluginInfoAddParam( OBJECT* tree, short obj, short type )
{
	/* every parameter has a description */
	if( PluginInfoCloneObject( tree, obj, PLUGIN_OPT_DESC ) == FALSE )
	{
		return;
	}
	
	obj++;
	
	switch( type )
	{
		case MXP_PAR_TYPE_BOOL:
			tree[PLUGIN_OPT_BOOL].ob_x = tree[obj-1].ob_x + tree[obj-1].ob_width;
			tree[PLUGIN_OPT_BOOL].ob_y = tree[obj-1].ob_y;
			PluginInfoCloneObject( tree, obj, PLUGIN_OPT_BOOL );
		break;
		
		case MXP_PAR_TYPE_INT:
			tree[PLUGIN_OPT_INT].ob_x = tree[obj-1].ob_x + tree[obj-1].ob_width;
			tree[PLUGIN_OPT_INT].ob_y = tree[obj-1].ob_y;
			PluginInfoCloneObject( tree, obj, PLUGIN_OPT_INT );
		break;
		
		case MXP_PAR_TYPE_CHAR:
			tree[PLUGIN_OPT_CHAR].ob_x = tree[obj-1].ob_x + tree[obj-1].ob_width;
			tree[PLUGIN_OPT_CHAR].ob_y = tree[obj-1].ob_y;
			PluginInfoCloneObject( tree, obj, PLUGIN_OPT_CHAR );
		break;
	}
	pluginParam[pluginParamCount].stringObj = obj - 1;
	pluginParam[pluginParamCount].valueObj = obj;
	pluginParam[pluginParamCount].valueType = type;
	pluginParamCount++;
}

/*
 * Common function for parameter adding. At first add all BOOL params,
 * then INT and finally CHAR ones. Add colons after parameter names.
 */
static void PluginInfoAddParams( OBJECT* tree, short freeObj, GRECT* pos, short freeObjs )
{
	struct SParameter* param;
	GRECT	currSlot;
	char	text[255+1];
	int		len;
	int		skip;
	short	editObj = 0;
	
	currSlot = *pos;
	skip = pluginParamCurrent;
	
	/* add checkboxes */
	param = g_pCurrAudioPlugin->pSParameter;
	while( param->pName != NULL && freeObj < freeObjs )
	{
		if( ( param->type & MXP_FLG_PLG_PARAM ) != 0
			&& ( param->type & 0x7fff ) == MXP_PAR_TYPE_BOOL )
		{
			if( skip == 0 )
			{
				/* description */
				len = MIN( 255, strlen( param->pName ) );
				strncpy( text, param->pName, len );
				text[len] = '\0';
				if( strlen( text ) < 255 )
				{
					strcat( text, ":" );
				}
				set_string( tree, PLUGIN_OPT_DESC, text );
				tree[PLUGIN_OPT_DESC].ob_x = currSlot.g_x;
				tree[PLUGIN_OPT_DESC].ob_y = currSlot.g_y;
	
				/* description + parameter */
				PluginInfoAddParam( tree, freeObj, MXP_PAR_TYPE_BOOL );
	
				currSlot.g_y += slotHeight;
				freeObj += 2;
			}
			else
			{
				skip--;
			}
		}
		param++;
	}
	
	/* add integer fields */
	param = g_pCurrAudioPlugin->pSParameter;
	while( param->pName != NULL && freeObj < freeObjs )
	{
		if( ( param->type & MXP_FLG_PLG_PARAM ) != 0
			&& ( param->type & 0x7fff ) == MXP_PAR_TYPE_INT )
		{
			if( skip == 0 )
			{
				/* description */
				len = MIN( 255, strlen( param->pName ) );
				strncpy( text, param->pName, len );
				text[len] = '\0';
				if( strlen( text ) < 255 )
				{
					strcat( text, ":" );
				}
				set_string( tree, PLUGIN_OPT_DESC, text );
				tree[PLUGIN_OPT_DESC].ob_x = currSlot.g_x;
				tree[PLUGIN_OPT_DESC].ob_y = currSlot.g_y;
	
				/* description + parameter */
				PluginInfoAddParam( tree, freeObj, MXP_PAR_TYPE_INT );
				if( editObj == 0 )
				{
					editObj = freeObj;
				}
	
				currSlot.g_y += slotHeight;
				freeObj += 2;
			}
			else
			{
				skip--;
			}
		}
		param++;
	}
	
	/* add string fields */
	param = g_pCurrAudioPlugin->pSParameter;
	while( param->pName != NULL && freeObj < freeObjs )
	{
		if( ( param->type & MXP_FLG_PLG_PARAM ) != 0
			&& ( param->type & 0x7fff ) == MXP_PAR_TYPE_CHAR )
		{
			if( skip == 0 )
			{
				/* description */
				len = MIN( 255, strlen( param->pName ) );
				strncpy( text, param->pName, len );
				text[len] = '\0';
				if( strlen( text ) < 255 )
				{
					strcat( text, ":" );
				}
				set_string( tree, PLUGIN_OPT_DESC, text );
				tree[PLUGIN_OPT_DESC].ob_x = currSlot.g_x;
				tree[PLUGIN_OPT_DESC].ob_y = currSlot.g_y;
	
				/* description + parameter */
				PluginInfoAddParam( tree, freeObj, MXP_PAR_TYPE_CHAR );
				if( editObj == 0 )
				{
					editObj = freeObj;
				}
	
				currSlot.g_y += slotHeight;
				freeObj += 2;
			}
			else
			{
				skip--;
			}
		}
		param++;
	}
	
	g_winDialogs[WD_PLUGIN]->edit_obj = editObj;
	g_winDialogs[WD_PLUGIN]->next_obj = 0;
	g_winDialogs[WD_PLUGIN]->edit_idx = 0;
}

/*
 * Check values of all parameters in dialog - set the corresponding state
 * of gem object and redraw both object and its description.
 */
static void PluginInfoCheckParams( void )
{
	struct SParameter* param;
	long	value;
	int		i;
	short	obj;
	
	for( i = 0; i < pluginParamCount; i++ )
	{
		obj = pluginParam[i].valueObj;
		
		if( PluginInfoGetParamType( g_winDialogs[WD_PLUGIN]->tree, obj, NULL, &param ) == TRUE )
		{
			/* this should always happen */
			AudioPluginGet( g_pCurrAudioPlugin, param, &value );
			if( param->Set == NULL )
			{
				set_state( g_winDialogs[WD_PLUGIN]->tree, obj, OS_DISABLED, TRUE );
			}
			
			switch( pluginParam[i].valueType )
			{
				case MXP_PAR_TYPE_BOOL:
					if( value == TRUE )
					{
						SelectObject( g_winDialogs[WD_PLUGIN], obj );
					}
					else
					{
						DeselectObject( g_winDialogs[WD_PLUGIN], obj );
					}
				break;
				
				case MXP_PAR_TYPE_INT:
					set_long( g_winDialogs[WD_PLUGIN]->tree, obj, value );
					/* last editable object will be selected */
					//change_wdedit( g_winDialogs[WD_PLUGIN], obj );
				break;
				
				case MXP_PAR_TYPE_CHAR:
					set_string( g_winDialogs[WD_PLUGIN]->tree, obj, (char*)value );
					//change_wdedit( g_winDialogs[WD_PLUGIN], obj );
				break;
			}
		}
		
		/* redraw them */
		redraw_wdobj( g_winDialogs[WD_PLUGIN], pluginParam[i].stringObj );
		redraw_wdobj( g_winDialogs[WD_PLUGIN], pluginParam[i].valueObj );
	}
}

/*
 * Set values of all parameters in dialog - set the corresponding value
 * according to gem object.
 */
static void PluginInfoSetParams( void )
{
	struct SParameter* param;
	char	tempString[255+1];
	long	value;
	int		i;
	short	obj;
	
	for( i = 0; i < pluginParamCount; i++ )
	{
		obj = pluginParam[i].valueObj;
		if( PluginInfoGetParamType( g_winDialogs[WD_PLUGIN]->tree, obj, NULL, &param ) == TRUE )
		{
			/* this should always happen */
			if( param->Set != NULL )
			{
				switch( pluginParam[i].valueType )
				{
					case MXP_PAR_TYPE_BOOL:
						value = (long)get_state( g_winDialogs[WD_PLUGIN]->tree, obj, OS_SELECTED );
						AudioPluginSet( g_pCurrAudioPlugin, param, value );
					break;
					
					case MXP_PAR_TYPE_INT:
						value = get_long( g_winDialogs[WD_PLUGIN]->tree, obj );
						AudioPluginSet( g_pCurrAudioPlugin, param, value );
					break;
					
					case MXP_PAR_TYPE_CHAR:
						get_string( g_winDialogs[WD_PLUGIN]->tree, obj, tempString );
						value = (long)tempString;
						AudioPluginSet( g_pCurrAudioPlugin, param, value );
					break;
				}
			}
		}
	}
}

/*
 * Get static informations about plugin.
 */
static void PluginInfoCheckBaseInfo( void )
{
	char*	pluginAuthor;
	char*	pluginVersion;
	char*	replayName;
	char*	replayAuthor;
	char*	replayVersion;
	long	flags = 0;
	OBJECT*	tree;
	
	tree = g_winDialogs[WD_PLUGIN]->tree;

	if( g_pCurrAudioPlugin != NULL )
	{
		AudioPluginGetBaseInfo( g_pCurrAudioPlugin, &pluginAuthor, &pluginVersion, &replayName, &replayAuthor, &replayVersion, &flags );
		set_string( tree, PLUGIN_PLG_AUTHOR, pluginAuthor );
		set_string( tree, PLUGIN_PLG_VERSION, pluginVersion );
		set_string( tree, PLUGIN_REP_NAME, replayName );
		set_string( tree, PLUGIN_REP_AUTHOR, replayAuthor );
		set_string( tree, PLUGIN_REP_VERSION, replayVersion );
	}
	else
	{
		set_string( tree, PLUGIN_PLG_AUTHOR, "n/a" );
		set_string( tree, PLUGIN_PLG_VERSION, "n/a" );
		set_string( tree, PLUGIN_REP_NAME, "n/a" );
		set_string( tree, PLUGIN_REP_AUTHOR, "n/a" );
		set_string( tree, PLUGIN_REP_VERSION, "n/a" );
	}
	
	if( ( flags & MXP_FLG_USE_020 ) != 0 )
	{
		set_string( tree, PLUGIN_CPU020, "Yes" );
	}
	else
	{
		set_string( tree, PLUGIN_CPU020, "No" );
	}
	
	if( ( flags & MXP_FLG_USE_DSP ) != 0 )
	{
		set_string( tree, PLUGIN_DSP, "Yes" );
	}
	else
	{
		set_string( tree, PLUGIN_DSP, "No" );
	}
	
	if( ( flags & MXP_FLG_USE_DMA ) != 0 )
	{
		set_string( tree, PLUGIN_DMA, "Yes" );
	}
	else
	{
		set_string( tree, PLUGIN_DMA, "No" );
	}
	
	if( ( flags & MXP_FLG_USE_FPU ) != 0 )
	{
		set_string( tree, PLUGIN_FPU, "Yes" );
	}
	else
	{
		set_string( tree, PLUGIN_FPU, "No" );
	}
}

/*
 * Delete tree (i.e. copy of our dialog)
 */
static void PluginInfoDestroyTree( OBJECT* tree )
{
	short obj;
	short objects;
	
	origPluginTree[ROOT].ob_x = tree[ROOT].ob_x;
	origPluginTree[ROOT].ob_y = tree[ROOT].ob_y;
	
	obj = GetObjectCount( origPluginTree );	/* number of old objects */
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
		else if( get_obtype( tree, obj, NULL ) == G_FTEXT )
		{
			free( tree[obj].ob_spec.tedinfo->te_ptext );
			tree[obj].ob_spec.tedinfo->te_ptext = NULL;
			free( tree[obj].ob_spec.tedinfo->te_ptmplt );
			tree[obj].ob_spec.tedinfo->te_ptmplt = NULL;
			free( tree[obj].ob_spec.tedinfo->te_pvalid );
			tree[obj].ob_spec.tedinfo->te_pvalid = NULL;
			free( tree[obj].ob_spec.tedinfo );
			tree[obj].ob_spec.tedinfo = NULL;
		}
	}
	
	free( tree );
}

/*
 * Reset the dialog into the default state and (re-)create dialog from scratch.
 */
static void PluginInfoCreateDialog( void )
{
	short	offset = 0;
	short	obj;
	short	params = 0;
	short	freeObj;
	OBJECT*	tree;
	short	objects;
	GRECT	r;
	
	/* reset the tree */
	if( tempPluginTree != NULL )
	{
		g_winDialogs[WD_PLUGIN]->tree = origPluginTree;
		
		PluginInfoDestroyTree( tempPluginTree );
		tempPluginTree = NULL;
		
		free( pluginParam );
		pluginParam = NULL;
		pluginParamCount = 0;
		
		g_winDialogs[WD_PLUGIN]->edit_obj = 0;
		g_winDialogs[WD_PLUGIN]->next_obj = 0;
		g_winDialogs[WD_PLUGIN]->edit_idx = 0;
	}
	
	tree = g_winDialogs[WD_PLUGIN]->tree;
	
	if( g_pCurrAudioPlugin != NULL )
	{
		params = PluginInfoGetParamsCount( g_pCurrAudioPlugin );
		if( params > 0 )
		{
			pluginParam = (struct SInfoParam*)malloc( params * sizeof( struct SInfoParam ) );
			if( VerifyAlloc( pluginParam ) == FALSE )
			{
				return;
			}
			pluginParamCount = 0;
			
			/* allocate space for the new dialog - for each slot two objects - desc and value */
			freeObj = CloneDialog( origPluginTree, &tempPluginTree, MIN( params, slots ) * 2 );
			if( freeObj == -1 )
			{
				return;
			}
	
			tree = tempPluginTree;
			offset = MIN( params, slots ) * slotHeight;

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
			
			if( params <= slots )
			{
				PluginInfoAddParams( tree, freeObj, &slotUp, freeObj + slots * 2 );
			}
			else
			{
				/* up button */
				tree[PLUGIN_OPT_UP].ob_x = slotUp.g_x + slotUp.g_w / 2 - tree[PLUGIN_OPT_UP].ob_width / 2;
				tree[PLUGIN_OPT_UP].ob_y = slotUp.g_y;
				set_flag( tree, PLUGIN_OPT_UP, OF_HIDETREE, FALSE );
				freeObj++;
				
				/* params */
				PluginInfoAddParams( tree, freeObj, &slotGen, freeObj + ( slots - 2 ) * 2 );
				freeObj += ( slots - 2 ) * 2;
				
				/* down button */
				tree[PLUGIN_OPT_DOWN].ob_x = slotDown.g_x + slotDown.g_w / 2 - tree[PLUGIN_OPT_DOWN].ob_width / 2;
				tree[PLUGIN_OPT_DOWN].ob_y = slotDown.g_y;
				set_flag( tree, PLUGIN_OPT_DOWN, OF_HIDETREE, FALSE );
				freeObj++;
			}
		}
		
		g_winDialogs[WD_PLUGIN]->tree = tree;
		
		/* dialog box */
		tree[ROOT].ob_height = origPluginTree[ROOT].ob_height + offset;
		
		/* internal cflib value */
		memcpy( &g_winDialogs[WD_PLUGIN]->work, &tree[ROOT].ob_x, 4 * sizeof( short ) );
		
		wind_calc_grect( WC_BORDER, g_winDialogs[WD_PLUGIN]->win_kind, &g_winDialogs[WD_PLUGIN]->work, &r );
		wind_set_grect( g_winDialogs[WD_PLUGIN]->win_handle, WF_CURRXYWH, &r );
	}
}

/*
 * Init dialog. Place it in the default state (no params), save important values, resize.
 */
void PluginInfoInit( void )
{
	short	obj;
	short	cut;
	OBJECT*	tree;
	short	objects;
	
	origPluginTree = g_winDialogs[WD_PLUGIN]->tree;
	tree = origPluginTree;
	
	slots = 0;
	
	objects = GetObjectCount( tree );
	
	for( obj = 1; obj < objects; obj++ )
	{
		if( get_state( tree, obj, OS_DISABLED ) == TRUE )
		{
			slots++;
		}
	}
	
	objects = GetObjectCount( tree );
	
	/* bounding slots */
	set_flag( tree, PLUGIN_POS_START, OF_HIDETREE, TRUE );
	set_flag( tree, PLUGIN_POS_END, OF_HIDETREE, TRUE );
	memcpy( &slot0.g_x, &tree[PLUGIN_POS_START].ob_x, 4 * sizeof( short ) );
	memcpy( &slotx.g_x, &tree[PLUGIN_POS_END].ob_x, 4 * sizeof( short ) );
	
	for( obj = 1; obj < objects; obj++ )
	{
		/* move up & hide everything between bounding slots */
		if( tree[obj].ob_y >= slot0.g_y && tree[obj].ob_y <= slotx.g_y + slotx.g_h )
		{
			tree[obj].ob_y -= slot0.g_h;
			set_flag( tree, obj, OF_HIDETREE, TRUE );
		}
	}
	
	/* slots for plugin parameters */
	memcpy( &slotUp.g_x, &tree[PLUGIN_POS_FIRST].ob_x, 4 * sizeof( short ) );
	memcpy( &slotGen.g_x, &tree[PLUGIN_POS_GEN].ob_x, 4 * sizeof( short ) );
	memcpy( &slotDown.g_x, &tree[PLUGIN_POS_LAST].ob_x, 4 * sizeof( short ) );

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
	g_winDialogs[WD_PLUGIN]->work.g_h -= cut;
	
	slotHeight = slotGen.g_h + ( slotGen.g_y - ( slotUp.g_y + slotUp.g_h ) );	/* with "border" */
}

/*
 * Dialog reinitialization. Called only by
 * PanelChangeSkin() in panel.c
 */
void PluginInfoReinit( void )
{
	PluginInfoCreateDialog();
	PluginInfoCheckBaseInfo();
	PluginInfoCheckParams();	/* here are params already redrawn but who cares ;-) */
	redraw_wdobj( g_winDialogs[WD_PLUGIN], ROOT );
}

/*
 * Update dialog if neccessary.
 */
void PluginInfoUpdate( void )
{
	if( ( g_winDialogs[WD_PLUGIN]->mode & WD_OPEN ) == 0 ) 
	{
		return;
	}
	else if( g_pCurrAudioPlugin == NULL )
	{
		/* currently used only for open dialog before any module is played */
		PluginInfoCheckBaseInfo();
		redraw_wdobj( g_winDialogs[WD_PLUGIN], ROOT );
		return;
	}
	else if( g_pCurrAudioPlugin == pOldAudioPlugin )
	{
		PluginInfoCheckParams();	/* some parameters could be changed */
		return;
	}
	else
	{
		pOldAudioPlugin = g_pCurrAudioPlugin;
		pluginParamCurrent = 0;	/* show first param */
		PluginInfoCreateDialog();
		PluginInfoCheckBaseInfo();
		PluginInfoCheckParams();	/* here are params already redrawn but who cares ;-) */
		redraw_wdobj( g_winDialogs[WD_PLUGIN], ROOT );	/* dialog could expand */
	}
}

/*
 * Callback function for up/down/param button press.
 */
void PluginInfoButton( short obj )
{
	struct SParameter* param;
	short	type;
	long	value;
	short	params;
	
	if( g_pCurrAudioPlugin != NULL )
	{
		params = PluginInfoGetParamsCount( g_pCurrAudioPlugin );
		
		switch( obj )
		{
			case PLUGIN_OPT_UP:
				DeselectObject( g_winDialogs[WD_PLUGIN], obj );
				
				if( pluginParamCurrent > 0 )
				{
					pluginParamCurrent--;
					PluginInfoCreateDialog();
					PluginInfoCheckParams();
					redraw_wdobj( g_winDialogs[WD_PLUGIN], ROOT );	// TODO: solution?
				}
			break;
			
			case PLUGIN_OPT_DOWN:
				DeselectObject( g_winDialogs[WD_PLUGIN], obj );
				
				if( pluginParamCurrent < params - 1 )
				{
					pluginParamCurrent++;
					PluginInfoCreateDialog();
					PluginInfoCheckParams();
					redraw_wdobj( g_winDialogs[WD_PLUGIN], ROOT );
				}
			break;
			
			case PLUGIN_OK:
				PluginInfoSetParams();
			break;
			
			default:
				if( PluginInfoGetParamType( g_winDialogs[WD_PLUGIN]->tree, obj, &type, &param ) == TRUE )
				{
					AudioPluginGet( g_pCurrAudioPlugin, param, &value );
					if( param->Set != NULL )
					{
						switch( type )
						{
							case MXP_PAR_TYPE_BOOL:
								if( value == TRUE )
								{
									DeselectObject( g_winDialogs[WD_PLUGIN], obj );
									AudioPluginSet( g_pCurrAudioPlugin, param, FALSE );
								}
								else
								{
									SelectObject( g_winDialogs[WD_PLUGIN], obj );
									AudioPluginSet( g_pCurrAudioPlugin, param, TRUE );
								}
							break;
							
							case MXP_PAR_TYPE_INT:
								change_wdedit( g_winDialogs[WD_PLUGIN], obj );
							break;
							
							case MXP_PAR_TYPE_CHAR:
								change_wdedit( g_winDialogs[WD_PLUGIN], obj );
							break;
						}
					}
				}
			break;
		}
	}
}
