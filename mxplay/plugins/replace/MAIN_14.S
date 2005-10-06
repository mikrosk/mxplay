*		High-level manager for ACE player
*		ACE plugin for mxPlay - Main()
*		by -XI-/Satantronic
*		version 1-noFPU   save:0.14   date:19.12.2005   time:22:19

		opt	d-
		comment	HEAD=%0111			;MinimalHeap,MallocInTT-RAM,LoadInTT-RAM,Fastload
		opt	p=68030
		output	.MXP

		include	"mxp_inc.s"

;====================================================		
		section text

;---Plugin header:-----------------------------------
ace_header:
		dc.l	"MXP1"
		ds.l	1
		bra.w	ace_register_module
		bra.w	ace_get_playtime
		bra.w	ace_init
		bra.w	ace_set
		bra.w	ace_unset
		bra.w	ace_deinit
		bra.w	ace_fwd
		bra.w	ace_rwd
		bra.w	ace_pause
		dc.l	ace_info
		dc.l	ace_extensions
		dc.l	ace_settings


;---Register:----------------------------------------
ace_register_module:
		movea.l	ace_header+MXP_PLUGIN_PARAMETER,a0
		move.l	(a0)+,filebuffer

		move.l	#MXP_FLG_INFOLINE,d0
		not.l	d0
		;and.l	d0,ace_set_title
		;and.l	d0,ace_set_artist
		;and.l	d0,ace_set_type
		and.l	d0,ace_set_getptim
		ori.l	#MXP_FLG_INFOLINE,ace_set_title
		ori.l	#MXP_FLG_INFOLINE,ace_set_artist
		ori.l	#MXP_FLG_INFOLINE,ace_set_type
		;ori.l	#MXP_FLG_MOD_PARAM,ace_set_getptim

		move.l	#MXP_FLG_PLG_PARAM,d0
		not.l	d0
		and.l	d0,ace_set_title
		and.l	d0,ace_set_artist
		and.l	d0,ace_set_type
		;and.l	d0,ace_set_getptim
		;ori.l	#MXP_FLG_INFOLINE,ace_set_title
		;ori.l	#MXP_FLG_INFOLINE,ace_set_artist
		;ori.l	#MXP_FLG_MOD_PARAM,ace_set_type
		ori.l	#MXP_FLG_MOD_PARAM,ace_set_getptim

		move.l	#MXP_FLG_MOD_PARAM,d0
		not.l	d0
		;and.l	d0,ace_set_title
		;and.l	d0,ace_set_artist
		;and.l	d0,ace_set_type
		and.l	d0,ace_set_getptim
		ori.l	#MXP_FLG_INFOLINE,ace_set_title
		ori.l	#MXP_FLG_INFOLINE,ace_set_artist
		ori.l	#MXP_FLG_MOD_PARAM,ace_set_type
		;ori.l	#MXP_FLG_MOD_PARAM,ace_set_getptim

		bra	ace_get_module_type


;---Check:-------------------------------------------
ace_check_module:
		bsr.w	ace_get_module_type		; d0 will contain return code
		rts


;---Get play time:-----------------------------------
ace_get_playtime:
		move.l	ace_custom_playtime,d0
		bne.b	.ok
		move.l	#3*60,d0				; 03'00"
.ok:		move.l	d0,ace_header+MXP_PLUGIN_PARAMETER	; for calling from settings structure
		rts


;---Set play time:-----------------------------------
ace_set_playtime:
		move.l	ace_header+MXP_PLUGIN_PARAMETER,ace_custom_playtime
		rts


;---Init:--------------------------------------------
ace_init:	moveq	#MXP_OK,d0
		rts


;---Set:---------------------------------------------
ace_set:	clr.l	stop_flag

		lea	_filter_table,a0
		move.l	#REPLACE_INITIALIZE,d0
		jsr	replace
		cmp.w	#REPLACE_OK,d0
		bne.s	.exit

		move.l	filebuffer,a0
		move.l	#REPLACE_INITIALIZE_MODULE,d0
		jsr	replace
		cmp.w	#REPLACE_OK,d0
		bne.s	.exit

;		move.l	#25,d1
;		move.l	#REPLACE_SET_VOLUME,d0
;		jsr	replace
;		cmp.w	#REPLACE_OK,d0
;		bne.s	.exit

		move.l	#REPLACE_START_INTERRUPT,d0
		jsr	replace
		cmp.w	#REPLACE_OK,d0
		bne.s	.exit

		move.l	#REPLACE_PLAY_SONG,d0
		jsr	replace
		cmp.w	#REPLACE_OK,d0
		bne.s	.exit

		moveq	#MXP_OK,d0
		rts

.exit		moveq	#MXP_ERROR,d0
		rts


;---Unset:-------------------------------------------
ace_unset:
		move.l	#REPLACE_STOP_SONG,d0
		jsr	replace
		cmp.w	#REPLACE_OK,d0
		bne.s	.exit

		move.l	#REPLACE_REMOVE_MODULE,d0
		jsr	replace
		cmp.w	#REPLACE_OK,d0
		bne.s	.exit
		
		move.l	#REPLACE_EXIT,d0
		jsr	replace

		moveq	#MXP_OK,d0
		rts

.exit		moveq	#MXP_ERROR,d0
		rts		


;---Deinit:------------------------------------------
ace_deinit:	moveq	#MXP_OK,d0
		rts


;---Module forward:----------------------------------
ace_fwd:	moveq	#MXP_UNIMPLEMENTED,d0
		rts



;---Module rewind:-----------------------------------
ace_rwd:	moveq	#MXP_UNIMPLEMENTED,d0
		rts
		
		
		
;---Module pause:------------------------------------
ace_pause:	tst.l	stop_flag
		beq.s	.stop
		clr.l	stop_flag
		move.l	#REPLACE_START_INTERRUPT,d0
		bra.s	.start
		
.stop		move.l	#1,stop_flag
		move.l	#REPLACE_STOP_INTERRUPT,d0
.start		jsr	replace	
		moveq	#MXP_OK,d0
		rts	


;---Subrouts:----------------------------------------
ace_get_module_title:
		move.l	#REPLACE_GET_MODULE_TITLE,d0	;song title
		jsr	replace

		lea.l	ace_module_title,a1
		movea.l	a1,a2
		move.w	#5-1,d7
.loop		move.l	(a0)+,(a1)+
		dbra.w	d7,.loop
		clr.b	(a1)

		move.l	a2,ace_header+MXP_PLUGIN_PARAMETER
		rts


ace_get_module_artist:
		move.l	#REPLACE_GET_MODULE_COMPOSER,d0	;song composer
		jsr	replace

		lea.l	ace_module_composer,a1
		movea.l	a1,a2
		move.w	#5-1,d7
.loop		move.l	(a0)+,(a1)+
		dbra.w	d7,.loop
		clr.b	(a1)

		move.l	a2,ace_header+MXP_PLUGIN_PARAMETER
		rts


ace_get_module_type:
		move.l	filebuffer,a0
		move.w	(a0),d0		
		lea	ace_formats,a0

.loop:		movea.l	(a0)+,a1			; 'format' address
		tst.l	a1				; NULL?
		beq.b	.not_found
		cmp.w	(a1),d0
		beq.b	.found
		addq.l	#4,a0				; skip 'name' address
		bra.b	.loop
		
.found:		move.l	(a0),ace_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

.not_found:	moveq	#MXP_ERROR,d0
		rts

		
;----------------------------------------------------
		include	"replace.def"


;====================================================
		section	data
		
.r:		incbin	"replace.bin"
replace:	equ	.r+28


_filter_table:	incbin	"f32.dat"
		even


ace_info:	dc.l	ace_info_plugin_author
		dc.l	ace_info_plugin_version
		dc.l	ace_info_replay_name
		dc.l	ace_info_replay_author
		dc.l	ace_info_replay_version
		dc.l	MXP_FLG_USE_DSP|MXP_FLG_USE_DMA|MXP_FLG_USE_020
		

ace_settings:	dc.l	ace_settings_module_type
ace_set_type	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	ace_get_module_type

		dc.l	ace_settings_module_title
ace_set_title	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	ace_get_module_title

		dc.l	ace_settings_module_artist
ace_set_artist	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	ace_get_module_artist

		dc.l	ace_settings_playtime
ace_set_getptim	dc.l	MXP_PAR_TYPE_INT|MXP_FLG_PLG_PARAM
		dc.l	ace_set_playtime
		dc.l	ace_get_playtime

		dc.l	0


ace_extensions:	dc.l	ace_extensions_mod
		dc.l	ace_extensions_mod_name
		
		dc.l	0


ace_formats:	dc.l	ace_formats_AM01
		dc.l	ace_formats_AM01_name	
		
		dc.l	0
		dc.l	0

ace_settings_module_title:
		dc.b	"Title",0
ace_settings_module_channels:
		dc.b	"Channels",0
ace_settings_module_type:
		dc.b	"Module type",0
ace_settings_module_artist:
		dc.b	"Artist",0
ace_settings_playtime:
		dc.b	"Playtime",0

ace_info_plugin_author:
		dc.b	"-XI-/Satantronic",0
ace_info_plugin_version:
		dc.b	"0.14 19.12.2005 ",0		
ace_info_replay_name:
		dc.b	"ACE - Replace",0
		even
ace_info_replay_author:
		dc.b	"New Beat",0
		even
ace_info_replay_version:
		dc.b	"0.37",0
		

ace_extensions_mod:
		dc.b	"AM",0
ace_extensions_mod_name:
		dc.b	"ACE module",0


ace_formats_AM01:
		dc.b	"AM01",0
ace_formats_AM01_name:
		dc.b	"AM (ACE Tracker)",0

		even


;====================================================		
		section	bss
stop_flag	ds.l	1
filebuffer	ds.l	1

ace_custom_playtime:
		ds.l	1

;ace_replayer_version:
;		ds.b	5
ace_module_title:
		ds.b	21
ace_module_composer:
		ds.b	21


;====================================================		
		section text