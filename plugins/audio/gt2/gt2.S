; gt2 plugin
; MiKRO / Mystic Bytes
; (c) 2012-2013

		opt	ow-

; ----------------------------------------------
		section text
; ----------------------------------------------

gt2_header:	dc.l	"MXP2"
		ds.l	1
		dc.l	gt2_register_module
		dc.l	0			; gt2_get_playtime
		dc.l	0			; gt2_get_songs
		dc.l	gt2_init
		dc.l	gt2_start_playback
		dc.l	0			; gt2_feed
		dc.l	gt2_stop_playback
		dc.l	gt2_unregister_module
		dc.l	gt2_pause
		dc.l	0			; gt2_mute
		dc.l	gt2_info
		dc.l	gt2_extensions
		dc.l	gt2_settings

; ----------------------------------------------

resident_ker:	equ	0

		include	'gt/sndkernl.s'
		include	'gt/gt2playr.s'

		section text

; ----------------------------------------------

		include	'../mxplay.inc'

gt2_register_module:
		movea.l	gt2_header+MXP_PLUGIN_PARAMETER,a0
		move.l	(a0),filename

		include	'loader.s'

		move.l	filebuffer,a0		; Check if the file is a Graoumf Tracker file

		cmp.w	#"GT",(a0)+
		bne.s	.err

		cmp.b	#"2",(a0)+
		bne.s	.err

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

		moveq	#MXP_OK,d0
		rts

.err:		moveq	#MXP_ERROR,d0
		rts

gt2_init:	move.l	#98340,d0		; calculate new replayfreq data
		move.w	gtkr_replay_prediv,d1	; default is for 49170 Hz
		addq.w	#1,d1			;
		divu.w	d1,d0			;
		move.w	d0,gtkr_replay_freq	;
		moveq	#MXP_OK,d0
		rts

gt2_unregister_module:
		move.l	filebuffer,-(sp)	; Mfree()
		move.w	#$49,-(sp)		;
		trap	#1			;
		addq.l	#6,sp			;

		moveq	#MXP_OK,d0
		rts

gt2_start_playback:
		move.l	#gtkpl_info_track,-(sp)
		move.w	#NBRVOIES_MAXI,-(sp)
		sndkernel kernel_on
		addq.l	#6,sp

		bsr	gtkpl_player_on

		clr.w	-(sp)
		clr.w	-(sp)
		pea	repeatbuffer
		move.l	filebuffer,-(sp)
		bsr	gtkpl_new_module
		lea	12(sp),sp

		moveq	#MXP_OK,d0
		rts

gt2_stop_playback:
		bsr	gtkpl_stop_module
		bsr	gtkpl_player_off
		sndkernel kernel_off

		moveq	#MXP_OK,d0
		rts

gt2_pause:	move.l	gt2_header+MXP_PLUGIN_PARAMETER,d0
		bne.b	.pause

.cont:		bsr	gtkpl_cont_module

		moveq	#MXP_OK,d0
		rts

.pause:		bsr	gtkpl_pause_module

		moveq	#MXP_OK,d0
		rts

; ----------------------------------------------

gt2_settings_module_name_get:
		movea.l	filebuffer,a0
		addq.l	#8,a0					; offset to songname
		clr.b	31(a0)					; terminate string
		move.l	a0,gt2_header+MXP_PLUGIN_PARAMETER

		moveq	#MXP_OK,d0
		rts

gt2_settings_channels_get:
		movea.l	filebuffer,a0				; gt2 file

		moveq	#20-1,d1				; maximum number of chunks to check
.loop:		add.l	4(a0),a0				; next chunk
		cmpi.l	#"PATS",(a0)				; check chunk
		beq.s	.foundchunk				; found
		dbra	d1,.loop				; not found

		bra.s	.nothingfound

.foundchunk:	clr.l	d0
		move.w	8(a0),d0				; extract number of channels
		move.l	d0,gt2_header+MXP_PLUGIN_PARAMETER

		moveq	#MXP_OK,d0
		rts

.nothingfound:	moveq	#MXP_ERROR,d0
		rts

gt2_settings_tracker_name_get:
		movea.l	filebuffer,a0
		lea	204(a0),a0				; offset to tracker information
		clr.b	23(a0)					; terminate string
		move.l	a0,gt2_header+MXP_PLUGIN_PARAMETER

		moveq	#MXP_OK,d0
		rts

gt2_settings_module_type_get:
		move.l	filebuffer,a0				; Check GT2 fileformat version number
		addq.l	#3,a0					;
		move.l	#gt2_format_08xx,d0

		cmp.b	#1,(a0)					;
		bne.s	.no					;
		move.l	#gt2_format_0700,d0			; 0.7
		bra.s	.ok					;

.no:		cmp.b	#2,(a0)					;
		bne.s	.no2					;
		move.l	#gt2_format_0726,d0			; 0.726
		bra.s	.ok					;

.no2:		cmp.b	#3,(a0)					;
		bne.s	.no3					;
		move.l	#gt2_format_0731,d0			; 0.731

.no3:		cmp.b	#4,(a0)					;
		bne.s	.ok					; if not 1, 2, 3 or 4, assume v0.8something
		move.l	#gt2_format_0877,d0			; 0.877

.ok:		move.l	d0,gt2_header+MXP_PLUGIN_PARAMETER
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
		dc.l	MXP_FLG_USE_DSP|MXP_FLG_USE_DMA|MXP_FLG_DONT_LOAD_MODULE

gt2_extensions:
		dc.l	gt2_extensions_gt2
		dc.l	0
		dc.l	0

gt2_settings:	dc.l	gt2_settings_module_name
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	gt2_settings_module_name_get

		dc.l	gt2_settings_channels
		dc.l	MXP_PAR_TYPE_INT|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	gt2_settings_channels_get

		dc.l	gt2_settings_tracker_name
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	gt2_settings_tracker_name_get

		dc.l	gt2_settings_module_type
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	gt2_settings_module_type_get

		dc.l	0

gt2_info_plugin_author:
		dc.b	"MiKRO / Mystic Bytes",0
gt2_info_plugin_version:
		dc.b	"1.0",0
gt2_info_replay_name:
		dc.b	"Graoumf Tracker Replay",0
gt2_info_replay_author:
		dc.b	"Laurent de Soras & Earx",0
gt2_info_replay_version:
		dc.b	"May 7 2001",0

gt2_extensions_gt2:
		dc.b	"GT2",0

gt2_settings_module_name:
		dc.b	"Title",0
gt2_settings_channels:
		dc.b	"Channels",0
gt2_settings_tracker_name:
		dc.b	"Tracker",0
gt2_settings_module_type:
		dc.b	"Type",0

gt2_format_0700:
		dc.b	"GT2 v0.700",0
gt2_format_0726:
		dc.b	"GT2 v0.726",0
gt2_format_0731:
		dc.b	"GT2 v0.731",0
gt2_format_0877:
		dc.b	"GT2 v0.877",0
gt2_format_08xx:
		dc.b	"GT2 v0.8xx",0

		even

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
