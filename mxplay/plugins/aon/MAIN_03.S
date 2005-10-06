*		High-level manager for AON player
*		AON plugin for mxPlay - Main()
*		by -XI-/Satantronic
*		version 1   save:0.03   date:19.12.2005   time:21:54

		opt	d-
		comment	HEAD=%0111			;MinimalHeap,MallocInTT-RAM,LoadInTT-RAM,Fastload
		opt	p=68030
		OUTPUT	.MXP

		include	"mxp_inc.s"


;====================================================
		section text

;---Plugin header:-----------------------------------
aon_header:
		dc.l	"MXP1"
		ds.l	1
		bra.w	aon_register_module
		bra.w	aon_get_playtime
		bra.w	aon_initt
		bra.w	aon_set
		bra.w	aon_unset
		bra.w	aon_deinit
		bra.w	aon_fwd
		bra.w	aon_rwd
		bra.w	aon_pause
		dc.l	aon_info
		dc.l	aon_extensions
		dc.l	aon_settings


;---Register:----------------------------------------
aon_register_module:

		movea.l	aon_header+MXP_PLUGIN_PARAMETER,a0
		move.l	(a0)+,filebuffer
		move.l	(a0)+,filelenght

start_tests:	jsr	aon_test_param

		move.l	#MXP_FLG_INFOLINE,d0
		not.l	d0
		and.l	d0,aon_set_file
		;and.l	d0,aon_set_type
		and.l	d0,aon_set_title
		and.l	d0,aon_set_artist
		and.l	d0,aon_set_channels
		and.l	d0,aon_set_date
		and.l	d0,aon_set_comment
		and.l	d0,aon_set_info
		and.l	d0,aon_set_getptim

		;ori.l	#MXP_FLG_INFOLINE,aon_set_file
		ori.l	#MXP_FLG_INFOLINE,aon_set_type
		ori.l	#MXP_FLG_INFOLINE,aon_set_title
		ori.l	#MXP_FLG_INFOLINE,aon_set_artist
		;ori.l	#MXP_FLG_INFOLINE,aon_set_channels
		;ori.l	#MXP_FLG_INFOLINE,aon_set_date
		;ori.l	#MXP_FLG_INFOLINE,aon_set_comment
		;ori.l	#MXP_FLG_INFOLINE,aon_set_info
		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_getpti


		move.l	#MXP_FLG_PLG_PARAM,d0
		not.l	d0
		and.l	d0,aon_set_file
		and.l	d0,aon_set_type
		and.l	d0,aon_set_title
		and.l	d0,aon_set_artist
		and.l	d0,aon_set_channels
		and.l	d0,aon_set_date
		and.l	d0,aon_set_comment
		and.l	d0,aon_set_info
		;and.l	d0,aon_set_getptim

		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_file
		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_type
		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_title
		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_artist
		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_channels
		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_date
		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_comment
		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_info
		ori.l	#MXP_FLG_MOD_PARAM,aon_set_getptim


		move.l	#MXP_FLG_MOD_PARAM,d0
		not.l	d0
		and.l	d0,aon_set_file
		;and.l	d0,aon_set_type
		;and.l	d0,aon_set_title
		;and.l	d0,aon_set_artist
		;and.l	d0,aon_set_channels
		;and.l	d0,aon_set_date
		;and.l	d0,aon_set_comment
		and.l	d0,aon_set_info
		and.l	d0,aon_set_getptim

		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_file
		ori.l	#MXP_FLG_MOD_PARAM,aon_set_type
		ori.l	#MXP_FLG_MOD_PARAM,aon_set_title
		ori.l	#MXP_FLG_MOD_PARAM,aon_set_artist
		ori.l	#MXP_FLG_MOD_PARAM,aon_set_channels
		ori.l	#MXP_FLG_MOD_PARAM,aon_set_date
		ori.l	#MXP_FLG_MOD_PARAM,aon_set_comment
		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_info
		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_getpti

ok		moveq	#MXP_OK,d0
		rts

no_AON:		moveq	#MXP_ERROR,d0
		rts


;---Get play time:-----------------------------------
aon_get_playtime:
		move.l	aon_custom_playtime,d0
		bne.b	.ok
		move.l	#3*60,d0				; 03'00"
.ok:		move.l	d0,aon_header+MXP_PLUGIN_PARAMETER	; for calling from settings structure
		rts


;---Set play time:-----------------------------------
aon_set_playtime:
		move.l	aon_header+MXP_PLUGIN_PARAMETER,aon_custom_playtime
		rts


;---Init:--------------------------------------------
aon_initt:	moveq	#MXP_OK,d0
.exit:		rts


;---Set:---------------------------------------------
aon_set:	clr.l	stop_flag
		move.l	filebuffer,a0
		clr.l	d0
		bsr	music_on
		moveq	#MXP_OK,d0
		rts


;---Unset:-------------------------------------------
aon_unset:	bsr	music_off
		moveq	#MXP_OK,d0
		rts

		
;---Deinit:------------------------------------------
aon_deinit:	moveq	#MXP_OK,d0
		rts


;---Module forward:----------------------------------
aon_fwd:	moveq	#MXP_UNIMPLEMENTED,d0
		rts


;---Module rewind:-----------------------------------
aon_rwd:	moveq	#MXP_UNIMPLEMENTED,d0
		rts

		
;---Module pause:------------------------------------
aon_pause:	tst.l	stop_flag
		beq.s	.stopp
		clr.l	stop_flag
		move.w	#1,-(a7)		;protocol (No Handshake)
		move.w	#1,-(a7)		;prescale (1 = 49170 Hz)
		move.w	#0,-(a7)		;srcclk   (0 = 25.175 int.)
		move.w	#%1001,-(a7)		;dst      (8 = DAC, 1 = DMAREC)
		move.w	#1,-(a7)		;src      (1 = DSP-Transmit)
		move.w	#139,-(a7)		;xbios 139, devconnect
		trap	#14
		lea	12(a7),a7
		moveq	#MXP_OK,d0
		rts
		
.stopp		move.l	#1,stop_flag
	        move.w	#1,-(a7)
       		 move.w	#0,-(a7)
       		 move.w	#0,-(a7)
	        move.w	#8,-(a7)		; Dac....
       	 	move.w	#0,-(a7)		; ...connected to nothing
	       	 move.w	#139,-(a7)
       		 trap	#14
	        lea	12(a7),a7
		moveq	#MXP_OK,d0
		rts

;---Subrouts:----------------------------------------
aon_get_module_file:
		lea.l	aon_module_filename,a2
		move.l	a2,aon_header+MXP_PLUGIN_PARAMETER
		rts


aon_get_module_type:
		move.l	filebuffer,a1
		move.l	(a1),d0
		lea.l	aon_formats,a0

		cmp.l	#"AON4",d0
		bne.s	.tst_AON6
		bra	.found

.tst_AON6	cmp.l	#"AON6",d0
		bne.s	.tst_AON8
		addq.l	#4,a0
		bra	.found

.tst_AON8	cmp.l	#"AON8",d0
		bne.s	.no_AON
		adda.l	#8,a0

.found:		move.l	(a0),aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

.no_AON:	moveq	#MXP_ERROR,d0
		rts


aon_get_module_title
		lea.l	aon_strgNAME,a2
		move.l	a2,aon_header+MXP_PLUGIN_PARAMETER
		rts

aon_get_module_artist
		lea.l	aon_strgAUTH,a2
		move.l	a2,aon_header+MXP_PLUGIN_PARAMETER
		rts

aon_get_module_channels
		lea.l	aon_strgChan,a2
		move.l	a2,aon_header+MXP_PLUGIN_PARAMETER
		rts

aon_get_module_date
		lea.l	aon_strgDATE,a2
		move.l	a2,aon_header+MXP_PLUGIN_PARAMETER
		rts

aon_get_module_comment
		lea.l	aon_strgRMRK,a2
		move.l	a2,aon_header+MXP_PLUGIN_PARAMETER
		rts

aon_get_module_info
		lea.l	aon_strgINFO,a2
		move.l	a2,aon_header+MXP_PLUGIN_PARAMETER
		rts


aon_test_param:	move.l	filebuffer,a1
		move.l	(a1),d0
		lea.l	aon_strgChan,a0
		lea.l	aon_formats,a4

		cmp.l	#"AON4",d0
		bne.s	.tst_AON6
		move.b	#"4",(a0)+
		clr.b	(a0)
		bra.s	.next_tst

.tst_AON6	cmp.l	#"AON6",d0
		bne.s	.tst_AON8
		move.b	#"6",(a0)+
		clr.b	(a0)
		addq.l	#4,a4
		bra.s	.next_tst

.tst_AON8	cmp.l	#"AON8",d0
		bne	no_AON
		move.b	#"8",(a0)+
		clr.b	(a0)			;terminate string
		addq.l	#8,a4


.next_tst:	adda.l	#$2e,a1			;start of TAGs space
		lea.l	aon_TAGS,a0

.loop2		cmp.l	#"ARPG",(a1)
		beq.s	.end

		tst.b	(a0)			;end of TAGs?
		beq.s	.skiponnext			;yes -> end

		cmp.l	(a1)+,(a0)+		;test name of TAG
		bne.w	.anotherTAG

		movea.l	(a0)+,a3		;a3 - pointer to string

		move.l	(a1)+,d0		;lenght of TAG
		tst.l	d0			;empty TAG?
		beq.s	.empty_tag			;yes
		movea.l	a1,a2
		adda.l	d0,a1			;skip with A0 on next TAG
		move.l	d0,d7
		and.l	#$ff,d7			;copy only 256 bytes = 256-1
.loop1		move.b	(a2)+,(a3)+
		dbra.w	d7,.loop1
		clr.b	(a3)			;terminate string
		bra.s	.loop2

.end		move.l	(a4),aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

.skiponnext	move.l	(a1)+,d0
		tst.l	d0
		beq.s	.loop2			;empty TAG
		adda.l	d0,a1
		bra.s	.loop2

.empty_tag	lea.l	aon_module_n_a,a5
		move.l	(a5),(a3)
		bra.s	.loop2

.anotherTAG	move.l	(a0)+,a3
		move.l	aon_module_n_a,(a3)
		bra.s	.loop2

		
;--- include source ---------------------------------
		include	"aon-ssi.s"

;====================================================
		section	data

		even

aon_info:	dc.l	aon_info_plugin_author
		dc.l	aon_info_plugin_version
		dc.l	aon_info_replay_name
		dc.l	aon_info_replay_author
		dc.l	aon_info_replay_version
		dc.l	MXP_FLG_USE_DSP|MXP_FLG_USE_DMA|MXP_FLG_PLG_PARAM|MXP_FLG_USE_020


aon_settings:	dc.l	aon_settings_module_file
aon_set_file	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_file

		dc.l	aon_settings_module_type
aon_set_type	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_type

		dc.l	aon_settings_module_title	;NAME
aon_set_title	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_title

		dc.l	aon_settings_module_artist	;AUTH
aon_set_artist	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_artist

		dc.l	aon_settings_module_channels
aon_set_channels	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_channels

		dc.l	aon_settings_module_date	;DATE
aon_set_date	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_date

		dc.l	aon_settings_module_comment	;RMRK
aon_set_comment	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment

		dc.l	aon_settings_module_info	;INFO
aon_set_info	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_info

		dc.l	aon_settings_playtime
aon_set_getptim	dc.l	MXP_PAR_TYPE_INT|MXP_FLG_PLG_PARAM
		dc.l	aon_set_playtime
		dc.l	aon_get_playtime

		dc.l	0


aon_extensions:	dc.l	aon_extensions_mod
		dc.l	aon_extensions_mod_name
		
		dc.l	ao4_extensions_mod
		dc.l	ao4_extensions_mod_name

		dc.l	ao6_extensions_mod
		dc.l	ao6_extensions_mod_name

		dc.l	ao8_extensions_mod
		dc.l	ao8_extensions_mod_name

		dc.l	0


aon_formats:	dc.l	aon_formats_AON4_name
		dc.l	aon_formats_AON6_name
		dc.l	aon_formats_AON8_name


aon_settings_module_file:
		dc.b	"File",0
aon_settings_module_type:
		dc.b	"Module type",0
aon_settings_module_title:
		dc.b	"Title",0
aon_settings_module_artist:
		dc.b	"Artist",0
aon_settings_module_channels:
		dc.b	"Channels",0
aon_settings_module_date:
		dc.b	"Date",0
aon_settings_module_comment:
		dc.b	"Comments",0
aon_settings_module_info:
		dc.b	"Info",0

aon_settings_playtime:
		dc.b	"Playtime",0

		
aon_info_plugin_author:
		dc.b	"-XI-/Satantronic",0
aon_info_plugin_version:
		dc.b	"0.03 19.12.2005",0
aon_info_replay_name:
		dc.b	"Art Of Noise Tracker",0
aon_info_replay_author:
		dc.b	"TaT/Avena",0
aon_info_replay_version:
		dc.b	"1.0",0
		

aon_extensions_mod:
		dc.b	"AON",0
aon_extensions_mod_name:
		dc.b	"AON module",0
ao4_extensions_mod:
		dc.b	"AO4",0
ao4_extensions_mod_name:
		dc.b	"AON4 module",0
ao6_extensions_mod:
		dc.b	"AO6",0
ao6_extensions_mod_name:
		dc.b	"AON6 module",0
ao8_extensions_mod:
		dc.b	"AO8",0
ao8_extensions_mod_name:
		dc.b	"AON8 module",0


aon_formats_AON4_name:
		dc.b	"AON4 (ArtOfNoiseTracker)",0

aon_formats_AON6_name:
		dc.b	"AON6 (ArtOfNoiseTracker)",0

aon_formats_AON8_name:
		dc.b	"AON8 (ArtOfNoiseTracker)",0


aon_module_filename:
		dc.b	0
		even
aon_module_n_a:
		dc.b	"n/a",0


		even
aon_tags	dc.b	"NAME"
		dc.l	aon_strgNAME

		dc.b	"AUTH"
		dc.l	aon_strgAUTH

		dc.b	"DATE"
		dc.l	aon_strgDATE

		dc.b	"RMRK"
		dc.l	aon_strgRMRK

		dc.b	"INFO"
		dc.l	aon_strgINFO

		dc.b	0

		even
;====================================================
		section	bss
		even
stop_flag	ds.l	1
filebuffer	ds.l	1
filelenght	ds.l	1

aon_custom_playtime:
		ds.l	1

aon_strgNAME	ds.b	256+1	;Title
aon_strgAUTH	ds.b	256+1	;Artist
aon_strgDATE	ds.b	256+1	;Date
aon_strgRMRK	ds.b	256+1	;Comment
aon_strgINFO	ds.b	256+1	;Info
aon_strgChan	ds.b	1+1	;Channels
		even


;====================================================
		section text