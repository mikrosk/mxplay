/*
 * asm_regs.s -- save/restore registers
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

	.globl	_asm_safe_call
	.globl	_asm_safe_pointer

// d0-d1 / a0-a1 are scratch registers, no need to save them
// (and d0 is used for the return value)

	.text

_asm_safe_call:
	lea	regs,a0
	movem.l	d2-d7/a2-a6,(a0)

	movea.l	_asm_safe_pointer,a0
	jsr	(a0)				// return value in d0

	lea	regs,a0
	movem.l	(a0),d2-d7/a2-a6
	rts

	.bss

regs:	ds.l	11
_asm_safe_pointer:
	ds.l	1
