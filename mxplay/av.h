#ifndef _AV_H_
#define _AV_H_

void AVInit( void );
void AVExit( void );
void AVSetStatus( short msg[8] );
BOOL VAParseArgs( short msg[8] );

#endif
