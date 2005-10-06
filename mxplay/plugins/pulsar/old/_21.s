;debug2

ERR_NOXM	equ	-1
ERR_NOMEM	equ	-2


ALL		=	$ffffffff
fade_in		=	65535
ini_vol		=	32

movei		macro	
		ifc "\0","w"
		move.w	\1,\2
		ror.w	#8,\2
		endc

		ifc "\0","l"
		move.l	\1,\2
		rol.w	#8,\2
		swap.w	\2
		rol.w	#8,\2			
		endc
		endm

BMP_2_Hz	macro
		ext.l	\1
		lsl.l	#8,\1
		add.l	\1,\1
		divu.l	#5,\1
		endm

limit		macro

		ifc	'\0','up'
		cmp.w	\2,\1
		blt.b	\@limit_ok
		move.w	\2,\1
\@limit_ok:
		endc

		ifc	'\0','down'
		cmp.w	\2,\1
		bgt.b	\@limit_ok2
		move.w	\2,\1
\@limit_ok2:
		endc

		endm

XM_Vib_retrig:	equ	0
XM_tremolo_retrig:	equ	1


		rsreset
XM_old_inst:	rs.w	1
XM_old_vol:	rs.w	1
XM_play_vol:	rs.w	1
XM_old_period:	rs.l	1
XM_play_period:	rs.l	1
XM_play_note:	rs.w	1
XM_old_note:	rs.w	1
XM_pulsar_vol:	rs.w	1
XM_fadeout:	rs.w	1
XM_venv_vol:	rs.w	1
XM_vsld:	rs.w	1
XM_porta:	rs.w	1
XM_penv:	rs.w	1
XM_pan:		rs.w	1
XM_lpan:	rs.w	1
XM_appreg_1:	rs.w	1
XM_appreg_2:	rs.w	1
XM_appreg_3:	rs.w	1
XM_appreg_flag:	rs.w	1
XM_temp_period	rs.l	1
XM_vib_last:	rs.w	1
XM_vib_depth2:	rs.w	1
XM_vib_pos:	rs.w	1
XM_vib_rate2:	rs.w	1
XM_vib_flag:	rs.w	1
XM_tone_last:	rs.w	1
XM_org_period	rs.l	1
XM_tone_flag:	rs.w	1
XM_tone_speed:	rs.w	1
XM_tremolo_depth:rs.w	1
XM_tremolo_pos:	rs.w	1
XM_tremolo_rate:rs.w	1
XM_tremolo_flag:rs.w	1
XM_tremolo_last:rs.w	1
XM_temp_vol	rs.w	1
XM_retrig_flag:	rs.w	1
XM_retrig_count:rs.w	1
XM_retrig_int:	rs.w	1
XM_Sample_ptr:	rs.l	1
XM_fine_vl:	rs.w	1
XM_fine_vl2:	rs.w	1
XM_fine_pl:	rs.w	1
XM_Sample_len:	rs.l	1
XM_vib_wave:	rs.l	1
XM_tremolo_wave:rs.l	1
XM_wave_flags:	rs.w	1
XM_inst_ptr:	rs.l	1
XM_spl_h_ptr:	rs.l	1
XM_cut_flag:	rs.w	1
_note		rs.b	1
_instrument	rs.b	1
_volume		rs.b	1
_effect		rs.b	1
_value		rs.b	1
_even_1:	rs.b	1
_even_2		rs.w	1	
XM_dont_flag:	rs.w	1
XM_note_period:	rs.l	1
XM_spl_force:	rs.w	1
XM_offset_ptr:	rs.l	1
XM_offset_flag:	rs.w	1
XM_was_flag:	rs.w	1
XM_ftune:	rs.w	1
XM_spl_raw_ptr:	rs.l	1
XM_const_period:rs.l	1
XM_inst_init:	rs.w	1

XM_venv_pts:	rs.w	1
XM_venv_time:	rs.w	1
XM_venv_ltime:	rs.w	1
XM_venv_lsize:	rs.w	1
XM_venv_sus_flag:rs.w	1

XM_penv_pts:	rs.w	1
XM_penv_time:	rs.w	1
XM_penv_ltime:	rs.w	1
XM_penv_lsize:	rs.w	1
XM_penv_sus_flag:rs.w	1

XM_voice_vol:	rs.w	1

XM_delay_flag:	rs.w	1
XM_key_off:	rs.w	1

channel_size:	rs.b	1

		;rsreset
;-------------------------------------------------------------------------------
	;XM instrument description

		;rsreset
XM_isize:	equ	0
XM_iname:	equ	4
XM_itype:	equ	26
XM_snum:	equ	27

XM_shs:		equ	29
XM_stabnum:	equ	33
XM_vol_env:	equ	129
XM_pan_env:	equ	177
XM_num_vol:	equ	225
XM_num_pan:	equ	226
XM_vol_sust:	equ	227
XM_vol_lp:	equ	228
XM_vol_elp:	equ	229
XM_pan_sust:	equ	230
XM_pan_lp:	equ	231
XM_pan_elp:	equ	232
XM_vol_type:	equ	233
XM_pan_type:	equ	234
XM_vib_type:	equ	235
XM_vib_sweep:	equ	236
XM_vib_depth:	equ	237
XM_vib_rate:	equ	238
XM_vol_fadeout:	equ	239
XM_reserved:	equ	241

	;XM sample header

		rsreset
XM_spl_len:	rs.l	1
XM_spl_ls:	rs.l	1
XM_spl_ll:	rs.l	1
XM_spl_vol:	rs.b	1
XM_spl_fine:	rs.b	1
XM_spl_type:	rs.b	1
XM_spl_panning	rs.b	1
XM_spl_rnn:	rs.b	1
XM_spl_res:	rs.b	1
XM_spl_name:	rs.b	22

		;XM commands

Command_Appregio:	equ	$0
Command_Porta_up:	equ	$2
Command_Porta_down:	equ	$1
Command_Tone_porta:	equ	$3
Command_Vibrato:	equ	$4
Command_Tone_vol:	equ	$5
Command_Vib_vol:	equ	$6
Command_Tremolo:	equ	$7
Command_Set_panning:	equ	$8
Command_Set_offset:	equ	$9
Command_Volume_slide:	equ	$a
Command_Set_volume:	equ	$c
Command_patt_break:	equ	$d
Command_E_comms:	equ	$e
Command_Set_tempo_BPM:	equ	$f
Command_Set_gvol:	equ	$10
Command_Slide_gvol	equ	$11
Command_Panning_sld:	equ	$19
Command_Multi_rtg:	equ	$20

Command_E_porta_up:	equ	$1
Command_E_porta_down:	equ	$2
Command_E_vib_control:	equ	$4
Command_E_Set_tune:	equ	$5
Command_E_loop:		equ	$6
Command_E_Retrig:	equ	$9
Command_E_slide_v_up:	equ	$a
Command_E_slide_v_down:	equ	$b
Command_E_cut_note:	equ	$c

XM_env_on		equ	0
XM_env_sustain		equ	1
XM_env_loop		equ	2

;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
; pulsar data structures

SPL_PLAY	equ	256
SPL_STOP	equ	0
SPL_MIXING	equ	1
SPL_STOP2	equ	257

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

PULSAR_INIT		equ	0
PULSAR_ENABLE_MIX	equ	1
PULSAR_EXIT		equ	2
PULSAR_PAUSE_SOUND	equ	3
PULSAR_SET_TICK		equ	4
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ


		jmp	start

		include	include\sys_lib.s
		include	include\unpack3.s
		include	pulsar\libs.s

start		setup

		write	<27,"E">
		super	#0

		lib_open	#Pulsar_name
		move.l	d0,Pulsar_base

		lea	mod,a0
		jsr	XM_init_module
		cmp.w	#ERR_NOXM,d0
		bne.b	is_xm
		writeln	<"NOT AN XM MODULE - ERROR!">
is_xm
		moveq	#1,d0	;play at 32Khz
		jsr	XM_init_sound
		jsr	XM_Play
	
		write	<13,10,"CPU time consumed: ">

loop:
		move.w	#$ff,-(sp)
		move.w	#6,-(sp)
		trap	#1
		addq.l	#4,sp
		
		ifd ef4cx34
		pusha
		write	<27,"j">
		move.w	cpu_power,d0
		write_c.w	d0
		write	<"%   ",27,"k">
		popa
		endc


		cmp.b	#"f",d0
		bne.b	loop2
	
		clr.w	patt_rows
		
loop2		cmp.b	#" ",d0
		bne	loop


		;read_key

		jsr	XM_free_module
		jsr	XM_deinit_sound

		ifd	sdgsdg
		write	<13,10,"silence_hit = ">
		move.l	silence_hit,d0
		write_c.l	d0
		writeln	<"">

		write	<"perfect_hit = ">
		move.l	perfect_hit,d0
		write_c.l	d0
		writeln	<"">

		write	<"imperfect_hit = ">
		move.l	imperfect_hit,d0
		write_c.l	d0
		writeln	<"">

		write	<"dsp_resampling_hit = ">
		move.l	perfect_dsp_hit,d0
		write_c.l	d0
		writeln	<"">
		endc

		;read_key
		
		move.l	#$fffffffffffffff,$fffffff9800.w

		pterm

vdi_hand:	ds.w	1
Pulsar_name:	dc.b	"pulsar\pulsar.lib",0
		even

;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
;		-Init XM-                                              
;
;	Makes whole module Morotola compatibile, 
;	initialize samples, fill player structures
;
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
XM_init_module:

	***************************************
	*      ~~PROCESS MODULE HEADER~~      *
        ***************************************

		lea	magic,a1
		moveq	#17-1,d7
chk_magic:	cmp.b	(a0)+,(a1)+
		dbne	d7,chk_magic
		tst.w	d7
		bmi.b	magic_ok
		move.w	#ERR_NOXM,d0
		rts
magic_ok:	write	<'Module  name: "'>
		clr.b	20(a0)
		print	a0
		writeln	<'"'>

		add.w	#21,a0

		write	<'Created with: "'>
		print	a0
		writeln	<'"'>

		write	<"File format version= ">

		add.w	#20,a0
		move.b	1(a0),d0
		write_c.b	d0
		write	<".">
		move.b	(a0),d0
		write_c.b	d0

		addq.l	#2,a0

		movei.l	(a0)+,d0
		write	<13,10,"Header size= ">
		write_c.l	d0

		movei.w	(a0)+,d0
		move.w	d0,Song_len
		write	<13,10,"Song length= ">
		write_c.w	d0

		movei.w	(a0)+,d0
		write	<"  Restart position= ">
		move.w	d0,XM_restart_song
		write_c.w	d0

		movei.w	(a0)+,d0
		move.w	d0,channel_Nb
		write	<cr,lf,"Nb of channels= ">
		write_c.w	d0

		movei.w	(a0)+,d0
		move.w	d0,pattern_Nb
		write	<cr,lf,"Nb of patterns= ">
		write_c.w	d0

		movei.w	(a0)+,d0
		move.w	d0,Instrument_Nb
		write	<cr,lf,"Nb of instruments= ">
		write_c.w	d0
	;--------------------------------------
		clr.b	XM_Amiga

		movei.w	(a0)+,d0
		btst	#0,d0
		beq.b	amiga_table
		write	<cr,lf,"Linear ">
		addq.b	#1,XM_Amiga
		move.w	#$1e40,XM_max_period
		move.w	#$c0,XM_min_period
		bra.b	table_used
amiga_table:	write	<cr,lf,"Amiga ">
		clr.b	XM_Amiga
		move.w	#$1ac0,XM_max_period
		move.w	#$f,XM_min_period

table_used:	writeln	<"frequency table used.">
	;--------------------------------------

		movei.w	(a0)+,d0
		move.w	d0,default_tempo
		write	<"Default tempo= ">
		write_c.l	d0

		movei.w	(a0)+,d0
		move.w	d0,default_BPM
		write	<cr,lf,"Default BPM= ">
		write_c.l	d0

	***************************************
	*     ~~PROCESS MODULE PATTERNS~~     *
        ***************************************

	;---------CREATE ORDER TABLE-----------

		lea	256(a0),a2			;pattern order table ptr
		lea	Order_table(pc),a1
		lea	Temp,a3
		move.w	pattern_Nb(pc),d7

		move.l	a2,Patterns_ptr

		bra.b	enter_cr_ptor

create_order_ptr_1:
		move.l	a2,(a3)+	;save pattern ptr

		movei.l	(a2),d0	;pattern header length
		move.l	d0,(a2)	;store back but in right format!
		movei.w	5(a2),d1	;pattern size [rows]
		move.w	d1,5(a2)	;	-||-
		movei.w	7(a2),d1	;pattern data len
		move.w	d1,7(a2)	;	-||-
		add.w	d1,a2		;next pattern ptr
		add.l	d0,a2

enter_cr_ptor:	dbf	d7,create_order_ptr_1	;loop for all patterns

	;---CREATE "QUICK" ORDER TABLE--------
						;a2==instruments
		lea	Temp,a1
		lea	Order_table(pc),a3
		move.w	Song_len(pc),d7

		bra.b	enter_ptr_song
ptr_song:	moveq	#0,d0
		move.b	(a0)+,d0
		move.l	(a1,d0.w*4),(a3)+

enter_ptr_song:	dbf	d7,ptr_song
		clr.l	(a3)+		~| NULL termiated |~
		clr.l	(a3)+
	***************************************
	*     ~~PROCESS MODULE INSTRUMENTS~~  *
	***************************************
		;illegal
		move.l	a2,a0
		lea	Instruments(pc),a1
		move.w	Instrument_Nb(pc),d7
		lea	Inst_samples(pc),a5

		bra	enter_instruments_scan
scan_instruments:
		movei.l	(a0),d0		;instrument size
		move.l	d0,(a0)

		movei.w	27(a0),d0	;number of samples
		move.w	d0,27(a0)

		tst.w	d0
		bne.b	XM_conv_have_spls
		clr.l	(a1)+	
		bra	no_samples

XM_conv_have_spls:	;cmp.w	#1,d0
		;ble.b	XM_conv_ok_nspl
		;illegal
		;writeln	<"Warning: spl_num!">
XM_conv_ok_nspl

		move.l	a0,(a1)+	;save to "quick reference table"

		;movei.w	27(a0),d0	;number of samples
		;move.w	d0,27(a0)

	;~~~CONVERT ENVELOPES~~~~~~~~~~~~~~~~~~~~~~~~~
		pusha
		lea	XM_vol_env(a0),a6
		move.l	a6,a3
		move.w	#24*2-1,d7
XM_conv_env:	movei.w	(a6)+,d0
		move.w	d0,(a3)+
		dbf	d7,XM_conv_env
		popa
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

		ifd	debug
		pusha
		writeln	<"">	
		lea	4(a0),a6
		print	a6
		popa
		endc

		ifd	debug2
		push.l	d0
		moveq	#0,d0
		write	<13,10,"nb_volenv_pts=">
		move.b	XM_num_vol(a0),d0
		write_c.w	d0
		;write	<13,10,"nb_panenv_pts=">
		moveq	#0,d0
		move.b	XM_num_pan(a0),d0
		;write_c.w	d0
		read_key
		pop.l	d0		
		endc

		movei.l	29(a0),d0	;sample header size
		move.l	d0,29(a0)
		move.l	d0,temp_size

		movei.w	239(a0),d0	;volume fadeout
		move.w	d0,239(a0)
		
		;pusha			~| Show envelopes |~

		;popa

;	      ~|PROCESS SAMPLE HEADERS|~

		move.w	27(a0),d6
		move.w	d6,temp_loop

		add.l	(a0),a0
		move.l	a0,a2
		bra.b	enter_convert_headers

convert_headers:	
		movei.l	(a0),d0	;sample length
		move.l	d0,(a0)

		movei.l	4(a0),d0	;sample loop start
		and.w	#$fffe,d0	~| evn loop st
		move.l	d0,4(a0)

		movei.l	8(a0),d0	;sample loop length
		and.w	#$fffe,d0	~| evn loop len
		move.l	d0,8(a0)

		;move.b	XM_spl_type(a0),d0

		add.l	temp_size(pc),a0	;move 2 next sample header
enter_convert_headers:	dbf	d6,convert_headers

;	      ~|PROCESS SAMPLES|~

		move.l	a5,a4
		move.w	temp_loop(pc),d6
		bra.b	begin_spl_conv

convert_samples:
		tst.l	(a2)
		bne.b	XM_void_spl

		clr.l	(a4)+
		clr.l	(a4)+
		bra.b	sixteen_done

XM_void_spl	move.l	a2,(a4)+	;store sample header ptr
		move.l	a0,(a4)+	;store sample ptr

		btst	#4,14(a2)
		beq.b	eight_bit
				;convert 16bit sample
		move.l	(a2),d5
		lsr.l	d5	;?
		move.l	d5,(a2)
	
		move.l	XM_spl_ls(a2),d0
		lsr.l	d0
		move.l	d0,XM_spl_ls(a2)

		move.l	XM_spl_ll(a2),d0
		lsr.l	d0
		move.l	d0,XM_spl_ll(a2)

		moveq	#0,d0
		bra.b	enter_delta_16
delta_16:	movei.w	(a0),d1
		add.w	d0,d1
		move.w	d1,(a0)+
		move.w	d1,d0
enter_delta_16:	dbf	d5,delta_16
		sub.l	#$10000,d5
		bpl.b	delta_16

		bra.b	sixteen_done
eight_bit:	 			;convert 8bit sample
		move.l	(a2),d5
		moveq	#0,d0
		bra.b	enter_delta_8
delta_8:	move.b	(a0),d1
		add.b	d0,d1
		move.b	d1,(a0)+
		move.b	d1,d0
enter_delta_8:	dbf	d5,delta_8
		sub.l	#$10000,d5
		bpl.b	delta_8

sixteen_done:	
		and.w	#$fffe,2(a2)

		add.l	temp_size(pc),a2

begin_spl_conv:	dbf	d6,convert_samples
		bra.b	have_samples

no_samples:	add.l	(a0),a0

have_samples:	add.l	#16*8,a5

enter_instruments_scan:	dbf	d7,scan_instruments

		move.l	#Order_table,Order_ptr
		clr.w	patt_rows
		clr.w	tempo
		move.w	default_tempo(pc),tempo
		move.w	default_tempo(pc),tempo_count
		;clr.w	tempo_count

		move.l	Order_ptr,a0		;Take next pattern ptr from
		move.l	(a0)+,a0		;order list.
		move.w	5(a0),patt_rows
		add.w	#9,a0
		move.l	a0,Playing_pat
		addq.l	#4,Order_ptr

		lea	channels,a1
		move.w	#32-1,d7

clear_channels:	move.l	a1,a0

		move.w	#0,(a0)+
		clr.w	(a0)+
		clr.w	(a0)+
		clr.l	(a0)+
		clr.l	(a0)+
		clr.w	(a0)+
		move.w	#$ff,(a0)+
		clr.w	(a0)+
		move.w	#$ffff,(a0)+
		move.w	#32,(a0)+
		clr.w	(a0)+
		clr.w	(a0)+

		move.w	#32,(a0)+
		move.w	#0,(a0)+

		clr.w	(a0)+
		clr.w	(a0)+
		clr.w	(a0)+
		clr.w	(a0)+
		clr.w	(a0)+

		clr.l	(a0)+

		clr.w	(a0)+		~| good vibes:)
		clr.w	(a0)+
		clr.w	(a0)+
		clr.w	(a0)+
		clr.w	(a0)+
		clr.w	(a0)+

		clr.w	(a0)+		~| tone porta

		clr.l	(a0)+
		clr.w	(a0)+
		clr.w	(a0)+
		clr.w	(a0)+

		clr.w	(a0)+
		clr.w	(a0)+
		clr.w	(a0)+
		clr.w	(a0)+
	
		clr.w	(a0)+		~| temp_vol

		clr.w	(a0)+		~| Note retrig
		clr.w	(a0)+
		clr.w	(a0)+
		clr.l	(a0)+
		clr.w	(a0)+

		clr.w	(a0)+		~| Fine vol slide
		clr.w	(a0)+		~| Fine vol slide2
		clr.w	(a0)+		~| Fine porta slide

		clr.l	(a0)+		~| Sample len

		moveq	#0,d0
		move.l	d0,(a0)+	~| Initialize wave for vibrato
		move.l	d0,(a0)+	~| Initialize wave for tremolo
		move.l	d0,XM_vib_wave(a1)
		move.l	d0,XM_tremolo_wave(a1)

		clr.w	(a0)+		~| clear wave flagz

		clr.l	(a0)+		~| instrument ptr
		clr.l	XM_inst_ptr(a1)
		clr.l	(a0)+		~| sample header ptr
		clr.l	XM_spl_h_ptr(a1)

		clr.w	(a0)+		~| note cut flag

		clr.l	(a0)+		~| current note entry
		clr.l	(a0)+		~| 

		move.b	#$ff,_note(a1)
		move.b	#$ff,_instrument(a1)

		clr.w	(a0)+		~| dont play flag
		clr.l	(a0)+		~| note period

		clr.w	(a0)+		~| spl force

		clr.l	(a0)+		~| offset ptr
		clr.w	(a0)+		~| offset flag

		clr.w	(a0)+		~| was flag
		clr.w	(a0)+		~| Fine tune
		clr.l	(a0)+		~| spl_raw_ptr
		clr.l	(a0)+		~| const_period

		clr.w	(a0)+		~| inst_init

		clr.l	(a0)+		~| vol env stuff
		clr.l	(a0)+		~| vol env stuff
		clr.w	(a0)+
		clr.w	(a0)+

		clr.l	(a0)+		~| vol env stuff
		clr.l	(a0)+		~| vol env stuff
		clr.w	(a0)+
		clr.w	(a0)+

		clr.w	(a0)+		~| key off

		add.l	#channel_size,a1

		dbf	d7,clear_channels
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		lea	XM_skip_tab,a0	~| Create table for patt break command
		
		move.w	#128-1,d7	~| if 7th bit !set then entry has 5 bytes
		moveq	#5,d0
XM_fill_skp_1:	move.w	d0,(a0)+
		dbf	d7,XM_fill_skp_1

		lea	XM_skip_tab,a0	~| ok, now create lookup for "packed entrys"
		move.w	#%10000000,d2
		move.w	#32-1,d7
XM_fill_skp_2:	move.w	d2,d0
		bsr	XM_count_bits
		move.w	d1,(a0,d2.w*2)	~| store "packed" entry length
		addq.w	#1,d2
		dbf	d7,XM_fill_skp_2
	
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

		xalloc	#96*256*2,#3
		bne.b	XM_alloc_1_ok
		moveq	#ERR_NOMEM,d0
		rts
XM_alloc_1_ok	move.l	d0,XM_Pertab

		tst.b	XM_Amiga
		beq.b	XM_setup_ln

		lea	XM_ltab,a0
		move.l	XM_Pertab(pc),a1
		move.w	#$2001-1,d7
XM_cp_ln	move.l	(a0)+,(a1)+
		dbf	d7,XM_cp_ln
		bra.b	XM_p_setup_done
XM_setup_ln
		lea	XM_atab,a0
		move.l	XM_Pertab(pc),a1
		move.w	#96*256*2/4-1,d7
XM_cp_a		move.l	(a0)+,(a1)+
		dbf	d7,XM_cp_a
XM_p_setup_done	
		move.l	XM_Pertab(pc),a0
		bsr	unpack

		moveq	#0,d0	
		rts

magic:		dc.b	"Extended Module: "
		even
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
;
XM_count_bits:	moveq	#0,d1
		push.w	d7
		move.w	#32-1,d7

XM_CNT_BITS:	lsr.l	d0
		bcc.b	XM_bcc
		addq.w	#1,d1
XM_bcc:		dbf	d7,XM_CNT_BITS

		pop.w	d7
		rts
;---ALLOCATE & INITIATE SOUND SYSTEM--------------------------------------------
XM_init_sound:	;illegal

		move.w	default_BPM(pc),d2
		BMP_2_Hz	d2
		
		move.l	d2,d1		;initial tick
		move.l	#XM_OPEN_INT,d2	;procedure called by the PULSAR
		move.l	#XM_CLOSE_INT,d3
		move.w	channel_Nb(pc),d4		;Nb of channels
		lib_exec	Pulsar_base,PULSAR_INIT
		move.l	d0,XM_trax_ptr

		rts
;---DEALLOC SOUND SYSTEM--------------------------------------------------------
XM_deinit_sound:
		lib_exec	Pulsar_base(pc),PULSAR_EXIT
		lib_close	Pulsar_base(pc)
		rts
;-------------------------------------------------------------------------------
XM_Play:	lib_exec	Pulsar_base(pc),PULSAR_ENABLE_MIX
		rts
;-------------------------------------------------------------------------------
XM_free_module:	mfree	XM_Pertab
		rts
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
;
;	Player routine called by PULSAR every BPM tick
;
;	NOTE: it have to be ended by _RTS_
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
XM_OPEN_INT:	clr.w	XM_ch_count
		clr.b	chujem

		tst.w	XM_patt_delay
		beq.b	XM_do_pattern2

		subq.w	#1,XM_patt_delay
		bra	XM_exit_pattern2
XM_do_pattern2
		addq.w	#1,tempo_count
		move.w	tempo(pc),d0
		cmp.w	tempo_count(pc),d0
		bgt	XM_exit_pattern		
XM_do_pattern:	
		clr.w	tempo_count
		;subq.w	#1,patt_rows
		tst.w	patt_rows		;r we playing any pattern (or wish to change pattern) ?
		bne	Pattern_ok

		move.l	Order_ptr(pc),a1		;Take next pattern ptr from
		move.l	(a1)+,a0		;order list.
		tst.l	a0
		bne.b	XM_Song_ok

		moveq	#0,d0
		lea	Order_table,a1
		move.w	XM_restart_song(pc),d0
		;cmp.w	Song_len(pc),d0
		;bgt.b	XM_rest_ok
		;moveq	#0,d0
XM_rest_ok:	lea	(a1,d0.w*4),a1
		move.l	(a1)+,a0
		
		ifd	chuj
		pusha
		moveq	#0,d0
		move.w	default_BPM(pc),d0
		BMP_2_Hz	d0
		;bsr	P_set_frame_tick
		lib_exec	Pulsar_base,PULSAR_SET_TICK

		move.w	default_tempo(pc),d0
		move.w	d0,tempo
		move.w	d0,tempo_count
		popa
		endc
		move.w	#63,XM_Global_vol

XM_Song_ok:	
		move.w	5(a0),patt_rows
		add.w	#9,a0
		move.l	a0,Playing_pat
		move.l	a1,Order_ptr

		clr.w	XM_loop_flag
		move.w	#$ffff,XM_loop_row

	;---------------------------------------
Pattern_ok:	move.l	Playing_pat(pc),a0

		move.l	a0,XM_temp_patt_ptr
		move.w	patt_rows(pc),XM_temp_row

		move.l	XM_trax_ptr(pc),a1
		lea	channels(pc),a2
		move.l	#XM_PLAY_INT,d0		;call me as U wish, call me now and in the dust (...) [Vader]

		rts

XM_exit_pattern:
		move.l	XM_trax_ptr(pc),a1
		lea	channels(pc),a2
		move.l	#XM_RESOLVER_INT,d0
		rts
XM_exit_pattern2:	move.l	#XM_VOID,d0
XM_VOID		rts
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
XM_PLAY_INT:
		move.b	(a0)+,d0	;depack channel
		bmi.b	unpack_note

		movem.l	a0-a2,-(sp)
		subq.l	#1,a0

		lea	_note(a2),a3
		move.l	(a0)+,(a3)+	~| copy note entry
		move.l	(a0)+,(a3)+	~| [this time unpacked!]

		bsr	XM_play_voice
		movem.l	(sp)+,a0-a2
		addq.l	#4,a0

		bra.b	XM_next_channel
unpack_note:	
		clr.l	_note(a2)
		clr.l	_note+4(a2)

		;cmp.b	#%10011111,d0
		;bne.b	XM_do_voice

		;move.w	#-1,_note(a2)
		;bra.b	XM_next_channel

XM_do_voice:	move.b	#$ff,d1
		lsr.b	d0
		bcc.b	pack_no_note
		move.b	(a0)+,d1
pack_no_note:
		move.b	d1,_note(a2)
		move.b	#$ff,d1

		lsr.b	d0
		bcc.b	pack_no_instrument
		move.b	(a0)+,d1
pack_no_instrument:
		move.b	d1,_instrument(a2)

		lsr.b	d0
		bcc.b	pack_no_volume
		move.b	(a0)+,_volume(a2)
pack_no_volume:
		lsr.b	d0
		bcc.b	pack_no_effect
		move.b	(a0)+,_effect(a2)
pack_no_effect:
		lsr.b	d0
		bcc.b	pack_no_value
		move.b	(a0)+,_value(a2)
pack_no_value:
		movem.l	a0-a2,-(sp)
		bsr	XM_play_voice
		movem.l	(sp)+,a0-a2
XM_next_channel:

enter_play_patterns:

		tst.w	XM_spl_force(a2)
		bne.b	XM_do_rslv1

		tst.w	spl_state(a1)
		beq.b	XM_no_resolve
XM_do_rslv1
		push.l	a0
		bsr	XM_resolve_spl
		pop.l	a0
XM_no_resolve
		add.w	#spl_size,a1	;move to next pulsar channel
		add.w	#channel_size,a2

		addq.w	#1,XM_ch_count
		rts
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
XM_RESOLVER_INT:
		bsr	XM_resolve_spl
XM_no_resolve2
		add.w	#spl_size,a1	;move to next pulsar channel
		add.w	#channel_size,a2

		addq.w	#1,XM_ch_count
		rts
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ

XM_CLOSE_INT:	
		cmp.l	#XM_PLAY_INT,a6
		bne.b	XM_exit_pattern_local

		tst.w	XM_break_flag
		beq.b	XM_do_what_to_do

		clr.w	XM_break_flag
		bra.b	XM_exit_pattern_local

XM_do_what_to_do:cmp.w	#2,XM_loop_flag
		bne.b	XM_ptr_update
		move.l	XM_loop_ptr(pc),a0
		subq.w	#1,XM_loop_flag
XM_ptr_update:	
		move.l	a0,Playing_pat
dupa_1
		subq.w	#1,patt_rows

XM_exit_pattern_local:
		rts
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
;
;	OK, now do the stuff needed to replay pattern position
;
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
XM_play_voice:	

	;-----FIRST, TEST FOR PENDING FLAGS TO BE CLEARED----

		tst.w	XM_vib_flag(a2)	
		beq.b	XM_skip_vib_fuck

		clr.w	XM_vib_flag(a2)
		move.l	XM_const_period(a2),XM_note_period(a2)

		addq.l	#1,XM_old_period(a2)
XM_skip_vib_fuck:

		tst.w	XM_appreg_flag(a2)
		beq.b	XM_skip_appreg_fuck

		clr.w	XM_appreg_flag(a2)
		move.l	XM_temp_period(a2),XM_note_period(a2)

		addq.l	#1,XM_old_period(a2)
XM_skip_appreg_fuck:

		tst.w	XM_tone_flag(a2)
		beq.b	XM_skip_tone_fuck
		clr.w	XM_tone_flag(a2)
XM_skip_tone_fuck:

		tst.w	XM_tremolo_flag(a2)
		beq.b	XM_skip_tremolo_fuck

		clr.w	XM_tremolo_flag(a2)
		move.w	XM_temp_vol(a2),XM_play_vol(a2)

XM_skip_tremolo_fuck:

		tst.w	XM_retrig_flag(a2)
		beq.b	XM_skip_retrig_fuck

		clr.w	XM_retrig_flag(a2)

XM_skip_retrig_fuck:
		clr.w	XM_dont_flag(a2)
		clr.w	XM_inst_init(a2)
		clr.w	XM_delay_flag(a2)

		;illegal
	;----NOW PLAY NOTE IF THERE IS ANY----

		cmp.b	#$ff,_note(a2)
		beq	XM_no_instrument

		cmp.b	#97,_note(a2)
		bne	XM_do_note
		addq.w	#1,XM_key_off(a2)
		move.b	#$ff,_note(a2)
		bra	XM_no_instrument
XM_do_note
		moveq	#0,d0
		move.b	_note(a2),d0
		cmp.b	#$ff,d0
		beq	XM_do_commands

		lea	Instruments(pc),a5
		lea	Inst_samples(pc),a6

		moveq	#0,d1
		move.b	_instrument(a2),d1
		cmp.b	#$ff,d1
		bne.b	XM_got_new_instrument

		move.w	XM_old_inst(a2),d1
		cmp.b	#$ff,d1
		beq	XM_no_instrument2

XM_got_new_instrument:	;move.w	XM_play_note(a2),XM_old_note(a2)
		move.w	d0,XM_play_note(a2)

		move.l	-4(a5,d1.w*4),a5	;get instrument ptr
		lsl.w	#7,d1
		lea	-128(a6,d1.w),a6
		
		tst.l	a5
		beq	XM_no_instrument2	~| Stuppid user, don't U know that playing void instruments is useless??

		moveq	#0,d2
		move.b	XM_stabnum(a5,d0.w),d2	;get sample number

		move.l	(a6,d2.l*8),a3		;sample header adress
		tst.l	a3			;what?
		beq	XM_no_instrument2

		move.l	4(a6,d2.l*8),a4		;sample adress
		tst.l	a4
		beq	XM_no_instrument2	;what?

		bra.b	XM_do_instrum

XM_no_instrument2:
		sub.l	a5,a5
		sub.l	a3,a3
		sub.l	a4,a4

		move.l	a5,XM_inst_ptr(a2)	;save them for later use
		move.l	a3,XM_spl_h_ptr(a2)
		move.l	a4,XM_spl_raw_ptr(a2)
		move.b	#$ff,_note(a2)
		move.b	#$ff,_instrument(a2)
		bra	XM_no_instrument
XM_do_instrum
		move.l	a5,XM_inst_ptr(a2)	;save them for later use
		move.l	a3,XM_spl_h_ptr(a2)
		move.l	a4,XM_spl_raw_ptr(a2)
		move.l	XM_spl_len(a3),XM_Sample_len(a2)

		move.b	XM_spl_rnn(a3),d1	;RealNote = PatternNote + RelativeTone
		extb.l	d1
		add.l	d1,d0
		move.b	XM_spl_fine(a3),d1
		extb.l	d1
		move.w	d1,XM_ftune(a2)
		bsr	XM_calc_period
		bmi.b	XM_no_instrument

		;move.l	d2,XM_note_period(a2)	~| Note period established
		move.l	d2,XM_const_period(a2)
		addq.w	#1,XM_inst_init(a2)
XM_no_instrument:
	;------------------------------------------

XM_do_commands:	moveq	#0,d0
		move.b	_volume(a2),d0
		lsr.b	#4,d0
		jsr	([XM_jump_vol_1.w,pc,d0.w*4])		
		
		moveq	#0,d0
		move.b	_effect(a2),d0
		jsr	([XM_cmd_jump_tree_1.w,pc,d0.w*4])		

	;------------------------------------------
		tst.w	XM_tone_flag(a2)
		beq.b	XM_process_inst

		cmp.b	#$ff,_instrument(a2)
		beq	XM_refresh_done

		move.l	XM_inst_ptr(a2),a5	~| just refresh volume (and maybe panning?)
		move.l	XM_spl_h_ptr(a2),a3
		tst.l	a5
		beq	XM_no_instrum
		tst.l	a3
		beq	XM_no_instrum

		moveq	#0,d0
		move.b	XM_spl_vol(a3),d0
		move.w	d0,XM_voice_vol(a2)
		move.w	d0,XM_play_vol(a2)

		move.w	#fade_in,XM_fadeout(a2)
		clr.w	XM_venv_time(a2)
		clr.w	XM_penv_time(a2)
		clr.w	XM_key_off(a2)
		move.w	#64,XM_venv_vol(a2)		;<-shity change
		move.w	#32,XM_penv(a2)

		bra	XM_refresh_done
XM_process_inst
	;------------------------------------------
		moveq	#0,d1
		move.b	_instrument(a2),d1

		cmp.b	#$ff,d1
		bne.b	XM_inst_try_one

		tst.w	XM_inst_init(a2)
		beq	XM_no_instrum

		move.w	#fade_in,XM_fadeout(a2)
		clr.w	XM_venv_time(a2)
		clr.w	XM_penv_time(a2)
		clr.w	XM_key_off(a2)
		move.w	#64,XM_venv_vol(a2)
		move.w	#32,XM_penv(a2)

		move.w	#SPL_PLAY,XM_spl_force(a2)
		move.l	XM_const_period(a2),XM_note_period(a2)
		bra	XM_refresh_done

XM_inst_try_one:tst.w	XM_inst_init(a2)
		bne.b	XM_got_both

		;move.l	XM_inst_ptr(a2),a5	~| just refresh volume (and maybe panning?)
		move.l	XM_spl_h_ptr(a2),a3
		;tst.l	a5
		;beq	XM_no_instrum
		tst.l	a3
		beq	XM_no_instrum

		moveq	#0,d0
		move.b	XM_spl_vol(a3),d0
		move.w	d0,XM_voice_vol(a2)
		move.w	d0,XM_play_vol(a2)

		move.w	#fade_in,XM_fadeout(a2)
		clr.w	XM_venv_time(a2)
		clr.w	XM_penv_time(a2)
		clr.w	XM_key_off(a2)
		move.w	#64,XM_venv_vol(a2)		;<-shity
		move.w	#32,XM_penv(a2)

		bra	XM_refresh_done
	;--------------------------------------
XM_got_both:	move.l	XM_const_period(a2),XM_note_period(a2)
		;move.w	XM_play_inst(a2),XM_old_inst(a2)
		move.w	d1,XM_old_inst(a2)

		move.l	XM_inst_ptr(a2),a5	;save them for later use
		move.l	XM_spl_h_ptr(a2),a3
		move.l	XM_spl_raw_ptr(a2),a4

		tst.l	a5
		beq	XM_stop
		tst.l	a3
		beq	XM_stop
		tst.l	a4
		beq	XM_stop

		move.l	a4,spl_ptr(a1)
		move.l	a4,XM_Sample_ptr(a2)

		move.l	XM_spl_len(a3),d0
		bne.b	XM_len_ok
XM_stop:
		clr.w	spl_state(a1)
		clr.w	XM_spl_force(a2)

		bra.b	XM_refresh_done

XM_len_ok:	move.l	d0,XM_Sample_len(a2)
		move.l	d0,spl_len(a1)

		move.b	XM_spl_type(a3),d0
		btst	#4,d0
		beq.b	XM_8bit
		
		lsl.w	d0
		and.w	#%110,d0
		bset	#0,d0
		move.w	d0,spl_flags(a1)
		bra.b	XM_chosen
XM_8bit	
		lsl.w	d0
		and.w	#%110,d0
		move.w	d0,spl_flags(a1)
XM_chosen:		
		move.l	XM_spl_ls(a3),spl_loop_off(a1)
		move.l	XM_spl_ll(a3),spl_loop_len(a1)
	;-------------------------------------------------
		move.w	#SPL_PLAY,XM_spl_force(a2)
XM_vol_and_pan:
		moveq	#0,d0
		move.b	XM_spl_vol(a3),d0
		move.w	d0,XM_voice_vol(a2)
		move.w	d0,XM_play_vol(a2)

		move.b	XM_spl_panning(a3),d0
		move.w	d0,XM_pan(a2)
		move.w	#fade_in,XM_fadeout(a2)
		clr.w	XM_key_off(a2)
		move.w	#64,XM_venv_vol(a2)		;<-shity
		move.w	#32,XM_penv(a2)
XM_chosen2
		clr.w	XM_venv_time(a2)
		clr.w	XM_penv_time(a2)
	
XM_refresh_done:

	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
XM_no_instrum:	
skipo
		tst.w	XM_delay_flag(a2)
		beq.b	XM_no_delay
		move.w	#1,XM_spl_force(a2)
XM_no_delay
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

		moveq	#0,d0
		move.b	_volume(a2),d0
		lsr.b	#4,d0
		jsr	([XM_jump_vol_3.w,pc,d0.w*4])

		moveq	#0,d0
		move.b	_effect(a2),d0
		jsr	([XM_cmd_jump_tree_3.w,pc,d0.w*4])

		rts

;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
;
;			STANDARD COMMANDS
;
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ

XM_cmd_jump_tree_1:
		dc.l	XM_appregio		~| $0
		dc.l	XM_nop			~| $1
		dc.l	XM_nop			~| $2
		dc.l	XM_Tone_porta		~| $3
		dc.l	XM_Vibrato		~| $4
		dc.l	XM_Tone_vol		~| $5
		dc.l	XM_Vib_vol		~| $6
		dc.l	XM_Tremolo		~| $7
		dc.l	XM_Set_panning		~| $8
		dc.l	XM_nop			~| $9
		dc.l	XM_nop			~| $a
		dc.l	XM_Position_jump 	~| $b
		dc.l	XM_Set_volume		~| $c
		dc.l	XM_pattern_break	~| $d
		dc.l	XM_E_Commands		~| $e
		dc.l	XM_Set_tempo_BPM	~| $f
		dc.l	XM_Set_gvol		~| $10
		dc.l	XM_nop			~| $11
		dc.l	XM_nop 			~| $12
		dc.l	XM_nop			~| $13
		dc.l	XM_nop			~| $14
		dc.l	XM_Set_env		~| $15
		dc.l	XM_nop			~| $16
		dc.l	XM_nop			~| $17
		dc.l	XM_nop			~| $18
		dc.l	XM_nop			~| $19
		dc.l	XM_nop			~| $1a
		dc.l	XM_nop			~| $1b
		dc.l	XM_nop			~| $1c
		dc.l	XM_nop			~| $1d
		dc.l	XM_nop			~| $1e
		dc.l	XM_nop			~| $1f
		dc.l	XM_nop			~| $20 ?

		rept	256
		dc.l	XM_nop
		endr

XM_cmd_jump_tree_2:
		dc.l	XM_run_app		~| $0
		dc.l	XM_Porta_down		~| $1
		dc.l	XM_Porta_up		~| $2
		dc.l	XM_run_porta		~| $3
		dc.l	XM_run_vib		~| $4
		dc.l	XM_Volume_slide		~| $5
		dc.l	XM_Volume_slide		~| $6
		dc.l	XM_run_tre		~| $7
		dc.l	XM_nop			~| $8
		dc.l	XM_nop			~| $9
		dc.l	XM_Volume_slide		~| $a
		dc.l	XM_nop			~| $b
		dc.l	XM_Set_volume		~| $c
		dc.l	XM_nop			~| $d
		dc.l	XM_E_Commands2		~| $e
		dc.l	XM_nop			~| $f
		dc.l	XM_nop			~| $10
		dc.l	XM_Slide_gvol		~| $11
		dc.l	XM_nop 			~| $12
		dc.l	XM_nop			~| $13
		dc.l	XM_nop			~| $14
		dc.l	XM_nop			~| $15
		dc.l	XM_nop			~| $16
		dc.l	XM_nop			~| $17
		dc.l	XM_nop			~| $18
		dc.l	XM_panning_slide	~| $19
		dc.l	XM_nop			~| $1a
		dc.l	XM_Multi_rtg		~| $1b
		dc.l	XM_nop			~| $1c
		dc.l	XM_nop			~| $1d
		dc.l	XM_nop			~| $1e
		dc.l	XM_nop			~| $1f
		dc.l	XM_nop			~| $20

		dc.l	XM_nop,XM_nop,XM_nop,XM_nop,XM_nop
		dc.l	XM_nop,XM_nop,XM_nop,XM_nop,XM_nop

		rept	256
		dc.l	XM_nop
		endr

XM_cmd_jump_tree_3:
		dc.l	XM_nop			~| $0
		dc.l	XM_nop			~| $1
		dc.l	XM_nop			~| $2
		dc.l	XM_nop			~| $3
		dc.l	XM_nop			~| $4
		dc.l	XM_nop			~| $5
		dc.l	XM_nop			~| $6
		dc.l	XM_nop			~| $7
		dc.l	XM_nop			~| $8
		dc.l	XM_Set_offset		~| $9
		dc.l	XM_nop			~| $a
		dc.l	XM_nop			~| $b
		dc.l	XM_Set_volume		~| $c
		dc.l	XM_nop			~| $d
		dc.l	XM_nop			~| $e
		dc.l	XM_nop			~| $f
		dc.l	XM_nop			~| $g
		dc.l	XM_nop			~| $h
		dc.l	XM_nop
		dc.l	XM_nop
		dc.l	XM_nop
		dc.l	XM_nop,XM_nop,XM_nop,XM_nop,XM_nop
		dc.l	XM_nop,XM_nop,XM_nop,XM_nop,XM_nop

		rept	256
		dc.l	XM_nop
		endr

XM_nop:		rts

;--------------------Appregio-------------------------
XM_appregio:	
		moveq	#0,d0
		move.b	_value(a2),d0
		beq.b	XM_appreg_skip
		move.w	d0,d1
		lsr.w	#4,d0
		and.w	#$f,d1		

		moveq	#0,d1
		lsl.w	d0
		add.w	XM_play_note(a2),d0
		;ext.l	d0
		and.l	#$ffff,d0
		push.w	d1
		bsr	XM_calc_period
		pop.w	d1
		move.w	d2,XM_appreg_2(a2)

		lsl.w	d1
		add.w	XM_play_note(a2),d1
		move.w	d1,d0
		;ext.l	d0
		and.l	#$ffff,d0
		moveq	#0,d1
		bsr	XM_calc_period
		move.w	d2,XM_appreg_3(a2)

		move.l	XM_const_period(a2),XM_temp_period(a2)
		move.w	XM_const_period+2(a2),XM_appreg_1(a2)
		
		addq.w	#1,XM_appreg_flag(a2)

XM_appreg_skip	
		rts
;----------------Portamento up------------------------
XM_Porta_up:		;rts
		moveq	#0,d0
		move.b	_value(a2),d0
		bne.b	XM_Porta_new_up
		move.w	XM_porta(a2),d0
XM_Porta_new_up:move.w	d0,XM_porta(a2)
		;lsl.w	#1,d0
		add.l	d0,XM_note_period(a2)
		move.w	XM_max_period(pc),d0
		cmp.l	XM_note_period(a2),d0
		bgt.b	Porta_up_ok
		move.l	d0,XM_note_period(a2)
Porta_up_ok
		rts

;----------------Portamento down----------------------
XM_Porta_down:	;rts
		moveq	#0,d0
		move.b	_value(a2),d0
		bne.b	XM_Porta_new_down
		move.w	XM_porta(a2),d0
XM_Porta_new_down:	move.w	d0,XM_porta(a2)
		;lsl.w	#1,d0
		sub.l	d0,XM_note_period(a2)
		move.w	XM_min_period(pc),d0
		cmp.l	XM_note_period(a2),d0
		blt.b	Porta_down_ok
		move.l	d0,XM_note_period(a2)
Porta_down_ok
		rts
;----------------Tone portamento----------------------
XM_Tone_porta:	
		moveq	#0,d0
		move.b	_value(a2),d0
		bne.b	XM_tone_new

		move.w	XM_tone_last(a2),d0
		beq	XM_tone_skip_1

XM_tone_new:	move.w	d0,XM_tone_last(a2)
		move.w	d0,XM_tone_speed(a2)

		move.l	XM_const_period(a2),XM_org_period(a2)
		addq.w	#1,XM_tone_flag(a2)
XM_tone_skip_1:
		rts
;--------------------Vibrato--------------------------
XM_Vibrato:	moveq	#0,d0
		move.b	_value(a2),d0
		bne.b	XM_Vibrato_new
		move.w	XM_vib_last(a2),d0
XM_Vibrato_new	move.w	d0,XM_vib_last(a2)

		move.w	d0,d1
		lsr.w	#2,d0
		move.w	d0,XM_vib_rate2(a2)
		and.w	#$0f,d1
		move.w	d1,XM_vib_depth2(a2)
		btst	#3,XM_vib_wave(a2)
		bne.b	XM_vib_wrap
		clr.w	XM_vib_pos(a2)
XM_vib_wrap	addq.w	#1,XM_vib_flag(a2)

		move.l	XM_const_period(a2),XM_temp_period(a2)

		rts
;----------------------Tremolo------------------------
XM_Tremolo:	
		moveq	#0,d0
		move.b	_value(a2),d0
		bne.b	XM_Tremolo_new
		move.w	XM_tremolo_last(a2),d0
XM_Tremolo_new	move.w	d0,XM_tremolo_last(a2)

		move.w	d0,d1
		lsr.w	#4,d0
		move.w	d0,XM_tremolo_rate(a2)
		and.w	#$0f,d1
		move.w	d1,XM_tremolo_depth(a2)
		clr.w	XM_tremolo_pos(a2)
		addq.w	#1,XM_tremolo_flag(a2)

		move.w	XM_play_vol(a2),XM_temp_vol(a2)
		rts
;----------Tone portamento + volume slide-------------
XM_Tone_vol:	
		move.w	XM_tone_last(a2),d0
		beq	XM_tone_skip_1_2

		move.w	d0,XM_tone_speed(a2)

		;move.w	d0,XM_tone_last(a2)
		;move.w	d0,XM_tone_speed(a2)

		move.l	XM_const_period(a2),XM_org_period(a2)
		addq.w	#1,XM_tone_flag(a2)

XM_tone_skip_1_2:
		rts
;---------------Vibrato + volume slide----------------
XM_Vib_vol:	
		move.w	XM_vib_last(a2),d0
		beq	XM_Vib_vol_kurwa

		move.w	d0,d1
		lsr.w	#4,d0
		move.w	d0,XM_vib_rate2(a2)
		and.w	#$0f,d1
		move.w	d1,XM_vib_depth2(a2)
		clr.w	XM_vib_pos(a2)
		addq.w	#1,XM_vib_flag(a2)

		move.l	XM_const_period(a2),XM_temp_period(a2)
XM_Vib_vol_kurwa
		rts
;----------------SET CHANNEL VOL----------------------		
XM_Set_volume:		
		;move.w	XM_play_vol(a2),XM_old_vol(a2)
		moveq	#0,d0
		move.b	_value(a2),d0
		limit.up	d0,#$40
		move.w	d0,XM_play_vol(a2)
		;move.w	d0,XM_old_vol(a2)
		rts

;---------------SET PATTERN TICK----------------------
XM_Set_tempo_BPM:	
		pusha
		moveq	#0,d0
		move.b	_value(a2),d0
		cmp.w	#31,d0
		ble.b	XM_set_tempo
		BMP_2_Hz	d0

		;jsr	P_set_frame_tick
		lib_exec	Pulsar_base,PULSAR_SET_TICK

		bra.b	XM_no_temp_speed
XM_set_tempo:
		move.w	d0,tempo
		clr.w	tempo_count
		;move.w	d0,tempo_count
XM_no_temp_speed:	popa
		rts
;-------------------SET OFFSET------------------------
XM_Set_offset:		
		moveq	#0,d0
		move.b	_value(a2),d0
		lsl.l	#8,d0
		cmp.l	XM_Sample_len(a2),d0
		bge.b	XM_offset_crossed	~| Stuppid user ??? |~

		btst	#0,spl_flags+1(a1)
		beq.b	XM_Set_offset_8bit
		add.l	d0,d0			~| *2 because sample is 16 bit |~
XM_Set_offset_8bit:	add.l	XM_spl_raw_ptr(a2),d0

		move.l	d0,spl_now_playing(a1)
		;move.w	#SPL_PLAY,XM_spl_force(a2)

		clr.b	spl_play_short(a1)
		clr.b	spl_loop_flag1(a1)
		clr.b	spl_pingpong_flag(a1)

		move.w	#fade_in,XM_fadeout(a2)
		clr.w	XM_venv_time(a2)
		clr.w	XM_key_off(a2)
		move.w	#64,XM_venv_vol(a2)

		move.w	#1,XM_spl_force(a2)
		rts
XM_offset_crossed:	move.w	#SPL_STOP2,XM_spl_force(a2)
		move.w	#$ffff,_note(a2)
		rts
;------------------Volume Slide-----------------------
XM_Volume_slide:
		moveq	#0,d0
		move.b	_value(a2),d0
		bne.b	Volume_slide_new_val

		move.w	XM_vsld(a2),d0
		
Volume_slide_new_val:	move.w	d0,XM_vsld(a2)

		lsr.b	#4,d0
		beq.b	Volume_slide_down
		add.w	d0,XM_play_vol(a2)		
		cmp.w	#64,XM_play_vol(a2)
		blt.b	Volume_slide_exit
		move.w	#64,XM_play_vol(a2)
		rts
Volume_slide_down:

		move.w	XM_vsld(a2),d0
		sub.w	d0,XM_play_vol(a2)
		tst.w	XM_play_vol(a2)
		bpl.b	Volume_slide_exit
		clr.w	XM_play_vol(a2)
Volume_slide_exit:
		rts

;-----------------Pattern break-----------------------
XM_pattern_break:

		pusha
	;~~~~~SELECT NEXT PATTERN FROM ORDER TABLE~~~~~
		
		move.l	Order_ptr(pc),a1		;Take next pattern ptr from
		move.l	(a1)+,a0		;order list.
		tst.l	a0
		bne.b	XM_Song_ok_

		moveq	#0,d0
		lea	Order_table,a1
		move.w	XM_restart_song(pc),d0
		lea	(a1,d0.w*4),a1
		move.l	(a1)+,a0

		ifd	sdfsdfasdf
		pusha
		moveq	#0,d0
		move.w	default_BPM(pc),d0
		BMP_2_Hz	d0

		;jsr	P_set_frame_tick
		lib_exec	Pulsar_base,PULSAR_SET_TICK


		move.w	default_tempo(pc),d0
		move.w	d0,tempo
		;move.w	d0,tempo_count
		clr.w	tempo_count
		popa

		move.w	#63,XM_Global_vol
		endc

XM_Song_ok_:	move.w	5(a0),patt_rows
		subq.w	#1,patt_rows
		add.w	#9,a0
		move.l	a0,Playing_pat
		move.l	a1,Order_ptr

		clr.w	XM_loop_flag
		move.w	#$ffff,XM_loop_row
		addq.w	#1,XM_break_flag

	;~~~~~~~~| SELECT RELPAY POSITION |~~~~~~~~~


		ifd	sdfsdfsdfknsdf
		move.l	Playing_pat(pc),a0
		move.w	channel_Nb(pc),d7
		subq.w	#1,d7		~| Its safe to do it this way coz its imposible to have 0 channels! |~
		moveq	#0,d6
		move.b	_value(a2),d6	~| go to this row |~
		beq.b	XM_break_dont_fuck
		sub.w	d6,patt_rows
		subq.w	#1,d6

		lea	XM_skip_tab,a1	~| Now this tab come in hand |~
		moveq	#0,d0
XM_position_loop:
		move.w	d7,d5
XM_line_loop_pb:	move.b	(a0),d0		~| What have we got there? |~
		add.w	(a1,d0.w*2),a0		~| yeah, move to next channel |~
		dbf	d5,XM_line_loop_pb

		subq.w	#1,d6
		bne.b	XM_position_loop

		endc		

		;move.l	a0,Playing_pat

		move.b	#1,chujem

XM_break_dont_fuck:
		popa
		rts
chujem		dc.b	0
		even
;--------------Set channel panning--------------------

XM_Set_panning:	moveq	#0,d0
		move.b	_value(a2),d0
		move.w	d0,XM_pan(a2)
		rts

;------------------Panning splide---------------------
XM_panning_slide:	moveq	#0,d0	
		move.b	_value(a2),d0
		bne.b	XM_pan_sld_new
		move.w	XM_lpan(a2),d0
XM_pan_sld_new:
		move.w	d0,XM_lpan(a2)

		lsr.w	#4,d0
		beq.b	XM_slide_left
		lsl.w	#4,d0
		add.w	d0,XM_pan(a2)
		cmp.w	#256,XM_pan(a2)
		blt.b	XM_slide_exit
		move.w	#256,XM_pan(a2)
		rts
XM_slide_left
		move.w	XM_lpan(a2),d0
		lsl.w	#4,d0
		sub.w	d0,XM_pan(a2)
		bpl.b	XM_slide_exit
		clr.w	XM_pan(a2)
XM_slide_exit:
		rts

;------------------Set global volume------------------
XM_Set_gvol:	moveq	#0,d0
		move.b	_value(a2),d0
		limit.up	d0,#$40-1
		move.w	d0,XM_Global_vol
		rts
;-----------------Slide global volume-----------------
XM_Slide_gvol:	moveq	#0,d0
		move.b	_value(a2),d0
		bne.b	Gvol_slide_new_val

		move.w	XM_Gvol_last(pc),d0
		
Gvol_slide_new_val:	move.w	d0,XM_Gvol_last

		lsr.b	#4,d0
		beq.b	Gvol_slide_down
		lsl.w	#1,d0
		add.w	d0,XM_Global_vol	
		cmp.w	#64,XM_Global_vol
		blt.b	Gvol_slide_exit

		move.w	#63,XM_Global_vol
		rts
Gvol_slide_down:

		moveq	#0,d0
		move.w	XM_Gvol_last(pc),d0
		lsl.w	#1,d0
		sub.w	d0,XM_Global_vol
		bpl.b	Gvol_slide_exit
		move.w	#0,XM_Global_vol
Gvol_slide_exit:
		rts
;-----------------Position jump command----------------
XM_Position_jump:	moveq	#0,d0
		move.b	_value(a2),d0
		cmp.w	Song_len(pc),d0
		bgt.b	XM_pj_stuppid_user

		lea	Order_table,a1
		lea	(a1,d0.w*4),a1
		move.l	(a1),a0

		move.w	5(a0),patt_rows
		add.w	#9,a0
		move.l	a0,Playing_pat
		move.l	a1,Order_ptr

		clr.w	XM_loop_flag
		move.w	#$ffff,XM_loop_row
		addq.w	#1,XM_break_flag

XM_pj_stuppid_user:
		rts
;---------------------Multi retrig----------------------
XM_Multi_rtg:	
		move.b	_value(a2),d0
		move.b	d0,d1
	
		tst.w	tempo_count(pc)
		bne.b	XM_Mtrg_fx

		clr.w	XM_retrig_count(a2)

		and.w	#$f,d1
		jmp	([XM_Multi_tree,pc,d1.w*4])
		
XM_Mtrg_fx	and.w	#$f0,d0
		lsr.w	#4,d0
		cmp.w	XM_retrig_count(a2),d0
		bgt.b	XM_Multi_no_change
		move.w	#SPL_PLAY,XM_spl_force(a2)	;its time hunny:)
		clr.w	XM_retrig_count(a2)
XM_Multi_no_change:
		addq.w	#1,XM_retrig_count(a2)
		rts

XM_Multi_tree:	dc.l	XM_nop
		dc.l	XM_Mtrg_m1
		dc.l	XM_Mtrg_m2
		dc.l	XM_Mtrg_m4
		dc.l	XM_Mtrg_m8
		dc.l	XM_Mtrg_m16
		dc.l	XM_Mtrg_2div3
		dc.l	XM_Mtrg_1div2
		dc.l	XM_nop
		dc.l	XM_Mtrg_p1
		dc.l	XM_Mtrg_p2
		dc.l	XM_Mtrg_p4
		dc.l	XM_Mtrg_p8
		dc.l	XM_Mtrg_p16
		dc.l	XM_Mtrg_3div2
		dc.l	XM_Mtrg_2div1

XM_Mtrg_m1:	subq.w	#1,XM_play_vol(a2)
		bra.b	XM_Mtrg_low_limit
XM_Mtrg_m2:	subq.w	#1,XM_play_vol(a2)
		bra.b	XM_Mtrg_low_limit
XM_Mtrg_m4:	subq.w	#4,XM_play_vol(a2)
		bra.b	XM_Mtrg_low_limit
XM_Mtrg_m8:	subq.w	#8,XM_play_vol(a2)
		bra.b	XM_Mtrg_low_limit
XM_Mtrg_m16:	sub.w	#16,XM_play_vol(a2)

XM_Mtrg_low_limit:	bpl.b	XM_Mtrg_low_ok
		clr.w	XM_play_vol(a2)
XM_Mtrg_low_ok	rts

XM_Mtrg_p1:	addq.w	#1,XM_play_vol(a2)
		bra.b	XM_Mtrg_up_limit
XM_Mtrg_p2:	addq.w	#2,XM_play_vol(a2)
		bra.b	XM_Mtrg_up_limit
XM_Mtrg_p4:	addq.w	#4,XM_play_vol(a2)
		bra.b	XM_Mtrg_up_limit
XM_Mtrg_p8:	addq.w	#8,XM_play_vol(a2)
		bra.b	XM_Mtrg_up_limit
XM_Mtrg_p16:	add.w	#16,XM_play_vol(a2)

XM_Mtrg_up_limit:	cmp.w	#63,XM_play_vol(a2)
		ble.b	XM_mtrg_up_ok
		move.w	#63,XM_play_vol(a2)
XM_mtrg_up_ok	rts

XM_Mtrg_2div3:	move.w	XM_play_vol(a2),d0
		lsl.w	d0
		divu.w	#3,d0
		move.w	d0,XM_play_vol(a2)
		rts

XM_Mtrg_1div2:	move.w	XM_play_vol(a2),d0
		lsr.w	d0
		move.w	d0,XM_play_vol(a2)
		rts

XM_Mtrg_3div2:	move.w	XM_play_vol(a2),d0
		mulu.w	#3,d0
		lsr.w	d0
		bra	XM_Mtrig_chk_up
		rts

XM_Mtrg_2div1:	move.w	XM_play_vol(a2),d0
		lsl.w	d0
XM_Mtrig_chk_up	cmp.w	#63,d0
		ble.b	XM_mrtg_2div1_ok
		moveq	#63,d0
XM_mrtg_2div1_ok: move.w	d0,XM_play_vol(a2)
		rts

;------------------------Key off------------------------
XM_Key_off:

		rts
;----------------Set envelope position------------------
XM_Set_env:	moveq	#0,d0
		move.b	_value(a2),d0
		move.w	d0,XM_venv_time(a2)
		move.w	d0,XM_penv_time(a2)
		rts
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
;
;			Execute E commands
;
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
XM_E_Commands:	
		moveq	#0,d0
		move.b	_value(a2),d0
		lsr.w	#4,d0
		jmp	([XM_jump_e_cmd.w,pc,d0.w*4])		

XM_E_Commands2:	
		moveq	#0,d0
		move.b	_value(a2),d0
		lsr.w	#4,d0
		jmp	([XM_jump_e_cmd2.w,pc,d0.w*4])		

XM_jump_e_cmd:	dc.l	XM_nop,XM_Fine_porta_down
		dc.l	XM_Fine_porta_up,XM_Set_gliss_control
		dc.l	XM_Vib_cont,XM_Set_tune
		dc.l	XM_Loop,XM_tremolo_cont,XM_nop
		dc.l	XM_Retrig_note,XM_fine_v_up
		dc.l	XM_fine_v_down,XM_cut_note
		dc.l	XM_nop,XM_Pattern_delay
		rept	16
		dc.l	XM_nop
		endr

XM_jump_e_cmd2:	dc.l	XM_nop,XM_nop
		dc.l	XM_nop,XM_nop
		dc.l	XM_nop,XM_nop
		dc.l	XM_nop,XM_nop,XM_nop
		dc.l	XM_run_trig,XM_nop
		dc.l	XM_nop,XM_run_cut
		dc.l	XM_run_delay,XM_nop
		rept	16
		dc.l	XM_nop
		endr
;-------------------------------------------------------------------------------
	;----Fine portamento slide up-----

XM_Fine_porta_up:	
		moveq	#0,d0
		move.b	_value(a2),d0
		and.w	#$f,d0
		bne.b	XM_FPorta_new_up
		move.w	XM_porta(a2),d0
XM_FPorta_new_up:move.w	d0,XM_porta(a2)
		add.l	d0,XM_note_period(a2)
		move.w	XM_max_period(pc),d0
		cmp.l	XM_note_period(a2),d0
		bgt.b	XM_FPorta_up_ok
		move.l	d0,XM_note_period(a2)
XM_FPorta_up_ok
		rts

;----------------Portamento down----------------------
XM_Fine_porta_down:	
		moveq	#0,d0
		move.b	_value(a2),d0
		and.w	#$f,d0
		bne.b	XM_FPorta_new_down
		move.w	XM_porta(a2),d0
XM_FPorta_new_down:	move.w	d0,XM_porta(a2)
		sub.l	d0,XM_note_period(a2)
		move.w	XM_min_period(pc),d0
		cmp.l	XM_note_period(a2),d0
		blt.b	XM_FPorta_down_ok
		move.l	d0,XM_note_period(a2)
XM_FPorta_down_ok
		rts

	;---------Retrig note-------------

XM_Retrig_note:		
		move.b	_value(a2),d0
		and.w	#$f,d0
		move.w	d0,XM_retrig_int(a2)
		clr.w	XM_retrig_count(a2)
		addq.w	#1,XM_retrig_flag(a2)
		rts

	;------Fine volume slide up-------
XM_fine_v_up:	
		moveq	#0,d0
		move.b	_value(a2),d0
		and.w	#$f,d0
		bne.b	XM_fine_Vol_slide_up
		move.w	XM_fine_vl(a2),d0
		beq.b	XM_fine_vol_e
XM_fine_Vol_slide_up	move.w	d0,XM_fine_vl(a2)

		add.w	d0,XM_play_vol(a2)		
		move.w	XM_play_vol(a2),d0
		cmp.w	#64,XM_play_vol(a2)
		blt.b	XM_fine_vol_e
		move.w	#64,XM_play_vol(a2)
XM_fine_vol_e:	rts

	;------Fine volume slide up-------
XM_fine_v_down:	moveq	#0,d0
		move.b	_value(a2),d0
		and.w	#$f,d0
		bne.b	XM_fine_Vol_slide_down
		move.w	XM_fine_vl2(a2),d0
		beq.b	XM_fine_vol_e2
XM_fine_Vol_slide_down:	move.w	d0,XM_fine_vl2(a2)

		sub.w	d0,XM_play_vol(a2)
		bpl.b	XM_fine_vol_e2
		clr.w	XM_play_vol(a2)
XM_fine_vol_e2:
		rts

	;--------Begin loop/do loop-------

XM_Loop:	
		move.b	_value(a2),d0
		and.w	#$f,d0
		tst.w	d0
		bne.b	XM_Loop_end
		
		move.w	patt_rows(pc),d1
		cmp.w	XM_loop_row(pc),d1
		beq.b	XM_loop_next

		move.l	Playing_pat(pc),XM_loop_ptr
		move.w	patt_rows(pc),XM_loop_row
		move.w	#1,XM_loop_flag
		rts

XM_Loop_end:	tst.w	XM_loop_count
		bne.b	XM_loop_branch
		bmi.b	XM_loop_next

		move.w	d0,XM_loop_count
		move.w	XM_loop_row(pc),patt_rows
		
		addq.w	#1,XM_loop_flag

		rts

XM_loop_branch:	move.w	XM_loop_row(pc),patt_rows

		addq.w	#1,XM_loop_flag

		subq.w	#1,XM_loop_count
		bne.b	XM_loop_next
		move.w	#256,XM_loop_flag
		move.w	#$ffff,XM_loop_row
		clr.w	XM_loop_count
XM_loop_next:
		rts

	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;	Vibrato Control

XM_Vib_cont:	moveq	#0,d0
		move.b	_value(a2),d0
		move.w	d0,XM_vib_wave(a2)
		rts

	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;	Tremolo Control

XM_tremolo_cont:	moveq	#0,d0
		move.b	_value(a2),d0
		move.w	d0,XM_tremolo_wave(a2)

		rts
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
XM_cut_note:	moveq	#0,d0
		move.b	_value(a2),d0
		
		and.w	#$f,d0
		move.w	d0,XM_cut_flag(a2)
		rts
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
XM_Set_tune:	moveq	#0,d0
		move.b	_value(a2),d0
		and.w	#$f,d0
		lsl.w	#4,d0
		extb.l	d0
		move.w	d0,XM_ftune(a2)
		rts
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
XM_Note_delay:	clr.w	spl_state(a1)
		clr.w	XM_spl_force(a2)
		rts
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
XM_Pattern_delay:
		move.b	_value(a2),d0
		and.w	#$f,d0
		mulu.w	tempo(pc),d0
		move.w	d0,XM_patt_delay
		;sub.w	d0,tempo_count
		rts
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
XM_Set_gliss_control:
		rts

;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
;	
;		~| VOLUME COLUMN EFFECTS |~
;		 ^^^^^^^^^^^^^^^^^^^^^^^^^
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ

XM_jump_vol_1:	dc.l	XM_nop,XM_volume
		dc.l	XM_volume,XM_volume
		dc.l	XM_volume,XM_volume
		dc.l	XM_nop,XM_nop
		dc.l	XM_vc_fvsd,XM_vc_fvsu
		dc.l	XM_vc_set_vs,XM_vc_vib
		dc.l	XM_vc_set_pan,XM_nop
		dc.l	XM_nop,XM_vc_tone_porta

XM_jump_vol_2:	dc.l	XM_nop,XM_volume
		dc.l	XM_volume,XM_volume
		dc.l	XM_volume,XM_volume
		dc.l	XM_vc_vol_sd,XM_vc_vol_su
		dc.l	XM_nop,XM_nop
		dc.l	XM_nop,XM_nop
		dc.l	XM_nop,XM_vc_psl
		dc.l	XM_vc_psr,XM_nop

XM_jump_vol_3:	dc.l	XM_nop,XM_volume
		dc.l	XM_volume,XM_volume
		dc.l	XM_volume,XM_volume
		dc.l	XM_nop,XM_nop
		dc.l	XM_nop,XM_nop
		dc.l	XM_nop,XM_nop
		dc.l	XM_nop,XM_nop
		dc.l	XM_nop,XM_nop
	
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
XM_volume:	moveq	#0,d0
		move.b	_volume(a2),d0		~| We've got "set volume" command
		sub.w	#$10,d0
		limit.up	d0,#$40
		move.w	d0,XM_play_vol(a2)
		rts	

	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
XM_vc_vol_sd:	move.b	_volume(a2),d0		~| Vol slide down
		and.w	#$0f,d0

		;lsl.w	#2,d0
		sub.w	d0,XM_play_vol(a2)
		tst.w	XM_play_vol(a2)
		bpl.b	Volume_slide_exit1_
		clr.w	XM_play_vol(a2)
Volume_slide_exit1_:	rts
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
XM_vc_vol_su:	move.b	_volume(a2),d0
		and.w	#$0f,d0

		;lsl.w	#2,d0
		add.w	d0,XM_play_vol(a2)		
		cmp.w	#64,XM_play_vol(a2)
		blt.b	Volume_slide_exit2_

		move.w	#64,XM_play_vol(a2)
Volume_slide_exit2_		rts
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
XM_vc_fvsd:	move.b	_volume(a2),d0	~| Fine volume slide down?? |~
		and.w	#$0f,d0

		sub.w	d0,XM_play_vol(a2)
		tst.w	XM_play_vol(a2)
		bpl.b	FVolume_slide_exit1
		clr.w	XM_play_vol(a2)
FVolume_slide_exit1:	rts
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
XM_vc_fvsu:	move.b	_volume(a2),d0	~| Fine volume slide up?? |~
		and.w	#$0f,d0

		add.w	d0,XM_play_vol(a2)		
		cmp.w	#64,XM_play_vol(a2)
		blt.b	FVolume_slide_exit2
		move.w	#64,XM_play_vol(a2)
FVolume_slide_exit2		rts
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
XM_vc_set_vs:	move.b	_volume(a2),d0	~| Set vib speed ?? |~
		and.w	#$0f,d0
		move.w	d0,XM_vib_rate2(a2)
		rts
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
XM_vc_vib:	move.b	_volume(a2),d0	~| Vibrato ?? |~
		and.w	#$0f,d0
		move.w	d0,XM_vib_depth2(a2)
		clr.w	XM_vib_pos(a2)
		addq.w	#1,XM_vib_flag(a2)

		move.l	XM_note_period(a2),XM_temp_period(a2)
		rts
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
XM_vc_set_pan:	move.b	_volume(a2),d0		~| Set panning ?? |~
		and.l	#$f,d0
		lsl.l	#4,d0
		;mulu.w	#10625/10,d0
		;divu.w	#10000/10,d0
		move.w	d0,XM_pan(a2)
		rts
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
XM_vc_psl:	;illegal
		move.b	_volume(a2),d0		~| Panning slide left |~
		and.w	#$f,d0
		;lsl.w	#4,d0
		sub.w	d0,XM_pan(a2)
		bpl.b	XM_slide_exitV_
		clr.w	XM_pan(a2)
XM_slide_exitV_:	rts
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
XM_vc_psr:	;illegal
		move.b	_volume(a2),d0		~| Panning slide right |~
		and.w	#$f,d0
		;lsl.w	#4,d0
		add.w	d0,XM_pan(a2)
		cmp.w	#256,XM_pan(a2)
		blt.b	XM_slide_leftV_
		move.w	#256,XM_pan(a2)
XM_slide_leftV_:	rts
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
XM_vc_tone_porta:		moveq	#0,d0
		move.b	_volume(a2),d0
		and.w	#$f,d0
		beq.b	XM_tone_skip_3

		lsl.w	#2,d0
		move.w	d0,XM_tone_speed(a2)


		move.l	XM_const_period(a2),XM_org_period(a2)
		addq.w	#1,XM_tone_flag(a2)
XM_tone_skip_3:
		rts

;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
XM_run_cut:
	;-----------Cut note???------------

		tst.w	tempo_count
		beq.b	XM_no_cut

		subq.w	#1,XM_cut_flag(a2)
		bne.b	XM_no_cut
	
		clr.w	XM_play_vol(a2)
XM_no_cut:
		rts
	;------------Note Delay------------
XM_run_delay:	
		;move.w	tempo,d0
		
		tst.w	tempo_count(pc)
		beq.b	XM_no_delay2

		move.w	tempo_count(pc),d0
		move.b	_value(a2),d1
		and.w	#$f,d1
		beq.b	XM_no_delay3
		cmp.w	d1,d0
		bne.b	XM_no_delay3

		move.w	#SPL_PLAY,XM_spl_force(a2)	;ok, now play
		;clr.b	_effect(a2)
		;clr.b	_value(a2)
XM_no_delay3	rts

XM_no_delay2:	clr.w	spl_state(a1)
		clr.w	XM_spl_force(a2)
		rts

	;----Perocess appregio command-----
XM_run_app:	
		tst.w	tempo_count
		beq.b	XM_no_appregio

		tst.b	_value(a2)
		beq.b	XM_no_appregio

		moveq	#0,d0
		move.w	XM_appreg_1(a2),d0

		move.l	d0,XM_note_period(a2)
		move.w	XM_appreg_2(a2),XM_appreg_1(a2)
		move.w	XM_appreg_3(a2),XM_appreg_2(a2)
		move.w	d0,XM_appreg_3(a2)
XM_no_appregio:
		rts

	;-----Process vibrato command------
XM_run_vib:	
		move.b	XM_vib_pos+1(a2),d0
		lsr.w	#2,d0
		and.w	#$1f,d0
		moveq	#0,d2
		move.l	XM_vib_wave(a2),d2
		and.b	#$03,d2
		beq.b	XM_vib_sine
		lsl.b	#3,d0
		cmp.b	#1,d2
		beq.b	XM_vib_rampdown
		move.b	#255,d2
		bra.b	XM_vib_set
XM_vib_rampdown
		tst.b	XM_vib_pos+1(a2)
		bpl.b	XM_vib_rampdown2
		move.b	#255,d2
		sub.b	d0,d2
		bra.b	XM_vib_set
XM_vib_rampdown2
		move.b	d0,d2
		bra.b	XM_vib_set
XM_vib_sine
		move.b	(XM_vibratotable,d0.w),d2
XM_vib_set
		move.w	XM_vib_depth2(a2),d0
		and.w	#15,d0
		mulu	d0,d2
		lsr.l	#5,d2
		move.l	XM_const_period(a2),d0
		tst.b	XM_vib_pos+1(a2)
		bmi.b	XM_vibratoneg
		add.l	d2,d0
		bra.b	XM_vibrato3
XM_vibratoneg
		sub.l	d2,d0
XM_vibrato3
		move.l	d0,XM_note_period(a2)

		move.w	XM_vib_rate2(a2),d0
		lsl.w	#2,d0
		and.w	#$3c,d0
		add.b	d0,XM_vib_pos+1(a2)
		rts	

	;-----Process tone portamento-----

XM_run_porta:	tst.w	tempo_count
		beq.b	XM_no_tone

		move.l	XM_org_period(a2),d0

		move.l	d0,d1
		sub.l	XM_note_period(a2),d0
		bmi.b	XM_tone_add
		moveq	#0,d0
		move.w	XM_tone_speed(a2),d0
		lsl.l	#2,d0
		add.l	d0,XM_note_period(a2)
		cmp.l	XM_note_period(a2),d1
		bgt.b	XM_no_tone
		move.l	d1,XM_note_period(a2)
		clr.w	XM_tone_flag(a2)
		bra.b	XM_no_tone

XM_tone_add:	moveq	#0,d0
		move.w	XM_tone_speed(a2),d0
		lsl.l	#2,d0
		sub.l	d0,XM_note_period(a2)
		cmp.l	XM_note_period(a2),d1
		blt.b	XM_no_tone
		move.l	d1,XM_note_period(a2)
		clr.w	XM_tone_flag(a2)

XM_no_tone:
		rts
	;----------Process tremolo------------
XM_run_tre:	tst.w	tempo_count
		beq.b	XM_no_tremolo

		moveq	#0,d0
		move.w	XM_temp_vol(a2),d0

		move.w	XM_tremolo_pos(a2),d1

		moveq	#0,d2
		move.l	XM_tremolo_wave(a2),a3
		move.b	(a3,d1.w),d2
		mulu.w	XM_tremolo_depth(a2),d2
	
		lsr.l	#6,d2

		sub.l	d2,d0
		bpl.b	XM_tremolo_proc_vok
		moveq	#0,d0
XM_tremolo_proc_vok:
		move.w	d0,XM_play_vol(a2)

		move.w	XM_tremolo_rate(a2),d0
		move.w	XM_tremolo_pos(a2),d1

		add.w	d0,d1
		and.w	#63,d1
		move.w	d1,XM_tremolo_pos(a2)
XM_no_tremolo:
		rts
	;---------Process retrig note------------
XM_run_trig:	
		tst.w	tempo_count		
		beq.b	XM_no_retrig

		move.w	XM_retrig_count(a2),d0
		cmp.w	XM_retrig_int(a2),d0
		blt.b	XM_no_retrig_2

		move.l	XM_Sample_ptr(a2),spl_ptr(a1)
		move.w	#SPL_PLAY,XM_spl_force(a2)
		clr.w	XM_retrig_count(a2)
		bra.b	XM_no_retrig
XM_no_retrig_2:	addq.w	#1,XM_retrig_count(a2)
XM_no_retrig:
		rts
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
;
;	This little routne process all the stuff that have to be
;	done in BPM tick, besides look yourself
;
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ

XM_resolve_spl:	move.l	XM_mask(pc),d0
		move.w	XM_ch_count(pc),d1
		btst	d1,d0
		beq	XM_channel_off2
	
	;תתתתתתתתתתתתתתתתתתתתתתתתתתתתתתתתתת
		moveq	#0,d0
		move.b	_volume(a2),d0
		lsr.b	#4,d0
		jsr	([XM_jump_vol_2.w,pc,d0.w*4])		

		moveq	#0,d0
		move.b	_effect(a2),d0
		jsr	([XM_cmd_jump_tree_2.w,pc,d0.w*4])

;-------------------Convert period into frequency [Hz]------------------------
;
;	
		move.l	XM_note_period(a2),d2

		tst.w	XM_spl_force(a2)
		bne.b	XM_recalc_anyway

		cmp.l	XM_play_period(a2),d2
		beq	XM_same_period
XM_recalc_anyway:
		move.l	XM_play_period(a2),XM_old_period(a2)
		move.l	d2,XM_play_period(a2)

		tst.b	XM_Amiga
		beq.b	XM_Amiga_freq
		
		move.l	XM_Pertab(pc),a6
		move.l	(a6,d2.l*4),spl_freq(a1)

		bra.b	XM_force_status

XM_Amiga_freq:	move.l	#8363*1712/2,d0
		divu.l	d2,d0
		move.l	d0,spl_freq(a1)

XM_force_status	
		move.w	XM_spl_force(a2),d0
		cmp.w	#SPL_STOP2,d0
		bne.b	XM_check_force2

		clr.w	spl_state(a1)
		bra.b	XM_same_period

XM_check_force2:tst.w	d0
		beq.b	XM_same_period
		move.w	d0,spl_state(a1)
		clr.w	XM_spl_force(a2)
		bra.b	XM_same_period

XM_channel_off2:clr.w	spl_state(a1)
		clr.w	XM_spl_force(a2)
		rts
XM_same_period:
;---------------Calculate volume by the formula:-------------------------
;
;FinalVol=(FadeOutVol/65536)*(EnvelopeVol/64)*(GlobalVol/64)*(Vol/64)*Scale;
;
		tst.w	XM_fadeout(a2)
		beq	XM_channel_off

		tst.w	spl_state(a1)
		beq	XM_channel_off

		push.l	a0
		bsr	XM_envelope_vol		~| tricky stuff:)
	;---------------------------------

		;tst.w	d6
		;beq.b	XM_no_fadeout

		tst.w	XM_key_off(a2)
		beq	XM_no_fadeout

		move.l	XM_inst_ptr(a2),a0
		tst.l	a0
		beq	XM_no_fadeout

		ifd	dfsddf
		movem.l	d0-d1,-(sp)
		moveq	#0,d0
		move.w	XM_vol_fadeout(a0),d0
		;cmp.w	#$80,d0
		;beq.b	XM_no_fadeout2
		moveq	#0,d1
		move.w	XM_fadeout(a2),d1
		sub.l	d0,d1
		bpl.b	XM_fadeout_ok
		moveq	#0,d1
XM_fadeout_ok:	move.w	d1,XM_fadeout(a2)
XM_no_fadeout2:	movem.l	(sp)+,d0-d1
		endc
XM_no_fadeout:
	;---------------------------------
		bsr	XM_envelope_pan		~| tricky stuff:)
		pop.l	a0
;FinalVol=(FadeOutVol/65536)*(EnvelopeVol/64)*(GlobalVol/64)*(Vol/64)*Scale;

		moveq	#0,d1
		move.w	XM_venv_vol(a2),d1

		moveq	#0,d2
		moveq	#0,d3
		move.w	XM_Global_vol(pc),d2
		mulu.l	d2,d3:d1
		
		moveq	#0,d2
		move.w	XM_play_vol(a2),d2
		mulu.l	d2,d3:d1

		moveq	#0,d0
		move.w	XM_fadeout(a2),d0
		mulu.l	d0,d3:D1
		divu.l	#fade_in,d3:d1

		lsr.l	#3,d1

		;move.w	XM_voice_vol(a2),d0
		;mulu.l	d0,d1
		;lsr.l	#6,d1
	
		move.w	d1,spl_volume(a1)

;-----------------Calculate panning value by the formula:------------------
;
;        FinalPan=Pan+(EnvelopePan-32)*(128-Abs(Pan-128))/32;

		moveq	#0,d0
		move.w	XM_pan(a2),d0
		move.w	d0,d1
		sub.w	#128,d1
		abs.w	d1
		move.w	#128,d2
		sub.w	d1,d2		;d2->(128-Abs(Pan-128)

		move.w	XM_penv(a2),d1
		sub.w	#32,d1		;d1->(EnvelopePan-32)
		muls	d2,d1
		asr.w	#5,d1
		add.w	d1,d0
		sub.w	#128,d0
		asl.w	#8,d0

		move.w	d0,spl_panning(a1)

XM_channel_off	rts
;-------------------------------------------------------------------------------
XM_calc_period:	moveq	#0,d1
		move.w	XM_ftune(a2),d1
		;ext.w	d1
		tst.b	XM_Amiga
		beq.b	XM_Amiga_period

		move.l	#121*64,d2		;(10*12*16*4) - (Note*16*4)
		;and.l	#$7f,d0
		lsl.l	#6,d0
		sub.l	d0,d2
		moveq	#0,d0
		move.b	d1,d0
		extb.l	d0
		asr.l	#1,d0
		sub.l	d0,d2			; Note*16*4 - FineTune/2;
		rts
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
XM_Amiga_period:
		lsl.w	#8,d0
		move.l	XM_Pertab(pc),a6
		moveq	#0,d2
		move.b	d1,d0
		move.w	(a6,d0.w*2),d2

		rts
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
XM_envelope_vol: 		;illegal

		move.l	XM_inst_ptr(a2),a0
		tst.l	a0
		beq	XM_v_vol_done

		btst	#XM_env_on,XM_vol_type(a0)
		beq	XM_v_vol_done_off
	
		tst.b	XM_num_vol(a0)
		beq	XM_v_vol_done_off2

XM_vol_env_in_prog:

		lea	XM_vol_env(a0),a6

		addq.w	#1,XM_venv_time(a2)
		move.w	XM_venv_time(a2),d6
	;ננננננננננננננננננננננננננננננננננננננננ
		btst	#XM_env_loop,XM_vol_type(a0)
		beq.b	XM_no_loop

		moveq	#0,d0
		move.b	XM_vol_elp(a0),d0
		cmp.w	(a6,d0.w*4),d6
		blt.b	XM_loop_nr

		move.b	XM_vol_lp(a0),d0
		move.w	(a6,d0.w*4),XM_venv_time(a2)
XM_loop_nr
	;ננננננננננננננננננננננננננננננננננננננננ
XM_no_loop:	btst	#XM_env_sustain,XM_vol_type(a0)
		beq.b	XM_no_sustain

		tst.w	XM_key_off(a2)
		bne.b	XM_no_sustain

		moveq	#0,d0
		move.b	XM_vol_sust(a0),d0
		cmp.w	(a6,d0.w*4),d6
		blt.b	XM_no_sustain
		
		move.w	(a6,d0.w*4),XM_venv_time(a2)

	;ננננננננננננננננננננננננננננננננננננננננ
XM_no_sustain:			

	;ננננננננננננננננננננננננננננננננננננננננ
		bsr	XM_get_point

		rts
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
XM_get_point:	                 ;llegal
		moveq	#0,d6
		move.w	XM_venv_time(a2),d0

		moveq	#0,d2
		move.b	XM_num_vol(a0),d2
		subq.w	#1,d2
		moveq	#0,d7

XM_fp_loop:	move.w	(a6),d1
		cmp.w	d1,d0
		blt.b	XM_take_point

		addq.w	#4,a6	;move 2 next point
		addq.w	#1,d7
		dbf	d2,XM_fp_loop

		subq.w	#1,XM_venv_time(a2)
		moveq	#-1,d6
	
XM_take_point:	subq.l	#4,a6
		subq.w	#1,d7

		move.w	(a6),d4
		sub.w	d4,d0
		move.w	d0,d2

		move.w	d1,d3
		sub.w	d4,d3

		move.w	2(a6),d0		~| First point volume	
		move.w	6(a6),d1		~| 2nd point volume

		exg.l	d2,d3

		extb.l	d0
		extb.l	d1
		sub.l	d0,d1
		asl.l	#8,d1
		divs.w	d2,d1
		muls.w	d3,d1
		asr.l	#8,d1
		add.l	d1,d0

		move.w	d0,XM_venv_vol(a2)
		rts

XM_v_vol_done:	
		rts
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
XM_v_vol_done_off:
		tst.w	XM_key_off(a2)
		beq	XM_venv_no_off
XM_v_vol_done_off2	clr.w	spl_state(a1)
XM_venv_no_off:	
		moveq	#0,d6
		rts

;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
XM_envelope_pan: 		;illegal

		move.l	XM_inst_ptr(a2),a0
		tst.l	a0
		beq	XM_v_pan_done

		btst	#XM_env_on,XM_pan_type(a0)
		beq	XM_v_pan_done_off
	
		tst.b	XM_num_pan(a0)
		beq	XM_v_pan_done_off2

XM_pan_env_in_prog:

		lea	XM_pan_env(a0),a6

		addq.w	#1,XM_penv_time(a2)
		move.w	XM_penv_time(a2),d6
	;ננננננננננננננננננננננננננננננננננננננננ
		btst	#XM_env_loop,XM_pan_type(a0)
		beq.b	XM_no_loop_pan

		moveq	#0,d0
		move.b	XM_pan_elp(a0),d0
		cmp.w	(a6,d0.w*4),d6
		blt.b	XM_loop_nr_pan

		move.b	XM_pan_lp(a0),d0
		move.w	(a6,d0.w*4),XM_penv_time(a2)
XM_loop_nr_pan
	;ננננננננננננננננננננננננננננננננננננננננ
XM_no_loop_pan:	btst	#XM_env_sustain,XM_pan_type(a0)
		beq.b	XM_no_sustain_pan

		tst.w	XM_key_off(a2)
		bne.b	XM_no_sustain_pan

		moveq	#0,d0
		move.b	XM_pan_sust(a0),d0
		cmp.w	(a6,d0.w*4),d6
		blt.b	XM_no_sustain_pan
		
		move.w	(a6,d0.w*4),XM_penv_time(a2)

	;ננננננננננננננננננננננננננננננננננננננננ
XM_no_sustain_pan:

	;ננננננננננננננננננננננננננננננננננננננננ
		bsr	XM_get_point_pan

XM_venv_exit_pan:	
		rts
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
XM_get_point_pan:	                 ;llegal

		move.w	XM_penv_time(a2),d0

		moveq	#0,d2
		move.b	XM_num_pan(a0),d2
		subq.w	#1,d2
		moveq	#0,d7

XM_fp_loop_pan:	move.w	(a6),d1
		cmp.w	d1,d0
		blt.b	XM_take_point_pan

		addq.w	#4,a6	;move 2 next point
		addq.w	#1,d7
		dbf	d2,XM_fp_loop_pan

		subq.w	#1,XM_penv_time(a2)
	
XM_take_point_pan:	subq.l	#4,a6
		subq.w	#1,d7

		move.w	(a6),d4
		sub.w	d4,d0
		move.w	d0,d2

		move.w	d1,d3
		sub.w	d4,d3

		move.w	2(a6),d0		~| First point panume	
		move.w	6(a6),d1		~| 2nd point panume

		exg.l	d2,d3

		extb.l	d0
		extb.l	d1
		sub.l	d0,d1
		asl.l	#8,d1
		divs.w	d2,d1
		muls.w	d3,d1
		asr.l	#8,d1
		add.l	d1,d0

		move.w	d0,XM_penv(a2)
		rts

XM_v_pan_done:
		rts
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
XM_v_pan_done_off:
XM_v_pan_done_off2
XM_penv_no_off:	
		rts

;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
;
;		tracker variables
;
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
XM_ch_count:	ds.w	1
XM_mask:	;dc.l	%00010000
		;dc.l	%10010000
		;dc.l	%11010000
		;dc.l	%1000000	-	sunflow
		;dc.l	%1000
		;dc.l	%0001000000
		;dc.l	%00000010000
		;dc.l	%000010000000	-buggy!
		;dc.l	%111
		;dc.l	%0010000000000	- beat
		;dc.l	%0000000000001000
		dc.l	$ffffffff

XM_max_period:	ds.w	1
XM_min_period:	ds.w	1

XM_Gvol_last:	ds.w	1
XM_Global_vol:	dc.w	63
XM_temp_patt_ptr:	ds.l	1
XM_temp_row:	ds.w	1
XM_loop_ptr:	ds.l	1
XM_loop_row:	ds.w	1
XM_loop_count:	ds.w	1
XM_loop_flag:	ds.w	1
XM_patt_delay:	dc.w	0
XM_Amiga:	ds.b	1
		even
XM_restart_song:ds.w	1
XM_break_flag:	ds.b	1
		even
pattern_Nb:	ds.w	1
Instrument_Nb:	ds.w	1
channel_Nb:	ds.w	1	
Song_len:	ds.w	1
default_tempo	ds.w	1
default_BPM:	ds.w	1
XM_trax_ptr:	ds.l	1
Patterns_ptr:	ds.l	1
temp_size:	ds.l	1
temp_loop:	ds.w	1
Order_ptr	ds.l	1
Playing_pat:	ds.l	1
_Playing_pat:	ds.l	1
patt_rows:	ds.w	1
XM_chuj:	ds.w	1

XM_Pertab:	ds.l	1

Pulsar_base:	ds.l	1

tempo:		ds.w	1
tempo_count:	ds.w	1
_tempo_count:	ds.w	1

	;-----CONSTANT TABLES-------
XM_vibratotable:
		dc.b 0,24,49,74,97,120,141,161
		dc.b 180,197,212,224,235,244,250,253
		dc.b 255,253,250,244,235,224,212,197
		dc.b 180,161,141,120,97,74,49,24
		
	;-----------------------

Order_table:	ds.l	256+2
Instruments:	ds.l	128	;instruments ptr's (if Instruments[i]==0 then no samples)
Inst_samples:	ds.l	128*32	;coz' each instrument can have 16 samples
channels:	ds.b	channel_size*32
XM_skip_tab:	ds.w	256	~| This table serves like a lookup when skippin pattern positions

Temp:		ds.l	1024

XM_ltab:	incbin	lnperiod.tap
XM_atab:	incbin	amperiod.tap
		even
;-------------------------------------------------------------------------------
mod		;incbin	f:\dwojka3.xm

		;incbin	g:\shell\mods\mb_demo2.xm
		;incbin	e:\xm'ms\back_coc.xm
		;incbin	e:\xm'ms\penv.xm
		;incbin	e:\scena\mods\xm's\propagan.xm
		;incbin	e:\scena\mods\jogeir\moonlit.xm
		;incbin h:\mods\mods\part1\xm\arnomnia.xm
		;incbin h:\mods\mods\part1\xm\polar.xm
		;incbin h:\mods\mods\part1\new-i!\fife.xm
		;incbin	panning.xm
		;incbin	fineslid.xm
		incbin	'd:\blaaha.xm'