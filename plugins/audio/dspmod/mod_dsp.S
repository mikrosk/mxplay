; High-level manager for DSPMOD player

		include	"../mxplay.inc"

; Plugin header

dspmod_header:	dc.l	"MXP2"
		ds.l	1
		dc.l	dspmod_register_module
		dc.l	0			; dspmod_get_playtime
		dc.l	0			; dspmod_get_songs
		dc.l	dspmod_init
		dc.l	dspmod_set
		dc.l	0			; dspmod_feed
		dc.l	dspmod_unset
		dc.l	0			; dspmod_unregister
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

		include	"dspmod.s"

; ------------------------------------------------------
		SECTION	DATA
; ------------------------------------------------------

dspmod_info:	dc.l	dspmod_info_plugin_author
		dc.l	dspmod_info_plugin_version
		dc.l	dspmod_info_replay_name
		dc.l	dspmod_info_replay_author
		dc.l	dspmod_info_replay_version
		dc.l	MXP_FLG_USE_DSP|MXP_FLG_USE_DMA

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

		dc.l	0

dspmod_extensions:
		dc.l	dspmod_extensions_mod
		dc.l	0

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

dspmod_extensions_mod:
		dc.b	"MOD",0

		even

dspmod_voltab4:
		dc.w $7fff,$7fff,$7fff,$7fff
		dc.w 0,0,0,0
		even

dspmod_voltab8:
		dc.w $3fff,$3fff,$3fff,$3fff
		dc.w $3fff,$3fff,$3fff,$3fff
		even

dspmod_formats:	dc.l	dspmod_formats_mk1
		dc.l	dspmod_formats_mk1_name

		dc.l	dspmod_formats_mk2
		dc.l	dspmod_formats_mk2_name

		dc.l	dspmod_formats_mk3
		dc.l	dspmod_formats_mk3_name

		dc.l	dspmod_formats_flt4
		dc.l	dspmod_formats_flt4_name

		dc.l	dspmod_formats_rasp
		dc.l	dspmod_formats_rasp_name

		dc.l	dspmod_formats_fa04
		dc.l	dspmod_formats_fa04_name

		dc.l	dspmod_formats_6chn
		dc.l	dspmod_formats_6chn_name

		dc.l	dspmod_formats_cd61
		dc.l	dspmod_formats_cd61_name

		dc.l	dspmod_formats_06ch
		dc.l	dspmod_formats_06ch_name

		dc.l	dspmod_formats_fa06
		dc.l	dspmod_formats_fa06_name

		dc.l	dspmod_formats_8chn
		dc.l	dspmod_formats_8chn_name

		dc.l	dspmod_formats_cd81
		dc.l	dspmod_formats_cd81_name

		dc.l	dspmod_formats_flt8
		dc.l	dspmod_formats_flt8_name

		dc.l	dspmod_formats_08ch
		dc.l	dspmod_formats_08ch_name

		dc.l	dspmod_formats_octa
		dc.l	dspmod_formats_octa_name

		dc.l	dspmod_formats_fa08
		dc.l	dspmod_formats_fa08_name

		dc.l	0

dspmod_formats_mk1:
		dc.b	"M.K.",0
dspmod_formats_mk1_name:
		dc.b	"MOD (NoiseTracker or compatible)",0
dspmod_formats_mk2:
		dc.b	"M!K!",0
dspmod_formats_mk2_name:
		dc.b	"MOD (NoiseTracker or compatible)",0
dspmod_formats_mk3:
		dc.b	"M&K&",0
dspmod_formats_mk3_name:
		dc.b	"MOD (NoiseTracker or compatible)",0
dspmod_formats_flt4:
		dc.b	"FLT4",0
dspmod_formats_flt4_name:
		dc.b	"MOD (StarTrekker)",0
dspmod_formats_rasp:
		dc.b	"RASP",0
dspmod_formats_rasp_name:
		dc.b	"MOD (StarTrekker)",0
dspmod_formats_fa04:
		dc.b	"FA04",0
dspmod_formats_fa04_name:
		dc.b	"MOD (Digital Tracker [old version])",0
dspmod_formats_6chn:
		dc.b	"6CHN",0
dspmod_formats_6chn_name:
		dc.b	"MOD (FastTracker)",0
dspmod_formats_cd61:
		dc.b	"CD61",0
dspmod_formats_cd61_name:
		dc.b	"MOD (Octalyser STe or compatible)",0
dspmod_formats_06ch:
		dc.b	"06CH",0
dspmod_formats_06ch_name:
		dc.b	"MOD (FastTracker or compatible)",0
dspmod_formats_fa06:
		dc.b	"FA06",0
dspmod_formats_fa06_name:
		dc.b	"MOD (Digital Tracker [old version])",0
dspmod_formats_8chn:
		dc.b	"8CHN",0
dspmod_formats_8chn_name:
		dc.b	"MOD (Fast Tracker or compatible)",0
dspmod_formats_cd81:
		dc.b	"CD81",0
dspmod_formats_cd81_name:
		dc.b	"MOD (Octalyser STe or compatible)",0
dspmod_formats_flt8:
		dc.b	"FLT8",0
dspmod_formats_flt8_name:
		dc.b	"MOD (StarTrekker)",0
dspmod_formats_08ch:
		dc.b	"08CH",0
dspmod_formats_08ch_name:
		dc.b	"MOD (FastTracker or compatible)",0
dspmod_formats_octa:
		dc.b	"OCTA",0
dspmod_formats_octa_name:
		dc.b	"MOD (Octalyser STe [old version])",0
dspmod_formats_fa08:
		dc.b	"FA08",0
dspmod_formats_fa08_name:
		dc.b	"MOD (Digital Tracker [old version])",0
		even

dspmod_player:
		incbin 'dspmod.tce'

		section	bss

		even

saveaudiobuf:	ds.w	10
dma_pointer:	ds.l	1
dspmod_buffer:	ds.l	1
dspmod_length:	ds.l	1
dspmod_version:	ds.l	1
dspmod_channels:ds.b	1+1
dspmod_module_name:
		ds.b	20+1
