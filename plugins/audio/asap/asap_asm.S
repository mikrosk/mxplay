; asap plugin glue layer
; MiKRO / Mystic Bytes
; (c) 2012-2013

		INCLUDE	"../mxplay.inc"
		XDEF	_asap_parameter

		XREF	_asap_register_module
		XREF	_asap_get_playtime
		XREF	_asap_init
		XREF	_asap_set
		XREF	_asap_feed
		XREF	_asap_unset
		XREF	_asap_deinit
		XREF	_asap_fwd
		XREF	_asap_rwd
		XREF	_asap_pause

		XREF	_timerA
		XDEF	_asm_install_timer_a
		XDEF	_asm_uninstall_timer_a

asap_header:	dc.l	"MXP2"
		ds.l	1
		dc.l	asap_register_module					; local function
		dc.l	_asap_get_playtime
		dc.l	_asap_init
		dc.l	_asap_set
		dc.l	_asap_feed
		dc.l	_asap_unset
		dc.l	_asap_deinit
		dc.l	_asap_fwd
		dc.l	_asap_rwd
		dc.l	_asap_pause
		dc.l	asap_info
		dc.l	asap_extensions
		dc.l	asap_settings

asap_register_module:
		move.l	asap_header+MXP_PLUGIN_PARAMETER,_asap_parameter
		bra.w	_asap_register_module					; call C function

; ----------------------------------------------------------------------------

timer_a:	movem.l	d0-d7/a0-a6,-(sp)

		bsr	_timerA

		move.b	#1,$fffffa1f.w			; reset to value '1'

		movem.l	(sp)+,d0-d7/a0-a6
		rte

_asm_install_timer_a:
		move	sr,d0				; save sr
		ori	#$0700,sr			; ints off

		lea	sample_save_mfp,a0
		move.l	$134.w,(a0)+
		move.b	$fffffa1f.w,(a0)+
		move.b	$fffffa19.w,(a0)+
		move.b	$fffffa17.w,(a0)+
		move.b	$fffffa07.w,(a0)+
		move.b	$fffffa13.w,(a0)+

		move.l	#timer_a,$134.w			; set timer a handler
		clr.b	$fffffa19.w			; clear timer a control register
		move.b	#1,$fffffa1f.w			; count to value '1'
		move.b	#%1000,$fffffa19.w		; event count mode
		bclr	#3,$fffffa17.w			; automatic end-of-interrupt mode
		bset	#5,$fffffa07.w			; enable timer a
		bset	#5,$fffffa13.w			; same here (mask register)

		move	d0,sr				; ints back
		rts

_asm_uninstall_timer_a:
		move	sr,d0				; save sr
		ori	#$0700,sr			; ints off

		lea	sample_save_mfp,a0
		move.l	(a0)+,$134.w
		move.b	(a0)+,$fffffa1f.w
		move.b	(a0)+,$fffffa19.w
		move.b	(a0)+,$fffffa17.w
		move.b	(a0)+,$fffffa07.w
		move.b	(a0)+,$fffffa13.w

		move	d0,sr				; ints back
		rts

; ----------------------------------------------------------------------------
		SECTION DATA
; ----------------------------------------------------------------------------

asap_info:	dc.l	asap_info_plugin_author
		dc.l	asap_info_plugin_version
		dc.l	asap_info_replay_name
		dc.l	asap_info_replay_author
		dc.l	asap_info_replay_version
		dc.l	MXP_FLG_USE_DMA|MXP_FLG_USE_020|MXP_FLG_USE_FPU|MXP_FLG_DONT_LOAD_MODULE|MXP_FLG_USER_CODE

asap_extensions:
		dc.l	asap_extensions_sap
		dc.l	asap_extensions_sap_name

		dc.l	asap_extensions_cmc
		dc.l	asap_extensions_cmc_name

		dc.l	asap_extensions_cm3
		dc.l	asap_extensions_cm3_name

		dc.l	asap_extensions_cmr
		dc.l	asap_extensions_cmr_name

		dc.l	asap_extensions_cms
		dc.l	asap_extensions_cms_name

		dc.l	asap_extensions_dmc
		dc.l	asap_extensions_dmc_name

		dc.l	asap_extensions_dlt
		dc.l	asap_extensions_dlt_name

		dc.l	asap_extensions_fc
		dc.l	asap_extensions_fc_name

		dc.l	asap_extensions_mpt
		dc.l	asap_extensions_mpt_name

		dc.l	asap_extensions_mpd
		dc.l	asap_extensions_mpd_name

		dc.l	asap_extensions_rmt
		dc.l	asap_extensions_rmt_name

		dc.l	asap_extensions_tmc
		dc.l	asap_extensions_tmc_name

		dc.l	asap_extensions_tm8
		dc.l	asap_extensions_tmc_name

		dc.l	asap_extensions_tm2
		dc.l	asap_extensions_tm2_name

asap_settings:	dc.l	0

; ----------------------------------------------------------------------------

asap_info_plugin_author:
		dc.b	"MiKRO / Mystic Bytes",0
asap_info_plugin_version:
		dc.b	"1.0",0
asap_info_replay_name:
		dc.b	"Another Slight Atari Player",0
asap_info_replay_author:
		dc.b	"Piotr Fusik ",0
asap_info_replay_version:
		dc.b	"3.1.3",0	; TODO: read it from libsap

; ----------------------------------------------------------------------------

asap_extensions_sap:
		dc.b	"SAP",0
asap_extensions_sap_name:
		dc.b	"Slight Atari Player",0

asap_extensions_cmc:
		dc.b	"CMC",0
asap_extensions_cmc_name:
		dc.b	"Chaos Music Composer",0

asap_extensions_cm3:
		dc.b	"CM3",0
asap_extensions_cm3_name:
		dc.b	"Chaos Music Composer \"3/4\"",0

asap_extensions_cmr:
		dc.b	"CMR",0
asap_extensions_cmr_name:
		dc.b	"Chaos Music Composer \"Rzog\"",0

asap_extensions_cms:
		dc.b	"CMS",0
asap_extensions_cms_name:
		dc.b	"Stereo Double Chaos Music Composer",0

asap_extensions_dmc:
		dc.b	"DMC",0
asap_extensions_dmc_name:
		dc.b	"DoublePlay Chaos Music Composer",0

asap_extensions_dlt:
		dc.b	"DLT",0
asap_extensions_dlt_name:
		dc.b	"Delta Music Composer",0

asap_extensions_fc:
		dc.b	"FC",0
asap_extensions_fc_name:
		dc.b	"Future Composer",0

asap_extensions_mpt:
		dc.b	"MPT",0
asap_extensions_mpt_name:
		dc.b	"Music ProTracker",0

asap_extensions_mpd:
		dc.b	"MPD",0
asap_extensions_mpd_name:
		dc.b	"Music ProTracker DoublePlay",0

asap_extensions_rmt:
		dc.b	"RMT",0
asap_extensions_rmt_name:
		dc.b	"Raster Music Tracker",0

asap_extensions_tmc:
		dc.b	"TMC",0
asap_extensions_tm8:
		dc.b	"TM8",0
asap_extensions_tmc_name:
		dc.b	"Theta Music Composer 1.x",0

asap_extensions_tm2:
		dc.b	"TM2",0
asap_extensions_tm2_name:
		dc.b	"Theta Music Composer 2.x",0

; ----------------------------------------------------------------------------
		SECTION BSS
; ----------------------------------------------------------------------------

_asap_parameter:
		ds.l	1
sample_save_mfp:
		ds.b	4+5
