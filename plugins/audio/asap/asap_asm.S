; asap plugin glue layer
; MiKRO / Mystic Bytes
; (c) 2012-2013

		XDEF	_start
		XDEF	asap_parameter

		XREF	asap_register_module
		XREF	asap_get_playtime
		XREF	asap_get_songs
		XREF	asap_init
		XREF	asap_set
		XREF	asap_feed
		XREF	asap_unset
		XREF	asap_pause
		XREF	asap_mute

		XREF	asap_info
		XREF	asap_extensions
		XREF	asap_settings

_start:
		dc.l	"MXP2"
asap_parameter:
		ds.l	1
		dc.l	asap_register_module
		dc.l	asap_get_playtime
		dc.l	asap_get_songs
		dc.l	asap_init
		dc.l	asap_set
		dc.l	asap_feed
		dc.l	asap_unset
		dc.l	0				; _asap_unregister
		dc.l	asap_pause
		dc.l	asap_mute
		dc.l	asap_info
		dc.l	asap_extensions
		dc.l	asap_settings
