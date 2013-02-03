; sndh plugin
; MiKRO / Mystic Bytes
; (c) 2012-2013

		include	'../mxplay.inc'

sndh_header:	dc.l	"MXP2"
		ds.l	1
		dc.l	sndh_register_module
		dc.l	0			; sndh_get_playtime
		dc.l	sndh_get_songs
		dc.l	0			; sndh_init
		dc.l	sndh_set
		dc.l	0			; sndh_feed
		dc.l	sndh_unset
		dc.l	sndh_unregister_module
		dc.l	0			; sndh_pause
		dc.l	0			; sndh_mute
		dc.l	sndh_info
		dc.l	sndh_extensions
		dc.l	sndh_settings

sndh_register_module:
		movea.l	sndh_header+MXP_PLUGIN_PARAMETER,a0
		move.l	(a0),song_address
		clr.w	packed

		clr.l	d0
		movea.l	song_address,a0
		movem.l	(a0),d3-d5

		cmp.l	#'ICE!',d3
		bne.b	.not_packed

		; D0 = size of file
		; D4 = Size of file - from ice header, we don't use this.
		; D5 = Size of unpacked file

		move.w	#3,-(sp)		; prefer TT RAM
		move.l	d5,-(sp)
		move.w	#$44,-(sp)		; Mxalloc()
		trap	#1
		addq.l	#8,sp
		tst.l	d0
		beq.b	.error

		move.w	#1,packed

		movea.l	song_address,a0		; src
		movea.l	d0,a1			; dst
		move.l	d0,song_address
		bsr	ice_decrunch

		move.l	song_address,d0
		movea.l	d0,a0
.not_packed:	cmpi.l	#'SNDH',(12,a0)
		bne.b	.error

		bsr	get_songinfo

		moveq	#MXP_OK,d0
		rts

.error:		tst.l	d0
		beq.b	.no_malloc

		move.l	d0,-(sp)
		move.w	#$49,-(sp)		; Mfree()
		trap	#1
		addq.l	#6,sp

.no_malloc:	moveq	#MXP_ERROR,d0
		rts

sndh_unregister_module:
		tst.w	packed
		beq.b	.no_malloc

		move.l	song_address,-(sp)
		move.w	#$49,-(sp)		; Mfree()
		trap	#1
		addq.l	#6,sp

.no_malloc:	moveq	#MXP_OK,d0
		rts

sndh_get_songs:	clr.l	d0
		move.w	songs,d0
		move.l	d0,sndh_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

sndh_set:	move.l	sndh_header+MXP_PLUGIN_PARAMETER,d0
		move.w	d0,current_sng
		bsr	start_play
		moveq	#MXP_OK,d0
		rts

sndh_unset:	bsr	stop_play
		moveq	#MXP_OK,d0
		rts

sndh_settings_title_get:
		move.l	title_txt,sndh_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts
sndh_settings_composer_get:
		move.l	composer_txt,sndh_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts
sndh_settings_ripped_get:
		move.l	ripper_txt,sndh_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts
sndh_settings_conversion_get:
		move.l	conversion_txt,sndh_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts
sndh_settings_method_get:
		move.l	method_txt,sndh_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

; ----------------------------------------------

MAX_HEADER:	equ     200

		include	'ice_unpa.s'
		include	'snd_head.s'
		include	'snd_play.s'

; ----------------------------------------------
		section data
; ----------------------------------------------

sndh_info:	dc.l	sndh_info_plugin_author
		dc.l	sndh_info_plugin_version
		dc.l	sndh_info_replay_name
		dc.l	sndh_info_replay_author
		dc.l	sndh_info_replay_version
		dc.l	MXP_FLG_USER_CODE|MXP_FLG_ONLY_030

sndh_extensions:
		dc.l	sndh_extensions_snd
		dc.l	sndh_extensions_sndh_name
		dc.l	sndh_extensions_sndh
		dc.l	sndh_extensions_sndh_name
		dc.l	0

sndh_settings:	dc.l	sndh_settings_title
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	sndh_settings_title_get

		dc.l	sndh_settings_composer
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	sndh_settings_composer_get

		dc.l	sndh_settings_ripped
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	sndh_settings_ripped_get

		dc.l	sndh_settings_conversion
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	sndh_settings_conversion_get

		dc.l	sndh_settings_method
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	sndh_settings_method_get

		dc.l	0

sndh_info_plugin_author:
		dc.b	"MiKRO / Mystic Bytes",0
sndh_info_plugin_version:
		dc.b	"1.0",0
sndh_info_replay_name:
		dc.b	"SNDH",0
sndh_info_replay_author:
		dc.b	"Evil/DHS & Ozk/AssemSoft",0
sndh_info_replay_version:
		dc.b	"May 14 2000",0

sndh_extensions_snd:
		dc.b	"SND",0
sndh_extensions_sndh:
		dc.b	"SNDH",0
sndh_extensions_sndh_name:
		dc.b	"SNDH",0

sndh_settings_song:
		dc.b	'Songs',0
sndh_settings_title:
		dc.b	'Title',0
sndh_settings_composer:
		dc.b	'Composer',0
sndh_settings_ripped:
		dc.b	'Ripped by',0
sndh_settings_conversion:
		dc.b	'Conversion',0
sndh_settings_method:
		dc.b	'Method',0

t_timer:	dc.b	'Timer ',0
t_no_inf:	dc.b	'?',0
t_vblon:	dc.b	'VBL, ?? Hz',0
t_vbiovr:	dc.b	', VBL override!',0
		even

; ----------------------------------------------
		section bss
; ----------------------------------------------

song_address:	ds.l	1
t_method:	ds.b	40			; 40 char buffer for constructin method info
t_songs:	ds.b	6
packed:		ds.w	1
