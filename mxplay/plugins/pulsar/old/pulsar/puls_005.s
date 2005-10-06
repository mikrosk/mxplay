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

P_MIX_DSP:	move.b	(a2,d2.w),(a1)	;dsp send 8bit
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
		moveq	#8,d1

MFP_recalc	cmp.l	#MFP_DIV_E,a0
		beq.b	MFP_NO_FREQ

		move.l	#2457600,d2	;MFP clock freq...
		moveq	#0,d3
		move.b	(a0)+,d3
		subq.l	#1,d1
		divu.l	d3,d2
		divu.l	d0,d2

		cmp.l	#$ff,d2
		bgt.b	MFP_recalc
		move.l	d2,d0
MFP_NO_FREQ
		rts
MFP_DIV		;dc.b	4,10,16,50,64,100,200
		dc.b	200,100,64,50,16,10,4
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
TIMER_A:	
		clr.b	$ffffffa19.w		;turn the timer off 
		move.b	MFP_DATA(pc),$ffffffa1f.w	;reload timer data reg.
		move.b	MFP_CONTROL(pc),$ffffffa19.w	;reload timer mode+div reg.
		bclr	#5,$fffffa0f.w
		not.l	$ffff9800.w

		pusha
	
		addq.l	#1,timer_tick
						;call DSP!
		;move.b	#$80+$13,$ffffa201.w	;execute dsp int at p:$26

		get_host	d0

		put_host	#"MIX"

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

		;-save

		lea.l	OLD_SS(pc),a0
		move.w	$ffff8900.w,(a0)+		; Interruptions, Son DMA
		bclr.b	#7,$ffff8901.w			; Registres PlayBack
		move.b	$ffff8903.w,(a0)+		; Start - High
		move.b	$ffff8905.w,(a0)+		; Start - Med
		move.b	$ffff8907.w,(a0)+		; Start - Low
		move.b	$ffff890f.w,(a0)+		; End - High
		move.b	$ffff8911.w,(a0)+		; End - Med
		move.b	$ffff8913.w,(a0)+		; End - Low
		bset.b	#7,$ffff8901.w			; Registres Record
		move.b	$ffff8903.w,(a0)+		; Start - High
		move.b	$ffff8905.w,(a0)+		; Start - Med
		move.b	$ffff8907.w,(a0)+		; Start - Low
		move.b	$ffff890f.w,(a0)+		; End - High
		move.b	$ffff8911.w,(a0)+		; End - Med
		move.b	$ffff8913.w,(a0)+		; End - Low

		move.w	$ffff8920.w,(a0)+		; Nb Voies, 8/16, Mono/Stereo
		move.w	$ffff8930.w,(a0)+		; Matrice : Sources
		move.w	$ffff8932.w,(a0)+		; Matrice : Destinations
		move.w	$ffff8934.w,(a0)+		; Prescales d'horloge
		move.w	$ffff8936.w,(a0)+		; Nb Voies Record,source ADDERIN
		move.w	$ffff8938.w,(a0)+		; Source ADC + Volumes entr‚es
		move.w	$ffff893a.w,(a0)+		; Volumes de Sortie

		;-setup

		clr.b	$ffff8901.w
		;move.b	#$0f,$ffff8920.w
	
		move.b	#1,$fffff8935.w
		move.l	#$1912080,$ffff8930.w

		;move.b	#%00010001,$ffff8930.w
		;move.b	#%00010001,$ffff8931.w
		;move.b	#%00110011,$ffff8932.w
		;move.b	#%00010011,$ffff8933.w

		move.b	#%10,$ffff8937.w
		rts

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
		lea.l	OLD_SS(pc),a0
		move.w	(a0)+,d0
		bclr.b	#7,$ffff8901.w			; Registres PlayBack
		move.b	(a0)+,$ffff8903.w		; Start - High
		move.b	(a0)+,$ffff8905.w		; Start - Med
		move.b	(a0)+,$ffff8907.w		; Start - Low
		move.b	(a0)+,$ffff890f.w		; End - High
		move.b	(a0)+,$ffff8911.w		; End - Med
		move.b	(a0)+,$ffff8913.w		; End - Low
		bset.b	#7,$ffff8901.w			; Registres Record
		move.b	(a0)+,$ffff8903.w		; Start - High
		move.b	(a0)+,$ffff8905.w		; Start - Med
		move.b	(a0)+,$ffff8907.w		; Start - Low
		move.b	(a0)+,$ffff890f.w		; End - High
		move.b	(a0)+,$ffff8911.w		; End - Med
		move.b	(a0)+,$ffff8913.w		; End - Low
		move.w	d0,$ffff8900.w			; Interruptions, Son DMA

		move.w	(a0)+,$ffff8920.w		; Nb Voies, 8/16, Mono/Stereo
		move.w	(a0)+,$ffff8930.w		; Matrice : Sources
		move.w	(a0)+,$ffff8932.w		; Matrice : Destinations
		move.w	(a0)+,$ffff8934.w		; Prescales d'horloge
		move.w	(a0)+,$ffff8936.w		; Nb Voies Record,source ADDERIN
		move.w	(a0)+,$ffff8938.w		; Source ADC + Volumes entr‚es
		move.w	(a0)+,$ffff893a.w		; Volumes de Sortie

		move.w	#129,-(a7)
		trap	#14
		addq.l	#2,a7

		rts
;-DSP BINARY CODE--------------------------------------------------------------
		align	4
DSP_start:	incbin	g:\pulsar\puls_002.p56
DSP_end:
;-PULSAR VOID DATAS------------------------------------------------------------

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

OLD_SS		ds.b	64
		even
;------------------------------------------------------------------------------
		text