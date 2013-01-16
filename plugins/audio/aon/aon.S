*		High-level manager for AON player
*		AON plugin for mxPlay - Main()
*		by -XI-/Satantronic
*		version 1   save:0.03b   date:02.01.2006   time:00:27
*               version 0.04 by MiKRO / Mystic Bytes (comments added)

		OPT	D-,NOCASE
		OPT	P=68030				; 68030 code allowed
		COMMENT	HEAD=%111			; MallocInTT-RAM,LoadInTT-RAM,Fastload

		INCLUDE	"../mxplay.inc"

COMMENTS_COUNT	EQU	48


;====================================================

;---Plugin header:-----------------------------------
aon_header:	dc.l	"MXP2"
		ds.l	1
		dc.l	aon_register_module
		dc.l	0			; aon_get_playtime
		dc.l	0			; aon_get_songs
		dc.l	aon_initt
		dc.l	aon_set
		dc.l	0			; aon_feed
		dc.l	aon_unset
		dc.l	aon_deinit
		dc.l	aon_pause
		dc.l	0			; aon_mute
		dc.l	aon_info
		dc.l	aon_extensions
		dc.l	aon_settings


;---Register:----------------------------------------
aon_register_module:

		movea.l	aon_header+MXP_PLUGIN_PARAMETER,a0
		move.l	(a0)+,filebuffer
		move.l	(a0)+,filelenght

start_tests:	;jsr	aon_test_param

		move.l	#MXP_FLG_INFOLINE,d0
		not.l	d0
		and.l	d0,aon_set_file
		;and.l	d0,aon_set_type
		and.l	d0,aon_set_title
		and.l	d0,aon_set_artist
		and.l	d0,aon_set_channels
		and.l	d0,aon_set_date
		and.l	d0,aon_set_info

		;ori.l	#MXP_FLG_INFOLINE,aon_set_file
		ori.l	#MXP_FLG_INFOLINE,aon_set_type
		ori.l	#MXP_FLG_INFOLINE,aon_set_title
		ori.l	#MXP_FLG_INFOLINE,aon_set_artist
		;ori.l	#MXP_FLG_INFOLINE,aon_set_channels
		;ori.l	#MXP_FLG_INFOLINE,aon_set_date
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
		and.l	d0,aon_set_info

		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_file
		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_type
		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_title
		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_artist
		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_channels
		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_date
		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_info


		move.l	#MXP_FLG_MOD_PARAM,d0
		not.l	d0
		and.l	d0,aon_set_file
		;and.l	d0,aon_set_type
		;and.l	d0,aon_set_title
		;and.l	d0,aon_set_artist
		;and.l	d0,aon_set_channels
		;and.l	d0,aon_set_date
		and.l	d0,aon_set_info

		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_file
		ori.l	#MXP_FLG_MOD_PARAM,aon_set_type
		ori.l	#MXP_FLG_MOD_PARAM,aon_set_title
		ori.l	#MXP_FLG_MOD_PARAM,aon_set_artist
		ori.l	#MXP_FLG_MOD_PARAM,aon_set_channels
		ori.l	#MXP_FLG_MOD_PARAM,aon_set_date
		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_info
		;ori.l	#MXP_FLG_MOD_PARAM,aon_set_getpti

		lea	aon_delimiter,a0		; fill delimiter field with '-'
		move.w	#255-1,d7
.loop:		move.b	#'-',(a0)+
		dbra	d7,.loop

ok		moveq	#MXP_OK,d0
		rts

no_AON:		moveq	#MXP_ERROR,d0
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
		moveq	#MXP_OK,d0
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
		moveq	#MXP_OK,d0
		rts

aon_get_module_artist
		lea.l	aon_strgAUTH,a2
		move.l	a2,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_channels
		lea.l	aon_strgChan,a2
		move.l	a2,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_date
		lea.l	aon_strgDATE,a2
		move.l	a2,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_info
		lea.l	aon_strgINFO,a2
		move.l	a2,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_delimiter:
		move.l	#aon_delimiter,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment1:
		move.l	aon_comment1,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment2:
		move.l	aon_comment2,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment3:
		move.l	aon_comment3,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment4:
		move.l	aon_comment4,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment5:
		move.l	aon_comment5,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment6:
		move.l	aon_comment6,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment7:
		move.l	aon_comment7,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment8:
		move.l	aon_comment8,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment9:
		move.l	aon_comment9,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment10:
		move.l	aon_comment10,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment11:
		move.l	aon_comment11,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment12:
		move.l	aon_comment12,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment13:
		move.l	aon_comment13,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment14:
		move.l	aon_comment14,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment15:
		move.l	aon_comment15,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment16:
		move.l	aon_comment16,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment17:
		move.l	aon_comment17,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment18:
		move.l	aon_comment18,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment19:
		move.l	aon_comment19,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment20:
		move.l	aon_comment20,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment21:
		move.l	aon_comment21,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment22:
		move.l	aon_comment22,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment23:
		move.l	aon_comment23,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment24:
		move.l	aon_comment24,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment25:
		move.l	aon_comment25,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment26:
		move.l	aon_comment26,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment27:
		move.l	aon_comment27,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment28:
		move.l	aon_comment28,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment29:
		move.l	aon_comment29,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment30:
		move.l	aon_comment30,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment31:
		move.l	aon_comment31,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment32:
		move.l	aon_comment32,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment33:
		move.l	aon_comment33,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment34:
		move.l	aon_comment34,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment35:
		move.l	aon_comment35,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment36:
		move.l	aon_comment36,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment37:
		move.l	aon_comment37,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment38:
		move.l	aon_comment38,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment39:
		move.l	aon_comment39,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment40:
		move.l	aon_comment40,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment41:
		move.l	aon_comment41,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment42:
		move.l	aon_comment42,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment43:
		move.l	aon_comment43,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment44:
		move.l	aon_comment44,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment45:
		move.l	aon_comment45,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment46:
		move.l	aon_comment46,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment47:
		move.l	aon_comment47,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

aon_get_module_comment48:
		move.l	aon_comment48,aon_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts


aon_test_param:	lea	aon_module_comments+4,a3	; offset to parameter type
		move.w	#COMMENTS_COUNT-1,d7

.loop0:		clr.l	(a3)
		lea	(4*4,a3),a3			; sizeof(mxp_struct_settings)
		dbra	d7,.loop0

		move.l	filebuffer,a1
		;lea	modxxx,a1

		move.l	(a1),d0
		lea.l	aon_strgChan,a0

		cmp.l	#"AON4",d0
		bne.s	.tst_AON6
		move.b	#"4",(a0)+
		clr.b	(a0)
		bra.s	.next_tst

.tst_AON6	cmp.l	#"AON6",d0
		bne.s	.tst_AON8
		move.b	#"6",(a0)+
		clr.b	(a0)
		bra.s	.next_tst

.tst_AON8	cmp.l	#"AON8",d0
		bne	no_AON
		move.b	#"8",(a0)+
		clr.b	(a0)			;terminate string


.next_tst:	adda.l	#$2e,a1			;start of TAGs space
		lea.l	aon_TAGS,a0

.loop2		cmp.l	#"ARPG",(a1)
		beq.s	.end

		cmp.l	#"RMRK",(a1)
		bne.b	.no_comment
		tst.l	4(a1)
		bne.w	.parse_comment

		addq.l	#8,a1
		bra.b	.loop2			; zero length

.no_comment:	tst.b	(a0)			;end of TAGs?
		beq.s	.skiponnext		;yes -> end

		cmp.l	(a1)+,(a0)+		;test name of TAG
		bne.w	.anotherTAG

		movea.l	(a0)+,a3		;a3 - pointer to string

		move.l	(a1)+,d0		;lenght of TAG
		tst.l	d0			;empty TAG?
		beq.s	.empty_tag		;yes
		movea.l	a1,a2
		adda.l	d0,a1			;skip with A0 on next TAG
		move.l	d0,d7

		subq.l	#1,d7

		and.l	#$ffffff00,d7
		tst.l	d7
		beq.s	.short
		move.l	#$fe,d7			;copy only 255 bytes
		bra.s	.loop1

.short		move.l	d0,d7
		subq.l	#1,d7

.loop1		move.b	(a2)+,(a3)+
		dbra.w	d7,.loop1
		clr.b	(a3)			;terminate string
		bra.s	.loop2

.end		moveq	#MXP_OK,d0
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

; parse comment from module
; we know its size it's >= 1

.parse_comment:
		move.l	a0,-(sp)

		movea.l	a1,a0
		addq.l	#4,a0				; skip 'RMRK'
		move.l	(a0)+,d5			; length of comment

		;bra.w	.loop5				; ignore comments

		lea	aon_comments,a1
		lea	aon_comments_pointers,a2
		lea	aon_module_comments+4,a3	; offset to parameter type

		move.w	#COMMENTS_COUNT-1,d7

.loop3:		move.l	a1,(a2)+			; save pointer
		move.l	#MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM,(a3)
		lea	(4*4,a3),a3			; sizeof(mxp_struct_settings)

		move.w	#255-1,d6			; max 255 chars + terminator

.loop4:		move.b	(a0)+,d0

		cmp.b	#$0a,d0				; Line Feed ?
		bne.b	.no_term

		cmp.w	#255-1,d6			; are we on the begin of the line?
		bne.b	.no_begin

		move.b	#' ',(a1)+			; at least one space char

.no_begin:	clr.b	d0				; terminate it
		bra.b	.printable

.no_term:	cmp.b	#$09,d0
		beq.b	.tab

		tst.b	d0				; if '\0', insert one space
		bne.b	.printable

		move.b	#' ',(a1)+
		bra.b	.printable

.tab:		move.w	#255-1,d1
		sub.w	d6,d1
		andi.w	#$07,d1				; modulo 8

		sub.w	#8,d1
		neg.w	d1				; 8 - (delta modulo 8)

		sub.w	d1,d6
		addq.w	#1,d6

		subq.w	#1,d1
		bpl.b	.tab_start
		move.w	#8-1,d1

.tab_start:	subq.w	#1,d1
		bmi.b	.tab_skip

.tab_loop:	move.b	#' ',(a1)+
		dbra	d1,.tab_loop

.tab_skip:	move.b	#' ',d0				; replace non-printable chars by ' '

.printable:	move.b	d0,(a1)+

		subq.l	#1,d5
		beq.b	.end_comment			; terminate it with \0

		tst.b	d0				; was the last char \0 ?
		dbeq	d6,.loop4			; if \0 stored or 255 chars -> end

		beq.b	.terminated			; already terminated

.not_terminated:
		cmpi.b	#$0a,(a1)+			; reached 255 chars, look for next line
		beq.b	.terminated			; LF found
		subq.l	#1,d5
		bne.b	.not_terminated
		bra.b	.parse_end

.end_comment:	clr.b	(a1)+				; if 255 chars -> store \0 as 256th char
		tst.l	d5				; on the end?
		beq.b	.parse_end

.terminated:	dbra	d7,.loop3

.loop5:		addq.l	#1,a0				; we reached total comments count
		subq.l	#1,d5				; but there are still some data to parse
		bne.b	.loop5

.parse_end:	movea.l	a0,a1
		movea.l	(sp)+,a0
		bra.w	.loop2


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

		dc.l	aon_settings_module_info	;INFO
aon_set_info	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_info

		dc.l	0

		; Comment

		dc.l	aon_delimiter
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_delimiter

aon_module_comments:
		dc.l	aon_module_comment1
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment1

		dc.l	aon_module_comment2
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment2

		dc.l	aon_module_comment3
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment3

		dc.l	aon_module_comment4
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment4

		dc.l	aon_module_comment5
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment5

		dc.l	aon_module_comment6
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment6

		dc.l	aon_module_comment7
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment7

		dc.l	aon_module_comment8
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment8

		dc.l	aon_module_comment9
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment9

		dc.l	aon_module_comment10
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment10

		dc.l	aon_module_comment11
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment11

		dc.l	aon_module_comment12
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment12

		dc.l	aon_module_comment13
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment13

		dc.l	aon_module_comment14
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment14

		dc.l	aon_module_comment15
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment15

		dc.l	aon_module_comment16
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment16

		dc.l	aon_module_comment17
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment17

		dc.l	aon_module_comment18
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment18

		dc.l	aon_module_comment19
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment19

		dc.l	aon_module_comment20
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment20

		dc.l	aon_module_comment21
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment21

		dc.l	aon_module_comment22
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment22

		dc.l	aon_module_comment23
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment23

		dc.l	aon_module_comment24
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment24

		dc.l	aon_module_comment25
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment25

		dc.l	aon_module_comment26
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment26

		dc.l	aon_module_comment27
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment27

		dc.l	aon_module_comment28
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment28

		dc.l	aon_module_comment29
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment29

		dc.l	aon_module_comment30
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment30

		dc.l	aon_module_comment31
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment31

		dc.l	aon_module_comment32
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment32

		dc.l	aon_module_comment33
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment33

		dc.l	aon_module_comment34
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment34

		dc.l	aon_module_comment35
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment35

		dc.l	aon_module_comment36
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment36

		dc.l	aon_module_comment37
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment37

		dc.l	aon_module_comment38
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment38

		dc.l	aon_module_comment39
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment39

		dc.l	aon_module_comment40
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment40

		dc.l	aon_module_comment41
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment41

		dc.l	aon_module_comment42
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment42

		dc.l	aon_module_comment43
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment43

		dc.l	aon_module_comment44
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment44

		dc.l	aon_module_comment45
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment45

		dc.l	aon_module_comment46
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment46

		dc.l	aon_module_comment47
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment47

		dc.l	aon_module_comment48
		dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	aon_get_module_comment48

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


aon_info_plugin_author:
		dc.b	"-XI-/Satantronic",0
aon_info_plugin_version:
		dc.b	"0.04 02.01.2006",0
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

aon_module_comment1:
		dc.b	"Comment #1",0
aon_module_comment2:
		dc.b	"Comment #2",0
aon_module_comment3:
		dc.b	"Comment #3",0
aon_module_comment4:
		dc.b	"Comment #4",0
aon_module_comment5:
		dc.b	"Comment #5",0
aon_module_comment6:
		dc.b	"Comment #6",0
aon_module_comment7:
		dc.b	"Comment #7",0
aon_module_comment8:
		dc.b	"Comment #8",0
aon_module_comment9:
		dc.b	"Comment #9",0
aon_module_comment10:
		dc.b	"Comment #10",0
aon_module_comment11:
		dc.b	"Comment #11",0
aon_module_comment12:
		dc.b	"Comment #12",0
aon_module_comment13:
		dc.b	"Comment #13",0
aon_module_comment14:
		dc.b	"Comment #14",0
aon_module_comment15:
		dc.b	"Comment #15",0
aon_module_comment16:
		dc.b	"Comment #16",0
aon_module_comment17:
		dc.b	"Comment #17",0
aon_module_comment18:
		dc.b	"Comment #18",0
aon_module_comment19:
		dc.b	"Comment #19",0
aon_module_comment20:
		dc.b	"Comment #20",0
aon_module_comment21:
		dc.b	"Comment #21",0
aon_module_comment22:
		dc.b	"Comment #22",0
aon_module_comment23:
		dc.b	"Comment #23",0
aon_module_comment24:
		dc.b	"Comment #24",0
aon_module_comment25:
		dc.b	"Comment #25",0
aon_module_comment26:
		dc.b	"Comment #26",0
aon_module_comment27:
		dc.b	"Comment #27",0
aon_module_comment28:
		dc.b	"Comment #28",0
aon_module_comment29:
		dc.b	"Comment #29",0
aon_module_comment30:
		dc.b	"Comment #30",0
aon_module_comment31:
		dc.b	"Comment #31",0
aon_module_comment32:
		dc.b	"Comment #32",0
aon_module_comment33:
		dc.b	"Comment #33",0
aon_module_comment34:
		dc.b	"Comment #34",0
aon_module_comment35:
		dc.b	"Comment #35",0
aon_module_comment36:
		dc.b	"Comment #36",0
aon_module_comment37:
		dc.b	"Comment #37",0
aon_module_comment38:
		dc.b	"Comment #38",0
aon_module_comment39:
		dc.b	"Comment #39",0
aon_module_comment40:
		dc.b	"Comment #40",0
aon_module_comment41:
		dc.b	"Comment #41",0
aon_module_comment42:
		dc.b	"Comment #42",0
aon_module_comment43:
		dc.b	"Comment #43",0
aon_module_comment44:
		dc.b	"Comment #44",0
aon_module_comment45:
		dc.b	"Comment #45",0
aon_module_comment46:
		dc.b	"Comment #46",0
aon_module_comment47:
		dc.b	"Comment #47",0
aon_module_comment48:
		dc.b	"Comment #48",0

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

aon_strgNAME	ds.b	255+1	;Title
aon_strgAUTH	ds.b	255+1	;Artist
aon_strgDATE	ds.b	255+1	;Date
aon_strgINFO	ds.b	255+1	;Info
aon_strgChan	ds.b	1+1	;Channels

aon_comments:	ds.b	COMMENTS_COUNT*(255+1)	;Comment (#comments * one line)

; pointer table
aon_comments_pointers:

aon_comment1:	ds.l	1
aon_comment2:	ds.l	1
aon_comment3:	ds.l	1
aon_comment4:	ds.l	1
aon_comment5:	ds.l	1
aon_comment6:	ds.l	1
aon_comment7:	ds.l	1
aon_comment8:	ds.l	1
aon_comment9:	ds.l	1
aon_comment10:	ds.l	1
aon_comment11:	ds.l	1
aon_comment12:	ds.l	1
aon_comment13:	ds.l	1
aon_comment14:	ds.l	1
aon_comment15:	ds.l	1
aon_comment16:	ds.l	1
aon_comment17:	ds.l	1
aon_comment18:	ds.l	1
aon_comment19:	ds.l	1
aon_comment20:	ds.l	1
aon_comment21:	ds.l	1
aon_comment22:	ds.l	1
aon_comment23:	ds.l	1
aon_comment24:	ds.l	1
aon_comment25:	ds.l	1
aon_comment26:	ds.l	1
aon_comment27:	ds.l	1
aon_comment28:	ds.l	1
aon_comment29:	ds.l	1
aon_comment30:	ds.l	1
aon_comment31:	ds.l	1
aon_comment32:	ds.l	1
aon_comment33:	ds.l	1
aon_comment34:	ds.l	1
aon_comment35:	ds.l	1
aon_comment36:	ds.l	1
aon_comment37:	ds.l	1
aon_comment38:	ds.l	1
aon_comment39:	ds.l	1
aon_comment40:	ds.l	1
aon_comment41:	ds.l	1
aon_comment42:	ds.l	1
aon_comment43:	ds.l	1
aon_comment44:	ds.l	1
aon_comment45:	ds.l	1
aon_comment46:	ds.l	1
aon_comment47:	ds.l	1
aon_comment48:	ds.l	1

aon_delimiter:	ds.b	255+1

		even
dummy_buffer		ds.l 49170/50*2
