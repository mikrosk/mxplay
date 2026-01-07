; xmp plugin glue layer
; MiKRO / Mystic Bytes
; (c) 2012-2013

		XDEF	_start
		XDEF	xmp_parameter

		XREF	xmp_register_module
		XREF	xmp_get_playtime
		XREF	xmp_init
		XREF	xmp_set
		XREF	xmp_feed
		XREF	xmp_unset
		XREF	xmp_pause
		XREF	xmp_mute

		XREF	xmp_info
		XREF	xmp_extensions
		XREF	xmp_settings

_start:
		dc.l	"MXP2"
xmp_parameter:
		ds.l	1
		dc.l	xmp_register_module
		dc.l	xmp_get_playtime
		dc.l	0			; 1 song per module
		dc.l	xmp_init
		dc.l	xmp_set
		dc.l	xmp_feed
		dc.l	xmp_unset
		dc.l	0			; xmp_unregister_module
		dc.l	xmp_pause
		dc.l	xmp_mute
		dc.l	xmp_info
		dc.l	xmp_extensions
		dc.l	xmp_settings
