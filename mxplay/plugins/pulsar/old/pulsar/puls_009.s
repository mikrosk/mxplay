;-INFORMATION HEADER------------------------------------------------------------
;
;	Pulsar - a generic, platform indepandent [not yet:)], sound kernel
;
		include	dsp.s

;-DEFINE SPL STRUCTURE----------------------------------------------------------
;
;
		rsreset
spl_ptr:	rs.l	1	;sample pointer
spl_len		rs.l	1	;sample lenght
spl_loop_off:	rs.l	1	;sample loop offset
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
spl_volume	rs.w	1	;volume :-)
spl_play_short	rs.b	1
spl_loop_flag1	rs.b	1
spl_pingpong_flag	rs.w	1

spl_size	rs.b	1
;-------------------------------------------------------------------------------
;	Pulsar - a generic, platform indepandent, sound kernel
;
;


;-INIT PULSAR------------------------------------------------------------------
INIT_PULSAR:	move.l	d0,dma_freq
		move.l	d1,replay_tick
		move.l	d3,feeder_ptr
	
		bsr	P_set_frame_tick
		bsr	P_INIT_mfp
		bsr	P_DSP_I
		move.b	#$80+$14,$ffffa201.w	;execute dsp int at p:$26
		bsr	P_SOUND_I

		clr.b	P_initial
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
		move.b	#$80+$14,$ffffa201.w	;execute dsp int at p:$26

		rts
;-MIX CHANNEL------------------------------------------------------------------
;	input:	
;		a0 - spl info ptr
;
P_MIX_1:	;illegal

		btst	#0,spl_flags+1(a0)
		bne	mix_16bit

		put_host	#1	;tell dsp to mix 8bit as input

		moveq	#0,d0
		move.w	spl_volume(a0),d0
		put_host	d0		;send volume

		move.w	spl_panning(a0),d0
		ext.l	d0
		put_host	d0		;send panning

		lea	$fffffa207.w,a1	;host adr -> a1
   ********************************************************************
   *	   Mix 8bit with loops, both normal and ping-pong,            *
   *	   and output mixed datas to the dsp part of mixer            *
   ********************************************************************

		move.w	spl_state(a0),d7
		tst.w	d7
		beq	MIX_EXIT_1

		cmp.w	#256,d7
		bne.b	spl_no_change

		move.l	spl_ptr(a0),spl_now_playing(a0)
		;add.l	#$1658+$5e00,spl_now_playing(a0)

		move.w	#1,spl_state(a0)
		clr.b	spl_play_short(a0)
		clr.b	spl_loop_flag1(a0)
		clr.b	spl_pingpong_flag(a0)

spl_no_change	moveq	#0,d1
		move.l	spl_freq(a0),d0	;desired frequency
		swap.w	d0
		move.w	d0,d1
		clr.w	d0
		divu.l	dma_freq(pc),d1:d0	;replay frequency
					;d0 -> fixed point step value
		moveq	#0,d2
		clr.b	spl_loop_flag1(a0)

		bfextu	spl_flags(a0){13:2},d1
		cmp.b	#1,d1
		beq.b	mix_normal_loop
		cmp.b	#2,d1
		beq	mix_ping_loop

**********************************************************************************
*              OK, so if no loops then check if                                  *
*              sample is expired                                                 *
**********************************************************************************

		move.l	spl_now_playing(a0),a2

		move.l	d0,d1
		move.w	bufer_len(pc),d3
		ext.l	d3
		mulu.l	d3,d1
		swap.w	d1
		lea	(a2,d1.w),a3	;will point frame end sample

mix_normal_loop_enter_1:
		moveq	#0,d5
		move.l	a3,spl_now_playing(a0)

		move.l	spl_len(a0),d4
		add.l	spl_ptr(a0),d4	;a4=spl_end
		
		sub.l	a3,d4		;current buffor end position minus
					;sample end
		cmp.l	d3,d4
		bge.b	spl_mix_full_buffer

		st	spl_play_short(a0)
		move.l	d4,d3

spl_mix_full_buffer:
		swap.w	d0
		
		put_host	d3
		subq.w	#1,d3

		add.l	d0,d2

mix_samples_inner_1:	move.b	(a2,d2.w),(a1)	;dsp send 8bit
		addx.l	d0,d2
		dbf	d3,mix_samples_inner_1

		tst.b	spl_play_short(a0)
		beq.b	spl_sample_not_expired		
		move.w	#256,spl_state(a0)
spl_sample_not_expired:

MIX_EXIT_1	rts
***********************************************************************************
*                     Heare U have normal loop service:                           *
***********************************************************************************
mix_normal_loop:
		moveq	#0,d4
		move.w	bufer_len(pc),d3
		ext.l	d3
		put_host	d3	;dsp -> mix d3 samples
		move.l	spl_now_playing(a0),a2
		moveq	#0,d7
mix_outer_loop:
		tst.l	d7
		beq.b	mix_loop_first_attempt
		move.l	d7,d3		;<-we've left with d3 samples
mix_loop_first_attempt:
		move.l	d0,d1
		mulu.l	d3,d1
		swap.w	d1
		lea	(a2,d1.w),a3	;will point 2 frame end sample

		move.l	spl_ptr(a0),d5
		add.l	spl_loop_off(a0),d5
		add.l	spl_loop_len(a0),d5

		cmp.l	a2,d5
		bls.b	mix_reinit

		sub.l	a3,d5		;(current end buffer pos)-(sample rep end point)
		bpl.b	spl_epnr
		neg.l	d5

		swap.w	d5
		clr.w	d5
		divu.l	d0,d5		;get it into buffer unit
		;swap.w	d5
		ext.l	d5
		sub.l	d5,d3
		move.l	d5,d7		;we left with d7 samples
		bra.b	spl_epr

spl_epnr	moveq	#0,d7
spl_epr		swap.w	d0
		moveq	#0,d2
		
		add.l	d3,d4

		add.l	d0,d2		;initial add
		
		bra.b	mix_ssil
mix_samples_inner_2:	move.b	(a2,d2.w),(a1)	;dsp send 8bit
		addx.l	d0,d2
mix_ssil	dbf	d3,mix_samples_inner_2

		swap.w	d0

		tst.l	d7
		beq.b	mix_loop_finished
mix_reinit
		;move.l	spl_ptr(a0),a2
		;add.l	spl_loop_off(a0),a2
		add.w	d2,a2
		sub.l	spl_loop_len(a0),a2

		bra.b	mix_outer_loop
mix_loop_finished:
		add.w	d2,a2
		move.l	a2,spl_now_playing(a0)

MIX_EXIT_2	rts

***********************************************************************************
*                     Heare U have ping-pong loop service:                        *
***********************************************************************************
mix_ping_loop:
		move.w	bufer_len(pc),d3
		ext.l	d3
		put_host	d3	;dsp -> mix d3 samples
		move.l	spl_now_playing(a0),a2
		moveq	#0,d7
mix_outer_loop_pp:
		tst.l	d7
		beq.b	mix_loop_first_attempt_pp
		move.l	d7,d3		;<-we've left with d3 samples
mix_loop_first_attempt_pp:
		move.l	d0,d1
		mulu.l	d3,d1
		swap.w	d1

		tst.b	spl_pingpong_flag(a0)
		beq.b	spl_ping_forth			;playing forward
			
		move.l	a2,a3				;playing backward
		sub.w	d1,a3	
		move.l	spl_ptr(a0),d5
		add.l	spl_loop_off(a0),d5

		cmp.l	a2,d5
		bhi	mix_reinit_ppp

		sub.l	a3,d5		;(current end buffer pos)-(sample rep end point)
		bmi.b	spl_epnr_pp

		swap.w	d5
		clr.w	d5
		divu.l	d0,d5		;get it into buffer unit
		;swap.w	d5
		ext.l	d5
		sub.l	d5,d3
		move.l	d5,d7		;we left with d7 samples
		bra.b	spl_epr_pp
	;-----------------------------------------
spl_ping_forth
		lea	(a2,d1.w),a3	;will point 2 frame end sample

		move.l	spl_ptr(a0),d5
		add.l	spl_loop_off(a0),d5
		add.l	spl_loop_len(a0),d5

		cmp.l	a2,d5
		bls.b	mix_reinit_pp

		sub.l	a3,d5		;(current end buffer pos)-(sample rep end point)
		bpl.b	spl_epnr_pp
		neg.l	d5

		swap.w	d5
		clr.w	d5
		divu.l	d0,d5		;get it into buffer unit
		;swap.w	d5
		ext.l	d5
		sub.l	d5,d3
		move.l	d5,d7		;we left with d7 samples
		bra.b	spl_epr_pp

spl_epnr_pp	moveq	#0,d7
spl_epr_pp	swap.w	d0
		moveq	#0,d2
		
		tst.b	spl_pingpong_flag(a0)
		bne.b	mix_pong

		add.l	d0,d2		;initial add

		bra.b	mix_ssil_pp
mix_samples_inner_2_pp:	move.b	(a2,d2.w),(a1)	;dsp send 8bit
		addx.l	d0,d2
mix_ssil_pp	dbf	d3,mix_samples_inner_2_pp

		swap.w	d0

		tst.l	d7
		beq.b	mix_loop_finished_pp
mix_reinit_pp
		move.l	spl_ptr(a0),a2
		add.l	spl_loop_off(a0),a2
		add.l	spl_loop_len(a0),a2	

		st.b	spl_pingpong_flag(a0)
		bra	mix_outer_loop_pp
mix_loop_finished_pp:
		add.w	d2,a2
		move.l	a2,spl_now_playing(a0)

		bra.b	MIX_EXIT_2_pp
	;---------------------------------------
mix_pong:	sub.l	d0,d2

		bra.b	mix_ssil_ppp
mix_samples_inner_2_ppp:	move.b	(a2,d2.w),(a1)	;dsp send 8bit
		subx.l	d0,d2
mix_ssil_ppp	dbf	d3,mix_samples_inner_2_ppp

		swap.w	d0

		tst.l	d7
		beq.b	mix_loop_finished_ppp
mix_reinit_ppp
		move.l	spl_ptr(a0),a2
		add.l	spl_loop_off(a0),a2

		sf.b	spl_pingpong_flag(a0)
		bra	mix_outer_loop_pp
mix_loop_finished_ppp:
		add.w	d2,a2
		move.l	a2,spl_now_playing(a0)

MIX_EXIT_2_pp	rts
**************************************************************************************
*	OK, now similar set of routines but this time they work
*	with 16bit samples
*
**************************************************************************************

mix_16bit

		rts
;-CALC BUF LEN & MFP VALS------------------------------------------------------
P_set_frame_tick:

		move.l	replay_tick(pc),d0
		bsr	CALC_MFP
		move.b	d0,MFP_DATA
		move.b	d1,MFP_CONTROL

		move.l	dma_freq,d0
		swap.w	d0
		clr.w	d0
		divu.l	replay_tick(pc),d0

		btst	#15,d0
		beq.b	no_tick_rnd
		add.l	#$10000,d0
no_tick_rnd	swap.w	d0
		move.w	d0,bufer_len

		rts
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
P_INIT_mfp	push.w	sr
		move.w	#$2700,sr

		clr.b	$ffffffa19.w

		move.l	#TIMER_A,$134.w
		bset	#5,$ffffffa07.w	;timer a enabled...
		bclr	#5,$ffffffa13.w	;but masked

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
		;illegal

		clr.b	$ffffffa19.w		;turn the timer off 
		move.b	MFP_DATA(pc),$ffffffa1f.w	;reload timer data reg.
		move.b	MFP_CONTROL(pc),$ffffffa19.w	;reload timer mode+div reg.
		bclr	#5,$fffffa0f.w
		not.l	$ffff9800.w
	
		pusha

		tst.b	P_initial
		bne.b	ok_initial
		put_host	#"GO!"
		move.b	#1,P_initial
ok_initial
		addq.l	#1,timer_tick
						;call DSP!
		move.b	#$80+$13,$ffffa201.w	;execute dsp int at p:$26

		get_host	d0		;ready?

		move.w	bufer_len(pc),d0
		ext.l	d0
		put_host	d0

		pusha
		lea	P_VOICE_TAB(pc),a0
		bsr	P_MIX_1
		popa

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

		move.w	#1,-(a7)		;protocol (No Handshake)
		move.w	#1,-(a7)		;prescale (1 = 49170 Hz)
		move.w	#0,-(a7)		;srcclk   (0 = 25.175 int.)
		move.w	#%1001,-(a7)		;dst      (8 = DAC, 1 = DMAREC)
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
DSP_start:	incbin	g:\pulsar\puls_003.p56
DSP_end:
;-PULSAR VOID DATAS------------------------------------------------------------

dma_freq:	ds.l	1
bufer_len	ds.w	1
replay_tick	ds.l	1
feeder_ptr	ds.l	1

MFP_DATA	ds.b	1
MFP_CONTROL	ds.b	1

ini		ds.b	1
P_initial	ds.b	1

timer_tick	dc.l	0

		even

P_VOICE_TAB:	ds.b	32*spl_size

OLD_SS		ds.b	64
		even
;------------------------------------------------------------------------------
		text