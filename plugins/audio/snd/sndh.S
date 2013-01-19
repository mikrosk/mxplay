; sndh plugin
; MiKRO / Mystic Bytes
; (c) 2012-2013

		include	'../mxplay.inc'

sndh_header:	dc.l	"MXP2"
		ds.l	1
		dc.l	sndh_register_module
		dc.l	0			; sndh_get_playtime
		dc.l	0			; sndh_get_songs
		dc.l	sndh_init
		dc.l	sndh_set
		dc.l	0			; sndh_feed
		dc.l	sndh_unset
		dc.l	sndh_deinit
		dc.l	0			; sndh_pause
		dc.l	0			; sndh_mute
		dc.l	sndh_info
		dc.l	sndh_extensions
		dc.l	sndh_settings

sndh_register_module:
		move.l	sndh_header+MXP_PLUGIN_PARAMETER,a0
		move.l	(a0),song_address

		clr.l	d0
		movea.l	song_address,a0
		movem.l	(a0),d3-d5

		cmp.l	#'ICE!',d3
		bne.b	.not_packed

		; D0 = size of file
		; D4 = Size of file - from ice header, we don't use this.
		; D5 = Size of unpacked file

		move.l	d5,-(sp)
		move.w	#$48,-(sp)		; Malloc()
		trap	#1
		addq.l	#6,sp
		tst.l	d0
		beq.b	.error

		movea.l	song_address,a0		; src
		movea.l	d0,a1			; dst
		move.l	d0,song_address
		bsr	ice_decrunch

		move.l	song_address,d0
		movea.l	d0,a0
.not_packed:	cmpi.l	#'SNDH',(12,a0)
		bne.b	.error
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

sndh_init:	moveq	#MXP_OK,d0
		rts

sndh_deinit:	moveq	#MXP_OK,d0
		rts

sndh_set:	bsr	start_play
		moveq	#MXP_OK,d0
		rts

sndh_unset:	bsr	stop_play
		moveq	#MXP_OK,d0
		rts

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
		dc.l	MXP_FLG_USER_CODE

sndh_extensions:
		dc.l	sndh_extensions_snd
		dc.l	sndh_extensions_sndh_name
		dc.l	sndh_extensions_sndh
		dc.l	sndh_extensions_sndh_name
		dc.l	0

sndh_settings:	dc.l	0

sndh_info_plugin_author:
		dc.b	"MiKRO / Mystic Bytes",0
sndh_info_plugin_version:
		dc.b	"1.0",0
sndh_info_replay_name:
		dc.b	"SNDH",0
sndh_info_replay_author:
		dc.b	"Evil / DHS & Odd Skancke",0
sndh_info_replay_version:
		dc.b	"May 14 2000",0

sndh_extensions_snd:
		dc.b	"SND",0
sndh_extensions_sndh:
		dc.b	"SNDH",0
sndh_extensions_sndh_name:
		dc.b	"SNDH",0

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
