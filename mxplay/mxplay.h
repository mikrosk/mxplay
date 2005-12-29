/*
 * mxplay.h -- definitions and external declarations for whole application
 *
 * Copyright (c) 2005 Miro Kropacek; mikro@hysteria.sk
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
