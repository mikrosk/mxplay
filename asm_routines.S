/*
 * asm_routines.s -- "private" asm routines
 *
 * Copyright (c) 2012-2013 Miro Kropacek; miro.kropacek@gmail.com
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

	.globl	asm_safe_call
	.globl	asm_safe_pointer

	// supervisor functions
	.globl	asm_save_audio
	.globl	asm_restore_audio
	.globl	asm_invalidate_cache

// d0-d1 / a0-a1 are scratch registers, no need to save them
// (and d0 is used for the return value)

	.text

asm_safe_call:
	lea	regs,a0
	movem.l	d2-d7/a2-a6,(a0)

	movea.l	asm_safe_pointer,a0
	jsr	(a0)				// return value in d0

	lea	regs,a0
	movem.l	(a0),d2-d7/a2-a6
	rts

asm_save_audio:
	lea	saveaudiobuf,a0
	move.w	0xffff8930.w,(a0)+
	move.w	0xffff8932.w,(a0)+
	move.b	0xffff8934.w,(a0)+
	move.b	0xffff8935.w,(a0)+
	move.b	0xffff8936.w,(a0)+
	move.b	0xffff8937.w,(a0)+
	move.b	0xffff8938.w,(a0)+
	move.b	0xffff8939.w,(a0)+
	move.b	0xffff893a.w,(a0)+
	move.b	0xffff893c.w,(a0)+
	move.b	0xffff8900.w,(a0)+
	move.b	0xffff8901.w,(a0)+
	move.b	0xffff8920.w,(a0)+
	move.b	0xffff8921.w,(a0)+
	rts

asm_restore_audio:
	lea	saveaudiobuf,a0
	move.w	(a0)+,0xffff8930.w
	move.w	(a0)+,0xffff8932.w
	move.b	(a0)+,0xffff8934.w
	move.b	(a0)+,0xffff8935.w
	move.b	(a0)+,0xffff8936.w
	move.b	(a0)+,0xffff8937.w
	move.b	(a0)+,0xffff8938.w
	move.b	(a0)+,0xffff8939.w
	move.b	(a0)+,0xffff893a.w
	move.b	(a0)+,0xffff893c.w
	move.b	(a0)+,0xffff8900.w
	move.b	(a0)+,0xffff8901.w
	move.b	(a0)+,0xffff8920.w
	move.b	(a0)+,0xffff8921.w
	rts

	.globl	g_cpu
// flush both caches as I'm lazy to implement per page/per line flush + cinv
asm_invalidate_cache:
	#ifndef	__mcoldfire__
	cmpi.l	#40,g_cpu
	bge.b	.cpu040

.cpu030:movec	cacr,d0
	or.l	#0b100000001000,d0		// cd/ci bit (clear d/i-cache)
	movec	d0,cacr
	rts

.cpu040:move	sr,d0				// save sr
	ori	#0x0700,sr			// ints off
	nop					// fix for some broken 040s
	cpusha	bc				// flush to memory
	cinva	bc				// invalidate
	move	d0,sr				// ints back
	#endif
	rts

	.bss

regs:	ds.l	11
asm_safe_pointer:
	ds.l	1
saveaudiobuf:
	ds.w	8
