#include <cflib.h>
#include <sys/param.h>	/* MIN */

#include "filelist.h"
#include "skins/skin.h"
#include "misc.h"
#include "playlist.h"
#include "mxplay.h"
#include "dialogs.h"
#include "panel.h"
#include "file_select.h"
#include "info_dialogs.h"

char*	g_currName = NULL;
char*	g_currPath = NULL;
BOOL	g_playAfterAdd = FALSE;
BOOL	g_emptyPlayList = TRUE;
BOOL	g_playlistNotActual = TRUE;

static struct SPlayListWindowEntry	SPlWindowEntry[PL_WINDOW_ENTRIES_MAX];
static int							plWindowEntries = 0;
static int							plAbove;	/* number of files "above" playlist */

static short						currFileColor;
static short						normFileColor;

static short origWidth;		/* original width & height */
static short origHeight;	/* (as stored in rsc file) */

static OBJECT*	tempPlayListTree = NULL;
static OBJECT*	origPlayListTree;

/*
 * Set & redraw number of tracks.
 */
static void PlayListDisplayTracksCount( void )
{
	set_long( g_winDialogs[WD_PLAYLIST]->tree, PLAYLIST_TRACKS, g_filesCount );
	redraw_wdobj( g_winDialogs[WD_PLAYLIST], PLAYLIST_TRACKS );
}

/*
 * Get default colors
 */
static void PlayListGetColors( void )
{
	TEDINFO*	pTed;
	short		obj;
	OBJECT*		tree;
	short		objects;
	
	/*typedef struct objc_colorword 
	 *{
	 *	unsigned	borderc : 4;
	 *	unsigned	textc   : 4;
	 *	unsigned	opaque  : 1;
	 *	unsigned	pattern : 3;
	 *	unsigned	fillc   : 4;
	 *} OBJC_COLORWORD;
	 */
	 
	tree = g_winDialogs[WD_PLAYLIST]->tree;
	
	pTed = (TEDINFO*)get_obspec( tree, PLAYLIST_TEXT1 );
	currFileColor = pTed->te_color;	/* first line represents color for current file */

	pTed = (TEDINFO*)get_obspec( tree, PLAYLIST_TEXT2 );
	normFileColor = pTed->te_color;	/* second line represents color for "normal" file */
	
	/* all playlist entries as normal color */
	objects = GetObjectCount( tree );
	
	for( obj = 1; obj < objects; obj++ )
	{
		/* check text objects which are selectable i.e. our entries */
		if( tree[obj].ob_type == G_TEXT && get_flag( tree, obj, OF_SELECTABLE ) == TRUE )
		{
			pTed = (TEDINFO*)get_obspec( tree, obj );
			pTed->te_color = normFileColor;	/* back normal color */
		}
	}
}

/*
 * Set slider according to size of playist window
 * and number of files in filelist
 */
static void PlayListSliderSet( void )
{
	short size;
	short pos;
	short old;
	short dummy;
	
	if( g_filesCount != 0 )
	{
		size = MIN( 1000, Round( 1000.0 * (float)plWindowEntries / (float)g_filesCount ) );
		if( size <= 0 )
		{
			size = 1;
		}
		
		pos = Round( ( 1000.0 * plAbove ) / (float)( g_filesCount - plWindowEntries ) );
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
	
	wind_get( g_winDialogs[WD_PLAYLIST]->win_handle, WF_VSLSIZE, &old, &dummy, &dummy, &dummy );
	if( old != size )
	{
		wind_set( g_winDialogs[WD_PLAYLIST]->win_handle, WF_VSLSIZE, size, 0, 0, 0 );
	}
	
	wind_get( g_winDialogs[WD_PLAYLIST]->win_handle, WF_VSLIDE, &old, &dummy, &dummy, &dummy );
	if( old != pos )
	{
		wind_set( g_winDialogs[WD_PLAYLIST]->win_handle, WF_VSLIDE, pos, 0, 0, 0 );
	}
}

/*
 * Remove all playlist entries
 */
static void PlayListClear( void )
{
	int		i;
	
	for( i = 0; i < PL_WINDOW_ENTRIES_MAX; i++ )
	{
		SPlWindowEntry[i].obj = -1;
		SPlWindowEntry[i].fileNumber = -1;
	}
	
	g_emptyPlayList = TRUE;
	plAbove = 0;
}

/*
 * Return file number (identifier) for obj on input
 * for the entry in the playlist window
 */
static int PlayListGetFileNumber( short obj )
{
	int i;
	
	for( i = 0; i < plWindowEntries; i++ )
	{
		if( SPlWindowEntry[i].obj == obj )
		{
			return SPlWindowEntry[i].fileNumber;
		}
	}
	
	return -1;
}

/*
 * Deselect all entries (in file struct)
 */
static void PlayListDeselectAllEntries( void )
{
	struct SFileListFile* pSFile;
	
	pSFile = FileListGetFirstEntry();
	
	while( pSFile != NULL )
	{
		pSFile->selected = FALSE;
		pSFile->current = FALSE;
		
		pSFile = pSFile->pSNext;
	}
}

/*
 * Select all entries (in file struct)
 */
static void PlayListSelectAllEntries( void )
{
	struct SFileListFile* pSFile;
	
	pSFile = FileListGetFirstEntry();
	
	while( pSFile != NULL )
	{
		pSFile->selected = TRUE;
		
		pSFile = pSFile->pSNext;
	}
}

/*
 * Inverse all entries (in file struct)
 */
static void PlayListInverseAllEntries( void )
{
	struct SFileListFile* pSFile;
	
	pSFile = FileListGetFirstEntry();
	
	while( pSFile != NULL )
	{
		pSFile->selected = !pSFile->selected;
		
		pSFile = pSFile->pSNext;
	}
}

/*
 * Update entry in the playlist window.
 */
static void PlayListUpdateEntry( struct SFileListFile* pSFile, short obj )
{
	TEDINFO* pTed;

	set_string( g_winDialogs[WD_PLAYLIST]->tree, obj, pSFile->name );
	pTed = (TEDINFO*)get_obspec( g_winDialogs[WD_PLAYLIST]->tree, obj );
	PadString( pTed->te_ptext, pTed->te_txtlen - 1 );
	
	if( pSFile->current == TRUE )
	{
		pTed->te_color = currFileColor;
	}
	else
	{
		pTed->te_color = normFileColor;
	}
	
	set_state( g_winDialogs[WD_PLAYLIST]->tree, obj, OS_SELECTED, pSFile->selected );
	set_state( g_winDialogs[WD_PLAYLIST]->tree, obj, OS_DISABLED, pSFile->disabled );
}

/*
 * Common function for scrolling the list down
 */
static void PlayListDownCommon( int count )
{
	struct SFileListFile* pSFile;
	int fix = 0;
	
	/* scroll only if full playlist window */
	if( SPlWindowEntry[plWindowEntries - 1].fileNumber != -1 )
	{
		pSFile = FileListGetEntry( SPlWindowEntry[plWindowEntries - 1].fileNumber );
		/* only if there's something to scroll */
		if( pSFile != NULL && pSFile->pSNext != NULL )
		{
			plAbove += count;
			
			if( plWindowEntries + plAbove > g_filesCount )
			{
				fix = g_filesCount - plWindowEntries - plAbove;
			}
			plAbove += fix;
			count += fix;
			
			if( count > 0 )
			{
				pSFile = FileListGetEntry( SPlWindowEntry[0].fileNumber );
				while( count-- > 0 )
				{
					pSFile = pSFile->pSNext;
				}
				SPlWindowEntry[0].fileNumber = pSFile->number;	/* this is everything we need */
								
				PlayListRefresh( TRUE );
			}
		}
	}
}

/*
 * Common function for scrolling the list up
 */
static void PlayListUpCommon( int count )
{
	struct SFileListFile* pSFile;
	
	/* scroll only if full playlist window */
	if( plAbove > 0 )
	{
		pSFile = FileListGetEntry( SPlWindowEntry[0].fileNumber );
		/* only if there's something to scroll */
		if( pSFile != NULL && pSFile->pSPrev != NULL )
		{
			plAbove -= count;
			
			if( plAbove < 0 )
			{
				count += plAbove;
				plAbove = 0;
			}
			
			if( count > 0 )
			{
				while( count-- > 0 )
				{
					pSFile = pSFile->pSPrev;
				}
				SPlWindowEntry[0].fileNumber = pSFile->number;	/* this is everything we need */
				
				PlayListRefresh( TRUE );
			}
		}
	}
}

/*
 * Count all text & selectable fields - i.e. our window entries
 * and fill save gem object numbers for every entry.
 */
static void PlayListSetPlWindowEntries( void )
{
	OBJECT*	tree;
	short	objects;
	short	obj;
	
	tree = g_winDialogs[WD_PLAYLIST]->tree;
	objects = GetObjectCount( tree );

	plWindowEntries = 0;

	/* we need to traverse whole dialog to find playlist entries */
	for( obj = 1; obj < objects; obj++ )
	{
		/* check text objects which are selectable i.e. our entries */
		if( tree[obj].ob_type == G_TEXT && get_flag( tree, obj, OF_SELECTABLE ) == TRUE )
		{
			SPlWindowEntry[plWindowEntries++].obj = obj;
		}
	}
}

/*
 * Delete tree (i.e. copy of our dialog)
 */
static void PlayListDestroyTree( OBJECT* tree )
{
	short obj;
	short objects;

	origPlayListTree[ROOT].ob_x = tree[ROOT].ob_x;
	origPlayListTree[ROOT].ob_y = tree[ROOT].ob_y;

	objects = GetObjectCount( tree );	/* number of old+new objects */

	/* we do it for all text entries since we allocated every te_ptext */
	for( obj = 1; obj < objects; obj++ )
	{
		/* check text objects which are selectable i.e. our entries */
		if( tree[obj].ob_type == G_TEXT && get_flag( tree, obj, OF_SELECTABLE ) == TRUE )
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
 * (Re-)create dialog - resize text fields etc.
 */
static void PlayListCreateDialog( void )
{
	OBJECT*		tree;
	TEDINFO*	pTed;
	short		oldTextFields = 0;
	short		newTextFields;
	short		newTextSize;
	short		obj;
	short		oldObjects;
	short		newObjects;
	char*		string;
	short		fontSize;
	short		y;
	short		lastTextObj = -1;
	
	tree = g_winDialogs[WD_PLAYLIST]->tree;
	
	oldObjects = GetObjectCount( tree );
	
	/* we need to traverse whole dialog to find playlist entries */
	for( obj = 1; obj < oldObjects; obj++ )
	{
		/* check text objects which are selectable i.e. our entries */
		if( tree[obj].ob_type == G_TEXT && get_flag( tree, obj, OF_SELECTABLE ) == TRUE )
		{
			oldTextFields++;
			lastTextObj = obj;
		}
	}
	
	newTextFields = tree[PLAYLIST_BACKGROUND].ob_height / tree[PLAYLIST_TEXT2].ob_height;
	
	/* there's no chance there will be fewer new entries than old ones */
	newObjects = oldObjects - oldTextFields + newTextFields;
	
	tempPlayListTree = (OBJECT*)malloc( newObjects * sizeof( OBJECT ) );
	if( VerifyAlloc( tempPlayListTree ) == FALSE )
	{
		return;
	}
	
	/* old objects */
	memcpy( tempPlayListTree, tree, oldObjects * sizeof( OBJECT ) );
	set_flag( tempPlayListTree, oldObjects - 1, OF_LASTOB, FALSE );

	/* new objects (text fields) */
	y = tree[lastTextObj].ob_y + tree[lastTextObj].ob_height;
	
	for( obj = oldObjects; obj < newObjects; obj++ )
	{
		memcpy( &tempPlayListTree[obj], &tree[PLAYLIST_TEXT2], sizeof( OBJECT ) );
		tempPlayListTree[obj].ob_y = y;
		
		tempPlayListTree[obj].ob_head = -1;	/* no childrens */
		tempPlayListTree[obj].ob_next = 0;
		tempPlayListTree[obj].ob_tail = -1;	/* no childrens */
		objc_add( tempPlayListTree, PLAYLIST_BACKGROUND, obj );
		
		/* this fix the situation TEXT2 objects is currently selected */
		pTed = (TEDINFO*)get_obspec( tempPlayListTree, obj );
		pTed->te_color = normFileColor;
		
		y += tree[PLAYLIST_TEXT2].ob_height;
	}
	set_flag( tempPlayListTree, newObjects - 1, OF_LASTOB, TRUE );

	tree = tempPlayListTree;
	
	pTed = tree[PLAYLIST_TEXT2].ob_spec.tedinfo;	/* every text field must have the same size */
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
	newTextSize = tree[PLAYLIST_BACKGROUND].ob_width / fontSize + 1;	/* incl. '\0' */
		
	/* allocate new tedinfo + te_ptext for every text field */
	for( obj = 1; obj < newObjects; obj++ )
	{
		if( tree[obj].ob_type == G_TEXT && get_flag( tree, obj, OF_SELECTABLE ) == TRUE )
		{
			/* new width */
			tree[obj].ob_width = tree[PLAYLIST_BACKGROUND].ob_width;	/* set new width */
			
			/* new tedinfo */
			tree[obj].ob_spec.tedinfo = (TEDINFO*)malloc( sizeof( TEDINFO ) );
			if( VerifyAlloc( tree[obj].ob_spec.tedinfo ) == FALSE )
			{
				return;
			}
			memcpy( tree[obj].ob_spec.tedinfo, pTed, sizeof( TEDINFO ) );	/* use TEXT2 attributes */
		
			/* new te_ptext */
			string = (char*)malloc( newTextSize );
			if( VerifyAlloc( string ) == FALSE )
			{
				return;
			}
			tree[obj].ob_spec.tedinfo->te_ptext = string;
			tree[obj].ob_spec.tedinfo->te_txtlen = newTextSize;
			set_string( tree, obj, "" );
		}
	}
	
	g_winDialogs[WD_PLAYLIST]->tree = tree;
}

static void PlayListResizeNested( OBJECT* tree, short root, short dx, short dy )
{
	short obj;
	
	if( tree[root].ob_head != -1 )
	{
		PlayListResizeNested( tree, tree[root].ob_head, dx, dy );
	
		if( dx != 0 )
		{
			obj = tree[root].ob_head;
			while( obj != tree[root].ob_tail )
			{
				tree[obj].ob_width += dx;
				obj = tree[obj].ob_next;
			}
			tree[obj].ob_width += dx;
		}
		
		if( dy != 0 )
		{
			obj = tree[root].ob_head;
			while( obj != tree[root].ob_tail )
			{
				tree[obj].ob_height += dy;
				obj = tree[obj].ob_next;
			}
			tree[obj].ob_height += dy;
		}
	}
}

/*
 * Change size and/or position of playlist's objects.
 */
static void PlayListResizeObjects( short deltaX, short deltaY )
{
	OBJECT*	tree;
	short	objects;
	short	obj;
	short	rightBound;
	short	bottomBound;
	
	tree = g_winDialogs[WD_PLAYLIST]->tree;
	
	objects = GetObjectCount( tree );
	
	/* Change object's coordinate according to BACKGROUND box.
	 * For nested elements it works too since their relative coordinate is
	 * always smaller than values they compare to.
	 */
	
	if( deltaX != 0 )
	{
		tree[ROOT].ob_width += deltaX;
	
		rightBound = tree[PLAYLIST_BACKGROUND].ob_x + tree[PLAYLIST_BACKGROUND].ob_width;
		
		for( obj = 1; obj < objects; obj++ )
		{
			if( tree[obj].ob_x > rightBound )
			{
				tree[obj].ob_x += deltaX;
			}
		}
		
		if( tree[PLAYLIST_BOX_UP].ob_head != -1 )
		{
			PlayListResizeNested( tree, PLAYLIST_BOX_UP, deltaX, 0 );
		}
		tree[PLAYLIST_BOX_UP].ob_width += deltaX;
		
		if( tree[PLAYLIST_BOX_DOWN].ob_head != -1 )
		{
			PlayListResizeNested( tree, PLAYLIST_BOX_DOWN, deltaX, 0 );
		}
		tree[PLAYLIST_BOX_DOWN].ob_width += deltaX;
		
		tree[PLAYLIST_BACKGROUND].ob_width += deltaX;
	}
	
	if( deltaY != 0 )
	{
		tree[ROOT].ob_height += deltaY;
		
		bottomBound = tree[PLAYLIST_BACKGROUND].ob_y + tree[PLAYLIST_BACKGROUND].ob_height;
		
		for( obj = 1; obj < objects; obj++ )
		{
			if( tree[obj].ob_y > bottomBound )
			{
				tree[obj].ob_y += deltaY;
			}
		}

		if( tree[PLAYLIST_BOX_LEFT].ob_head != -1 )
		{
			PlayListResizeNested( tree, PLAYLIST_BOX_LEFT, 0, deltaY );
		}
		tree[PLAYLIST_BOX_LEFT].ob_height += deltaY;
		
		if( tree[PLAYLIST_BOX_RIGHT].ob_head != -1 )
		{
			PlayListResizeNested( tree, PLAYLIST_BOX_RIGHT, 0, deltaY );
		}
		tree[PLAYLIST_BOX_RIGHT].ob_height += deltaY;

		tree[PLAYLIST_BACKGROUND].ob_height += deltaY;
	}
}

/*
 * Refresh all playlist entries. You need to set plWindowEntries,
 * first file number and to have all [entry].obj-s actual.
 */
void PlayListRefresh( BOOL redraw )
{
	struct SFileListFile* pSFile;
	int		i;
	OBJECT*	tree;
	
	tree = g_winDialogs[WD_PLAYLIST]->tree;
	
	/* first entry in the window */
	if( SPlWindowEntry[0].fileNumber != -1 )
	{
		pSFile = FileListGetEntry( SPlWindowEntry[0].fileNumber );
	}
	else
	{
		/* this happens when we have empty playlist */
		pSFile = NULL;
	}
	
	for( i = 0; i < plWindowEntries; i++ )
	{
		/* there could be a situation playlist is initialized and it's not full */
		if( pSFile != NULL )
		{
			SPlWindowEntry[i].fileNumber = pSFile->number;
			PlayListUpdateEntry( pSFile, SPlWindowEntry[i].obj );
			pSFile = pSFile->pSNext;
		}
		else
		{
			SPlWindowEntry[i].fileNumber = -1;
			
			/* if not used, set as empty string */
			set_string( tree, SPlWindowEntry[i].obj, "" );
			/* for sure */
			set_state( tree, SPlWindowEntry[i].obj, OS_SELECTED, FALSE );
		}
		
		if( redraw == TRUE )
		{
			redraw_wdobj( g_winDialogs[WD_PLAYLIST], SPlWindowEntry[i].obj );
		}
	}

	PlayListSliderSet();
}

/*
 * Display current number of tracks.
 */
void PlayListDisplayTrackNumber( void )
{
	long fileNumber;
	
	fileNumber = FileListGetFileNumber( NULL );
	if( fileNumber != -1 )
	{
		set_long( g_winDialogs[WD_PLAYLIST]->tree, PLAYLIST_TRACK_NUMBER, fileNumber );
	}
	else
	{
		set_string( g_winDialogs[WD_PLAYLIST]->tree, PLAYLIST_TRACK_NUMBER, "-" );
	}
	redraw_wdobj( g_winDialogs[WD_PLAYLIST], PLAYLIST_TRACK_NUMBER );
}

/*
 * Set current file in the playlist. Must be called with
 * FileListSetCurrFile()
 */
void PlayListSetCurrFile( struct SFileListFile* pSFile )
{
	PlayListDeselectAllEntries();
	
	/* only if filelist operation was successfull */
	if( g_currPath != NULL && g_currName != NULL )
	{
		pSFile->current = TRUE;
		pSFile->disabled = FALSE;
	}
	else
	{
		pSFile->disabled = TRUE;
	}
	
	PlayListRefresh( TRUE );
}

/*
 * Update playlist after file was added to the
 * filelist. Slider is updated, too.
 */
void PlayListUpdate( struct SFileListFile* pSFile )
{
	int	i;
	
	g_emptyPlayList = FALSE;
	g_playlistNotActual = TRUE;
	
	for( i = 0; i < plWindowEntries; i++ )
	{
		if( SPlWindowEntry[i].fileNumber == -1 )
		{
			SPlWindowEntry[i].fileNumber = pSFile->number;
			
			/* possible == -1 ? */
			if( SPlWindowEntry[i].obj != -1 )
			{
				PlayListUpdateEntry( pSFile, SPlWindowEntry[i].obj );
				redraw_wdobj( g_winDialogs[WD_PLAYLIST], SPlWindowEntry[i].obj );
			}
			
			break;
		}
	}
	
	PlayListDisplayTracksCount();
	PlayListSliderSet();
}

/*
 * Playlist initialization. Called only once in
 * InitRsc() in dialogs.c
 */
void PlayListInit( void )
{
	origPlayListTree = g_winDialogs[WD_PLAYLIST]->tree;
	
	origWidth = origPlayListTree[ROOT].ob_width;	/* equivalent to work.g_w (which is could be still empty) */
	origHeight = origPlayListTree[ROOT].ob_height;	/* equivalent to work.g_h */
	
	set_string( g_winDialogs[WD_PLAYLIST]->tree, PLAYLIST_TRACK_NUMBER, "-" );
	set_string( g_winDialogs[WD_PLAYLIST]->tree, PLAYLIST_TRACKS, "0" );
		
	PlayListClear();
	PlayListGetColors();
	PlayListSetPlWindowEntries();
}

/*
 * Playlist reinitialization. Called only by
 * PanelChangeSkin() in panel.c.
 */
void PlayListReinit( void )
{
	struct SFileListFile* pSFile;
	
	origPlayListTree = g_winDialogs[WD_PLAYLIST]->tree;
	origWidth = origPlayListTree[ROOT].ob_width;	/* equivalent to work.g_w (which is could be still empty) */
	origHeight = origPlayListTree[ROOT].ob_height;	/* equivalent to work.g_h */

	if( tempPlayListTree != NULL )
	{
		PlayListDestroyTree( tempPlayListTree );
		tempPlayListTree = NULL;
	}
	
	PlayListGetColors();
	PlayListSetPlWindowEntries();
	
	plAbove = 0;
	
	pSFile = FileListGetFirstEntry();
	if( pSFile != NULL )
	{
		SPlWindowEntry[0].fileNumber = pSFile->number;
	}
	else
	{
		SPlWindowEntry[0].fileNumber = -1;
	}
	
	PlayListDisplayTracksCount();
	PlayListDisplayTrackNumber();
	
	PlayListRefresh( TRUE );	/* refresh with correct values */
}

/*
 * Add the file/directory to the filelist
 * (playlist update is done from there, too)
 */
BOOL PlayListAdd( char* path, char* name )
{
	BOOL ret;
	
	if( strstr( name, ".m3u" ) != NULL || strstr( name, ".M3U" ) != NULL )
	{
		/* playlist on the way! */
		CombinePath( g_playlistFile, path, name );
		return PlayListLoadFromFile( g_playlistFile );
	}
	else
	{
		if( strcmp( name, "" ) == 0 || IsDirectory( path, name ) == TRUE )
		{
			ret = FileListAddDirectory( path, name );
			return ret;
		}
		else
		{
			ret = FileListAddFile( path, name );
			return ret;
		}
	}
}

/*
 * Load the filelist from the file
 * (playlist is updated automatically)
 */
BOOL PlayListLoadFromFile( char* filename )
{
	FILE*					pFileStream = NULL;
	struct SFileListFile*	pSFile;
	char					tempPath[PATH_MAX+1];
	char					path[PATH_MAX+1];
	char					name[FILENAME_MAX+1];
	
	pFileStream = fopen( filename, "r" );
	if( pFileStream == NULL )
	{
		split_filename( filename, path, name );
		ShowLoadErrorDialog( name );
		return FALSE;
	}
	else
	{
		/* delete file- and playlist */
		pSFile = FileListGetFirstEntry();
		FileListClear( pSFile );
		PlayListClear();
		PlayListSetPlWindowEntries();	/* for PlayListUpdate() */
		
		g_playAfterAdd = FALSE;
		g_currFileUpdated = FALSE;	/* reset flag */
		
		while( fgets( tempPath, PATH_MAX+1, pFileStream ) != NULL )
		{
			tempPath[strlen( tempPath ) - 1] = '\0';	/* ignore newline char */
			split_filename( tempPath, path, name );
			FileListAddFile( path, name );
		}
		
		fclose( pFileStream );
		
		g_playlistNotActual = FALSE;
		PlayListRefresh( TRUE );
		
		return TRUE;
	}
}

/*
 * Traverse filelist and save the filenames
 * in M3U format (complete paths)
 */
BOOL PlayListSaveToFile( char* filename )
{
	FILE*					pFileStream;
	struct SFileListFile*	pSFile;
	char					tempPath[PATH_MAX+1];

	pFileStream = fopen( filename, "w" );
	if( pFileStream == NULL )
	{
		split_filename( filename, NULL, tempPath );
		ShowLoadErrorDialog( tempPath );
		return FALSE;
	}
	else
	{
		pSFile = FileListGetFirstEntry();
		while( pSFile != NULL )
		{
			CombinePath( tempPath, pSFile->path, pSFile->name );
			fprintf( pFileStream, "%s\n", tempPath );
			
			pSFile = pSFile->pSNext;
		}
		
		fclose( pFileStream );
		
		g_playlistNotActual = FALSE;
		return TRUE;
	}
	
	return TRUE;
}

/*
 * Functions for each object (cicon)
 */
 
void PlayListSlider( short deltaY )
{
	short oldDeltaY;
	float delta;
	short value;
	short dummy;
	
	wind_get( g_winDialogs[WD_PLAYLIST]->win_handle, WF_VSLIDE, &oldDeltaY, &dummy, &dummy, &dummy );

	delta = ( deltaY - oldDeltaY ) * ( (float)( g_filesCount - plWindowEntries ) / 1000.0 );
	value = Round( delta );
	
	if( value > 0 )
	{
		PlayListDownCommon( value );
	}
	else if( value < 0 )
	{
		PlayListUpCommon( -value );
	}
}

void PlayListLoad( void )
{
	char path[PATH_MAX+1] = "";
	char name[FILENAME_MAX+1] = "";
	
	SelectObject( g_winDialogs[WD_PLAYLIST], PLAYLIST_LOAD );
	
	strcpy( path, g_homePath );	/* $HOME as default */
	split_filename( g_playlistFile, NULL, name );	/* current playlist */
	
	if( select_file( path, name, "*.M3U", "Select playlist", CB_PlayListFileSelect ) == TRUE )
	{
		/* Classic fileselector protocol? */
		if( strcmp( name, "" ) != 0 && strcmp( path, "" ) != 0 )
		{
			CombinePath( g_playlistFile, path, name );
		}
		
		PlayListLoadFromFile( g_playlistFile );
	}
	
	DeselectObject( g_winDialogs[WD_PLAYLIST], PLAYLIST_LOAD );
}

void PlayListSave( void )
{
	char path[PATH_MAX+1] = "";
	char name[FILENAME_MAX+1] = "";

	SelectObject( g_winDialogs[WD_PLAYLIST], PLAYLIST_SAVE );
	
	strcpy( path, g_homePath );	/* $HOME as default */
	split_filename( g_playlistFile, NULL, name );	/* current playlist */
	
	if( select_file( path, name, "*.M3U", "Select playlist", CB_PlayListFileSelect ) == TRUE )
	{
		/* Classic fileselector protocol? */
		if( strcmp( name, "" ) != 0 && strcmp( path, "" ) != 0 )
		{
			CombinePath( g_playlistFile, path, name );
		}
		
		if( strstr( g_playlistFile, ".m3u" ) == NULL && strstr( g_playlistFile, ".M3U" ) == NULL )
		{
			strcat( g_playlistFile, ".M3U" );
		}
		
		if( file_exists( g_playlistFile ) == FALSE
			|| ( file_exists( g_playlistFile ) == TRUE && ShowOverwriteFileDialog() == 1 ) )
		{
			PlayListSaveToFile( g_playlistFile );
		}
		else
		{
			PlayListSave();
		}
	}
	
	DeselectObject( g_winDialogs[WD_PLAYLIST], PLAYLIST_SAVE );
}

void PlayListAddFile( void )
{
	SharedFileOpen( g_winDialogs[WD_PLAYLIST], PLAYLIST_ADD_FILE );
}

void PlayListAddDir( void )
{
	SharedDirOpen( g_winDialogs[WD_PLAYLIST], PLAYLIST_ADD_DIR );
}

void PlayListSelectAll( void )
{
	SelectObject( g_winDialogs[WD_PLAYLIST], PLAYLIST_SELECT_ALL );
	
	if( g_withShift ==TRUE )
	{
		PlayListInverseAllEntries();
	}
	else
	{
		PlayListSelectAllEntries();
	}
	
	PlayListRefresh( TRUE );
	DeselectObject( g_winDialogs[WD_PLAYLIST], PLAYLIST_SELECT_ALL );
}

void PlayListRemove( void )
{
	struct SFileListFile* pSFile;
	
	SelectObject( g_winDialogs[WD_PLAYLIST], PLAYLIST_REMOVE );
	
	pSFile = FileListGetFirstEntry();
	
	while( pSFile != NULL )
	{
		if( pSFile->selected == TRUE )
		{
			pSFile = FileListRemove( pSFile );
			g_playlistNotActual = TRUE;
		}
		else
		{
			pSFile = pSFile->pSNext;
		}
	}
	
	/* reinit */
	PlayListClear();	/* this clears not only filenumbers but gem objects, too */
	PlayListSetPlWindowEntries();	/* so we have to set them again... */
	PlayListRefresh( FALSE );
	
	pSFile = FileListGetFirstEntry();
	
	/* refill */
	while( pSFile != NULL )
	{
		PlayListUpdate( pSFile );
		
		pSFile = pSFile->pSNext;
	}
	
	PlayListDisplayTrackNumber();
	PlayListDisplayTracksCount();
	
	PlayListRefresh( TRUE );
	
	DeselectObject( g_winDialogs[WD_PLAYLIST], PLAYLIST_REMOVE );
}

void PlayListResize( GRECT* pNewR )
{
	struct SFileListFile* pSFile;
	int		count;
	short	deltaX;
	short	deltaY;
	short	objWidth;
	short	objHeight;
	int		oldPlWindowEntries;
	GRECT	oldR;
	GRECT	tempR;
	
	/* get area of old window */
	wind_get_grect( g_winDialogs[WD_PLAYLIST]->win_handle, WF_CURRXYWH, &oldR );
	
	objWidth = g_winDialogs[WD_PLAYLIST]->tree[ROOT].ob_width;
	objHeight = g_winDialogs[WD_PLAYLIST]->tree[ROOT].ob_height;
	
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

	/* this MUST be done before resize! */
	if( tempPlayListTree != NULL )
	{
		g_winDialogs[WD_PLAYLIST]->tree = origPlayListTree;
		
		PlayListDestroyTree( tempPlayListTree );
		tempPlayListTree = NULL;
	}
	
	PlayListResizeObjects( deltaX, deltaY );
	
	PlayListCreateDialog();
	
	oldPlWindowEntries = plWindowEntries;
	
	PlayListSetPlWindowEntries();
	
	if( SPlWindowEntry[0].fileNumber != -1 && plAbove + oldPlWindowEntries == g_filesCount )
	{
		pSFile = FileListGetEntry( SPlWindowEntry[0].fileNumber );
		count = MIN( plAbove, plWindowEntries - oldPlWindowEntries );
		
		while( count-- > 0 )
		{
			pSFile = pSFile->pSPrev;	/* no chance we'll get NULL */
			plAbove--;
		}
		
		SPlWindowEntry[0].fileNumber = pSFile->number;
	}
	
	PlayListRefresh( FALSE );
	
	wind_set_grect( g_winDialogs[WD_PLAYLIST]->win_handle, WF_CURRXYWH, &tempR );
	wind_calc_grect( WC_WORK, g_winDialogs[WD_PLAYLIST]->win_kind, &tempR, &g_winDialogs[WD_PLAYLIST]->work );

	redraw_wdobj( g_winDialogs[WD_PLAYLIST], ROOT );
}

void PlayListScroll( short direction )
{
	switch( direction )
	{
		case WA_UPPAGE:
			PlayListUpCommon( plWindowEntries );
		break;
		
		case WA_UPLINE:
			PlayListUpCommon( 1 );
		break;
		
		case WA_DNPAGE:
			PlayListDownCommon( plWindowEntries );
		break;
		
		case WA_DNLINE:
			PlayListDownCommon( 1 );
		break;
	}
}

void PlayListSelectFile( short obj )
{
	struct SFileListFile*	pSFile;
	long					fileNumber;
	
	/* there's no chance we click on file which isn't in the window :) */
	fileNumber = PlayListGetFileNumber( obj );
	if( fileNumber == -1 )
	{
		/* empty -> just deselect */
		DeselectObject( g_winDialogs[WD_PLAYLIST], obj );
	}
	else
	{
		pSFile = FileListGetEntry( fileNumber );
		
		if( g_mouseClicks == 1 )
		{
			if( pSFile->selected == TRUE )
			{
				pSFile->selected = FALSE;
				DeselectObject( g_winDialogs[WD_PLAYLIST], obj );
			}
			else
			{
				pSFile->selected = TRUE;
				SelectObject( g_winDialogs[WD_PLAYLIST], obj );
			}
		}
		else
		{
			FileListSetCurrFile( pSFile );
			PlayListSetCurrFile( pSFile );
			FileListSaveToHistory();
			LoadAndPlay();
		}
	}
}
