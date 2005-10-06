#ifndef _FILE_SELECT_H_
#define _FILE_SELECT_H_

#include "mxplay.h"

BOOL CB_ModuleFileSelect( char* path, char* name );
BOOL CB_ModuleDirSelect( char* path, char* name );
BOOL CB_RscFileSelect( char* path, char* name );
BOOL CB_PlayListFileSelect( char* path, char* name );

#endif