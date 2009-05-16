/*
 * vbl_timer_asm.s -- VBL counter for one-second-exact time measure (assembler level)
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

		.ifdef NO_MINT
		
		.globl	_timer_start_measure
		.globl	_timer_stop_measure
		.globl	_timer_is_finished
		.globl	_timer_install
		.globl	_timer_uninstall
		.globl	_timer_reset
		.globl	_timer_pause
		
		.globl	_timer_addtime
		.globl	_timer_subtime
		
| ------------------------------------------------------
		.text
| ------------------------------------------------------
		
| long timer_start_measure( void );

_timer_start_measure:
		movem.l	d1-a6,-(sp)			| save for gcc
		
		move.l	#300*1,stop_time		| 300 Hz timer * 1 second
		
		move	sr,d2				| save sr
		ori	#0x0700,sr			| ints off
		
		lea	save_mfp,a0			| save mfp
		move.b	0xfffffa09.w,(a0)+		|
		move.b	0xfffffa15.w,(a0)+		|
		move.b	0xfffffa1d.w,(a0)+		|
		move.b	0xfffffa25.w,(a0)+		|

		bset	#4,0xfffffa09.w			| timer-d
		bset	#4,0xfffffa15.w			|
		or.b	#0x07,0xfffffa1d.w		| %111 = divide by 200
		move.b	#41,0xfffffa25.w		| 2457600/200/41 approx 300 Hz

		pea	timer_d				| own timer-d
		move.w	#0x110/4,-(sp)			|
		move.w	#0x05,-(sp)			|
		trap	#13				|
		addq.l	#8,sp				|
		move.l	d0,save_timer_d			| save old value

		move.l	#vbl1,d0			| own vbl
		bsr.w	install_vbl

		move.l	d0,save_vbl
		sne	return_code			| if succeed, set to $ff else $00
		
		move	d2,sr				| ints back
		
		bsr.w	handle_error
		
		movem.l	(sp)+,d1-a6			| restore for gcc
		rts

| long timer_stop_measure( void );

_timer_stop_measure:
		movem.l	d1-a6,-(sp)			| save for gcc
		
		move	sr,d2				| save sr
		ori	#0x0700,sr			| ints off
		
		move.l	save_vbl,d0			| used slot
		bsr.w	uninstall_vbl

		tst.l	d0
		sne	return_code			| if succeed, set to $ff else $00
		
		move.l	save_timer_d,-(sp)		| old value
		move.w	#0x110/4,-(sp)			|
		move.w	#0x05,-(sp)			|
		trap	#13				|
		addq.l	#8,sp				|
		
		lea	save_mfp,a0			| mfp regs
		move.b	(a0)+,0xfffffa09.w		|
		move.b	(a0)+,0xfffffa15.w		|
		move.b	(a0)+,0xfffffa1d.w		|
		move.b	(a0)+,0xfffffa25.w		|
		
		move	d2,sr				| ints back
		
		bsr.w	handle_error

		movem.l	(sp)+,d1-a6			| restore for gcc
		rts
		
| BOOL timer_is_finished( void );

_timer_is_finished:
		tst.l	stop_time
		beq.b	finished1
		
running1:	moveq	#0,d0
		rts
		
finished1:	moveq	#1,d0
		rts
		
| void timer_reset( unsigned int time );

_timer_reset:	move.l	d0,-(sp)

		move.l	8(sp),d0			| return address + d0.l

		move.l	d0,_timer_subtime
		mulu.l	reached_vbls,d0
		move.l	d0,int_subtime
		move.l	d0,module_time
				
		clr.l	int_addtime
		clr.l	_timer_addtime			| 0 / x = 0
		
		move.l	(sp)+,d0
		rts

| void timer_pause( void );

_timer_pause:	not.w	paused
		rts

| long timer_install( void );

_timer_install:	movem.l	d1-a6,-(sp)			| save for gcc

		move	sr,d2				| save sr
		ori	#0x0700,sr			| ints off

		move.l	#vbl2,d0
		bsr.w	install_vbl
		
		move	d2,sr				| ints back

		move.l	d0,save_vbl
		sne	return_code			| if succeed, set to $ff else $00
		bsr.w	handle_error
		
		movem.l	(sp)+,d1-a6			| restore for gcc
		rts

| long timer_uninstall( void );

_timer_uninstall:
		movem.l	d1-a6,-(sp)			| save for gcc
		
		move	sr,d2				| save sr
		ori	#0x0700,sr			| ints off
		
		move.l	save_vbl,d0
		bsr.w	uninstall_vbl
		
		move	d2,sr				| ints back
		
		tst.l	d0
		sne	return_code
		bsr.w	handle_error
		
		movem.l	(sp)+,d1-a6			| restore for gcc
		rts

| VBL installer
| IN:  d0.l: VBL routine
| OUT: d0.l: 0 if error

install_vbl:	move.w	0x0454.w,d1
		subq.w	#1,d1
		movea.l	0x0456.w,a0

search1:	tst.l	(a0)+
		beq.b	found1
		dbra	d1,search1
		bra.b	not_found1
found1:		move.l	d0,-(a0)
		bra.b	exit1
not_found1:	moveq	#0,d0
exit1:		rts

| VBL uninstaller
| IN:  d0.l: VBL slot
| OUT: d0.l: 0 if error

uninstall_vbl:	move.w	0x0454.w,d1
		subq.w	#1,d1
		movea.l	0x0456.w,a0

search2:	cmp.l	(a0)+,d0
		beq.b	found2
		dbra	d1,search2
		bra.b	not_found2
found2:		clr.l	-(a0)
		bra.b	exit2
not_found2:	moveq	#0,d0
exit2:		rts

| Convert $ff/$00 to TRUE/FALSE
| OUT: d0.l: TRUE/FALSE

handle_error:	clr.l	d0
		move.b	return_code,d0
		beq.b	false
true:		moveq	#1,d0
false:		rts

| Custom VBL handler (for vertical frequency measure)

vbl1:		tst.l	stop_time			| don't increase when we're done
		beq.b	vbl1_skip

		addq.l	#1,reached_vbls
vbl1_skip:	rts
		
| Custom VBL handler (for module time)

vbl2:		tst.w	paused
		bne.b	pause
		
		move.l	int_addtime,d0
		cmp.l	module_time,d0
		beq.b	no_add
		addq.l	#1,d0
		move.l	d0,int_addtime
		
no_add:		move.l	int_subtime,d1
		beq.b	no_sub
		subq.l	#1,d1
		move.l	d1,int_subtime
		
no_sub:		divu.l	reached_vbls,d0
		divu.l	reached_vbls,d1
		
		move.l	d0,_timer_addtime
		move.l	d1,_timer_subtime

pause:		rts

| Custom Timer D handler

timer_d:	tst.l	stop_time
		beq.b	finished2
		
		subq.l	#1,stop_time

finished2:	bclr	#4,0xfffffa11.w			| clear busybit
		rte

| ------------------------------------------------------
		.bss
| ------------------------------------------------------

_timer_addtime:	ds.l	1
_timer_subtime:	ds.l	1

module_time:	ds.l	1
int_addtime:	ds.l	1
int_subtime:	ds.l	1
		
save_stack:	ds.l	1				| old stack
save_vbl:	ds.l	1				| used slot
save_timer_d:	ds.l	1				| old timer-d
save_mfp:	ds.b	4				| old mfp

stop_time:	ds.l	1
reached_vbls:	ds.l	1
paused:		ds.w	1

return_code:	ds.b	1

| ------------------------------------------------------
		.text
| ------------------------------------------------------

		.endif	/* NO_MINT */
