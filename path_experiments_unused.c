static void GetFileSystemLimits( const char* sPath, size_t* pPathNameMax, size_t* pFileNameMax )
{
	if( pPathNameMax != NULL )
	{
		*pPathNameMax = pathconf( sPath, _PC_PATH_MAX );
		*pPathNameMax = ( *pPathNameMax == -1 || *pPathNameMax > 4095 ) ? 4095 : *pPathNameMax;
	}

	if( pFileNameMax )
	{
		*pFileNameMax = pathconf( sPath, _PC_NAME_MAX );
		*pFileNameMax = ( *pFileNameMax == -1 || *pFileNameMax > 255 ) ? 255 : *pFileNameMax;
	}
}

void GetFileNameBuffer( const char* sFileSystemPath, char** ppFileName )
{
	size_t fileNameMax;
	GetFileSystemLimits( sFileSystemPath, NULL, &fileNameMax );

	if( ppFileName != NULL )
	{
		*ppFileName = (char*)malloc( fileNameMax + 1 );
		if( VerifyAlloc( *ppFileName ) == FALSE )
		{
			ExitPlayer( 1 );
		}
	}
}

void GetPathBuffer( const char* sFileSystemPath, char** ppPath )
{
	size_t pathNameMax;
	GetFileSystemLimits( sFileSystemPath, &pathNameMax, NULL );

	if( ppPath != NULL )
	{
		*ppPath = (char*)malloc( pathNameMax + 1 );
		if( VerifyAlloc( *ppPath ) == FALSE )
		{
			ExitPlayer( 1 );
		}
	}
}

void CombinePath( const char* sPath, const char* sFileName, char** ppFilePath )
{
	GetPathBuffer( sPath, ppFilePath );

	strcpy( *ppFilePath, sPath );
	if( *ppFilePath[strlen( *ppFilePath ) - 1] != '\\' && *ppFilePath[strlen( *ppFilePath ) - 1] != '/' )
	{
		strcat( *ppFilePath, "\\" );
	}

	if( sFileName != NULL && strlen( sFileName ) > 0 )
	{
		strcat( *ppFilePath, sFileName );
		if( *ppFilePath[strlen( *ppFilePath ) - 1] == '\\' || *ppFilePath[strlen( *ppFilePath ) - 1] == '/' )
		{
			*ppFilePath[strlen( *ppFilePath ) - 1]  = '\0';	/* we don't want path/name.ext/ */
		}
	}
}

void SplitPath( const char* sFilePath, char** ppPath, char** ppFileName )
{
	GetPathBuffer( sFilePath, ppPath );
	GetFileNameBuffer( sFilePath, ppFilePath );

	split_filename( sFilePath, ppPath != NULL ? *ppPath : NULL, ppFileName != NULL ? *ppFileName : NULL );
}

void CombinePath( const char* sPath, const char* sFileName, char** ppFilePath )
{
	if( ppFilePath != NULL )
	{
		// +1 for the case we are missing trailing (back)slash
		int len = strlen( sPath ) + strlen( sFileName ) + 1 + 1;
		*ppFilePath = (char*)malloc( len );
		if( VerifyAlloc( *ppFilePath ) == FALSE )
		{
			ExitPlayer( 1 );
		}

		strcpy( *ppFilePath, sPath );
		len = strlen( *ppFilePath );
		if( *ppFilePath[len - 1] != '\\' && *ppFilePath[len - 1] != '/' )
		{
			strcat( *ppFilePath, "\\" );
		}

		if( sFileName != NULL && strlen( sFileName ) > 0 )
		{
			strcat( *ppFilePath, sFileName );
			len = strlen( *ppFilePath );
			if( *ppFilePath[len - 1] == '\\' || *ppFilePath[len - 1] == '/' )
			{
				*ppFilePath[len - 1]  = '\0';	/* we don't want path/name.ext/ */
			}
		}
	}
}

void SplitPath( const char* sFilePath, char** ppPath, char** ppFileName )
{
	int i;
	for( i = strlen( sFilePath ) - 1; i >= 0 && ( sFilePath[i] != '\\' && sFilePath[i] != '/' ); --i );

	// special cases first
	if( i == -1 || ( i == 0 && strlen( sFilePath ) == 1 ) )
	{
		if( ppPath != NULL )
		{
			*ppPath = (char*)malloc( 1 );
			if( VerifyAlloc( *ppPath ) == FALSE )
			{
				ExitPlayer( 1 );
			}
			(*ppPath)[0] = '\0';
		}
		if( ppFileName != NULL )
		{
			*ppFileName = (char*)malloc( 1 );
			if( VerifyAlloc( *ppFileName ) == FALSE )
			{
				ExitPlayer( 1 );
			}
			(*ppFileName)[0] = '\0';
		}
		return;
	}

	if( ppPath != NULL )
	{
		int len = i + 1;
		*ppPath = (char*)malloc( len + 1 );
		if( VerifyAlloc( *ppPath ) == FALSE )
		{
			ExitPlayer( 1 );
		}
		strncpy( *ppPath, sFilePath, len );
		(*ppPath)[i == 0 ? len : len-1] = '\0';	// we want '/'
	}

	if( ppFileName != NULL )
	{
		int len = strlen( sFilePath ) - i - 1;
		*ppFileName = (char*)malloc( len + 1 );
		if( VerifyAlloc( *ppFileName ) == FALSE )
		{
			ExitPlayer( 1 );
		}
		strncpy( *ppFileName, &sFilePath[i+1], len );
		(*ppFileName)[len] = '\0';
	}
}
