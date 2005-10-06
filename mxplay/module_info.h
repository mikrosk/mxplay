#ifndef _MODULE_INFO_H_
#define _MODULE_INFO_H_

extern void	ModuleInfoInit( void );
extern void	ModuleInfoReinit( void );
extern void	ModuleInfoUpdate( void );
extern void	ModuleInfoButton( short obj );
extern void ModuleInfoResize( GRECT* pR );
extern void ModuleInfoScroll( short direction );
extern void ModuleInfoSlider( short deltaY );

#endif
