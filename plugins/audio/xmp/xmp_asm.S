; xmp plugin glue layer
; MiKRO / Mystic Bytes
; (c) 2012-2013

		INCLUDE	"../mxplay.inc"
		XDEF	_xmp_parameter

		XREF	_xmp_register_module
		XREF	_xmp_get_playtime
		XREF	_xmp_init
		XREF	_xmp_set
		XREF	_xmp_unset
		XREF	_xmp_deinit
		XREF	_xmp_fwd
		XREF	_xmp_rwd
		XREF	_xmp_pause

		XREF	_timerA
		XDEF	_asm_install_timer_a
		XDEF	_asm_uninstall_timer_a

xmp_header:	dc.l	"MXP2"
		ds.l	1
		dc.l	xmp_register_module					; local function
		dc.l	_xmp_get_playtime
		dc.l	_xmp_init
		dc.l	_xmp_set
		dc.l	_xmp_unset
		dc.l	_xmp_deinit
		dc.l	_xmp_fwd
		dc.l	_xmp_rwd
		dc.l	_xmp_pause
		dc.l	xmp_info
		dc.l	xmp_extensions
		dc.l	xmp_settings

xmp_register_module:
		move.l	xmp_header+MXP_PLUGIN_PARAMETER,_xmp_parameter
		bra.w	_xmp_register_module					; call C function

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

xmp_info:	dc.l	xmp_info_plugin_author
		dc.l	xmp_info_plugin_version
		dc.l	xmp_info_replay_name
		dc.l	xmp_info_replay_author
		dc.l	xmp_info_replay_version
		dc.l	MXP_FLG_USE_DMA|MXP_FLG_USE_020|MXP_FLG_USE_FPU|MXP_FLG_DONT_LOAD_MODULE|MXP_FLG_USER_CODE

xmp_extensions:	dc.l	xmp_extensions_all
		dc.l	xmp_extensions_all_name

xmp_settings:	dc.l	0

; ----------------------------------------------------------------------------

xmp_info_plugin_author:
		dc.b	"MiKRO / Mystic Bytes",0
xmp_info_plugin_version:
		dc.b	"1.0",0
xmp_info_replay_name:
		dc.b	"Extended Module Player",0
xmp_info_replay_author:
		dc.b	"Claudio Matsuoka and Hipolito Carraro Jr",0
xmp_info_replay_version:
		dc.b	"4.0.0",0	; TODO: read it from libxmp

; ----------------------------------------------------------------------------

xmp_extensions_all:
		dc.b	"*",0
xmp_extensions_all_name:
		dc.b	"Module",0

; ----------------------------------------------------------------------------
		SECTION BSS
; ----------------------------------------------------------------------------

_xmp_parameter:
		ds.l	1
sample_save_mfp:
		ds.b	4+5
