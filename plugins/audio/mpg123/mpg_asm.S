; mpg123 plugin glue layer
; MiKRO / Mystic Bytes
; (c) 2012-2013

		XDEF	_start
		XDEF	mpg_parameter

		XREF	mpg_register_module
		XREF	mpg_get_playtime
		XREF	mpg_init
		XREF	mpg_set
		XREF	mpg_feed
		XREF	mpg_unset
		XREF	mpg_pause
		XREF	mpg_mute

		XREF	mpg_info
		XREF	mpg_extensions
		XREF	mpg_settings

_start:
		dc.l	"MXP2"
mpg_parameter:
		ds.l	1
		dc.l	mpg_register_module
		dc.l	mpg_get_playtime
		dc.l	0				; mpg_get_songs
		dc.l	mpg_init
		dc.l	mpg_set
		dc.l	mpg_feed
		dc.l	mpg_unset
		dc.l	0				; mpg_unregister
		dc.l	mpg_pause
		dc.l	mpg_mute
		dc.l	mpg_info
		dc.l	mpg_extensions
		dc.l	mpg_settings
