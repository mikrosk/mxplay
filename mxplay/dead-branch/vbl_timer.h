#ifndef _VLB_TIMER_H_
#define _VLB_TIMER_H_

#include "mxplay.h"

#ifdef NO_MINT
extern long	timer_start_measure( void );
extern long	timer_stop_measure( void );

extern BOOL	timer_is_finished( void );
extern long	timer_install( void );
extern long	timer_uninstall( void );

extern unsigned long timer_addtime;
extern unsigned long timer_subtime;

#endif	/* NO_MINT */

extern void	timer_reset( unsigned long time );
extern void	timer_pause( void );

extern unsigned long TimerGetSubTime( void );
extern unsigned long TimerGetAddTime( void );

#endif
