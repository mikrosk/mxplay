;-INFORMATION HEADER------------------------------------------------------------
;
;	Pulsar - a generic, platform indepandent, sound kernel
;


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

		move.w	#32000/4,bufer_len

		bsr	INIT_mfp

		rts

;-ALLOCATE PULSAR--------------------------------------------------------------
;	input:	none
;	output: d0 -pointer to chanel structures if all right
;		   -or negative error code if something wrong
ALLOC_SOUND:	move.l	#P_VOICE_TAB,d0
		rts


;-ENABLE MIX ------------------------------------------------------------------
;
ENABLE_MIX:	bset	#5,$fffffa13.w	;run my interrupt
		move.b	MFP_DATA(pc),$ffffffa1f.w
		move.b	MFP_CONTROL(pc),$ffffffa19.w

		rts
;-EXIT-------------------------------------------------------------------------
;
PULSAR_EXIT:	bsr	DEINIT_mfp

		rts
;-MIX CHANNEL------------------------------------------------------------------
;	input:	
;		a0 - spl info ptr
;
P_MIX_1:	move.w	spl_state(a0),d7
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
		lea	out_buf,a1	;!!!!
		add.l	dupa,a1

		move.w	bufer_len(pc),d7
		subq.w	#1,d7

P_MIX_DSP:	move.b	(a2,d2.w),(a1)+
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

;-PULSAR VOID DATAS------------------------------------------------------------
;
INIT_mfp	push.w	sr
		move.w	#$2700,sr

		bset	#5,$ffffffa07.w	;timer a enabled...
		bclr	#5,$ffffffa13.w	;but masked

		move.l	#61,d0
		bsr	CALC_MFP
		move.b	d0,MFP_DATA
		move.b	d1,MFP_CONTROL

		clr.b	$ffffffa19.w
	
		move.l	#TIMER_A,$134.w

		pop.w	sr
		rts

;-PULSAR VOID DATAS------------------------------------------------------------
DEINIT_mfp	push.w	sr
		move.w	#$2700,sr

		bset	#5,$ffffffa07.w	;timer a enabled...
		bclr	#5,$ffffffa13.w	;but masked

		pop.w	sr
		rts
;-PULSAR VOID DATAS------------------------------------------------------------
;
;
TIMER_A:	
		not.l	$ffff9800.w

		move.b	MFP_DATA(pc),$ffffffa1f.w
		move.b	MFP_CONTROL(pc),$ffffffa19.w
		bclr	#5,$fffffa0f.w
		not.l	$ffff9800.w
		rte
;-PULSAR VOID DATAS------------------------------------------------------------
;	
dma_freq:	ds.l	1
bufer_len	ds.w	1
default_bpm	ds.w	1
default_speed	ds.w	1
feeder_ptr	ds.l	1

MFP_DATA	ds.b	1
MFP_CONTROL	ds.b	1

P_VOICE_TAB:	ds.b	32*spl_size
		even
;------------------------------------------------------------------------------
		text