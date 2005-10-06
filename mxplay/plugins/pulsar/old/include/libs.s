	
lib_open	macro
		move.l	\1,a0
		jsr	_open_library
		endm

lib_exec	macro
		move.l	a6,-(sp)
		move.l	\1,a6
		jsr	\2*4(a6)
		move.l	(sp)+,a6
		endm

lib_close:	macro
		move.l	\1,a0
		pushm	d1-a6
		move.l	-4(a0),d0
		mfree	d0
		popm	d1-a6
		endm

_open_library:	pushm	d1-a6

		pea	_null
		pea	_null
		move.l	a0,-(sp)
		move.w	#3,-(sp)
		move.w	#$4B,-(sp)
		trap	#1
		lea      16(sp),sp

		tst.l	d0
		bmi.b	_pexec_error

		move.l  d0,a0        ; Obtain pointer to basepage
		move.l	8(a0),a2
		push.l	a2

		move.l	a0,-4(a2)

		move.l	$0C(a0),a1
		add.l  $14(a0),a1      ; BSS Base address
		adda.l  $1C(a0),a1      ; Add BSS size
		add.l	#$500,a1
		move.l  a1,-(sp)
		move.l  a0,-(sp)
		clr.w   -(sp)
		move.w  #$4a,-(sp)      ; Mshrink()
		trap        #1
		lea     12(sp),sp       ; Fix up stack
		tst.l	d0
		beq.b	_lib_ok
		addq.l	#4,sp
		moveq	#-1,d0
		bra.b	_pexec_error

_lib_ok:	pop.l	d0

_pexec_error:	
		popm	d1-a6
		rts

_close_library:	pushm	d1-a6
		move.l	-4(a0),d0
		mfree	d0
		popm	d1-a6
		rts

_null		dc.b	0,0

