		jmp	start

		include	g:\sys_lib.s
		include	puls_004.s
;-------------------------------------------------------------------------------
start		setup
		super	#0

         	move.b #%10000000,$fffffff8921.w                  
         	move.b #%00000000,$fffffff8920.w
         	move.b #%1,$ffff8935.w

	
		write	<27,"ESCALING SAMPLE...">

;------------------------------------------------------------------------------
		move.l	#49170,d0	;base freq
		move.w	#125,d1		;initial bpm
		move.w	#10,d2		;initial speed
		move.l	#interpreter,d3	;procedure called by the PULSAR
		jsr	INIT_PULSAR	;initialize PULSAR
		jsr	ALLOC_SOUND	;get channels ptr

		move.l	d0,P_BASE
		move.l	d0,a0
		move.l	#spl,spl_ptr(a0)
		move.l	#24585,spl_freq(a0)
		move.w	#256,spl_state(a0)
		clr.w	spl_flags(a0)

		jsr	ENABLE_MIX	;mixer on from NOW!

		writeln	<"PLAYING...">
;-------------------------------------------------------------------------------
next
		read_key
		cmp.b	#" ",d0
		beq.b	exit
	
		move.l	P_BASE,a0
		sub.l	#100,spl_freq(a0)	
		bra.b	next

exit		move.b #%00000000,$fffffff8901.w

		jsr	PULSAR_EXIT

		move.l	#$fffffffffffffff,$fffff9800.w
;-------------------------------------------------------------------------------
		pterm

;-------------------------------------------------------------------------------
interpreter:	
		rts

dupa		dc.l	0
P_BASE		ds.l	1

		data
spl		incbin	e:\house.raw
spl_end:
		bss
