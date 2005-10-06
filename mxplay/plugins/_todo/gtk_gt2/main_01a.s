*		High-level manager for GT2 player
*		GT2 plugin for mxPlay - Main()
*		by -XI-/Satantronic
*		version 1   save:0.01   date:23.10.2005   time:20:46

		opt	d-
		comment	HEAD=%0000			;MinimalHeap,MallocInTT-RAM,LoadInTT-RAM,Fastload
		opt	p=68030
		OUTPUT	.MXP


		include	"mxp_inc.s"

;====================================================
		section text

;---Plugin header:-----------------------------------
gt2_header:
		dc.l	"MXP1"
		ds.l	1
		bra.w	gt2_register_module
		bra.w	gt2_check_module
		bra.w	gt2_get_playtime
		bra.w	gt2_init
		bra.w	gt2_set
		bra.w	gt2_unset
		bra.w	gt2_deinit
		bra.w	gt2_fwd
		bra.w	gt2_rwd
		bra.w	gt2_pause
		dc.l	gt2_info
		dc.l	gt2_extensions
		dc.l	gt2_settings


;---Register:----------------------------------------
gt2_register_module:
		movea.l	gt2_header+MXP_PLUGIN_PARAMETER,a0
		move.l	(a0)+,filebuffer
		move.l	(a0)+,filelenght	

		moveq	#MXP_OK,d0
		rts

		moveq	#MXP_ERROR,d0
		rts


;---Check:-------------------------------------------
gt2_check_module:
		bsr.w	gt2_get_module_type		; d0 will contain return code
		rts


;---Get play time:-----------------------------------
gt2_get_playtime:
		move.w	#2*60,d0
		rts


;---Init:--------------------------------------------
gt2_init:
		move.l	#98340,d0			;calculate new replayfreq data
		move.w	gtkr_replay_prediv,d1		;
		addq.w	#1,d1				;
		divu.w	d1,d0				;
		move.w	d0,gtkr_replay_freq		;



		move.l	#gtkpl_info_track,-(sp)
		move.w	#NBRVOIES_MAXI,-(sp)
		sndkernel	kernel_on	
		addq.l	#6,sp
		bsr	gtkpl_player_on		

		;pea	module_gt2		
		;pea	module_gt2
		move.l	filebuffer,-(sp)
		move.l	filebuffer,-(sp)

		move.w	#0,-(sp)		
		bsr	gtkpl_convert_module
		lea	10(sp),sp
		pea	0.l			
		pea	repeatbuffer		

		;pea	module_gt2
		move.l	filebuffer,-(sp)

		bsr	gtkpl_make_rb_module
		lea	12(sp),sp

		moveq	#MXP_OK,d0
		rts


;---Set:---------------------------------------------
gt2_set:	clr.l	stop_flag


		clr.w	-(sp)			
		clr.w	-(sp)
		pea	repeatbuffer

		;pea	module_gt2
		move.l	filebuffer,-(sp)

		bsr	gtkpl_new_module
		lea	12(sp),sp

		moveq	#MXP_OK,d0
		rts


;---Unset:-------------------------------------------
gt2_unset:	bsr	gtkpl_stop_module

		moveq	#MXP_OK,d0
		rts

		
;---Deinit:------------------------------------------
gt2_deinit:	bsr		gtkpl_player_off
		sndkernel	kernel_off

		moveq	#MXP_OK,d0
		rts


;---Module forward:----------------------------------
gt2_fwd:	moveq	#MXP_UNIMPLEMENTED,d0
		rts


;---Module rewind:-----------------------------------
gt2_rwd:	moveq	#MXP_UNIMPLEMENTED,d0
		rts

		
;---Module pause:------------------------------------
gt2_pause:	tst.l	stop_flag
		beq.s	.stop
		clr.l	stop_flag
		bsr	gtkpl_cont_module
		moveq	#MXP_OK,d0
		rts

.stop		move.l	#1,stop_flag
		bsr	gtkpl_pause_module	
		moveq	#MXP_OK,d0
		rts	


;---Subrouts:----------------------------------------
gt2_get_module_name:
		move.l	gt2_filebuffer,a0
		adda.l	#8,a0
		move.l	gt2_module_name,a1
		
		move.w	#$c0-1,d7
.loop		move.b	(a0)+,(a1)+
		dbra	d7,.loop
		clr.b	(a1)

.end		move.l	a2,gt2_header+MXP_PLUGIN_PARAMETER
		rts


gt2_get_module_type:
		move.l	gt2_filebuffer,a0
		move.l	(a0),d0
		and.l	#$ffffff00,d0
		cmp.l	gt2_extensions_mod,d0
		bne.s	.no_GT2		

		move.l	(a0),gt2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

.no_GT2:	moveq	#MXP_ERROR,d0
		rts


gt2_get_module_artist:
		lea.l	gt2_module_artist,a2

.end		move.l	a2,gt2_header+MXP_PLUGIN_PARAMETER
		rts




resident_ker:	equ	0

		include	'gt\sndkernl.s'
		include	'gt\gt2playr.s'

		section text
	

;====================================================
		section	data

		even

gt2_info:	dc.l	gt2_info_plugin_author
		dc.l	gt2_info_plugin_version
		dc.l	gt2_info_replay_name
		dc.l	gt2_info_replay_author
		dc.l	gt2_info_replay_version
		dc.l	MXP_FLG_USE_DSP|MXP_FLG_USE_DMA|MXP_FLG_USE_020


gt2_settings:	dc.l	gt2_settings_module_name
		dc.l	1|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	gt2_get_module_name

		dc.l	gt2_settings_module_type
		dc.l	1|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	gt2_get_module_type

		dc.l	gt2_settings_module_artist
		dc.l	1|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	gt2_get_module_artist

		dc.l	0


gt2_extensions:	dc.l	gt2_extensions_mod
		dc.l	gt2_extensions_mod_name
		
		dc.l	0


gt2_formats:	dc.l	gt2_formats_GT2_name


gt2_settings_module_name:
		dc.b	"Songname",0
gt2_settings_module_channels:
		dc.b	"Channels",0
gt2_settings_module_type:
		dc.b	"Module type",0
gt2_settings_module_artist:
		dc.b	"Artist",0
		
gt2_info_plugin_author:
		dc.b	"-XI-/Satantronic",0
gt2_info_plugin_version:
		dc.b	"0.01 23.10.2005",0
gt2_info_replay_name:
		dc.b	"GT2 replay",0
gt2_info_replay_author:
		dc.b	"Laurent de Soras & Earx & Swe",0
gt2_info_replay_version:
		dc.b	"0.xx",0
		

gt2_extensions_mod:
		dc.b	"GT2",0
gt2_extensions_mod_name:
		dc.b	"GT2 module",0


gt2_formats_GT2_name:
		dc.b	"GT2 (Graoumf Tracker)",0


gt2_module_filename:
		dc.b	0
gt2_module_artist:
		dc.b	"n/a",0

		even
;====================================================
		section	bss
		even
stop_flag	ds.l	1


filebuffer	ds.l	1
filelenght	ds.l	1

gt2_module_name	ds.b	$c1

		even


;====================================================
		section text