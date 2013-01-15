; High-level manager for DSPMOD player

		OPT	p=68030				; 68030 code allowed
		OPT	D-
		COMMENT HEAD=%101			; fastload on/loadalt off/mallocalt on
		OUTPUT	.MXP

		include	"..\mxplay.inc"

; ------------------------------------------------------
		SECTION	TEXT
; ------------------------------------------------------

; Plugin header

dspmod_header:	dc.l	"MXP2"
		ds.l	1
		dc.l	dspmod_register_module
		dc.l	dspmod_get_playtime
		dc.l	0			; dspmod_get_songs
		dc.l	dspmod_init
		dc.l	dspmod_set
		dc.l	0			; dspmod_feed
		dc.l	dspmod_unset
		dc.l	dspmod_deinit
		dc.l	0			; dspmod_pause
		dc.l	0			; dspmod_mute
		dc.l	dspmod_info
		dc.l	dspmod_extensions
		dc.l	dspmod_settings

; Register

dspmod_register_module:
		movea.l	dspmod_header+MXP_PLUGIN_PARAMETER,a0
		move.l	(a0)+,dspmod_buffer
		move.l	(a0),dspmod_length

		bsr.w	dspmod_get_module_type		; d0 will contain return code
		rts

; Get play time

dspmod_get_playtime:
		;bsr.w	dspmod_calc_playtime		; result in d0.l
		move.l	dspmod_custom_playtime,dspmod_header+MXP_PLUGIN_PARAMETER	; for calling from settings structure
		moveq	#MXP_OK,d0
		rts

dspmod_set_playtime:
		move.l	dspmod_header+MXP_PLUGIN_PARAMETER,dspmod_custom_playtime
		rts

; Init

dspmod_init:	clr.w	-(sp)				; mxalloc() - reserve stram only
		move.l	#8000,-(sp)			; for dma playbuffer
		move.w	#$44,-(sp)			;
		trap	#1				;
		addq.l	#8,sp				;

		tst.l	d0				; check if there is stram enough
		beq.b	.exit				; nope

		move.l	d0,dma_pointer			; store address of stram buffer

		moveq	#MXP_OK,d0
		rts

.exit:		moveq	#MXP_ERROR,d0
		rts

; Setup

dspmod_set:	bsr.w	dspmod_begin

		bsr.w	dspmod_get_version		; HACK

		moveq	#MXP_OK,d0
		rts

; Unsetup

dspmod_unset:	bsr.w	dspmod_end

		moveq	#MXP_OK,d0
		rts

; Deinit

dspmod_deinit:	pea	dma_pointer			; Mfree()
		move.w	#$49,-(sp)			;
		trap	#1				;
		addq.l	#6,sp				;

		moveq	#MXP_OK,d0
		rts

; ------------------------------------------------------
		SECTION	DATA
; ------------------------------------------------------

dspmod_info:	dc.l	dspmod_info_plugin_author
		dc.l	dspmod_info_plugin_version
		dc.l	dspmod_info_replay_name
		dc.l	dspmod_info_replay_author
		dc.l	dspmod_info_replay_version
		dc.l	MXP_FLG_USE_DSP|MXP_FLG_USE_DMA|MXP_FLG_USE_020

dspmod_settings:
		dc.l	dspmod_settings_module_name
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	dspmod_get_module_name

		dc.l	dspmod_settings_module_type
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	dspmod_get_module_type

		dc.l	dspmod_settings_module_channels
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	dspmod_get_module_channels

		dc.l	dspmod_settings_interpolation
		dc.l	MXP_PAR_TYPE_BOOL|MXP_FLG_PLG_PARAM
		dc.l	dspmod_set_interpolation
		dc.l	dspmod_get_interpolation

		dc.l	dspmod_settings_surround
		dc.l	MXP_PAR_TYPE_BOOL|MXP_FLG_PLG_PARAM
		dc.l	dspmod_set_surround
		dc.l	dspmod_get_surround

		dc.l	dspmod_settings_playtime
		dc.l	MXP_PAR_TYPE_INT|MXP_FLG_PLG_PARAM
		dc.l	dspmod_set_playtime
		dc.l	dspmod_get_playtime

		dc.l	0

dspmod_extensions:
		dc.l	dspmod_extensions_mod
		dc.l	dspmod_extensions_mod_name

		dc.l	0

dspmod_settings_module_name:
		dc.b	"Songname",0
dspmod_settings_module_channels:
		dc.b	"Channels",0
dspmod_settings_module_type:
		dc.b	"Module type",0

dspmod_info_plugin_author:
		dc.b	"MiKRO / Mystic Bytes",0
dspmod_info_plugin_version:
		dc.b	"0.9",0
dspmod_info_replay_name:
		dc.b	"DSPMOD",0
dspmod_info_replay_author:
		dc.b	"bITmASTER of TCE",0
dspmod_info_replay_version:
		dc.b	"Version 3.1 Dec  4 1994",0

dspmod_settings_interpolation:
		dc.b	"Interpolation",0
dspmod_settings_surround:
		dc.b	"Surround sound",0
dspmod_settings_playtime:
		dc.b	"Playtime",0

dspmod_extensions_mod:
		dc.b	"MOD",0
dspmod_extensions_mod_name:
		dc.b	"4/6/8 channel MODs",0

		even
dspmod_custom_playtime:
		dc.l	2*60

; ------------------------------------------------------
		SECTION	TEXT
; ------------------------------------------------------

		include	"dspmod.s"
