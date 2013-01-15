; mgt plugin glue layer
; MiKRO / Mystic Bytes
; (c) 2012-2013

		XDEF	_mgt_parameter

		XREF	_mgt_register_module
		XREF	_mgt_get_playtime
		;XREF	_mgt_get_songs
		XREF	_mgt_init
		XREF	_mgt_set
		;XREF	_mgt_feed
		XREF	_mgt_unset
		XREF	_mgt_deinit
		;XREF	_mgt_pause
		;XREF	_mgt_mute

		XREF	_mgt_info
		XREF	_mgt_extensions
		XREF	_mgt_settings

		dc.l	"MXP2"
_mgt_parameter:	ds.l	1
		dc.l	_mgt_register_module
		dc.l	_mgt_get_playtime
		dc.l	0			; _mgt_get_songs
		dc.l	_mgt_init
		dc.l	_mgt_set
		dc.l	0			; _mgt_feed
		dc.l	_mgt_unset
		dc.l	_mgt_deinit
		dc.l	0			; _mgt_pause
		dc.l	0			; _mgt_mute
		dc.l	_mgt_info
		dc.l	_mgt_extensions
		dc.l	_mgt_settings
