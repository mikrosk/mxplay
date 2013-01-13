; asap plugin glue layer
; MiKRO / Mystic Bytes
; (c) 2012-2013

		XDEF	_asap_parameter

		XREF	_asap_register_module
		XREF	_asap_get_playtime
		XREF	_asap_get_songs
		XREF	_asap_init
		XREF	_asap_set
		XREF	_asap_feed
		XREF	_asap_unset
		XREF	_asap_deinit
		XREF	_asap_pause
		XREF	_asap_mute

		XREF	_asap_info
		XREF	_asap_extensions
		XREF	_asap_settings

		dc.l	"MXP2"
_asap_parameter:	ds.l	1
		dc.l	_asap_register_module
		dc.l	_asap_get_playtime
		dc.l	_asap_get_songs
		dc.l	_asap_init
		dc.l	_asap_set
		dc.l	_asap_feed
		dc.l	_asap_unset
		dc.l	_asap_deinit
		dc.l	_asap_pause
		dc.l	_asap_mute
		dc.l	_asap_info
		dc.l	_asap_extensions
		dc.l	_asap_settings
