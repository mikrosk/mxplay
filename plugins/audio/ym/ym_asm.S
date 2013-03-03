; ym plugin glue layer
; MiKRO / Mystic Bytes
; (c) 2013

		XDEF	_ym_parameter

		XREF	_ym_register_module
		XREF	_ym_get_playtime
		XREF	_ym_init
		XREF	_ym_set
		XREF	_ym_feed
		XREF	_ym_unset
		XREF	_ym_pause
		XREF	_ym_mute

		XREF	_ym_info
		XREF	_ym_extensions
		XREF	_ym_settings

		dc.l	"MXP2"
_ym_parameter:	ds.l	1
		dc.l	_ym_register_module
		dc.l	0			; _ym_get_playtime
		dc.l	0			; 1 song per module
		dc.l	_ym_init
		dc.l	_ym_set
		dc.l	_ym_feed
		dc.l	_ym_unset
		dc.l	0			; _ym_unregister_module
		dc.l	_ym_pause
		dc.l	_ym_mute
		dc.l	_ym_info
		dc.l	_ym_extensions
		dc.l	0			; _ym_settings
