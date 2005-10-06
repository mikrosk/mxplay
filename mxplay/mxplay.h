#ifndef _MXPLAY_H_
#define _MXPLAY_H_

#ifndef FALSE
#define FALSE				0
#endif
#ifndef TRUE
#define TRUE				1
#endif
#ifndef BOOL
#define BOOL				int
#endif
#ifndef E_OK
#define E_OK				0
#endif
#ifndef PATH_MAX
#define PATH_MAX			1023
#endif
/*
#ifndef FILENAME_MAX
#define FILENAME_MAX		255
#endif
*/

#define VERSION				"1.0.0"
#define WELCOME_MESSAGE		"--- Welcome to mxPlay version %s made by MiKRO / Mystic Bytes and -XI- / Satantronic "

typedef struct
{
	unsigned short	mode;
	long			index;
	unsigned short	dev;
	unsigned short	reserved1;
	unsigned short	nlink;
	unsigned short	uid;
	unsigned short	gid;
	long			size;
	long			blksize;
	long			nblocks;
	short			mtime;
	short			mdate;
	short			atime;
	short			adate;
	short			ctime;
	short			cdate;
	short			attr;
	short			reserved2;
	long			reserved3;
	long			reserved4;
} XATTR;

struct timeval
{
	unsigned long tv_sec;
	unsigned long tv_usec;
};

extern BOOL		g_quitApp;
extern short	g_msgBuffer[8];
extern long		g_cpu;
extern long		g_fpu;
extern BOOL		g_hasDma;
extern BOOL		g_hasDsp;

extern void	HandleMessage( short msg[8] );
extern int	SendMessage( short recipientId );
extern void	ExitPlayer( int code );

#endif
