#include <cflib.h>

#include "filelist.h"
#include "skins/skin.h"
#include "misc.h"
#include "playlist.h"
#include "mxplay.h"
#include "dialogs.h"
#include "panel.h"
#include "file_select.h"

char*	g_currName = NULL;
char*	g_currPath = NULL;
BOOL	g_playAfterAdd = FALSE;
BOOL	g_emptyPlayList = TRUE;
BOOL	g_playlistNotActual = TRUE;

static struct SPlayListWindowEntry	SPlWindowEntry[PL_WINDOW_ENTRIES_MAX];
static int							plWindowEntries = 0;
static float						plAbove;	/* number of files "above" playlist */
static GRECT						sliderOld;	/* screen coordinates ! */

static short						currFileColor;
static short						normFileColor;
static BFOBSPEC						origSliderObSpec;
static BOOL							sliderSelected = FALSE;

static short origWidth;		/* original width & height */
static short origHeight;	/* (as stored in rsc file) */
static short prevWidth;
static short prevHeight;

static short shadeTab[] = { IP_HOLLOW,	/* G_WHITE */
							IP_SOLID,	/* G_BLACK */
							IP_HOLLOW,	/* G_RED */
							IP_1PATT,	/* G_GREEN */
							IP_1PATT,	/* G_BLUE */
							IP_2PATT,	/* G_CYAN */
							IP_2PATT,	/* G_YELLOW */
							IP_3PATT,	/* G_MAGENTA */
							IP_3PATT,	/* G_LWHITE */
							IP_SOLID,	/* G_LBLACK */
							IP_4PATT,	/* G_LRED */
							IP_4PATT,	/* G_LGREEN */
							IP_5PATT,	/* G_LBLUE */
							IP_5PATT,	/* G_LCYAN */
							IP_6PATT,	/* G_LYELLOW */
							IP_6PATT	/* G_LMAGENTA */ };
/*
 * Get default colors
 */
static void PlayListGetColors( void )
{
	TEDINFO*	pTed;
	BFOBSPEC*	pObSpec;
	short		obj;
	
	/*typedef struct objc_colorword 
	 *{
	 *	unsigned	borderc : 4;
	 *	unsigned	textc   : 4;
	 *	unsigned	opaque  : 1;
	 *	unsigned	pattern : 3;
	 *	unsigned	fillc   : 4;
	 *} OBJC_COLORWORD;
	 */
	pTed = (TEDINFO*)get_obspec( g_winDialogs[WD_PLAYLIST]->tree, PLAYLIST_TEXT1 );
	currFileColor = pTed->te_color;	/* first line represents color for current file */

	pTed = (TEDINFO*)get_obspec( g_winDialogs[WD_PLAYLIST]->tree, PLAYLIST_TEXT2 );
	normFileColor = pTed->te_color;	/* second line represents color for "normal" file */
	
	/* get_obspec is very unhandy this time */
	pObSpec = &g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_SLIDER].ob_spec.obspec;
		
	/* save the original */
	origSliderObSpec = *pObSpec;
	
	if( gl_planes <= 2 )
	{
		/* 2 and 4 colors */
		pObSpec->fillpattern = shadeTab[origSliderObSpec.interiorcol];
		pObSpec->interiorcol = G_BLACK;
	}
	
	/* all playlist entries as normal color */
	obj = g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_BACKGROUND].ob_head;
	
	/* we need to traverse whole dialog to find playlist entries */
	while( obj != PLAYLIST_BACKGROUND && obj != -1 )
	{
		/* check text objects which are selectable i.e. our entries */
		if( g_winDialogs[WD_PLAYLIST]->tree[obj].ob_type == G_TEXT
			&& get_flag( g_winDialogs[WD_PLAYLIST]->tree, obj, OF_SELECTABLE ) == TRUE )
		{
			pTed = (TEDINFO*)get_obspec( g_winDialogs[WD_PLAYLIST]->tree, obj );
			pTed->te_color = normFileColor;	/* back normal color */
		}
		
		obj = g_winDialogs[WD_PLAYLIST]->tree[obj].ob_next;
	}
}

/*
 * Get slider rectangle
 */
static void PlayListSliderGet( void )
{
	objc_offset( g_winDialogs[WD_PLAYLIST]->tree, PLAYLIST_SLIDER, &sliderOld.g_x, &sliderOld.g_y );
	sliderOld.g_w = g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_SLIDER].ob_width;
	sliderOld.g_h = g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_SLIDER].ob_height;
}

/*
 * Intelligent slider redraw.
 * Redraw only parts that are really dirty.
 */
static void PlayListSliderRedraw( void )
{
	GRECT slider;
	GRECT r;
	
	objc_offset( g_winDialogs[WD_PLAYLIST]->tree, PLAYLIST_SLIDER, &slider.g_x, &slider.g_y );
	slider.g_w = g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_SLIDER].ob_width;
	slider.g_h = g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_SLIDER].ob_height;
	
	/* custom redraw */
	wind_update( BEG_UPDATE );
	graf_mouse( M_OFF, NULL );

	wind_get_grect( g_winDialogs[WD_PLAYLIST]->win_handle, WF_FIRSTXYWH, &r );
	while( r.g_w != 0 && r.g_h != 0 )
	{
		if( rc_intersect( &sliderOld, &r ) != 0 )
		{
			/* remove old slider */
			objc_draw( g_winDialogs[WD_PLAYLIST]->tree, PLAYLIST_SLIDER_BOX, MAX_DEPTH, r.g_x, r.g_y, r.g_w, r.g_h );
		}
		
		wind_get_grect( g_winDialogs[WD_PLAYLIST]->win_handle, WF_NEXTXYWH, &r );
	}
	
	wind_get_grect( g_winDialogs[WD_PLAYLIST]->win_handle, WF_FIRSTXYWH, &r );
	while( r.g_w != 0 && r.g_h != 0 )
	{
		if( rc_intersect( &slider, &r ) != 0 )
		{
			/* draw new slider */
			objc_draw( g_winDialogs[WD_PLAYLIST]->tree, PLAYLIST_SLIDER, MAX_DEPTH, r.g_x, r.g_y, r.g_w, r.g_h );
		}

		wind_get_grect( g_winDialogs[WD_PLAYLIST]->win_handle, WF_NEXTXYWH, &r );
	}
		
	graf_mouse( M_ON, NULL );
	wind_update( END_UPDATE );
}

/*
 * Set slider according to size of playist window
 * and number of files in filelist
 */
static void PlayListSliderSet( void )
{
	float ratio;
	float height;
	float y;
	short sliderBoxHeight;
	
	PlayListSliderGet();	/* fill sliderOld structure */
	
	sliderBoxHeight = g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_SLIDER_BOX].ob_height;
	
	if( g_filesCount != 0 )
	{
		ratio = (float)plWindowEntries / (float)g_filesCount;
		if( ratio > 1.0 )
		{
			ratio = 1.0;
		}
	
		height = ratio * sliderBoxHeight;
		g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_SLIDER].ob_height = Round( height );
		
		y = (float)( sliderBoxHeight * (int)plAbove ) / (float)g_filesCount;
		g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_SLIDER].ob_y = Round( y );
	}
	else
	{
		g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_SLIDER].ob_y = 0;
		g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_SLIDER].ob_height = sliderBoxHeight;
	}
	
	PlayListSliderRedraw();
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
	plAbove = 0.0;
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
 * Refresh all playlist entries. Called from PlayList[Re]Init(),
 * and playlist redraws.
 */
static void PlayListRefresh( void )
{
	struct SFileListFile*	pSFile;
	int						i;
	short					obj;
	
	/*
	 * At first, we have to determine number of window entries.
	 * It's true this is not everytime neccessary but I don't
	 * find it as big overhead - playlist window has maybe 10-50 entries..
	 */
	plWindowEntries = 0;
	obj = g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_BACKGROUND].ob_head;
	
	/* we need to traverse whole dialog to find playlist entries */
	while( obj != PLAYLIST_BACKGROUND && obj != -1 )
	{
		/* check text objects which are selectable i.e. our entries */
		if( g_winDialogs[WD_PLAYLIST]->tree[obj].ob_type == G_TEXT
			&& get_flag( g_winDialogs[WD_PLAYLIST]->tree, obj, OF_SELECTABLE ) == TRUE )
		{
			SPlWindowEntry[plWindowEntries++].obj = obj;
		}
		
		obj = g_winDialogs[WD_PLAYLIST]->tree[obj].ob_next;
	}
	
	/* ok, now we know how big we have the window
	 * and what obj number belongs to each entry
	 */
	
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
			PlayListUpdateEntry( pSFile, SPlWindowEntry[i].obj );
			
			pSFile = pSFile->pSNext;
		}
		else
		{
			/* if not used, set as empty string */
			set_string( g_winDialogs[WD_PLAYLIST]->tree, SPlWindowEntry[i].obj, "" );
			/* for sure */
			set_state( g_winDialogs[WD_PLAYLIST]->tree, SPlWindowEntry[i].obj, OS_SELECTED, FALSE );
		}
		
		redraw_wdobj( g_winDialogs[WD_PLAYLIST], SPlWindowEntry[i].obj );
	}

	PlayListSliderSet();
}

/*
 * Common function for scrolling the list down
 */
static void PlayListDownCommon( float count )
{
	struct SFileListFile*	pSFile;
	int						i;
	int						fix = 0;
	int						roundedCount;
	int						roundedPlAbove;
	
	/* scroll only if full playlist window */
	if( SPlWindowEntry[plWindowEntries - 1].fileNumber != -1 )
	{
		pSFile = FileListGetEntry( SPlWindowEntry[plWindowEntries - 1].fileNumber );
		/* only if there's something to scroll */
		if( pSFile != NULL && pSFile->pSNext != NULL )
		{
			roundedPlAbove = (int)plAbove;	/* old (current) position */
			plAbove += count;
			roundedCount = (int)plAbove - roundedPlAbove;
			roundedPlAbove = (int)plAbove;
			
			if( plWindowEntries + roundedPlAbove > g_filesCount )
			{
				fix = g_filesCount - plWindowEntries - roundedPlAbove;
			}
			plAbove += fix;
			roundedCount += fix;
			
			if( roundedCount > 0 )
			{
				/* take the first file in the playlist window */
				pSFile = FileListGetEntry( SPlWindowEntry[0].fileNumber );
				
				/* move down in the filelist */
				while( roundedCount-- > 0 )
				{
					pSFile = pSFile->pSNext;
				}
				
				for( i = 0; i < plWindowEntries; i++ )
				{
					SPlWindowEntry[i].fileNumber = pSFile->number;
					pSFile = pSFile->pSNext;
				}
				
				PlayListRefresh();
			}
		}
	}
}

/*
 * Common function for scrolling the list up
 */
static void PlayListUpCommon( float count )
{
	struct SFileListFile*	pSFile;
	int						i;
	int						fix = 0;
	int						roundedCount;
	int						roundedPlAbove;
	
	/* scroll only if full playlist window */
	if( SPlWindowEntry[plWindowEntries - 1].fileNumber != -1 )
	{
		pSFile = FileListGetEntry( SPlWindowEntry[0].fileNumber );
		/* only if there's something to scroll */
		if( pSFile != NULL && pSFile->pSPrev != NULL )
		{
			roundedPlAbove = (int)plAbove;	/* old (current) position */
			plAbove -= count;
			roundedCount = roundedPlAbove - (int)plAbove;
			roundedPlAbove = (int)plAbove;
			
			if( plAbove < 0 )
			{
				fix = roundedPlAbove;
			}
			plAbove -= fix;
			roundedCount += fix;
			
			if( roundedCount > 0 )
			{
				/* take the last file in the playlist window */
				pSFile = FileListGetEntry( SPlWindowEntry[plWindowEntries - 1].fileNumber );
				
				/* move up in the filelist */
				while( roundedCount-- > 0 )
				{
					pSFile = pSFile->pSPrev;
				}
				
				for( i = plWindowEntries - 1; i >= 0; i-- )
				{
					SPlWindowEntry[i].fileNumber = pSFile->number;
					pSFile = pSFile->pSPrev;
				}
				
				PlayListRefresh();
			}
		}
	}
}

/*
 * Special slider select function
 */
void PlayListSliderSelect( void )
{
	/*typedef struct
	 *{
	 *   unsigned character   :  8;
	 *   signed   framesize   :  8;
	 *   unsigned framecol    :  4;
	 *   unsigned textcol     :  4;
	 *   unsigned textmode    :  1;
	 *   unsigned fillpattern :  3;
	 *   unsigned interiorcol :  4;
	 *
	 *} bfobspec;
	 */
	BFOBSPEC*		pObSpec;
	unsigned short	col;
	
	if( sliderSelected == TRUE )
	{
		/* nothing to do */
		return;
	}

	sliderSelected = TRUE;
	
	pObSpec = &g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_SLIDER].ob_spec.obspec;
	
	if( gl_planes > 2 )
	{
		/* 4, 16 and 256 colors */
		col = pObSpec->interiorcol;
		pObSpec->interiorcol = pObSpec->framecol;
		pObSpec->framecol = col;
	}
	else
	{
		/* 2 and 4 colors */
		pObSpec->fillpattern = shadeTab[origSliderObSpec.framecol];
		pObSpec->interiorcol = G_BLACK;
	}
	
	redraw_wdobj( g_winDialogs[WD_PLAYLIST], PLAYLIST_SLIDER );
}

/*
 * Special slider deselect function
 */
void PlayListSliderDeselect( void )
{
	BFOBSPEC*		pObSpec;
	unsigned short	col;
	
	if( sliderSelected == FALSE )
	{
		/* nothing to do */
		return;
	}
	
	sliderSelected = FALSE;

	pObSpec = &g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_SLIDER].ob_spec.obspec;
	
	if( gl_planes > 2 )
	{
		/* 4, 16 and 256 colors */
		pObSpec->fillpattern = IP_SOLID;
		col = pObSpec->interiorcol;
		pObSpec->interiorcol = pObSpec->framecol;
		pObSpec->framecol = col;
	}
	else
	{
		/* 2 and 4 colors */
		pObSpec->fillpattern = shadeTab[origSliderObSpec.interiorcol];
		pObSpec->interiorcol = G_BLACK;
	}
	
	redraw_wdobj( g_winDialogs[WD_PLAYLIST], PLAYLIST_SLIDER );
}


/*
 * Play from the first file in playlist
 */
void PlayListPlayFromFirstFile( void )
{
	struct SFileListFile* pSFile;
	
	pSFile = FileListGetFirstEntry();
	
	if( pSFile != NULL )
	{
		FileListSetCurrFile( pSFile );
		if( FileListSetNext() == TRUE )
		{
			LoadAndPlay();
		}
	}
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
	
	PlayListRefresh();
}

/*
 * Update playlist after file was added to the
 * filelist. Slider is updated, too.
 */
void PlayListUpdate( struct SFileListFile* pSFile )
{
	int	i;
	
	if( g_emptyPlayList == TRUE )
	{
		g_emptyPlayList = FALSE;
	}
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
			
			return;
		}
	}
	
	PlayListSliderSet();
}

/*
 * Playlist initialization. Called only once after
 * InitRsc() in dialogs.c
 */
void PlayListInit( void )
{
	origWidth = g_winDialogs[WD_PLAYLIST]->work.g_w;
	origHeight = g_winDialogs[WD_PLAYLIST]->work.g_h;

	prevWidth = origWidth;
	prevHeight = origHeight;
	
	PlayListClear();
	PlayListGetColors();
	PlayListSliderGet();	/* fill sliderOld structure */
	PlayListRefresh();
}

/*
 * Playlist reinitialization. Called only by
 * PanelChangeSkin() in panel.c
 */
void PlayListReinit( void )
{
	struct SFileListFile* pSFile;
	int i;
	
	origWidth = g_winDialogs[WD_PLAYLIST]->work.g_w;
	origHeight = g_winDialogs[WD_PLAYLIST]->work.g_h;
	
	prevWidth = origWidth;
	prevHeight = origHeight;
	
	PlayListGetColors();
	PlayListRefresh();	/* get plWindowEntries */
	
	plAbove = 0.0;
	pSFile = FileListGetFirstEntry();
	for( i = 0; i < plWindowEntries; i++ )
	{
		SPlWindowEntry[i].fileNumber = pSFile->number;
		pSFile = pSFile->pSNext;
	}
	
	PlayListRefresh();	/* refresh with correct values */
}

/*
 * Add the file/directory to the filelist
 * (playlist update is done from there, too)
 */
BOOL PlayListAdd( char* path, char* name )
{
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
			return FileListAddDirectory( path, name );
		}
		else
		{
			return FileListAddFile( path, name );
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
		PlayListRefresh();
		
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
		PlayListRefresh();
		
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
 
/*void PlayListSlider( void )
{
	short value;
	float y;
	short sliderBoxHeight;
	short sliderHeight;
	short sliderY;
	float delta;
	
	SelectObject( g_winDialogs[WD_PLAYLIST], PLAYLIST_SLIDER );
	//DeselectObject( g_winDialogs[WD_PLAYLIST], PLAYLIST_SLIDER );
	//PlayListSelectSlider();
	
	sliderBoxHeight = g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_SLIDER_BOX].ob_height;
	sliderHeight = g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_SLIDER].ob_height;
	sliderY = g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_SLIDER].ob_y;
	
	if( sliderHeight < sliderBoxHeight )
	{
		value = graf_slidebox( g_winDialogs[WD_PLAYLIST]->tree, PLAYLIST_SLIDER_BOX, PLAYLIST_SLIDER, 1 );
		
		y = (float)value * (float)( ( sliderBoxHeight - sliderHeight ) / 1000.0 );
		
		delta = ( y - (float)sliderY ) * ( (float)g_filesCount / (float)sliderBoxHeight );
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
	
	DeselectObject( g_winDialogs[WD_PLAYLIST], PLAYLIST_SLIDER );
	//PlayListDeselectSlider();
}*/

void PlayListSlider( short deltaY )
{
	short sliderY;
	short sliderBoxHeight;
	float delta;
	
	sliderY = g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_SLIDER].ob_y;
	sliderBoxHeight = g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_SLIDER_BOX].ob_height;
	
	delta = (float)deltaY * ( (float)g_filesCount / (float)sliderBoxHeight );
	
	if( delta > 0 )
	{
		PlayListDownCommon( delta );
	}
	else if( delta < 0 )
	{
		PlayListUpCommon( -delta );
	}
}

void PlayListSliderBox( short my )
{
	short sliderHeight;
	short ox, oy;
	
	sliderHeight = g_winDialogs[WD_PLAYLIST]->tree[PLAYLIST_SLIDER].ob_height;
	
	objc_offset( g_winDialogs[WD_PLAYLIST]->tree, PLAYLIST_SLIDER, &ox, &oy );
	
	if( my < oy )
	{
		PlayListUpCommon( plWindowEntries );
	}
	else if( my > oy + sliderHeight )
	{
		PlayListDownCommon( plWindowEntries );
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
	
	PlayListRefresh();
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
	PlayListClear();	
	PlayListRefresh();
	
	pSFile = FileListGetFirstEntry();
	
	/* refill */
	while( pSFile != NULL )
	{
		PlayListUpdate( pSFile );
		
		pSFile = pSFile->pSNext;
	}
	
	PlayListRefresh();
	
	DeselectObject( g_winDialogs[WD_PLAYLIST], PLAYLIST_REMOVE );
}

void PlayListResize( short mx, short my )
{
#if 0
	GRECT	r;
	BOOL	redraw = FALSE;
	short	width;
	short	height;
	short	deltaX;
	short	deltaY;
	
	width = mx - g_winDialogs[WD_PLAYLIST]->work.g_x;
	height = my - g_winDialogs[WD_PLAYLIST]->work.g_y;
	
	if( ( width <= origWidth && prevWidth == origWidth )
		&& ( height <= origHeight && prevHeight == origHeight ) )
	{
		return;
	}
	else
	{
		if( width >= origWidth )
		{
			deltaX = width - g_winDialogs[WD_PLAYLIST]->work.g_w;
			
			g_winDialogs[WD_PLAYLIST]->work.g_w = width;
			g_winDialogs[WD_PLAYLIST]->tree[ROOT].ob_width += deltaX;
			prevWidth = width;
			redraw = TRUE;
		}
		
		if( height >= origHeight )
		{
			deltaY = height - g_winDialogs[WD_PLAYLIST]->work.g_h;
			
			g_winDialogs[WD_PLAYLIST]->work.g_h = height;
			g_winDialogs[WD_PLAYLIST]->tree[ROOT].ob_height += deltaY;
			prevHeight = height;
			redraw = TRUE;
		}
	}
	
	if( redraw == TRUE )
	{
		redraw_wdobj( g_winDialogs[WD_PLAYLIST], ROOT );
		wind_calc_grect( WC_BORDER, g_winDialogs[WD_PLAYLIST]->win_kind, &g_winDialogs[WD_PLAYLIST]->work, &r );
		wind_set_grect( g_winDialogs[WD_PLAYLIST]->win_handle, WF_CURRXYWH, &r );
	}
#endif
}

void PlayListUp( void )
{
	SelectObject( g_winDialogs[WD_PLAYLIST], PLAYLIST_UP );
	
	if( g_withShift == TRUE )
	{
		PlayListUpCommon( plWindowEntries );	/* big step */
	}
	else
	{
		PlayListUpCommon( 1 );	/* just one entry */
	}
		
	DeselectObject( g_winDialogs[WD_PLAYLIST], PLAYLIST_UP );
}

void PlayListDown( void )
{	
	SelectObject( g_winDialogs[WD_PLAYLIST], PLAYLIST_DOWN );
	
	if( g_withShift == TRUE )
	{
		PlayListDownCommon( plWindowEntries );	/* big step */
	}
	else
	{
		PlayListDownCommon( 1 );	/* just one entry */
	}
		
	DeselectObject( g_winDialogs[WD_PLAYLIST], PLAYLIST_DOWN );
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
