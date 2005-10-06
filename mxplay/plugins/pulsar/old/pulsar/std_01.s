;-INFORMATION HEADER------------------------------------------------------------
;
;	Pulsar - a generic, platform indepandent [not yet:)], sound kernel
;
		include	dsp.s

SPL_PLAY	equ	256
SPL_STOP	equ	0
SPL_MIXING	equ	1
SPL_STOP2	equ	257

FSPL_16BIT	equ	0


FRM_DUMMY	equ	"DMY"	;this frame is void

FRM_MIX_8	equ	"M8R"	;frame ident as 8bit resampled 4 times unroled
FRM_MIX_8_2	equ	"M9R"	;frame ident as 8bit resampled
FRM_MIX_16	equ	"MFR"	;frame ident as 16bit resampled
FRM_MIX_16_2	equ	"MF2"	;frame ident as 16bit resampled

FRM_REMIX_8	equ	"M8S"	;frame ident as 8bit packed sample data that have 2 be additionaly resampled
FRM_REMIX_16	equ	"MFS"	;as above but for 16 bit

FRM_VOID	equ	"NUL"	;hellow my dsp companion, sorry but I don't need you for awhile!

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
				;	0 - silence (means that replaying was finished or wasn't started [channel wasn't used yet])
				;	1 - replay in progress
				;	256 - reinitialize replay [change compleatly sample and freq]
spl_freq:	rs.l	1	;replay frequency [Hz]
spl_panning	rs.w	1	;panning
spl_volume	rs.w	1	;volume :-)
spl_play_short	rs.b	1
spl_loop_flag1	rs.b	1
spl_pingpong_flag	rs.w	1

spl_now_playing2	rs.l	1
spl_size	rs.b	1
;-------------------------------------------------------------------------------
;	Pulsar - a generic, platform indepandent, sound kernel
;
;


;-INIT PULSAR------------------------------------------------------------------
INIT_PULSAR:	move.l	d1,replay_tick
		move.l	d3,open_ptr
		move.l	d4,close_ptr
		move.w	d5,Nb_trax

		;~~~~~~~~~~~~~~~~~~~~
		;Select DAC frequency
		;~~~~~~~~~~~~~~~~~~~~

		move.l	(pre_tab.w,pc,d0.w*4),d1
		move.w	d1,prescale
		move.l	(freq_tab.w,pc,d0.w*4),d1
		move.l	d1,dma_freq
		move.l	(firr_tab.w,pc,d0.w*4),d1
		add.l	#FIRR_coeffs,d1
		move.l	d1,firr_tab_base

		move.l	replay_tick(pc),d0
		bsr	P_set_frame_tick
		bsr	P_DSP_I
		move.b	#$80+$14,$ffffa201.w	;execute dsp int at p:$26
		bsr	P_SOUND_I
		bsr	P_INIT_mfp

		lea	P_VOICE_TAB(pc),a0
		move.w	#spl_size*32/4-1,d7
		moveq	#0,d0
PL_clr_voices:	move.l	d0,(a0)+
		dbf	d7,PL_clr_voices

		rts
;-ALLOCATE PULSAR--------------------------------------------------------------
;	input:	none
;	output: d0 -pointer to chanel structures if allright
;		   -or negative error code if something wrong
ALLOC_SOUND:	move.l	#P_VOICE_TAB,d0
		rts

;-ENABLE MIX-------------------------------------------------------------------
;
ENABLE_MIX:	put_host	#"GO!"
		move.b	MFP_DATA(pc),$ffffffa1f.w
		move.b	MFP_CONTROL(pc),$ffffffa19.w
		bset	#5,$fffffa13.w	;run my interrupt
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
P_MIX_1:	
		btst	#0,spl_flags+1(a0)
		bne	mix_16bit

		move.w	spl_state(a0),d7
		bne.b	spl_mix_no_void

		;cmp.l	#$ffff,spl_ptr(a0)
		;ble.b	spl_mix_no_void
spl_mix_void:
		put_host #FRM_DUMMY
		rts		
spl_mix_no_void:
	;
		;illegal
		moveq	#0,d1
		move.l	spl_freq(a0),d0	;desired frequency
		swap.w	d0
		move.w	d0,d1
		clr.w	d0		
		divu.l	dma_freq(pc),d1:d0

		tst.w	spl_volume(a0)
		beq	MIX_VOID_8

		cmp.l	#$00010000,d0
		bgt.b	fuck_shit_on
		
		addq.l	#1,perfect_dsp_hit
fuck_shit_on
		cmp.l	#1024*4,spl_len(a0)
		ble	PL_spl8bsc
		cmp.l	#1024*8,spl_loop_len(a0)
		ble	PL_spl8bsc

		addq.l	#1,imperfect_hit
	;

		put_host #FRM_MIX_8	;tell dsp to mix 8bit as input

		moveq	#0,d2
		move.w	spl_volume(a0),d2
		divu.w	Nb_trax(pc),d2
		ext.l	d2
		put_host	d2		;send volume

		move.w	spl_panning(a0),d1
		muls.w	d2,d1
		divs.w	#$7fff,d1
		ext.l	d1
		put_host	d1		;send panning

		lea	$fffffa207.w,a1	;host adr -> a1
		lea	$fffffa206.w,a4	;host adr -> a1

   ********************************************************************
   *	   Mix 8bit with loops, both normal and ping-pong,            *
   *	   and output mixed datas to the dsp part of mixer            *
   ********************************************************************

		cmp.w	#SPL_PLAY,d7
		bne.b	spl_no_change

		move.l	spl_ptr(a0),spl_now_playing(a0)

		move.w	#1,spl_state(a0)
		clr.b	spl_play_short(a0)
		clr.b	spl_loop_flag1(a0)
		clr.b	spl_pingpong_flag(a0)

spl_no_change				;d0 -> fixed point step value
		moveq	#0,d2
		clr.b	spl_loop_flag1(a0)

		bfextu	spl_flags(a0){13:2},d1
		cmp.b	#1,d1
		beq	mix_normal_loop
		cmp.b	#2,d1
		beq	mix_ping_loop

**********************************************************************************
*              OK, so if there's no loops then check if                          *
*              sample is expired                                                 *
**********************************************************************************

		move.l	spl_now_playing(a0),a2

		move.l	d0,d1
		moveq	#0,d3
		move.w	bufer_len(pc),d3
		mulu.l	d3,d1
		round.l	d1
		swap.w	d1
		lea	(a2,d1.w),a3	;will 2 point frame end sample

		moveq	#0,d5
		move.l	a3,spl_now_playing(a0)

		move.l	spl_len(a0),d4
		add.l	spl_ptr(a0),d4	;d4=spl_end
		
		sub.l	a3,d4		;current buffor end position minus
					;sample end
		;bpl.b	spl_mix_full_buffer
	
		abs.l	d4

		;asr.l	d4	
		swap.w	d4
		moveq	#0,d5
		move.w	d4,d5
		clr.w	d4
		divu.l	d0,d5:d4

		;abs.l	d4
		cmp.l	d3,d4
		bgt.b	spl_mix_full_buffer

		;neg.l	d4
		st	spl_play_short(a0)
		move.l	d4,d3

spl_mix_full_buffer:
		move.l	#$80000000,d2
		swap.w	d0
		
		put_host	d3

		lsr.w	#2,d3
		add.l	d0,d2
		bra.b	mix_samples_inner_8
mix_samples_inner_1:
		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		addx.l	d0,d2
		move.b	(a2,d2.w),(a1)
		addx.l	d0,d2
		nop
		nop

		;ifd	sdfdsffd
		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		addx.l	d0,d2
		move.b	(a2,d2.w),(a1)
		addx.l	d0,d2
		nop
		nop
		;endc

mix_samples_inner_8:	dbf	d3,mix_samples_inner_1

		subx.l	d0,d2
		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		move.b	(a2,d2.w),(a1)
		nop
		nop
		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		move.b	(a2,d2.w),(a1)
		nop
		nop
		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		move.b	(a2,d2.w),(a1)

		tst.b	spl_play_short(a0)
		beq.b	spl_sample_not_expired		
		clr.w	spl_state(a0)
spl_sample_not_expired:

MIX_EXIT_1_OK:	rts
***********************************************************************************
*                     Heare U have normal loop service:                           *
***********************************************************************************
mix_normal_loop:
		moveq	#0,d4
		moveq	#0,d3
		move.w	bufer_len(pc),d3
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

		move.l	spl_loop_len(a0),d5
		add.l	spl_loop_off(a0),d5
		add.l	spl_ptr(a0),d5

		cmp.l	a2,d5
		ble	mix_reinit

		sub.l	a3,d5		;(current end buffer pos)-(sample rep end point)
		bge.b	spl_epnr
		neg.l	d5

		swap.w	d5
		clr.w	d5
		divu.l	d0,d5		;get it into buffer unit
		ext.l	d5

		move.l	d5,d7
		sub.l	d5,d3

		bra.b	spl_epr

spl_epnr	moveq	#0,d7
spl_epr		swap.w	d0
		moveq	#0,d2
		
		move.w	d3,d4
		lsr.w	#2,d3	
		add.l	d0,d2
		bra.b	mix_ssil
mix_samples_inner_2:
		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		addx.l	d0,d2
		move.b	(a2,d2.w),(a1)
		addx.l	d0,d2
		nop
		nop

		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		addx.l	d0,d2
		move.b	(a2,d2.w),(a1)
		addx.l	d0,d2
		nop
		nop

mix_ssil	dbf	d3,mix_samples_inner_2


		subx.l	d0,d2
		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		move.b	(a2,d2.w),(a1)
		nop
		nop
		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		move.b	(a2,d2.w),(a1)
		nop
		nop
		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		move.b	(a2,d2.w),(a1)

		swap.w	d0

		tst.w	d7
		beq.b	mix_loop_finished
mix_reinit
		move.l	spl_loop_off(a0),a2
		add.l	spl_ptr(a0),a2

		bra	mix_outer_loop
mix_loop_finished:
		add.w	d2,a2
		move.l	a2,spl_now_playing(a0)

MIX_EXIT_2	
		rts
***********************************************************************************
*                     Heare U have ping-pong loop service:                        *
***********************************************************************************
mix_ping_loop:	
		moveq	#0,d3
		move.w	bufer_len(pc),d3
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
		;moveq	#0,d2
		;and.l	#$3ff,d3
		move.l	#$80000000,d2
		
		tst.b	spl_pingpong_flag(a0)
		bne.b	mix_pong

		add.l	d0,d2		;initial add

		;and.l	#$fff,d3
		;put_host	d3
		;tst.w	d3
		;beq	MIX_EXIT_2_pp_a

		lsr.w	#2,d3
		bra.b	mix_ssil_pp
mix_samples_inner_2_pp:
		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		addx.l	d0,d2
		move.b	(a2,d2.w),(a1)
		addx.l	d0,d2
		nop
		nop

		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		addx.l	d0,d2
		move.b	(a2,d2.w),(a1)
		addx.l	d0,d2
		nop
		nop
mix_ssil_pp	dbf	d3,mix_samples_inner_2_pp

		subx.l	d0,d2
		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		move.b	(a2,d2.w),(a1)
		nop
		nop
		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		move.b	(a2,d2.w),(a1)
		nop
		nop
		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		move.b	(a2,d2.w),(a1)
		
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
		lsr.w	#2,d3
		bra.b	mix_ssil_ppp
mix_samples_inner_2_ppp:
		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		subx.l	d0,d2
		move.b	(a2,d2.w),(a1)
		subx.l	d0,d2
		nop
		nop

		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		subx.l	d0,d2
		move.b	(a2,d2.w),(a1)
		subx.l	d0,d2
		nop
		nop
mix_ssil_ppp	dbf	d3,mix_samples_inner_2_ppp

		addx.l	d0,d2
		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		move.b	(a2,d2.w),(a1)
		nop
		nop
		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		move.b	(a2,d2.w),(a1)
		nop
		nop
		move.b	(a2,d2.w),(a4)	;dsp send 8bit
		move.b	(a2,d2.w),(a1)

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

MIX_EXIT_2_pp
MIX_EXIT_2_OK_pp:

		rts

;行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行
;Special case coding

PL_spl8bsc:	put_host #FRM_MIX_8_2	;tell dsp to mix 8bit as input

		moveq	#0,d2
		move.w	spl_volume(a0),d2
		divu.w	Nb_trax(pc),d2
		ext.l	d2
		put_host	d2		;send volume

		move.w	spl_panning(a0),d1
		muls.w	d2,d1
		divs.w	#$7fff,d1
		ext.l	d1
		put_host	d1		;send panning

		lea	$fffffa207.w,a1	;host adr -> a1

		addq.l	#1,perfect_hit

   ********************************************************************
   *	   Mix 8bit with loops, both normal and ping-pong,            *
   *	   and output mixed datas to the dsp part of mixer            *
   ********************************************************************

		cmp.w	#SPL_PLAY,d7
		bne.b	PL_spl_no_change_sc

		move.l	spl_ptr(a0),spl_now_playing(a0)

		move.w	#1,spl_state(a0)
		clr.b	spl_play_short(a0)
		clr.b	spl_loop_flag1(a0)
		clr.b	spl_pingpong_flag(a0)

PL_spl_no_change_sc		;d0 -> fixed point step value
		moveq	#0,d2
		clr.b	spl_loop_flag1(a0)

		bfextu	spl_flags(a0){13:2},d1
		cmp.b	#1,d1
		beq	PL_mix_normal_loop_sc
		cmp.b	#2,d1
		beq	PL_mix_ping_loop_sc
;行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行行
PL_mix8b_sc
		move.l	spl_now_playing(a0),a2

		move.l	d0,d1
		moveq	#0,d3
		move.w	bufer_len(pc),d3
		mulu.l	d3,d1
		round.l	d1
		swap.w	d1
		lea	(a2,d1.w),a3	;will 2 point frame end sample

		moveq	#0,d5
		move.l	a3,spl_now_playing(a0)

		move.l	spl_len(a0),d4
		add.l	spl_ptr(a0),d4	;d4=spl_end
		
		sub.l	a3,d4		;current buffor end position minus
					;sample end
	
		abs.l	d4

		;asr.l	d4	
		swap.w	d4
		moveq	#0,d5
		move.w	d4,d5
		clr.w	d4
		divu.l	d0,d5:d4

		;abs.l	d4
		cmp.l	d3,d4
		bgt.b	PL_spl_mix_full_buffer_sc

		;neg.l	d4
		st	spl_play_short(a0)
		move.l	d4,d3

PL_spl_mix_full_buffer_sc:
		move.l	#$80000000,d2
		swap.w	d0
		
		put_host	d3

		add.l	d0,d2
		bra.b	PL_mix_samples_inner_8_sc
PL_mix_samples_inner_1_sc:
		move.b	(a2,d2.w),(a1)
		addx.l	d0,d2
PL_mix_samples_inner_8_sc:
		dbf	d3,PL_mix_samples_inner_1_sc

		tst.b	spl_play_short(a0)
		beq.b	PL_spl_sample_not_expired_sc
		clr.w	spl_state(a0)
PL_spl_sample_not_expired_sc:

		rts
***********************************************************************************
*                     Heare U have normal loop service:                           *
***********************************************************************************
PL_mix_normal_loop_sc:
		moveq	#0,d4
		moveq	#0,d3
		move.w	bufer_len(pc),d3
		put_host	d3	;dsp -> mix d3 samples
		move.l	spl_now_playing(a0),a2
		moveq	#0,d7
PL_mix_outer_loop_sc:
		tst.l	d7
		beq.b	PL_mix_loop_first_attempt_sc
		move.l	d7,d3		;<-we've left with d3 samples
PL_mix_loop_first_attempt_sc:
		move.l	d0,d1
		mulu.l	d3,d1
		swap.w	d1
		lea	(a2,d1.w),a3	;will point 2 frame end sample

		move.l	spl_loop_len(a0),d5
		add.l	spl_loop_off(a0),d5
		add.l	spl_ptr(a0),d5

		cmp.l	a2,d5
		ble	PL_mix_reinit_sc

		sub.l	a3,d5		;(current end buffer pos)-(sample rep end point)
		bge.b	PL_spl_epnr_sc
		neg.l	d5

		swap.w	d5
		clr.w	d5
		divu.l	d0,d5		;get it into buffer unit
		ext.l	d5

		move.l	d5,d7
		sub.l	d5,d3

		bra.b	PL_spl_epr_sc

PL_spl_epnr_sc	moveq	#0,d7
PL_spl_epr_sc	swap.w	d0
		moveq	#0,d2
		
		add.l	d0,d2
		bra.b	PL_mix_ssil_sc
PL_mix_samples_inner_2_sc:
		move.b	(a2,d2.w),(a1)
		addx.l	d0,d2

PL_mix_ssil_sc	dbf	d3,PL_mix_samples_inner_2_sc

		swap.w	d0

		tst.w	d7
		beq.b	PL_mix_loop_finished_sc
PL_mix_reinit_sc
		move.l	spl_loop_off(a0),a2
		add.l	spl_ptr(a0),a2

		bra	PL_mix_outer_loop_sc
PL_mix_loop_finished_sc:
		add.w	d2,a2
		move.l	a2,spl_now_playing(a0)

		rts
***********************************************************************************
*                     Heare U have ping-pong loop service:                        *
***********************************************************************************
PL_mix_ping_loop_sc:
		moveq	#0,d3
		move.w	bufer_len(pc),d3
		put_host	d3	;dsp -> mix d3 samples
		move.l	spl_now_playing(a0),a2
		moveq	#0,d7
PL_mix_outer_loop_pp_sc:
		tst.l	d7
		beq.b	PL_mix_loop_first_attempt_pp_sc
		move.l	d7,d3		;<-we've left with d3 samples
PL_mix_loop_first_attempt_pp_sc:
		move.l	d0,d1
		mulu.l	d3,d1
		swap.w	d1

		tst.b	spl_pingpong_flag(a0)
		beq.b	PL_spl_ping_forth_sc		;playing forward
			
		move.l	a2,a3				;playing backward
		sub.w	d1,a3	
		move.l	spl_ptr(a0),d5
		add.l	spl_loop_off(a0),d5

		cmp.l	a2,d5
		bhi	PL_mix_reinit_ppp_sc

		sub.l	a3,d5		;(current end buffer pos)-(sample rep end point)
		bmi.b	PL_spl_epnr_pp_sc

		swap.w	d5
		clr.w	d5
		divu.l	d0,d5		;get it into buffer unit
		;swap.w	d5
		ext.l	d5
		sub.l	d5,d3
		move.l	d5,d7		;we left with d7 samples
		bra.b	PL_spl_epr_pp_sc
	;-----------------------------------------
PL_spl_ping_forth_sc
		lea	(a2,d1.w),a3	;will point 2 frame end sample

		move.l	spl_ptr(a0),d5
		add.l	spl_loop_off(a0),d5
		add.l	spl_loop_len(a0),d5

		cmp.l	a2,d5
		bls.b	PL_mix_reinit_pp_sc

		sub.l	a3,d5		;(current end buffer pos)-(sample rep end point)
		bpl.b	PL_spl_epnr_pp_sc
		neg.l	d5

		swap.w	d5
		clr.w	d5
		divu.l	d0,d5		;get it into buffer unit
		;swap.w	d5
		ext.l	d5
		sub.l	d5,d3
		move.l	d5,d7		;we left with d7 samples
		bra.b	PL_spl_epr_pp_sc

PL_spl_epnr_pp_sc:	moveq	#0,d7
PL_spl_epr_pp_sc:	swap.w	d0
		move.l	#$80000000,d2
		
		tst.b	spl_pingpong_flag(a0)
		bne.b	PL_mix_pong_sc

		add.l	d0,d2		;initial add
		bra.b	PL_mix_ssil_pp_sc
PL_mix_samples_inner_2_pp_sc:
		move.b	(a2,d2.w),(a1)
		addx.l	d0,d2
PL_mix_ssil_pp_sc	dbf	d3,PL_mix_samples_inner_2_pp_sc

		swap.w	d0

		tst.l	d7
		beq.b	PL_mix_loop_finished_pp_sc
PL_mix_reinit_pp_sc
		move.l	spl_ptr(a0),a2
		add.l	spl_loop_off(a0),a2
		add.l	spl_loop_len(a0),a2	

		st.b	spl_pingpong_flag(a0)
		bra	PL_mix_outer_loop_pp_sc
PL_mix_loop_finished_pp_sc:
		add.w	d2,a2
		move.l	a2,spl_now_playing(a0)

		bra.b	PL_quit_pp_sc
	;---------------------------------------
PL_mix_pong_sc:	sub.l	d0,d2
		bra.b	PL_mix_ssil_ppp_sc
PL_mix_samples_inner_2_ppp_sc:
		subx.l	d0,d2
		move.b	(a2,d2.w),(a1)
PL_mix_ssil_ppp_sc	dbf	d3,PL_mix_samples_inner_2_ppp_sc

		swap.w	d0

		tst.l	d7
		beq.b	PL_mix_loop_finished_ppp_sc
PL_mix_reinit_ppp_sc
		move.l	spl_ptr(a0),a2
		add.l	spl_loop_off(a0),a2

		sf.b	spl_pingpong_flag(a0)
		bra	PL_mix_outer_loop_pp_sc
PL_mix_loop_finished_ppp_sc:
		add.w	d2,a2
		move.l	a2,spl_now_playing(a0)
PL_quit_pp_sc
		rts

;
MIX_VOID_8:	;illegal
		put_host #FRM_VOID	;tell dsp to mix 8bit as input

		addq.l	#1,silence_hit

   ********************************************************************
   *	   Mix 8bit with loops, both normal and ping-pong,            *
   *	   and output mixed datas to the dsp part of mixer            *
   ********************************************************************

		cmp.w	#SPL_PLAY,d7
		bne.b	PL_spl_no_change_nv

		move.l	spl_ptr(a0),spl_now_playing(a0)

		move.w	#1,spl_state(a0)
		clr.b	spl_play_short(a0)
		clr.b	spl_loop_flag1(a0)
		clr.b	spl_pingpong_flag(a0)

PL_spl_no_change_nv		;d0 -> fixed point step value
		moveq	#0,d2
		clr.b	spl_loop_flag1(a0)

		bfextu	spl_flags(a0){13:2},d1
		cmp.b	#1,d1
		beq	MIX_null_vol_lp
		cmp.b	#2,d1
		beq	MIX_null_vol_pp
;
MIX_null_vol:	

		move.l	spl_now_playing(a0),a2

		move.l	d0,d1
		moveq	#0,d3
		move.w	bufer_len(pc),d3
		mulu.l	d3,d1
		round.l	d1
		swap.w	d1
		lea	(a2,d1.w),a3	;will 2 point frame end sample

		moveq	#0,d5
		move.l	a3,spl_now_playing(a0)

		move.l	spl_len(a0),d4
		add.l	spl_ptr(a0),d4	;d4=spl_end
		
		sub.l	a3,d4		;current buffor end position minus
					;sample end
		abs.l	d4

		swap.w	d4
		moveq	#0,d5
		move.w	d4,d5
		clr.w	d4
		divu.l	d0,d5:d4

		tst.b	spl_play_short(a0)
		beq.b	spl_sample_not_expired_nv
		clr.w	spl_state(a0)
spl_sample_not_expired_nv:

		rts
***********************************************************************************
*                     Heare U have normal loop service:                           *
***********************************************************************************
MIX_null_vol_lp:
		moveq	#0,d4
		moveq	#0,d3
		move.w	bufer_len(pc),d3
		move.l	spl_now_playing(a0),a2
		moveq	#0,d7
mix_outer_loop_nv:
		tst.l	d7
		beq.b	mix_loop_first_attempt_nv
		move.l	d7,d3		;<-we've left with d3 samples
mix_loop_first_attempt_nv:
		move.l	d0,d1
		mulu.l	d3,d1
		swap.w	d1
		lea	(a2,d1.w),a3	;will point 2 frame end sample

		move.l	spl_loop_len(a0),d5
		add.l	spl_loop_off(a0),d5
		add.l	spl_ptr(a0),d5

		cmp.l	a2,d5
		ble	mix_reinit_nv

		sub.l	a3,d5		;(current end buffer pos)-(sample rep end point)
		bge.b	spl_epnr_nv
		neg.l	d5

		swap.w	d5
		clr.w	d5
		divu.l	d0,d5		;get it into buffer unit
		ext.l	d5

		move.l	d5,d7
		sub.l	d5,d3

		bra.b	spl_epr_nv

spl_epnr_nv	moveq	#0,d7
spl_epr_nv		
		move.l	d3,d2
		mulu.l	d0,d2
		swap.w	d2

		tst.w	d7
		beq.b	mix_loop_finished_nv
mix_reinit_nv
		move.l	spl_loop_off(a0),a2
		add.l	spl_ptr(a0),a2

		bra	mix_outer_loop_nv
mix_loop_finished_nv:
		add.w	d2,a2
		move.l	a2,spl_now_playing(a0)

		rts
***********************************************************************************
*                     Heare U have ping-pong loop service:                        *
***********************************************************************************
MIX_null_vol_pp:
		moveq	#0,d3
		move.w	bufer_len(pc),d3
		move.l	spl_now_playing(a0),a2
		moveq	#0,d7
mix_outer_loop_pp_nv:
		tst.l	d7
		beq.b	mix_loop_first_attempt_pp_nv
		move.l	d7,d3		;<-we've left with d3 samples
mix_loop_first_attempt_pp_nv:
		move.l	d0,d1
		mulu.l	d3,d1
		swap.w	d1

		tst.b	spl_pingpong_flag(a0)
		beq.b	spl_ping_forth_nv			;playing forward
			
		move.l	a2,a3				;playing backward
		sub.w	d1,a3	
		move.l	spl_ptr(a0),d5
		add.l	spl_loop_off(a0),d5

		cmp.l	a2,d5
		bhi	mix_reinit_ppp_nv

		sub.l	a3,d5		;(current end buffer pos)-(sample rep end point)
		bmi.b	spl_epnr_pp_nv

		swap.w	d5
		clr.w	d5
		divu.l	d0,d5		;get it into buffer unit
		;swap.w	d5
		ext.l	d5
		sub.l	d5,d3
		move.l	d5,d7		;we left with d7 samples
		bra.b	spl_epr_pp_nv
	;-----------------------------------------
spl_ping_forth_nv
		lea	(a2,d1.w),a3	;will point 2 frame end sample

		move.l	spl_ptr(a0),d5
		add.l	spl_loop_off(a0),d5
		add.l	spl_loop_len(a0),d5

		cmp.l	a2,d5
		bls.b	mix_reinit_pp_nv

		sub.l	a3,d5		;(current end buffer pos)-(sample rep end point)
		bpl.b	spl_epnr_pp_nv
		neg.l	d5

		swap.w	d5
		clr.w	d5
		divu.l	d0,d5		;get it into buffer unit
		;swap.w	d5
		ext.l	d5
		sub.l	d5,d3
		move.l	d5,d7		;we left with d7 samples
		bra.b	spl_epr_pp_nv

spl_epnr_pp_nv	moveq	#0,d7
spl_epr_pp_nv	
		tst.b	spl_pingpong_flag(a0)
		bne.b	mix_pong_nv

		move.l	d3,d2
		mulu.l	d0,d2
		swap.w	d2
		
		tst.l	d7
		beq.b	mix_loop_finished_pp_nv
mix_reinit_pp_nv:
		move.l	spl_ptr(a0),a2
		add.l	spl_loop_off(a0),a2
		add.l	spl_loop_len(a0),a2	

		st.b	spl_pingpong_flag(a0)
		bra	mix_outer_loop_pp_nv
mix_loop_finished_pp_nv:
		add.w	d2,a2
		move.l	a2,spl_now_playing(a0)

		rts
	;---------------------------------------
mix_pong_nv:	move.l	d3,d2
		mulu.l	d0,d2
		swap.w	d2
		and.l	#$ffff,d2
		neg.l	d2

		tst.l	d7
		beq.b	mix_loop_finished_ppp_nv
mix_reinit_ppp_nv
		move.l	spl_ptr(a0),a2
		add.l	spl_loop_off(a0),a2

		sf.b	spl_pingpong_flag(a0)
		bra	mix_outer_loop_pp_nv
mix_loop_finished_ppp_nv:
		add.w	d2,a2
		move.l	a2,spl_now_playing(a0)

		rts
**************************************************************************************
*	OK, now similar set of routines but this time they work
*	with 16bit samples
*
**************************************************************************************

mix_16bit	;illegal
		move.w	spl_state(a0),d7
		beq.b	mix_void_2

		moveq	#0,d0
		move.w	spl_volume(a0),d0

		bne.b	spl_volume_gz_2
mix_void_2:
		put_host	#FRM_DUMMY
		rts

spl_volume_gz_2	put_host	#FRM_MIX_16	;tell dsp to take 16bit as input

		divu.w	Nb_trax(pc),d0
		ext.l	d0
		put_host	d0		;send volume

		move.w	spl_panning(a0),d1
		muls.w	d0,d1
		divs.w	#$7fff,d1

		ext.l	d1
		put_host	d1		;send panning

		lea	$fffffa206.w,a1	;host adr -> a1
   ********************************************************************
   *	   Mix 16bit with loops, both normal and ping-pong,            *
   *	   and output mixed datas to the dsp part of mixer            *
   ********************************************************************

		cmp.w	#256,d7
		bne.b	spl_no_change_16

		move.l	spl_ptr(a0),spl_now_playing(a0)

		move.w	#1,spl_state(a0)
		clr.b	spl_play_short(a0)
		clr.b	spl_pingpong_flag(a0)

spl_no_change_16	moveq	#0,d1
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
		beq	mix_normal_loop_16
		cmp.b	#2,d1
		beq	mix_ping_loop_16

**********************************************************************************
*              OK, so if no loops then check if                                  *
*              sample is expired                                                 *
**********************************************************************************
		;illegal

		move.l	spl_now_playing(a0),a2

		move.l	d0,d1
		moveq	#0,d3
		move.w	bufer_len(pc),d3
		mulu.l	d3,d1
		round.l	d1
		swap.w	d1
		lea	(a2,d1.w*2),a3	;will point 2  frame end sample

		moveq	#0,d5
		move.l	a3,spl_now_playing(a0)

		move.l	spl_len(a0),d4
		lsl.l	d4		;16bit!
		add.l	spl_ptr(a0),d4	;d4=spl_end
		
		sub.l	a3,d4		;current buffor end position minus
		abs.l	d4

		asr.l	d4
		swap.w	d4
		moveq	#0,d5
		move.w	d4,d5
		clr.w	d4
		divu.l	d0,d5:d4
					;sample end
		;abs.l	d4
		cmp.l	d3,d4
		bgt.b	spl_mix_full_buffer_16

		st	spl_play_short(a0)
		move.l	d4,d3

spl_mix_full_buffer_16:
		move.l	#$80000000,d2
		swap.w	d0

		put_host	d3

		add.l	d0,d2

		bra.b	mix_samples_inner_begin
mix_samples_inner_16:	move.w	(a2,d2.w*2),(a1)	;dsp send 8bit
		addx.l	d0,d2
mix_samples_inner_begin:	dbf	d3,mix_samples_inner_16

		tst.b	spl_play_short(a0)
		beq.b	spl_sample_not_expired_16
		clr.w	spl_state(a0)
spl_sample_not_expired_16:

MIX_EXIT_16
		rts
***********************************************************************************
*                     Heare U have normal loop service:                           *
***********************************************************************************

mix_normal_loop_16:	;illegal
		moveq	#0,d4
		moveq	#0,d3
		move.w	bufer_len(pc),d3
		put_host	d3	;dsp -> mix d3 samples
		move.l	spl_now_playing(a0),a2
		moveq	#0,d7

mix_outer_loop_16:
		tst.l	d7
		beq.b	mix_loop_first_attempt_16
		move.l	d7,d3		;<-we've left with d3 samples
		;addq.w	#1,temp_mix
mix_loop_first_attempt_16:
		move.l	d0,d1
		mulu.l	d3,d1
		round.l	d1
		swap.w	d1
		lea	(a2,d1.w*2),a3	;will point 2 frame end sample

		move.l	spl_ptr(a0),d5
		move.l	spl_loop_off(a0),d2
		add.l	spl_loop_len(a0),d2
		lsl.l	d2
		add.l	d2,d5

		cmp.l	a2,d5
		ble.b	mix_reinit_16

		sub.l	a3,d5		;(current end buffer pos)-(sample rep end point)
		bpl.b	spl_epnr_16
		neg.l	d5

		lsr.l	d5	;16bit!!!

		swap.w	d5
		clr.w	d5
		divu.l	d0,d5		;get it into buffer unit
		ext.l	d5

		sub.w	d5,d3
		move.l	d5,d7		;we left with d7 samples

		bra.b	spl_epr_16

spl_epnr_16	moveq	#0,d7
spl_epr_16	swap.w	d0	
		move.l	#$80000000,d2

		add.l	d3,d4
		add.l	d0,d2		;initial add
	
		bra.b	mix_ssil_16
mix_samples_inner_2_16:	move.w	(a2,d2.w*2),(a1)	;dsp send 8bit
		addx.l	d0,d2
mix_ssil_16	dbf	d3,mix_samples_inner_2_16

		swap.w	d0

		tst.l	d7
		beq.b	mix_loop_finished_16
mix_reinit_16

		move.l	spl_ptr(a0),a2
		move.l	spl_loop_off(a0),d2
		lsl.l	d2
		add.l	d2,a2

		bra	mix_outer_loop_16
mix_loop_finished_16:

		lea	(a2,d2.w*2),a2		;16bit!!!
		move.l	a2,spl_now_playing(a0)
MIX_EXIT_2_16
		rts

***********************************************************************************
*                     Heare U have ping-pong loop service:                        *
***********************************************************************************
mix_ping_loop_16:	;illegal
		moveq	#0,d3
		move.w	bufer_len(pc),d3
		put_host	d3	;dsp -> mix d3 samples
		move.l	spl_now_playing(a0),a2
		moveq	#0,d7
mix_outer_loop_pp_16:
		tst.l	d7
		beq.b	mix_loop_first_attempt_pp_16
		move.l	d7,d3		;<-we've left with d3 samples
mix_loop_first_attempt_pp_16:
		move.l	d0,d1
		mulu.l	d3,d1
		swap.w	d1

		tst.b	spl_pingpong_flag(a0)
		beq.b	spl_ping_forth_16			;playing forward
	
	;-----------------------------------------
		move.l	a2,a3				;playing backward
		lsl.l	d1
		sub.w	d1,a3	
		move.l	spl_ptr(a0),d5
		move.l	spl_loop_off(a0),d2
		lsl.l	d2
		add.l	d2,d5
		
		cmp.l	a2,d5
		bhi	mix_reinit_ppp_16

		sub.l	a3,d5		;(current end buffer pos)-(sample rep end point)
		bmi.b	spl_epnr_pp_16
		lsr.l	d5
		swap.w	d5
		clr.w	d5
		divu.l	d0,d5		;get it into buffer unit
		ext.l	d5
		sub.l	d5,d3
		move.l	d5,d7		;we left with d7 samples
		bra.b	spl_epr_pp_16
	;-----------------------------------------
spl_ping_forth_16
		lea	(a2,d1.w*2),a3	;will point 2 frame end sample

		move.l	spl_ptr(a0),d5
		move.l	spl_loop_off(a0),d2
		lsl.l	d2
		add.l	d2,d5
		move.l	spl_loop_len(a0),d2
		lsl.l	d2
		add.l	d2,d5

		cmp.l	a2,d5
		bls.b	mix_reinit_pp_16

		sub.l	a3,d5		;(current end buffer pos)-(sample rep end point)
		bpl.b	spl_epnr_pp_16
		neg.l	d5
		lsr.l	d5
		swap.w	d5
		clr.w	d5
		divu.l	d0,d5		;get it into buffer unit
		ext.l	d5
		sub.l	d5,d3
		move.l	d5,d7		;we left with d7 samples
		bra.b	spl_epr_pp_16

spl_epnr_pp_16	moveq	#0,d7
spl_epr_pp_16	swap.w	d0
		moveq	#0,d2
		
		tst.b	spl_pingpong_flag(a0)
		bne.b	mix_pong_16

		add.l	d0,d2		;initial add

		bra.b	mix_ssil_pp_16
mix_samples_inner_2_pp_16:	move.w	(a2,d2.w*2),(a1)	;dsp send 8bit
		addx.l	d0,d2
mix_ssil_pp_16	dbf	d3,mix_samples_inner_2_pp_16

		swap.w	d0

		tst.l	d7
		beq.b	mix_loop_finished_pp_16
mix_reinit_pp_16
		move.l	spl_ptr(a0),a2
		move.l	spl_loop_off(a0),d2
		lea	(a2,d2.l*2),a2
		move.l	spl_loop_len(a0),d2
		lea	(a2,d2.l*2),a2

		st.b	spl_pingpong_flag(a0)
		bra	mix_outer_loop_pp_16
mix_loop_finished_pp_16:
		lea	(a2,d2.w*2),a2
		move.l	a2,spl_now_playing(a0)

		bra.b	MIX_EXIT_2_pp_16
	;---------------------------------------
mix_pong_16:	sub.l	d0,d2

		bra.b	mix_ssil_ppp_16
mix_samples_inner_2_ppp_16:	move.w	(a2,d2.w*2),(a1)	;dsp send 8bit
		subx.l	d0,d2
mix_ssil_ppp_16	dbf	d3,mix_samples_inner_2_ppp_16

		swap.w	d0

		tst.l	d7
		beq.b	mix_loop_finished_ppp_16
mix_reinit_ppp_16
		move.l	spl_ptr(a0),a2
		move.l	spl_loop_off(a0),d2
		lea	(a2,d2.l*2),a2

		sf.b	spl_pingpong_flag(a0)
		bra	mix_outer_loop_pp_16
mix_loop_finished_ppp_16:
		lea	(a2,d2.w*2),a2
		move.l	a2,spl_now_playing(a0)
MIX_EXIT_2_pp_16

		rts
;*******************************************************************************
;
;
;-CALC BUF LEN & MFP VALS-------------------------------------------------------
;
;
;*******************************************************************************		
P_set_frame_tick:
		clr.w	timer_delay
		clr.w	timer_delay_work
check_freq:
		cmp.l	#60*$100,d0		;minimum freq rate (to avoid receive buffer overflow)
		bge.b	freq_ok
		lsl.l	d0
		addq.w	#1,timer_delay
		bra.b	check_freq
freq_ok:
		bsr	CALC_MFP
		move.b	d0,MFP_DATA
		move.b	d1,MFP_CONTROL

		rts
;-MFP CALC TIMER VALS----------------------------------------------------------
;	input:	d0.l - requested freq in [Hz*$100]
;	output: d0 - timer data reg
;		d1 - timerm control reg

CALC_MFP:	lea	MFP_TAB(pc),a0
		moveq	#0,d1

MFP_recalc	cmp.l	#MFP_TAB_E,a0
		beq.b	MFP_NO_FREQ	;should never happend (in pulsar!)

		move.l	#2457600*$100,d2	;MFP clock freq...
		moveq	#0,d3
		move.w	(a0)+,d3
		move.w	(a0)+,d1
		divu.l	d3,d2
		lsl.l	#8,d2
		divu.l	d0,d2

		cmp.l	#$ff,d2
		bgt.b	MFP_recalc
		move.l	d2,d0
MFP_NO_FREQ
		rts
MFP_TAB		dc.w	200*$100,7,100*$100,6,64*$100,5,50*$100,4,16*$100,3,10*$100,2,4*$100,1
MFP_TAB_E	even

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
debug_mode_0

TIMER_A:	
		tst.b	saturation(pc)
		bne	timer_exit

		move.b	#1,saturation
	;---INITIAL PART---------------------------------
		move.b	MFP_DATA(pc),$ffffffa1f.w	;reload timer data reg.
		move.b	MFP_CONTROL(pc),$ffffffa19.w	;reload timer mode+div reg.

		bclr	#3,icr.w

		;ifnd	debug_mode_0
		move.w	#$2500,sr	
		bclr	#5,$fffffa0f.w		;mask off timer A
		;endc	

		pusha
		addq.l	#1,timer_tick	;useful for debugging??

	;----SYNCHRONIZE---------------------------------
						;call DSP!
		move.b	#$80+$13,$ffffa201.w	;execute dsp int at p:$26

		get_host	d0		;ready?

		get_host	d0
		;beq	MIX_EXIT
		move.w	d0,bufer_len
	;------------------------------------------------
		move.l	firr_tab_base,a0
		add.l	#0*30,a0
		moveq	#10-1,d7

firr_send:	wait_transmit
		move.b	(a0)+,$ffffffa205.w
		move.b	(a0)+,$ffffffa206.w
		move.b	(a0)+,$ffffffa207.w
		dbf	d7,firr_send

	;------------------------------------------------
		subq.w	#1,timer_delay_work
		
		move.w	timer_delay_work(pc),_timer_delay_work

		tst.w	_timer_delay_work(pc)
		bpl.b	skip_open_user

		jsr	([pc,open_ptr.w])

		move.l	d0,a6
		movem.l	a0-a4,sav_regz
		
skip_open_user
	;----MIX ALL CHANNELS----------------------------

		lea	P_VOICE_TAB(pc),a0
	
		move.w	Nb_trax(pc),d0
		bra.b	enter_trax
Mix_trax:
		push.w	d0
		bsr	P_MIX_1
		pop.w	d0

	;----------------------------------
		tst.w	_timer_delay_work(pc)
		bpl.b	skip_driver_user
		
		not.l	$fffff9800.w

		push.l	a0
		push.w	d0
		push.l	a6

		movem.l	sav_regz(pc),a0-a4
		jsr	(a6)
		movem.l	a0-a4,sav_regz

		pop.l	a6
		pop.w	d0
		pop.l	a0

		not.l	$fffff9800.w

skip_driver_user
	;----------------------------------

		bset	#3,icr.w	
		get_host	d1
		bclr	#3,icr.w
	;----------------------------------

		add.l	#spl_size,a0
enter_trax:
		dbf	d0,Mix_trax

		get_host	d0	;r U allright?

	;---EXECUTE USER ROUTINE-------------------------
		tst.w	_timer_delay_work(pc)
		bpl.b	skip_close_user

		movem.l	sav_regz(pc),a0-a4
		jsr	([pc,close_ptr.w])

	;------------------------------------------------
		moveq	#0,d0
		move.b	MFP_DATA(pc),d0		;how manny time did left
		sub.b	$ffffffa1f.w,d0		;to the next int?

		tst.w	d0
		bne.b	no_strurated
		move.w	#100,cpu_power
		bra.b	MIX_EXIT
no_strurated:	moveq	#0,d1
		move.b	MFP_DATA(pc),d1
		lsl.l	#8,d0
		divu.w	d1,d0
		mulu.w	#100,d0
		lsr.l	#8,d0
		move.w	d0,cpu_power

		move.w	timer_delay(pc),timer_delay_work

skip_close_user:
	;----OK, NOW EXIT--------------------------------
MIX_EXIT
		popa

		;ifd	debug_mode_0
		bclr	#5,$fffffa0f.w
		;endc

		clr.b	saturation
		rte

timer_exit	
		;ifnd	debug_mode_0
		bclr	#5,$fffffa0f.w		;mask off timer A
		;endc
		move.w	#100,cpu_power
		rte

;







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
		move.w	$ffff8938.w,(a0)+		; Source ADC + Volumes entr俥s
		move.w	$ffff893a.w,(a0)+		; Volumes de Sortie

		;-setup

		move.w	#1,-(a7)		;protocol (No Handshake)
		move.w	prescale(pc),-(a7)		;prescale (1 = 49170 Hz)
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
DSP_init_OK	
		move.w	Nb_trax,d0
		ext.l	d0
		put_host	d0

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
		move.w	(a0)+,$ffff8938.w		; Source ADC + Volumes entr俥s
		move.w	(a0)+,$ffff893a.w		; Volumes de Sortie

		move.w	#129,-(a7)
		trap	#14
		addq.l	#2,a7

		rts
;------------------------------------------------------------------------------
HSR_ERR:	illegal
		
		bra	*
;-DSP BINARY CODE--------------------------------------------------------------
		even
DSP_start:	incbin	g:\pulsar\puls_009.p56
DSP_end:

;-PRESCALE TABLES--------------------------------------------------------------
pre_tab:	dc.l	1,2,3,4,5,9,11
freq_tab:	dc.l	49170,32780,24585,19668,16390,19834,8940
firr_tab:	dc.l	11520,9600,7680,5760,3840,1920,0

;-PULSAR VOID DATAS------------------------------------------------------------
		even
clr_r		ds.l	16

dma_freq:	ds.l	1
bufer_len	ds.w	1
replay_tick	ds.l	1
open_ptr	ds.l	1
close_ptr	ds.l	1
Nb_trax		ds.w	1
firr_tab_base:	ds.l	1

	;---------------------------
silence_hit:	dc.l	0		;64 bit!
		dc.l	0
perfect_hit	dc.l	0
		dc.l	0
imperfect_hit	dc.l	0
		dc.l	0
perfect_dsp_hit	dc.l	0
		dc.l	0
imperfect_dsp_hit	dc.l	0
		dc.l	0
	;---------------------------

cpu_power:	ds.w	1

MFP_DATA	ds.b	1
MFP_CONTROL	ds.b	1

prescale	ds.w	1

timer_delay	ds.w	1
timer_delay_work	ds.w	1
_timer_delay_work	ds.w	1

ini		ds.b	1
P_initial	ds.b	1
saturation:	ds.b	1
		even

timer_tick	dc.l	0

sav_regz	ds.l	5
		even

P_VOICE_TAB:	ds.b	128*spl_size	;max 128 channels!
		ds.b	10
		even

OLD_SS		ds.b	64+64
		even
FIRR_coeffs:	incbin	g:\pulsar\fir_calc\firr_tab.bin
;------------------------------------------------------------------------------
 		text