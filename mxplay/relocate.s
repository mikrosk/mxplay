/*
 * relocate.s -- plugin relocation
 *
 * Copyright (c) 2005 Miro Kropacek; miro.kropacek@gmail.com
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

		.globl	_plugin_relocate

		.text

| void plugin_relocate( char* plugin );

_plugin_relocate:
		move.l	4(sp),d0			| d0 isn't used bu gcc
		movem.l	d1/a0-a2,-(sp)
		movea.l	d0,a0
		move.l	0x02(a0),d0			| d0:  length of text segment
		add.l	0x06(a0),d0			|    + length of data segment
		add.l	0x0e(a0),d0			|    + length of symbol segment
		lea	0x1c(a0),a0			| a0: pointer to text segment
		movea.l	a0,a1
		movea.l	a0,a2
		move.l	a0,d1
		adda.l	d0,a1
		move.l	(a1)+,d0
		adda.l	d0,a2
		add.l	d1,(a2)
		moveq	#0,d0
.loop:		move.b	(a1),d0
		clr.b	(a1)+
		tst.b	d0
		beq.b	.done
		cmp.b	#1,d0
		beq.b	.special_branch
		adda.l	d0,a2
		add.l	d1,(a2)
		bra.b	.loop
.special_branch:
		lea	0xfe(a2),a2
		bra.b	.loop
.done:		movem.l	(sp)+,d1/a0-a2
		rts
