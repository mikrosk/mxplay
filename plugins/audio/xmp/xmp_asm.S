; xmp plugin glue layer
; MiKRO / Mystic Bytes
; (c) 2012-2013

		XDEF	_xmp_parameter

		XREF	_xmp_register_module
		XREF	_xmp_get_playtime
		XREF	_xmp_init
		XREF	_xmp_set
		XREF	_xmp_feed
		XREF	_xmp_unset
		XREF	_xmp_pause
		XREF	_xmp_mute

		XREF	_xmp_info
		XREF	_xmp_extensions
		XREF	_xmp_settings

		dc.l	"MXP2"
_xmp_parameter:	ds.l	1
		dc.l	_xmp_register_module
		dc.l	_xmp_get_playtime
		dc.l	0			; 1 song per module
		dc.l	_xmp_init
		dc.l	_xmp_set
		dc.l	_xmp_feed
		dc.l	_xmp_unset
		dc.l	0			; _xmp_unregister_module
		dc.l	_xmp_pause
		dc.l	_xmp_mute
		dc.l	_xmp_info
		dc.l	_xmp_extensions
		dc.l	_xmp_settings
