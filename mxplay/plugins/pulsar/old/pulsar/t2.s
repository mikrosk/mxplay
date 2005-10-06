		jmp	start

		include	sys_lib.s
		include	puls_010.s
;-------------------------------------------------------------------------------
start		setup
		super	#0
	
;------------------------------------------------------------------------------
		jsr	ALLOC_SOUND	;get channels ptr

		move.l	d0,P_BASE
		move.l	d0,a0

		move.l	#spl,spl_ptr(a0)
		move.l	#44100*2,spl_freq(a0)
		move.w	#256,spl_state(a0)
		move.l	#(spl_end-spl)/2,spl_len(a0)
		move.l	#$0,spl_loop_off(a0)
		move.l	#(spl_end-spl)/2,spl_loop_len(a0)
		move.w	#%01,spl_flags(a0)
		clr.w	spl_play_short(a0)
		move.w	#$7fff,spl_volume(a0)
		move.w	#$7fff,spl_panning(a0)

		add.l	#spl_size,a0

		move.l	#spl2,spl_ptr(a0)
		move.l	#44100/2,spl_freq(a0)
		move.w	#256,spl_state(a0)
		move.l	#(spl_end2-spl2)/2,spl_len(a0)
		move.l	#$0,spl_loop_off(a0)
		move.l	#(spl_end2-spl2)/2,spl_loop_len(a0)
		move.w	#%000,spl_flags(a0)
		clr.w	spl_play_short(a0)
		move.w	#$7fff,spl_volume(a0)
		move.w	#$f00,spl_panning(a0)

		add.l	#spl_size,a0

		move.l	#spl2,spl_ptr(a0)
		move.l	#44100/4,spl_freq(a0)
		move.w	#256,spl_state(a0)
		move.l	#(spl_end2-spl2)/2,spl_len(a0)
		move.l	#$0,spl_loop_off(a0)
		move.l	#(spl_end2-spl2)/2,spl_loop_len(a0)
		move.w	#%000,spl_flags(a0)
		clr.w	spl_play_short(a0)
		move.w	#$7fff,spl_volume(a0)
		move.w	#$000,spl_panning(a0)

		add.l	#spl_size,a0

		move.l	#spl3,spl_ptr(a0)
		move.l	#44100,spl_freq(a0)
		move.w	#256,spl_state(a0)
		move.l	#(spl_end3-spl3)/2,spl_len(a0)
		move.l	#$0,spl_loop_off(a0)
		move.l	#(spl_end3-spl3)/2,spl_loop_len(a0)
		move.w	#%000,spl_flags(a0)
		clr.w	spl_play_short(a0)
		move.w	#$7fff,spl_volume(a0)
		move.w	#$000,spl_panning(a0)

		move.l	#2,d0
		move.l	#80,d1		;initial tick
		move.l	#interpreter,d3	;procedure called by the PULSAR
		move.w	#4,d4		;Nb of channels
		jsr	INIT_PULSAR	;initialize PULSAR

		;lea	P_VOICE_TAB(pc),a0
		;bsr	P_MIX_1


		jsr	ENABLE_MIX	;mixer on from NOW!

		writeln	<27,"EPLAYING...">

;-------------------------------------------------------------------------------
next
		read_key
		cmp.b	#" ",d0
		beq	exit
	
		move.l	P_BASE,a0
		write	<27,"jvolume=">
		move.w	spl_panning(a0),d0
		write_c.w	d0
		write	<"      ",27,"k">
		sub.w	#500,spl_panning(a0)
		bra	next

exit		move.l	P_BASE,a0
		move.l	#spl,spl_ptr(a0)
		move.l	#44100*2,spl_freq(a0)
		move.w	#256,spl_state(a0)
		move.l	#(spl_end-spl)/2,spl_len(a0)
		move.l	#$0,spl_loop_off(a0)
		move.l	#(spl_end-spl)/2,spl_loop_len(a0)
		move.w	#%01,spl_flags(a0)
		clr.w	spl_play_short(a0)
		move.w	#$7fff,spl_volume(a0)
		move.w	#-$7fff,spl_panning(a0)

		read_key

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
		ds.l	1000

spl		
		incbin	i:\fife.raw
spl_end:	

spl2		
		incbin	i:\loop5.raw
spl_end2:

spl3		
		incbin	i:\loop1.raw
spl_end3:	

		ds.b	20000
		bss
