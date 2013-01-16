; High-level manager for AMIGAMOD player
;
; v0.91; 31.12.2005
;
; MiKRO / Mystic Bytes; mikro@hysteria.sk

		OPT	D-
		OPT	P=68030				; 68030 code allowed
		COMMENT	HEAD=%100111			; Super,MallocInTT-RAM,LoadInTT-RAM,Fastload
		OUTPUT	.MXP

		INCLUDE	"..\mxplay.inc"

; ------------------------------------------------------
		SECTION	TEXT
; ------------------------------------------------------

; Plugin header

amigamod_header:dc.l	"MXP2"
		ds.l	1
		dc.l	amigamod_register_module
		dc.l	0			; amigamod_get_playtime
		dc.l	0			; amigamod_get_songs
		dc.l	amigamod_init
		dc.l	amigamod_set
		dc.l	0			; amigamod_feed
		dc.l	amigamod_unset
		dc.l	amigamod_deinit
		dc.l	amigamod_pause
		dc.l	0			; amigamod_mute
		dc.l	amigamod_info
		dc.l	amigamod_extensions
		dc.l	amigamod_settings

; Register

amigamod_register_module:
		movea.l	amigamod_header+MXP_PLUGIN_PARAMETER,a0
		move.l	(a0)+,amigamod_buffer
		move.l	(a0),amigamod_length

		movea.l	amigamod_buffer,a0
		bsr	MGTK_Init_Module_Samples

		tst.w	d0
		bmi.b	.error

		lea	amigamod_delimiter,a0		; fill delimiter field with '-'
		move.w	#255-1,d7
.loop0:		move.b	#'-',(a0)+
		dbra	d7,.loop0

		movea.l	amigamod_buffer,a0
		lea	(20,a0),a0			; sample names position
		lea	amigamod_sample1,a1		; start of sample names
		moveq	#31-1,d7			; 31 samples

.loop1:		moveq	#22-1,d6			; 22 chars per sample name

.loop2:		move.b	(a0)+,d0
		cmpi.b	#' ',d0
		bge.b	.ok
		move.b	#' ',d0				; control chars as spaces

.ok:		move.b	d0,(a1)+
		dbra	d6,.loop2

		lea	(30-22,a0),a0			; 22 chars already done
		clr.b	(a1)+				; skip/set NULL terminator

		dbra	d7,.loop1

		moveq	#MXP_OK,d0
		rts

.error:		moveq	#MXP_ERROR,d0
		rts

; Init

amigamod_init:	moveq	#MXP_OK,d0
		rts

; Setup

amigamod_set:
		bsr	MGTK_Init_DSP

		tst.w	d0
		bmi.b	.error

		bsr	MGTK_Save_Sound
		bsr	MGTK_Init_Sound

		moveq	#1,d0				; 49.17 KHz
		bsr	MGTK_Set_Replay_Frequency

		st	MGTK_Restart_Loop		; Loop On
		bsr	MGTK_Play_Music

		moveq	#MXP_OK,d0
		rts

.error:		moveq	#MXP_ERROR,d0
		rts

; Unsetup

amigamod_unset:
		bsr	MGTK_Stop_Music
		bsr	MGTK_Restore_Sound

		; free used memory for samples
		move.l	MGTK_WorkSpace_Adr,-(sp)	; Mfree()
		move.w	#$49,-(sp)			;
		trap	#1				;
		addq.l	#6,sp				;

		moveq	#MXP_OK,d0
		rts

; Deinit

amigamod_deinit:
		moveq	#MXP_OK,d0
		rts

; Pause

amigamod_pause:
		bsr	MGTK_Pause_Music
		moveq	#MXP_OK,d0
		rts

; ------------------------------------------------------

amigamod_get_module_channels:
		clr.l	d0
		move.w	MGTK_Nb_Voices,d0
		move.l	d0,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_type:
		movea.l	amigamod_buffer,a0
		move.l	1080(a0),d0
		lea	amigamod_formats,a0
.loop:		movea.l	(a0)+,a1			; 'format' address
		tst.l	a1				; NULL?
		beq.b	.not_found
		cmp.l	(a1),d0
		beq.b	.found
		addq.l	#4,a0				; skip 'name' address
		bra.b	.loop

.found:		move.l	(a0),amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

.not_found:	moveq	#MXP_ERROR,d0
		rts

amigamod_get_module_name:
		movea.l	amigamod_buffer,a0
		lea	amigamod_module_name,a1
		moveq	#20-1,d0
.loop:		move.b	(a0)+,(a1)+
		dbra	d0,.loop
		clr.b	(a1)				; terminate it (for sure)

		move.l	#amigamod_module_name,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_delimiter:
		move.l	#amigamod_delimiter,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample1:
		move.l	#amigamod_sample1,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample2:
		move.l	#amigamod_sample2,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample3:
		move.l	#amigamod_sample3,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample4:
		move.l	#amigamod_sample4,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample5:
		move.l	#amigamod_sample5,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample6:
		move.l	#amigamod_sample6,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample7:
		move.l	#amigamod_sample7,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample8:
		move.l	#amigamod_sample8,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample9:
		move.l	#amigamod_sample9,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample10:
		move.l	#amigamod_sample10,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample11:
		move.l	#amigamod_sample11,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample12:
		move.l	#amigamod_sample12,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample13:
		move.l	#amigamod_sample13,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample14:
		move.l	#amigamod_sample14,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample15:
		move.l	#amigamod_sample15,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample16:
		move.l	#amigamod_sample16,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample17:
		move.l	#amigamod_sample17,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample18:
		move.l	#amigamod_sample18,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample19:
		move.l	#amigamod_sample19,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample20:
		move.l	#amigamod_sample20,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample21:
		move.l	#amigamod_sample21,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample22:
		move.l	#amigamod_sample22,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample23:
		move.l	#amigamod_sample23,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample24:
		move.l	#amigamod_sample24,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample25:
		move.l	#amigamod_sample25,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample26:
		move.l	#amigamod_sample26,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample27:
		move.l	#amigamod_sample27,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample28:
		move.l	#amigamod_sample28,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample29:
		move.l	#amigamod_sample29,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample30:
		move.l	#amigamod_sample30,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

amigamod_get_module_sample31:
		move.l	#amigamod_sample31,amigamod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

; ------------------------------------------------------
		SECTION	DATA
; ------------------------------------------------------

amigamod_info:
		dc.l	amigamod_info_plugin_author
		dc.l	amigamod_info_plugin_version
		dc.l	amigamod_info_replay_name
		dc.l	amigamod_info_replay_author
		dc.l	amigamod_info_replay_version
		dc.l	MXP_FLG_USE_DSP|MXP_FLG_USE_DMA|MXP_FLG_USE_020

amigamod_settings:
		dc.l	amigamod_settings_module_name
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_name

		dc.l	amigamod_settings_module_type
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_type

		dc.l	amigamod_settings_module_channels
		dc.l	MXP_PAR_TYPE_INT|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_channels

		dc.l	amigamod_delimiter
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_delimiter

		dc.l	0

		; module sample names - place it as last ones

		dc.l	amigamod_settings_module_sample1
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample1

		dc.l	amigamod_settings_module_sample2
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample2

		dc.l	amigamod_settings_module_sample3
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample3

		dc.l	amigamod_settings_module_sample4
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample4

		dc.l	amigamod_settings_module_sample5
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample5

		dc.l	amigamod_settings_module_sample6
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample6

		dc.l	amigamod_settings_module_sample7
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample7

		dc.l	amigamod_settings_module_sample8
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample8

		dc.l	amigamod_settings_module_sample9
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample9

		dc.l	amigamod_settings_module_sample10
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample10

		dc.l	amigamod_settings_module_sample11
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample11

		dc.l	amigamod_settings_module_sample12
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample12

		dc.l	amigamod_settings_module_sample13
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample13

		dc.l	amigamod_settings_module_sample14
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample14

		dc.l	amigamod_settings_module_sample15
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample15

		dc.l	amigamod_settings_module_sample16
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample16

		dc.l	amigamod_settings_module_sample17
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample17

		dc.l	amigamod_settings_module_sample18
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample18

		dc.l	amigamod_settings_module_sample19
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample19

		dc.l	amigamod_settings_module_sample20
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample20

		dc.l	amigamod_settings_module_sample21
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample21

		dc.l	amigamod_settings_module_sample22
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample22

		dc.l	amigamod_settings_module_sample23
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample23

		dc.l	amigamod_settings_module_sample24
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample24

		dc.l	amigamod_settings_module_sample25
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample25

		dc.l	amigamod_settings_module_sample26
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample26

		dc.l	amigamod_settings_module_sample27
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample27

		dc.l	amigamod_settings_module_sample28
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample28

		dc.l	amigamod_settings_module_sample29
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample29

		dc.l	amigamod_settings_module_sample30
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample30

		dc.l	amigamod_settings_module_sample31
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	amigamod_get_module_sample31

		dc.l	0

amigamod_extensions:
		dc.l	amigamod_extensions_mod
		dc.l	amigamod_extensions_mod_name

		dc.l	0

amigamod_settings_module_name:
		dc.b	"Songname",0
amigamod_settings_module_channels:
		dc.b	"Channels",0
amigamod_settings_module_type:
		dc.b	"Module type",0
amigamod_settings_module_sample1:
		dc.b	"Sample #1",0
amigamod_settings_module_sample2:
		dc.b	"Sample #2",0
amigamod_settings_module_sample3:
		dc.b	"Sample #3",0
amigamod_settings_module_sample4:
		dc.b	"Sample #4",0
amigamod_settings_module_sample5:
		dc.b	"Sample #5",0
amigamod_settings_module_sample6:
		dc.b	"Sample #6",0
amigamod_settings_module_sample7:
		dc.b	"Sample #7",0
amigamod_settings_module_sample8:
		dc.b	"Sample #8",0
amigamod_settings_module_sample9:
		dc.b	"Sample #9",0
amigamod_settings_module_sample10:
		dc.b	"Sample #10",0
amigamod_settings_module_sample11:
		dc.b	"Sample #11",0
amigamod_settings_module_sample12:
		dc.b	"Sample #12",0
amigamod_settings_module_sample13:
		dc.b	"Sample #13",0
amigamod_settings_module_sample14:
		dc.b	"Sample #14",0
amigamod_settings_module_sample15:
		dc.b	"Sample #15",0
amigamod_settings_module_sample16:
		dc.b	"Sample #16",0
amigamod_settings_module_sample17:
		dc.b	"Sample #17",0
amigamod_settings_module_sample18:
		dc.b	"Sample #18",0
amigamod_settings_module_sample19:
		dc.b	"Sample #19",0
amigamod_settings_module_sample20:
		dc.b	"Sample #20",0
amigamod_settings_module_sample21:
		dc.b	"Sample #21",0
amigamod_settings_module_sample22:
		dc.b	"Sample #22",0
amigamod_settings_module_sample23:
		dc.b	"Sample #23",0
amigamod_settings_module_sample24:
		dc.b	"Sample #24",0
amigamod_settings_module_sample25:
		dc.b	"Sample #25",0
amigamod_settings_module_sample26:
		dc.b	"Sample #26",0
amigamod_settings_module_sample27:
		dc.b	"Sample #27",0
amigamod_settings_module_sample28:
		dc.b	"Sample #28",0
amigamod_settings_module_sample29:
		dc.b	"Sample #29",0
amigamod_settings_module_sample30:
		dc.b	"Sample #30",0
amigamod_settings_module_sample31:
		dc.b	"Sample #31",0

amigamod_info_plugin_author:
		dc.b	"MiKRO / Mystic Bytes",0
amigamod_info_plugin_version:
		dc.b	"0.9",0
amigamod_info_replay_name:
		dc.b	"AMIGAMOD",0
amigamod_info_replay_author:
		dc.b	"Simplet / Fatal Design",0
amigamod_info_replay_version:
		dc.b	"09/16/1995",0

amigamod_extensions_mod:
		dc.b	"MOD",0
amigamod_extensions_mod_name:
		dc.b	"4/6/8 channel MODs",0

		even

amigamod_formats:
		dc.l	amigamod_formats_mk1
		dc.l	amigamod_formats_mk1_name

		dc.l	amigamod_formats_mk2
		dc.l	amigamod_formats_mk2_name

		dc.l	amigamod_formats_mk3
		dc.l	amigamod_formats_mk3_name

		dc.l	amigamod_formats_flt4
		dc.l	amigamod_formats_flt4_name

		dc.l	amigamod_formats_rasp
		dc.l	amigamod_formats_rasp_name

		dc.l	amigamod_formats_fa04
		dc.l	amigamod_formats_fa04_name

		dc.l	amigamod_formats_6chn
		dc.l	amigamod_formats_6chn_name

		dc.l	amigamod_formats_cd61
		dc.l	amigamod_formats_cd61_name

		dc.l	amigamod_formats_06ch
		dc.l	amigamod_formats_06ch_name

		dc.l	amigamod_formats_fa06
		dc.l	amigamod_formats_fa06_name

		dc.l	amigamod_formats_8chn
		dc.l	amigamod_formats_8chn_name

		dc.l	amigamod_formats_cd81
		dc.l	amigamod_formats_cd81_name

		dc.l	amigamod_formats_flt8
		dc.l	amigamod_formats_flt8_name

		dc.l	amigamod_formats_08ch
		dc.l	amigamod_formats_08ch_name

		dc.l	amigamod_formats_octa
		dc.l	amigamod_formats_octa_name

		dc.l	amigamod_formats_fa08
		dc.l	amigamod_formats_fa08_name

		dc.l	0

amigamod_formats_mk1:
		dc.b	"M.K.",0
amigamod_formats_mk1_name:
		dc.b	"MOD (NoiseTracker or compatible)",0
amigamod_formats_mk2:
		dc.b	"M!K!",0
amigamod_formats_mk2_name:
		dc.b	"MOD (NoiseTracker or compatible)",0
amigamod_formats_mk3:
		dc.b	"M&K&",0
amigamod_formats_mk3_name:
		dc.b	"MOD (NoiseTracker or compatible)",0
amigamod_formats_flt4:
		dc.b	"FLT4",0
amigamod_formats_flt4_name:
		dc.b	"MOD (StarTrekker)",0
amigamod_formats_rasp:
		dc.b	"RASP",0
amigamod_formats_rasp_name:
		dc.b	"MOD (StarTrekker)",0
amigamod_formats_fa04:
		dc.b	"FA04",0
amigamod_formats_fa04_name:
		dc.b	"MOD (Digital Tracker [old version])",0
amigamod_formats_6chn:
		dc.b	"6CHN",0
amigamod_formats_6chn_name:
		dc.b	"MOD (FastTracker)",0
amigamod_formats_cd61:
		dc.b	"CD61",0
amigamod_formats_cd61_name:
		dc.b	"MOD (Octalyser STe or compatible)",0
amigamod_formats_06ch:
		dc.b	"06CH",0
amigamod_formats_06ch_name:
		dc.b	"MOD (FastTracker or compatible)",0
amigamod_formats_fa06:
		dc.b	"FA06",0
amigamod_formats_fa06_name:
		dc.b	"MOD (Digital Tracker [old version])",0
amigamod_formats_8chn:
		dc.b	"8CHN",0
amigamod_formats_8chn_name:
		dc.b	"MOD (Fast Tracker or compatible)",0
amigamod_formats_cd81:
		dc.b	"CD81",0
amigamod_formats_cd81_name:
		dc.b	"MOD (Octalyser STe or compatible)",0
amigamod_formats_flt8:
		dc.b	"FLT8",0
amigamod_formats_flt8_name:
		dc.b	"MOD (StarTrekker)",0
amigamod_formats_08ch:
		dc.b	"08CH",0
amigamod_formats_08ch_name:
		dc.b	"MOD (FastTracker or compatible)",0
amigamod_formats_octa:
		dc.b	"OCTA",0
amigamod_formats_octa_name:
		dc.b	"MOD (Octalyser STe [old version])",0
amigamod_formats_fa08:
		dc.b	"FA08",0
amigamod_formats_fa08_name:
		dc.b	"MOD (Digital Tracker [old version])",0
		even

; ------------------------------------------------------
		SECTION	BSS
; ------------------------------------------------------

amigamod_buffer:
		ds.l	1
amigamod_length:
		ds.l	1
amigamod_module_name:
		ds.b	20+1

; space for 31 sample names (22 chars each + terminator)

amigamod_sample1:
		ds.b	22+1
amigamod_sample2:
		ds.b	22+1
amigamod_sample3:
		ds.b	22+1
amigamod_sample4:
		ds.b	22+1
amigamod_sample5:
		ds.b	22+1
amigamod_sample6:
		ds.b	22+1
amigamod_sample7:
		ds.b	22+1
amigamod_sample8:
		ds.b	22+1
amigamod_sample9:
		ds.b	22+1
amigamod_sample10:
		ds.b	22+1
amigamod_sample11:
		ds.b	22+1
amigamod_sample12:
		ds.b	22+1
amigamod_sample13:
		ds.b	22+1
amigamod_sample14:
		ds.b	22+1
amigamod_sample15:
		ds.b	22+1
amigamod_sample16:
		ds.b	22+1
amigamod_sample17:
		ds.b	22+1
amigamod_sample18:
		ds.b	22+1
amigamod_sample19:
		ds.b	22+1
amigamod_sample20:
		ds.b	22+1
amigamod_sample21:
		ds.b	22+1
amigamod_sample22:
		ds.b	22+1
amigamod_sample23:
		ds.b	22+1
amigamod_sample24:
		ds.b	22+1
amigamod_sample25:
		ds.b	22+1
amigamod_sample26:
		ds.b	22+1
amigamod_sample27:
		ds.b	22+1
amigamod_sample28:
		ds.b	22+1
amigamod_sample29:
		ds.b	22+1
amigamod_sample30:
		ds.b	22+1
amigamod_sample31:
		ds.b	22+1

amigamod_delimiter:
		ds.b	255+1

		even

; ------------------------------------------------------
		SECTION	TEXT
; ------------------------------------------------------

		include	'amigadsp.s'
