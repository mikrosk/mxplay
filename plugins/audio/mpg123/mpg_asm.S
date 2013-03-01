; mpg123 plugin glue layer
; MiKRO / Mystic Bytes
; (c) 2012-2013

		XDEF	_mpg_parameter

		XREF	_mpg_register_module
		XREF	_mpg_get_playtime
		XREF	_mpg_get_songs
		XREF	_mpg_init
		XREF	_mpg_set
		XREF	_mpg_feed
		XREF	_mpg_unset
		XREF	_mpg_pause
		XREF	_mpg_mute

		XREF	_mpg_info
		XREF	_mpg_extensions
		XREF	_mpg_settings

		dc.l	"MXP2"
_mpg_parameter:	ds.l	1
		dc.l	_mpg_register_module
		dc.l	0				; _mpg_get_playtime
		dc.l	0				; _mpg_get_songs
		dc.l	_mpg_init
		dc.l	_mpg_set
		dc.l	_mpg_feed
		dc.l	_mpg_unset
		dc.l	0				; _mpg_unregister
		dc.l	_mpg_pause
		dc.l	_mpg_mute
		dc.l	_mpg_info
		dc.l	_mpg_extensions
		dc.l	0				; _mpg_settings
