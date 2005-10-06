;-INFORMATION HEADER------------------------------------------------------------
;
;	Pulsar - a generic, platform indepandent, sound kernel
;
		include	dsp.s

;-DEFINE SPL STRUCTURE----------------------------------------------------------
;
;
		rsreset
spl_ptr:	rs.l	1	;sample pointer
spl_len		rs.l	1	;sample lenght
spl_loop_ptr:	rs.l	1	;sample loop pointer
spl_loop_len:	rs.l	1	;loop len
spl_now_playing	rs.l	1	;actual replay pointer
spl_flags	rs.w	1	;sample flags:
				;bit 0: 16 bit sample if set
				;bit 1-2: 0 - no loop
				;	  1 - normal loop
				;	  2 - ping-pong loop
spl_state:	rs.w	1	;replaying state:
				;	0 - silence (means that replaying was finished or not even started [channel wasn't used at all])
				;	1 - replay in progress
				;	256 - reinitialize replay [change compleatly sample and freq]
spl_freq:	rs.l	1	;replay frequency [Hz]
spl_panning	rs.w	1	;panning

spl_size	rs.b	1
;-------------------------------------------------------------------------------
;	Pulsar - a generic, platform indepandent, sound kernel
;
;


;-INIT PULSAR------------------------------------------------------------------
INIT_PULSAR:	move.l	d0,dma_freq
		move.w	d1,default_bpm
		move.w	d2,default_speed
		move.l	d3,feeder_ptr

		move.b	#%0100,$ffff8900.w
		move.w	#984,bufer_len

		bsr	INIT_mfp
		bsr	P_SOUND_I
		bsr	P_DSP_I
		rts

;-ALLOCATE PULSAR--------------------------------------------------------------
;	input:	none
;	output: d0 -pointer to chanel structures if allright
;		   -or negative error code if something wrong
ALLOC_SOUND:	move.l	#P_VOICE_TAB,d0
		rts

;-ENABLE MIX-------------------------------------------------------------------
;
ENABLE_MIX:	bset	#5,$fffffa13.w	;run my interrupt
		move.b	MFP_DATA(pc),$ffffffa1f.w
		move.b	MFP_CONTROL(pc),$ffffffa19.w

		rts
;-EXIT-------------------------------------------------------------------------
;
PULSAR_EXIT:	bsr	DEINIT_mfp
		bsr	P_SS_STOP
		rts
;-MIX CHANNEL------------------------------------------------------------------
;	input:	
;		a0 - spl info ptr
;
P_MIX_1:	;illegal

		move.w	spl_state(a0),d7
		tst.w	d7
		beq	MIX_EXIT_1

		cmp.w	#256,d7
		bne.b	spl_no_change

		move.l	spl_ptr(a0),spl_now_playing(a0)
		move.w	#1,spl_state(a0)

spl_no_change	moveq	#0,d1
		move.l	spl_freq(a0),d0	;desired frequency
		swap.w	d0
		move.w	d0,d1
		clr.w	d0
		divu.l	dma_freq(pc),d1:d0	;replay frequency
					;d0 -> fixed point step value
		moveq	#0,d2

		swap.w	d0

		move.l	spl_now_playing(a0),a2

		;---------------------
		;just for tests!
		;lea	out_buf,a1	;!!!!
		;add.l	dupa,a1

		lea	$fffffa207.w,a1

		move.w	bufer_len(pc),d7
		move.w	d7,d6
		subq.w	#1,d7

P_MIX_DSP:	move.b	(a2,d2.w*2),(a1)	;dsp send 8bit
		addx.l	d0,d2
		dbf	d7,P_MIX_DSP

		add.w	d2,a2
		move.l	a2,spl_now_playing(a0)

MIX_EXIT_1	rts
;-MFP CALC TIMER VALS----------------------------------------------------------
;	input:	d0.l - requested freq in [Hz]
;	output: d0 - timer data reg
;		d1 - timerm control reg

CALC_MFP:	lea	MFP_DIV(pc),a0
		moveq	#0,d1

MFP_recalc	cmp.l	#MFP_DIV_E,a0
		beq.b	MFP_NO_FREQ

		move.l	#2457600,d2	;MFP clock freq...
		moveq	#0,d3
		move.b	(a0)+,d3
		addq.l	#1,d1
		divu.l	d3,d2
		divu.l	d0,d2

		cmp.l	#$ff,d2
		bgt.b	MFP_recalc
		move.l	d2,d0
MFP_NO_FREQ
		rts
MFP_DIV		dc.b	4,10,16,50,64,100,200
MFP_DIV_E	even

;-INITIALIZE INTS---------------------------------------------------------------
;
INIT_mfp	push.w	sr
		move.w	#$2700,sr

		clr.b	$ffffffa19.w

		move.l	#TIMER_A,$134.w
		bset	#5,$ffffffa07.w	;timer a enabled...
		bset	#5,$ffffffa13.w	;but masked

		move.l	#50,d0
		bsr	CALC_MFP
		move.b	d0,MFP_DATA
		move.b	d1,MFP_CONTROL

		pop.w	sr
		rts
;-RESTORE INTS------------------------------------------------------------------
DEINIT_mfp	push.w	sr
		move.w	#$2700,sr

		bset	#5,$ffffffa07.w	;timer a enabled...
		bclr	#5,$ffffffa13.w	;but masked

		pop.w	sr
		rts
;-MIXER INTERRUPT---------------------------------------------------------------
;
;
TIMER_A:	;illegal
		;temp

		clr.b	$ffffffa19.w		;turn the timer off 
		move.b	MFP_DATA(pc),$ffffffa1f.w	;reload timer data reg.
		move.b	MFP_CONTROL(pc),$ffffffa19.w	;reload timer mode+div reg.

		not.l	$ffff9800.w

		pusha
	
		addq.l	#1,timer_tick
						;call DSP!
		move.b	#$80+$13,$ffffa201.w	;execute dsp int at p:$26

		get_host	d0

		lea	P_VOICE_TAB(pc),a0
		bsr	P_MIX_1

		get_host	d0

		not.l	$ffff9800.w
		popa
		bclr	#5,$fffffa0f.w		;mask off timer A
		rte

;-INITIALIZE SOUNDSYSTEM--------------------------------------------------------
;
P_SOUND_I:
		move.w	#128,-(a7)		;xbios 128, locksnd
		trap	#14
		addq.l	#2,a7
		tst.w	d0
		bmi	track_error

		move.w	#1,-(a7)		;protocol (No Handshake)
		move.w	#1,-(a7)		;prescale (1 = 49170 Hz)
		move.w	#0,-(a7)		;srcclk   (0 = 25.175 int.)
		move.w	#%1000,-(a7)		;dst      (8 = DAC, 1 = DMAREC)	#%1001
		move.w	#1,-(a7)		;src      (1 = DSP-Transmit)
		move.w	#139,-(a7)		;xbios 139, devconnect
		trap	#14
		lea	12(a7),a7

		move.w	#1,-(a7)		;16 bit stereo
		move.w	#132,-(a7)		;xbios 132, setmode
		trap	#14
		addq.l	#4,a7

		move.w	#0,-(a7)		;DSP-Rec: off
		move.w	#1,-(a7)		;DSP-Xmit: on
		move.w	#137,-(a7)		;xbios 137, dsptristate
		trap	#14
		addq.l	#6,a7

track_ok:
		moveq	#0,d0
track_error:
		rts
;----DSP BOST-------------------------------------------------------------------
;
P_DSP_I:	Dsp_ExecProg #DSP_start,#(DSP_end-DSP_start)/3,#0
		get_host	d0
		cmp.l	#"PLS",d0
		beq.b	DSP_init_OK
	
		writeln	<"Couldn't entablish connection with DSP!">
		moveq	#-1,d0
		bra	DSP_exit

DSP_init_OK	move.w	bufer_len(pc),d0	;
		ext.l	d0			;send initial bufer lenght
		put_host	d0		;	

DSP_exit	rts
;-STOP SOUNDSYSTEM--------------------------------------------------------------
;
P_SS_STOP:
		move.w	#1,-(a7)
		move.w	#0,-(a7)
		move.w	#0,-(a7)
		move.w	#8,-(a7)		; Dac....
		move.w	#0,-(a7)		; ...connected to nothing	
		move.w	#139,-(a7)
		trap	#14	
		lea	12(a7),a7

; Set the DSP-Transmit off:
		move.w	#0,-(a7)		;DSP-Rec: off
		move.w	#0,-(a7)		;DSP-Xmit: off
		move.w	#137,-(a7)		;xbios 137, dsptristate
		trap	#14
		addq.l	#6,a7

		move.w	#129,-(a7)
		trap	#14
		addq.l	#2,a7

		rts
;-DSP BINARY CODE--------------------------------------------------------------
		align	4
DSP_start:	incbin	g:\pulsar\puls_001.p56
DSP_end:
;-PULSAR VOID DATAS------------------------------------------------------------
;	
MIX_1_PTR:	dc.l	MIX_BUF_1
MIX_2_PTR:	dc.l	MIX_BUF_2

dma_freq:	ds.l	1
bufer_len	ds.w	1
default_bpm	ds.w	1
default_speed	ds.w	1
feeder_ptr	ds.l	1

MFP_DATA	ds.b	1
MFP_CONTROL	ds.b	1

ini		ds.b	1

timer_tick	dc.l	0

		even

P_VOICE_TAB:	ds.b	32*spl_size
		even

		bss
MIX_BUF_1	ds.l	4096
MIX_BUF_2	ds.l	4096
;------------------------------------------------------------------------------
		text