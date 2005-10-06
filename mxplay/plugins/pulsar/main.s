; High-level manager for XM player

		OPT	p=68030				; 68030 code allowed
		OPT	D-
		COMMENT HEAD=%111			; fastload on/loadalt on/mallocalt on
		OUTPUT	.MXP

		include	"mxp_inc.s"

; ------------------------------------------------------
		SECTION	TEXT
; ------------------------------------------------------

; Plugin header

xm_header:
		dc.l	"MXP1"
		ds.l	1
		bra.w	xm_register_module
		bra.w	xm_get_playtime
		bra.w	xm_init
		bra.w	xm_set
		bra.w	xm_unset
		bra.w	xm_deinit
		;bra.w	xm_fwd
		dc.l	0
		;bra.w	xm_rwd
		dc.l	0
		;bra.w	xm_pause
		dc.l	0
		dc.l	xm_info
		dc.l	xm_extensions
		dc.l	xm_settings

; Get play time

xm_get_playtime:
		move.l	xm_custom_playtime,d0
		bne.b	.ok
		move.l	#2*60,d0
.ok:		move.l	d0,xm_header+MXP_PLUGIN_PARAMETER	; for calling from settings structure
		rts

xm_set_playtime:
		move.l	xm_header+MXP_PLUGIN_PARAMETER,xm_custom_playtime
		rts

; ------------------------------------------------------
		SECTION	DATA
; ------------------------------------------------------

xm_info:	dc.l	xm_info_plugin_author
		dc.l	xm_info_plugin_version
		dc.l	xm_info_replay_name
		dc.l	xm_info_replay_author
		dc.l	xm_info_replay_version
		dc.l	MXP_FLG_USE_DSP|MXP_FLG_USE_DMA|MXP_FLG_USE_020
		
xm_settings:
		dc.l	xm_settings_module_name
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	xm_get_module_name
		
		dc.l	xm_settings_tracker_name
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	xm_get_tracker
		
		dc.l	xm_settings_module_version
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	xm_get_module_version
		
		dc.l	xm_settings_module_channels
		dc.l	MXP_PAR_TYPE_INT|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	xm_get_module_channels
		
		dc.l	xm_settings_playtime
		dc.l	MXP_PAR_TYPE_INT|MXP_FLG_PLG_PARAM
		dc.l	xm_set_playtime
		dc.l	xm_get_playtime
		
		dc.l	0
		
xm_extensions:
		dc.l	xm_extensions_mod
		dc.l	xm_extensions_mod_name
		
		dc.l	0
		
xm_settings_module_name:
		dc.b	"Songname",0
xm_settings_tracker_name:
		dc.b	"Created in",0
xm_settings_module_channels:
		dc.b	"Channels",0
xm_settings_module_version:
		dc.b	"Module version",0
xm_settings_playtime:
		dc.b	"Playtime",0
		
xm_info_plugin_author:
		dc.b	"MiKRO / Mystic Bytes",0
xm_info_plugin_version:
		dc.b	"0.1",0
xm_info_replay_name:
		dc.b	"Pulsar/XM",0
xm_info_replay_author:
		dc.b	"Sqward / Mystic Bytes",0
xm_info_replay_version:
		dc.b	"0.20",0
		
xm_extensions_mod:
		dc.b	"XM",0
xm_extensions_mod_name:
		dc.b	"Extended Module",0

		even

; ------------------------------------------------------
		SECTION	BSS
; ------------------------------------------------------

xm_custom_playtime:
		ds.l	1
		
; ------------------------------------------------------
		SECTION	TEXT
; ------------------------------------------------------

		include	"xm.s"