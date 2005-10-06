#ifndef _MISC_H_
#define _MISC_H_

#include <cflib.h>
#include "mxplay.h"

#define CNF_FILE			"mxplay.inf"
#define DEFAULT_RSC_FILE	"default.rsc"
#define DEFAULT_M3U_FILE	"default.m3u"

extern void			WriteConfigFile( void );
extern void			ReadConfigFile( void );
extern void			GetHomePath( void );
extern unsigned long GetCurrentTime( void );
extern void			CombinePath( char* fullpath, char* path, char* name );
extern BOOL			VerifyAlloc( void* pointer );
extern void			ParseArgs( char* cmdline );
extern unsigned long GetFileNameSize( char* filename );
extern BOOL			IsDirectory( char* path, char* name );
extern void			DeselectObject( WDIALOG* wd, short obj );
extern void			SelectObject( WDIALOG* wd, short obj );
extern void			ARGVParseArgs( int argc, char* argv[] );
extern short		Round( float value );
extern BOOL			IsTopWindow( WDIALOG* wd );
extern void			SharedFileOpen( WDIALOG* wd, short obj );
extern void			SharedDirOpen( WDIALOG* wd, short obj );
extern void			UnpadString( char* string );
extern void			PadString( char* string, int newLength );
extern void			InitRandom( void );
extern void			EnableObject( WDIALOG* wd, short obj );
extern void			DisableObject( WDIALOG* wd, short obj );

extern char		g_homePath[PATH_MAX+1];
extern char		g_rscName[FILENAME_MAX+1];
extern char		g_playlistFile[PATH_MAX+1];
extern int		g_panelX;
extern int		g_panelY;
extern int		g_playlistX;
extern int		g_playlistY;

#endif
