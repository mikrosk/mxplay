; gt2 plugin
; MiKRO / Mystic Bytes
; (c) 2012-2013

		comment HEAD=%111
		output .mxp
		opt	p=68030,NOCASE,D-

; ----------------------------------------------
		section text
; ----------------------------------------------

gt2_header:	dc.l	"MXP2"
		ds.l	1
		dc.l	gt2_register_module
		dc.l	gt2_get_playtime
		dc.l	0			; gt2_get_songs
		dc.l	gt2_init
		dc.l	gt2_start_playback
		dc.l	0			; gt2_feed
		dc.l	gt2_stop_playback
		dc.l	gt2_deinit
		dc.l	gt2_pause
		dc.l	0			; gt2_mute
		dc.l	gt2_info
		dc.l	gt2_extensions
		dc.l	gt2_settings

; ----------------------------------------------

resident_ker:	equ	0

		include	'gt\sndkernl.s'
		include	'gt\gt2playr.s'

		section text

; ----------------------------------------------

		include	'..\mxplay.inc'

gt2_register_module:
		movea.l	gt2_header+MXP_PLUGIN_PARAMETER,a0
		move.l	(a0),filename

		movem.l	d2-d7/a2-a6,-(sp)

		include	'loader.s'
		include	'parse.s'		; TODO params

		movem.l	(sp)+,d2-d7/a2-a6

		moveq	#MXP_OK,d0
		rts

gt2_get_playtime:
		move.l	#5*60,d0		; TODO (positions?)
		rts

gt2_init:	move.l	#98340,d0		; calculate new replayfreq data
		move.w	gtkr_replay_prediv,d1	; default is for 49170 Hz
		addq.w	#1,d1			;
		divu.w	d1,d0			;
		move.w	d0,gtkr_replay_freq	;
		moveq	#MXP_OK,d0
		rts

gt2_start_playback:
		movem.l	d2-d7/a2-a6,-(sp)

		move.l	#gtkpl_info_track,-(sp)
		move.w	#NBRVOIES_MAXI,-(sp)
		sndkernel kernel_on
		addq.l	#6,sp
		bsr	gtkpl_player_on

		move.l	filebuffer,-(sp)
		move.l	filebuffer,-(sp)
		move.w	#0,-(sp)
		bsr	gtkpl_convert_module
		lea	10(sp),sp

		pea	0.l
		pea	repeatbuffer
		move.l	filebuffer,-(sp)
		bsr	gtkpl_make_rb_module
		lea	12(sp),sp

		clr.w	-(sp)
		clr.w	-(sp)
		pea	repeatbuffer
		move.l	filebuffer,-(sp)
		bsr	gtkpl_new_module
		lea	12(sp),sp

		movem.l	(sp)+,d2-d7/a2-a6
		moveq	#MXP_OK,d0
		rts

gt2_stop_playback:
		movem.l	d2-d7/a2-a6,-(sp)

		bsr	gtkpl_stop_module
		bsr	gtkpl_player_off
		sndkernel kernel_off

		move.l	filebuffer,-(sp)
		move.w	#73,-(sp)
		trap	#1
		addq.l	#6,sp

		movem.l	(sp)+,d2-d7/a2-a6
		moveq	#MXP_OK,d0
		rts

gt2_deinit:	moveq	#MXP_OK,d0
		rts

gt2_pause:	movem.l	d2-d7/a2-a6,-(sp)

		move.l	gt2_header+MXP_PLUGIN_PARAMETER,d0
		bne.b	.pause

.cont:		bsr	gtkpl_cont_module

		movem.l	(sp)+,d2-d7/a2-a6
		moveq	#MXP_OK,d0
		rts

.pause:		bsr	gtkpl_pause_module

		movem.l	(sp)+,d2-d7/a2-a6
		moveq	#MXP_OK,d0
		rts

; ----------------------------------------------
		section data
; ----------------------------------------------
		even

gt2_info:	dc.l	gt2_info_plugin_author
		dc.l	gt2_info_plugin_version
		dc.l	gt2_info_replay_name
		dc.l	gt2_info_replay_author
		dc.l	gt2_info_replay_version
		dc.l	MXP_FLG_USE_DSP|MXP_FLG_USE_DMA|MXP_FLG_USE_020|MXP_FLG_DONT_LOAD_MODULE

gt2_extensions:
		dc.l	gt2_extensions_gt2
		dc.l	gt2_extensions_gt2_name
		dc.l	0

gt2_settings:	dc.l	0

gt2_info_plugin_author:
		dc.b	"MiKRO / Mystic Bytes",0
gt2_info_plugin_version:
		dc.b	"1.0",0
gt2_info_replay_name:
		dc.b	"Graoumf Tracker Replay",0
gt2_info_replay_author:
		dc.b	"Laurent de Soras & Earx / FUN",0
gt2_info_replay_version:
		dc.b	"May 7 2001",0

gt2_extensions_gt2:
		dc.b	"GT2",0
gt2_extensions_gt2_name:
		dc.b	"Graoumf Tracker Module",0

; ----------------------------------------------
		section bss
; ----------------------------------------------
		even

filelength:	ds.l	1			; length in bytes of loaded file
filename:	ds.l	1			; address to filename to load
file_error:	ds.l	1			; error check
filenumber:	ds.w	1			; filenumber
filebuffer:	ds.l	1			; address to loader dest buffer
dta:		ds.l	11			; new dta buffer

gtkpl_info_track:
		ds.b	nbrvoies_maxi*next_t	; maximum channels info
repeatbuffer:	ds.b	nbrsamples_maxi*1024	; gt repeatbuffer
