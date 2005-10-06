*		High-level manager for SND player
*		SND plugin for mxPlay - Main()
*		by -XI-/Satantronic
*		version 1   save:0.01a   date:03.11.2005   time:02:32

		opt	d-
		comment	HEAD=%0111			;MinimalHeap,MallocInTT-RAM,LoadInTT-RAM,Fastload
		opt	p=68030
		OUTPUT	.MXP

		include	"mxp_inc.s"

MAX_HEADER:	equ	200

;====================================================
		section text

;---Plugin header:-----------------------------------
snd_header:
		dc.l	"MXP1"
		ds.l	1
		bra.w	snd_register_module
		bra.w	snd_check_module
		bra.w	snd_get_playtime
		bra.w	snd_initt
		bra.w	snd_set
		bra.w	snd_unset
		bra.w	snd_deinit
		bra.w	snd_fwd
		bra.w	snd_rwd
		bra.w	snd_pause
		dc.l	snd_info
		dc.l	snd_extensions
		dc.l	snd_settings


;---Register:----------------------------------------
snd_register_module:

		movea.l	snd_header+MXP_PLUGIN_PARAMETER,a0
		move.l	(a0)+,filebuffer
		move.l	(a0)+,filelenght

start_tests:	jsr	snd_test_file

		jsr	snd_test_param

		move.l	#MXP_FLG_INFOLINE,d0
		not.l	d0
		and.l	d0,snd_set_title
		and.l	d0,snd_set_artist
		and.l	d0,snd_set_ripper
		and.l	d0,snd_set_convers
		and.l	d0,snd_set_method
		and.l	d0,snd_set_songs

		;ori.l	#MXP_FLG_INFOLINE,snd_set_file
		ori.l	#MXP_FLG_INFOLINE,snd_set_type
		ori.l	#MXP_FLG_INFOLINE,snd_set_title
		ori.l	#MXP_FLG_INFOLINE,snd_set_artist
		;ori.l	#MXP_FLG_INFOLINE,snd_set_ripper
		;ori.l	#MXP_FLG_INFOLINE,snd_set_convers
		;ori.l	#MXP_FLG_INFOLINE,snd_set_method
		;ori.l	#MXP_FLG_INFOLINE,snd_set_songs


		move.l	#MXP_FLG_MOD_PARAM,d0
		not.l	d0
		and.l	d0,snd_set_title
		and.l	d0,snd_set_artist
		and.l	d0,snd_set_ripper
		and.l	d0,snd_set_convers
		and.l	d0,snd_set_method
		and.l	d0,snd_set_songs

		ori.l	#MXP_FLG_MOD_PARAM,snd_set_file
		ori.l	#MXP_FLG_MOD_PARAM,snd_set_type
		ori.l	#MXP_FLG_MOD_PARAM,snd_set_title
		ori.l	#MXP_FLG_MOD_PARAM,snd_set_artist
		ori.l	#MXP_FLG_MOD_PARAM,snd_set_ripper
		ori.l	#MXP_FLG_MOD_PARAM,snd_set_convers
		ori.l	#MXP_FLG_MOD_PARAM,snd_set_method
		;ori.l	#MXP_FLG_MOD_PARAM,snd_set_songs

.ok		moveq	#MXP_OK,d0
		rts

no_ram:
no_SND:		moveq	#MXP_ERROR,d0
		rts


;---Check:-------------------------------------------
snd_check_module:
		bsr.w	snd_get_module_type		; d0 will contain return code
		rts


;---Get play time:-----------------------------------
snd_get_playtime:
		move.l	#6*60,d0			; 06'00"
		rts


;---Init:--------------------------------------------
snd_initt:	moveq	#MXP_OK,d0
.exit:		rts


;---Set:---------------------------------------------
snd_set:	clr.l	stop_flag

		bsr.w	start_play	

		moveq	#MXP_OK,d0
		rts


;---Unset:-------------------------------------------
snd_unset:	bsr.w	stop_play	

		moveq	#MXP_OK,d0
		rts

		
;---Deinit:------------------------------------------
snd_deinit:	pea	memoryblock			;mfree()
		move.w	#$49,-(sp)
		trap	#1
		addq.l	#6,sp
	
		moveq	#MXP_OK,d0
		rts


;---Module forward:----------------------------------
snd_fwd:	moveq	#MXP_UNIMPLEMENTED,d0
		rts


;---Module rewind:-----------------------------------
snd_rwd:	moveq	#MXP_UNIMPLEMENTED,d0
		rts

		
;---Module pause:------------------------------------
snd_pause:	tst.l	stop_flag
		beq.s	.stop
		clr.l	stop_flag
		;bsr	_start_
		moveq	#MXP_OK,d0
		rts
		
.stop		move.l	#1,stop_flag
		;bsr	_stop_
		moveq	#MXP_OK,d0
		rts

;---Subrouts:----------------------------------------
snd_get_module_file:
		lea.l	snd_module_filename,a2
		move.l	a2,snd_header+MXP_PLUGIN_PARAMETER
		rts

snd_get_module_type:
		move.l	filebuffer,a1
		move.l	(a1),d0
		lea.l	snd_formats,a0

		cmp.l	#"ICE!",d0
		bne.s	.tst_unpack
		bra	.found

.tst_unpack	cmp.l	#"SNDH",d0
		bne	.no_SND
		addq.l	#4,a0

.found:		move.l	(a0),snd_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

.no_SND:	moveq	#MXP_ERROR,d0
		rts


snd_get_module_title
		move.l	title_txt,a2

.end		move.l	a2,snd_header+MXP_PLUGIN_PARAMETER
		rts

snd_get_module_artist
		move.l	composer_txt,a2

.end		move.l	a2,snd_header+MXP_PLUGIN_PARAMETER
		rts

snd_get_module_ripper
		move.l	ripper_txt,a2

.end		move.l	a2,snd_header+MXP_PLUGIN_PARAMETER
		rts

snd_get_module_convers
		move.l	conversion_txt,a2

.end		move.l	a2,snd_header+MXP_PLUGIN_PARAMETER
		rts

snd_get_module_method
		move.l	method_txt,a2

.end		move.l	a2,snd_header+MXP_PLUGIN_PARAMETER
		rts

snd_get_module_songs
		move.l	songs_txt,a2

.end		move.l	a2,snd_header+MXP_PLUGIN_PARAMETER
		rts


snd_test_file:	move.l	filebuffer,a1
		move.l	(a1),d0

		cmp.l	#"ICE!",d0
		bne.s	.tst_unpack

		move.l	filebuffer,a1
		move.l	a1,old_filebuffer		;zaloha

		move.l	8(a1),d0
		;add.l	filelenght,d0			;size of packed+unpacked data

		move.w	#0,-(sp)			;mxAlloc() in STRAM
		move.l	d0,-(sp)
		move.w	#$44,-(sp)
		trap	#1
		addq.l	#8,sp
		tst.l	d0
		beq	no_ram				;no enought memory

		move.l	d0,song_address			;store address of memory
		move.l	d0,memoryblock			;store for mfree()
		move.l	d0,a1				;to - address to unpack data

		move.l	filebuffer,a0			;from - address of packed data
		bsr	ice_decrunch

		bsr.w	get_songinfo

		bra.s	.ok

.tst_unpack	cmp.l	#"SNDH",d0
		bne	no_SND
		move.l	a1,song_address
.ok		rts


snd_test_param:	rts

		
;--- include source ---------------------------------
		;include	"snd_load.s"				;load/depack snd file
		include	"ice_unpa.s"				;ice depacker
		include	"snd_head.s"				;parse sndh header
		include	"snd_play.s"				;setup irq and play


;====================================================
		section	data

		even

snd_info:	dc.l	snd_info_plugin_author
		dc.l	snd_info_plugin_version
		dc.l	snd_info_replay_name
		dc.l	snd_info_replay_author
		dc.l	snd_info_replay_version
		dc.l	MXP_FLG_USE_DSP|MXP_FLG_USE_DMA|MXP_FLG_USE_020


snd_settings:	dc.l	snd_settings_module_file
snd_set_file	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	snd_get_module_file

		dc.l	snd_settings_module_type
snd_set_type	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	snd_get_module_type

		dc.l	snd_settings_module_title	;NAME
snd_set_title	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	snd_get_module_title

		dc.l	snd_settings_module_artist	;AUTH
snd_set_artist	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	snd_get_module_artist

		dc.l	snd_settings_module_ripper
snd_set_ripper	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	snd_get_module_ripper

		dc.l	snd_settings_module_convers	;DATE
snd_set_convers	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	snd_get_module_convers

		dc.l	snd_settings_module_method	;RMRK
snd_set_method	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	snd_get_module_method

		dc.l	snd_settings_module_songs	;INFO
snd_set_songs	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	snd_get_module_songs

		;dc.l	snd_settings_interpolation
		;dc.l	MXP_PAR_TYPE_BOOL
		;dc.l	snd_set_interpolation
		;dc.l	snd_get_interpolation

		dc.l	0


snd_extensions:	dc.l	snd_extensions_mod
		dc.l	snd_extensions_mod_name
		
		dc.l	0


snd_formats:	dc.l	snd_formats_SNDICE_name
		dc.l	snd_formats_SNDunpk_name


snd_settings_module_file:
		dc.b	"File",0
snd_settings_module_type:
		dc.b	"Module type",0
snd_settings_module_title:
		dc.b	"Title",0
snd_settings_module_artist:
		dc.b	"Artist",0
snd_settings_module_ripper:
		dc.b	"Ripper",0
snd_settings_module_convers:
		dc.b	"Conversion",0
snd_settings_module_method:
		dc.b	"Method",0
snd_settings_module_songs:
		dc.b	"Songs",0

		
snd_info_plugin_author:
		dc.b	"-XI-/Satantronic",0
snd_info_plugin_version:
		dc.b	"0.01a 30.11.2005",0
snd_info_replay_name:
		dc.b	"SND",0
snd_info_replay_author:
		dc.b	"",0
snd_info_replay_version:
		dc.b	"1.0",0
		

snd_extensions_mod:
		dc.b	"SND",0
snd_extensions_mod_name:
		dc.b	"SND module",0


snd_formats_SNDICE_name:
		dc.b	"SND (packedwith ICE)",0

snd_formats_SNDunpk_name:
		dc.b	"SND (---)",0


snd_module_filename:
		dc.b	0
snd_module_n_a:
		dc.b	"n/a",0


		even
snd_tags	dc.b	"NAME"
		dc.l	snd_strgNAME

		dc.b	"AUTH"
		dc.l	snd_strgAUTH

		dc.b	"DATE"
		dc.l	snd_strgDATE

		dc.b	"RMRK"
		dc.l	snd_strgRMRK

		dc.b	"INFO"
		dc.l	snd_strgINFO

		dc.b	0

		even
t_no_inf:	dc.b	'?',0
t_timer:	dc.b	'Timer ',0
		even

t_vblon		dc.b	"VBI, ?? Hz",0
t_vbloff:	dc.b	'Off!',0
t_vbiovr:	dc.b	", VBL override!",0
t_musicmon	dc.b	"Can't play MusicMon tunes!",0

		even
;====================================================
		section	bss
		even
stop_flag	ds.l	1
filebuffer	ds.l	1
filelenght	ds.l	1
old_filebuffer	ds.l	1

memoryblock	ds.l	1

song_address	ds.l	1
t_songs:	ds.b	6
t_method:	ds.b	40					;30 char buffer for constructin method info

snd_strgNAME	ds.b	256+1	;Title
snd_strgAUTH	ds.b	256+1	;Artist
snd_strgDATE	ds.b	256+1	;Date
snd_strgRMRK	ds.b	256+1	;Comment
snd_strgINFO	ds.b	256+1	;Info
snd_strgChan	ds.b	1+1	;Channels
		even


;====================================================
		section text