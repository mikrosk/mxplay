; ace plugin
; MiKRO / Mystic Bytes
; (c) 2012-2013

		include	'../mxplay.inc'
		include	'replace.def'

; ----------------------------------------------
		section text
; ----------------------------------------------

ace_header:	dc.l	"MXP2"
		ds.l	1
		dc.l	ace_register_module
		dc.l	0			; ace_get_playtime
		dc.l	0			; ace_get_songs
		dc.l	0			; ace_init
		dc.l	ace_set
		dc.l	0			; ace_feed
		dc.l	ace_unset
		dc.l	0			; ace_unregister
		dc.l	ace_pause
		dc.l	0			; ace_mute
		dc.l	ace_info
		dc.l	ace_extensions
		dc.l	ace_settings


ace_register_module:
		movea.l	ace_header+MXP_PLUGIN_PARAMETER,a0
		move.l	(a0),filebuffer
		movea.l	(a0),a0
		cmpi.l	#'AM01',(a0)
		bne.b	.error

		moveq	#MXP_OK,d0
		rts

.error:		moveq	#MXP_ERROR,d0
		rts

ace_set:	;suba.l	a0,a0			; FPU version
		lea	filter_table,a0
		move.l	#REPLACE_INITIALIZE,d0
		jsr	replace
		cmp.w	#REPLACE_OK,d0
		bne.b	.error

		movea.l	filebuffer,a0
		move.l	#REPLACE_INITIALIZE_MODULE,d0
		jsr	replace
		cmp.w	#REPLACE_OK,d0
		bne.b	.error

		;move.l	#REPLACE_DELAY_ENABLE,d0
		;jsr	replace
		;cmp.w	#REPLACE_OK,d0
		;bne.b	.error

		move.l	#REPLACE_START_INTERRUPT,d0
		jsr	replace
		cmp.w	#REPLACE_OK,d0
		bne.b	.error

		;move.l	#127,d1
		;move.l	#REPLACE_SET_VOLUME,d0
		;jsr	replace
		;cmp.w	#REPLACE_OK,d0
		;bne.b	.error

		move.l	#REPLACE_PLAY_SONG,d0
		jsr	replace
		cmp.w	#REPLACE_OK,d0
		bne.b	.error

		moveq	#MXP_OK,d0
		rts

.error:		moveq	#MXP_ERROR,d0
		rts

ace_unset:	move.l	#REPLACE_STOP_SONG,d0
		jsr	replace
		cmp.w	#REPLACE_OK,d0
		bne.b	.error

		move.l	#REPLACE_REMOVE_MODULE,d0
		jsr	replace
		cmp.w	#REPLACE_OK,d0
		bne.b	.error

		move.l	#REPLACE_EXIT,d0
		jsr	replace

		moveq	#MXP_OK,d0
		rts

.error:		moveq	#MXP_ERROR,d0
		rts

ace_pause:	move.l	ace_header+MXP_PLUGIN_PARAMETER,d0
		bne.b	.pause

		move.l	#REPLACE_START_INTERRUPT,d0
		bra.b	.set_interrupt

.pause:		move.l	#REPLACE_STOP_INTERRUPT,d0

.set_interrupt:	jsr	replace
		cmp.w	#REPLACE_OK,d0
		bne.b	.error

		moveq	#MXP_OK,d0
		rts

.error:		moveq	#MXP_ERROR,d0
		rts

; ----------------------------------------------

ace_settings_title_get:
		move.l	#REPLACE_GET_MODULE_TITLE,d0
		jsr	replace
		cmp.w	#REPLACE_OK,d0
		bne.b	.error

		lea	title,a1
		moveq	#20-1,d0
.loop:		move.b	(a0)+,(a1)+
		dbra	d0,.loop
		move.l	#title,ace_header+MXP_PLUGIN_PARAMETER

		moveq	#MXP_OK,d0
		rts

.error:		moveq	#MXP_ERROR,d0
		rts

ace_settings_composer_get:
		move.l	#REPLACE_GET_MODULE_COMPOSER,d0
		jsr	replace
		cmp.w	#REPLACE_OK,d0
		bne.b	.error

		lea	composer,a1
		moveq	#20-1,d0
.loop:		move.b	(a0)+,(a1)+
		dbra	d0,.loop
		move.l	#composer,ace_header+MXP_PLUGIN_PARAMETER

		moveq	#MXP_OK,d0
		rts

.error:		moveq	#MXP_ERROR,d0
		rts

ace_settings_channels_get:
		move.l	#REPLACE_GET_NUMBER_OF_VOICES,d0
		jsr	replace
		move.l	d0,ace_header+MXP_PLUGIN_PARAMETER

		moveq	#MXP_OK,d0
		rts

ace_settings_delay_set:
		move.l	ace_header+MXP_PLUGIN_PARAMETER,d0
		move.l	d0,delay
		beq.b	.disable

		move.l	#REPLACE_DELAY_ENABLE,d0
		bra.b	.set_delay

.disable:	move.l	#REPLACE_DELAY_DISABLE,d0

.set_delay:	jsr	replace
		cmp.w	#REPLACE_OK,d0
		bne.b	.error

		moveq	#MXP_OK,d0
		rts

.error:		moveq	#MXP_ERROR,d0
		rts

ace_settings_delay_get:
		move.l	delay,ace_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

; ----------------------------------------------
		section data
; ----------------------------------------------

		even

.r:		incbin	'replace.bin'
replace:	equ	.r+28

ace_info:	dc.l	ace_info_plugin_author
		dc.l	ace_info_plugin_version
		dc.l	ace_info_replay_name
		dc.l	ace_info_replay_author
		dc.l	ace_info_replay_version
		dc.l	MXP_FLG_USE_DSP|MXP_FLG_USE_DMA

ace_extensions:	dc.l	ace_extensions_am
		dc.l	ace_extensions_am_name
		dc.l	0

ace_settings:	dc.l	ace_settings_title
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	ace_settings_title_get

		dc.l	ace_settings_composer
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	ace_settings_composer_get

		dc.l	ace_settings_channels
		dc.l	MXP_PAR_TYPE_INT|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	ace_settings_channels_get

		dc.l	ace_settings_delay
		dc.l	MXP_PAR_TYPE_BOOL|MXP_FLG_PLG_PARAM
		dc.l	ace_settings_delay_set
		dc.l	ace_settings_delay_get

		dc.l	0

ace_info_plugin_author:
		dc.b	"MiKRO / Mystic Bytes",0
ace_info_plugin_version:
		dc.b	"1.0",0
ace_info_replay_name:
		dc.b	"ACE Tracker Replay",0
ace_info_replay_author:
		dc.b	"Thomas / New Beat",0
ace_info_replay_version:
		dc.b	"0.37",0

ace_extensions_am:
		dc.b	"AM",0
ace_extensions_am_name:
		dc.b	"ACE Tracker (AM01)",0

ace_settings_title:
		dc.b	"Title",0
ace_settings_composer:
		dc.b	"Composer",0
ace_settings_channels:
		dc.b	"Channels",0

ace_settings_delay:
		dc.b	"Delay",0

		even

delay:		dc.l	0

filter_table:	incbin	'f32.dat'

; ----------------------------------------------
		section bss
; ----------------------------------------------

		even

filebuffer:	ds.l	1
title:		ds.b	21
composer:	ds.b	21

		even
