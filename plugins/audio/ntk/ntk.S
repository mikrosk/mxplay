; ntk plugin
; MiKRO / Mystic Bytes
; (c) 2012-2013
		opt	ow-

		include	'../mxplay.inc'

ntk_header:	dc.l	"MXP2"
		ds.l	1
		dc.l	ntk_register_module
		dc.l	0			; ntk_get_playtime
		dc.l	0			; ntk_get_songs
		dc.l	ntk_init
		dc.l	ntk_set
		dc.l	0			; ntk_feed
		dc.l	ntk_unset
		dc.l	ntk_deinit
		dc.l	0			; ntk_pause
		dc.l	0			; ntk_mute
		dc.l	ntk_info
		dc.l	ntk_extensions
		dc.l	0			; ntk_settings

ntk_register_module:
		move.l	ntk_header+MXP_PLUGIN_PARAMETER,a0
		movea.l	(a0),a0
		move.l	a0,filebuffer

		cmpi.l	#'NTK4',($b0,a0)
		beq.b	.ok

		moveq	#MXP_ERROR,d0
		rts

.ok:		moveq	#MXP_OK,d0
		rts

ntk_init:	moveq	#MXP_OK,d0
		rts

ntk_deinit:	moveq	#MXP_OK,d0
		rts

ntk_set:	bsr	playmodule
		moveq	#MXP_OK,d0
		rts

ntk_unset:	bsr	stopmodule
		moveq	#MXP_OK,d0
		rts

		include	'dnt/player.s'

; ----------------------------------------------
		section data
; ----------------------------------------------

ntk_info:	dc.l	ntk_info_plugin_author
		dc.l	ntk_info_plugin_version
		dc.l	ntk_info_replay_name
		dc.l	ntk_info_replay_author
		dc.l	ntk_info_replay_version
		dc.l	MXP_FLG_USE_DSP|MXP_FLG_USE_DMA|MXP_FLG_ONLY_030

ntk_extensions:
		dc.l	ntk_extensions_ntk
		dc.l	ntk_extensions_ntk_name
		dc.l	0

ntk_info_plugin_author:
		dc.b	"MiKRO / Mystic Bytes",0
ntk_info_plugin_version:
		dc.b	"1.0",0
ntk_info_replay_name:
		dc.b	"Nullos Tracker",0
ntk_info_replay_author:
		dc.b	"Nullos / DNT-Crew",0
ntk_info_replay_version:
		dc.b	"2.7",0

ntk_extensions_ntk:
		dc.b	"NTK",0
ntk_extensions_ntk_name:
		dc.b	"Nullos Tracker Module",0

		even

; ----------------------------------------------
		section bss
; ----------------------------------------------

filebuffer:	ds.l	1
