*		High-level manager for MP2 player
*		MP2 plugin for mxPlay - Main()
*		by -XI-/Satantronic
*		version 1   save:0.10   date:19.12.2005   time:21:57

		opt	d-
		comment	HEAD=%0111			;MinimalHeap,MallocInTT-RAM,LoadInTT-RAM,Fastload
		opt	p=68030
		OUTPUT	.MXP

		include	"..\mxplay.inc"


;====================================================
		section text

;---Plugin header:-----------------------------------
mp2_header:	dc.l	"MXP2"
		ds.l	1
		dc.l	mp2_register_module
		dc.l	mp2_get_playtime
		dc.l	0			; mp2_get_songs
		dc.l	mp2_init
		dc.l	mp2_set
		dc.l	0			; mp2_feed
		dc.l	mp2_unset
		dc.l	mp2_deinit
		dc.l	mp2_pause
		dc.l	0			; mp2_mute
		dc.l	mp2_info
		dc.l	mp2_extensions
		dc.l	mp2_settings

;---Register:----------------------------------------
mp2_register_module:
		clr.l	id3v1_flag
		clr.l	id3v2_flag

		movea.l	mp2_header+MXP_PLUGIN_PARAMETER,a0
		move.l	(a0)+,filebuffer
		move.l	(a0)+,filelenght

		move.l	#MXP_PAR_TYPE_INT,d0
		not.l	d0
		and.l	d0,mp2_id3v1_set_track
		ori.l	#MXP_PAR_TYPE_CHAR,mp2_id3v1_set_track

		bsr	mp2_test_id3v2
		bsr	mp2_test_id3v1
start_tests:
mp2_get_freq:	move.l	mp2_filebuffer,a0

		move.l	(a0),d0
		bfextu	d0{20:2},d7

		cmp.l	#0,d7
		beq.s	.f44
		cmp.l	#1,d7
		beq.s	.f48
		cmp.l	#2,d7
		beq.s	.f32
		bra.w	no_MP2
.f32		move.l	#32000,mp2player+MP2_FREQUENCY
		bra.s	.ok
.f44		move.l	#44100,mp2player+MP2_FREQUENCY
		bra.s	.ok
.f48		move.l	#48000,mp2player+MP2_FREQUENCY
.ok:		lsl.l	#6,d7				;for framelenght table

mp2_get_bitrate:
		;move.l	mp2_filebuffer,a0
		;move.l	(a0),d0
		bfextu	d0{16:4},d1
		cmp.l	#$0f,d1
		beq	no_MP2
		lea.l	mpeg1_bitrate,a1
		move.l	(a1,d1.w*4),mp2_bitrate		;bitrate is in kbit/s


;---patch for MP2_INC.BIN---				;skipping blank MPEG frames on start
		;move.l	mp2_filebuffer,a0
		;move.l	(a0),d0
		lea.l	mpeg_framesize,a1
		add.l	d7,a1				;framelenght is frequency depended
		move.l	(a1,d1.w*4),d3			;d3 - lenght of actual mpeg frame
		btst.l	#9,d0				;padding?
		beq.l	.no_padding			;no
		addq.l	#1,d3				;yes => framelenght+1

.no_padding	move.l	d3,d2
		subq.l	#5,d2				;4+1 = lenght of head is 4b, and 1b for dbra
		addq.l	#4,a0				;skip head

.loop		tst.b	(a0)+
		bne	.no_blank
		dbra.w	d2,.loop

		add.l	d3,mp2_filebuffer		;skip blank frame
		bra.w	start_tests			;make all test for next frame (bitrate,lenght,padding,...)
;---end of patch------------


.no_blank:
		move.l	#MXP_FLG_INFOLINE,d0
		not.l	d0
		and.l	d0,mp2_id3v2_set_id3v2
		and.l	d0,mp2_id3v2_set_title
		and.l	d0,mp2_id3v2_set_artist
		and.l	d0,mp2_id3v2_set_album
		and.l	d0,mp2_id3v2_set_year
		and.l	d0,mp2_id3v2_set_comment
		and.l	d0,mp2_id3v2_set_composer
		and.l	d0,mp2_id3v2_set_oriartist
		and.l	d0,mp2_id3v2_set_copyright
		and.l	d0,mp2_id3v2_set_url
		and.l	d0,mp2_id3v2_set_encodedby
		and.l	d0,mp2_id3v2_set_track

		and.l	d0,mp2_id3v1_set_id3v1
		and.l	d0,mp2_id3v1_set_title
		and.l	d0,mp2_id3v1_set_artist
		and.l	d0,mp2_id3v1_set_album
		and.l	d0,mp2_id3v1_set_year
		and.l	d0,mp2_id3v1_set_comment
		and.l	d0,mp2_id3v1_set_track

		ori.l	#MXP_FLG_INFOLINE,mp2_set_file
		ori.l	#MXP_FLG_INFOLINE,mp2_set_type


		move.l	#MXP_FLG_PLG_PARAM,d0
		not.l	d0
		and.l	d0,mp2_id3v2_set_id3v2
		and.l	d0,mp2_id3v2_set_title
		and.l	d0,mp2_id3v2_set_artist
		and.l	d0,mp2_id3v2_set_album
		and.l	d0,mp2_id3v2_set_year
		and.l	d0,mp2_id3v2_set_comment
		and.l	d0,mp2_id3v2_set_composer
		and.l	d0,mp2_id3v2_set_oriartist
		and.l	d0,mp2_id3v2_set_copyright
		and.l	d0,mp2_id3v2_set_url
		and.l	d0,mp2_id3v2_set_encodedby
		and.l	d0,mp2_id3v2_set_track

		and.l	d0,mp2_id3v1_set_id3v1
		and.l	d0,mp2_id3v1_set_title
		and.l	d0,mp2_id3v1_set_artist
		and.l	d0,mp2_id3v1_set_album
		and.l	d0,mp2_id3v1_set_year
		and.l	d0,mp2_id3v1_set_comment
		and.l	d0,mp2_id3v1_set_track

		and.l	d0,mp2_set_file
		and.l	d0,mp2_set_type


		move.l	#MXP_FLG_MOD_PARAM,d0
		not.l	d0
		and.l	d0,mp2_id3v2_set_title
		and.l	d0,mp2_id3v2_set_artist
		and.l	d0,mp2_id3v2_set_album
		and.l	d0,mp2_id3v2_set_year
		and.l	d0,mp2_id3v2_set_comment
		and.l	d0,mp2_id3v2_set_composer
		and.l	d0,mp2_id3v2_set_oriartist
		and.l	d0,mp2_id3v2_set_copyright
		and.l	d0,mp2_id3v2_set_url
		and.l	d0,mp2_id3v2_set_encodedby
		and.l	d0,mp2_id3v2_set_track

		and.l	d0,mp2_id3v1_set_title
		and.l	d0,mp2_id3v1_set_artist
		and.l	d0,mp2_id3v1_set_album
		and.l	d0,mp2_id3v1_set_year
		and.l	d0,mp2_id3v1_set_comment
		and.l	d0,mp2_id3v1_set_track

		and.l	d0,mp2_set_file

		ori.l	#MXP_FLG_MOD_PARAM,mp2_id3v2_set_id3v2
		ori.l	#MXP_FLG_MOD_PARAM,mp2_id3v1_set_id3v1


		cmp.l	#1,id3v2_flag					;SET if ID3v2 exist
		bne	.v1
		move.l	#MXP_FLG_INFOLINE,d0
		not.l	d0
		and.l	d0,mp2_set_file
		;and.l	d0,mp2_set_type

		ori.l	#MXP_FLG_INFOLINE,mp2_id3v2_set_title
		ori.l	#MXP_FLG_INFOLINE,mp2_id3v2_set_artist
		;ori.l	#MXP_FLG_INFOLINE,mp2_id3v2_set_album
		;ori.l	#MXP_FLG_INFOLINE,mp2_id3v2_set_year
		;ori.l	#MXP_FLG_INFOLINE,mp2_id3v2_set_comment
		;ori.l	#MXP_FLG_INFOLINE,mp2_id3v2_set_composer
		;ori.l	#MXP_FLG_INFOLINE,mp2_id3v2_set_oriartist
		;ori.l	#MXP_FLG_INFOLINE,mp2_id3v2_set_copyright
		;ori.l	#MXP_FLG_INFOLINE,mp2_id3v2_set_url
		;ori.l	#MXP_FLG_INFOLINE,mp2_id3v2_set_encodedby
		;ori.l	#MXP_FLG_INFOLINE,mp2_id3v2_set_track

		ori.l	#MXP_FLG_MOD_PARAM,mp2_id3v2_set_title
		ori.l	#MXP_FLG_MOD_PARAM,mp2_id3v2_set_artist
		ori.l	#MXP_FLG_MOD_PARAM,mp2_id3v2_set_album
		ori.l	#MXP_FLG_MOD_PARAM,mp2_id3v2_set_year
		ori.l	#MXP_FLG_MOD_PARAM,mp2_id3v2_set_comment
		ori.l	#MXP_FLG_MOD_PARAM,mp2_id3v2_set_composer
		ori.l	#MXP_FLG_MOD_PARAM,mp2_id3v2_set_oriartist
		ori.l	#MXP_FLG_MOD_PARAM,mp2_id3v2_set_copyright
		ori.l	#MXP_FLG_MOD_PARAM,mp2_id3v2_set_url
		ori.l	#MXP_FLG_MOD_PARAM,mp2_id3v2_set_encodedby
		ori.l	#MXP_FLG_MOD_PARAM,mp2_id3v2_set_track
		bra	.end

.v1		cmp.l	#1,id3v1_flag					;SET if ID3v1 exist
		bne	.end
		move.l	#MXP_FLG_INFOLINE,d0
		not.l	d0
		and.l	d0,mp2_set_file
		;and.l	d0,mp2_set_type

		ori.l	#MXP_FLG_INFOLINE,mp2_id3v1_set_title
		ori.l	#MXP_FLG_INFOLINE,mp2_id3v1_set_artist
		;ori.l	#MXP_FLG_INFOLINE,mp2_id3v1_set_album
		;ori.l	#MXP_FLG_INFOLINE,mp2_id3v1_set_year
		;ori.l	#MXP_FLG_INFOLINE,mp2_id3v1_set_comment
		;ori.l	#MXP_FLG_INFOLINE,mp2_id3v1_set_track

		ori.l	#MXP_FLG_MOD_PARAM,mp2_id3v1_set_title
		ori.l	#MXP_FLG_MOD_PARAM,mp2_id3v1_set_artist
		ori.l	#MXP_FLG_MOD_PARAM,mp2_id3v1_set_album
		ori.l	#MXP_FLG_MOD_PARAM,mp2_id3v1_set_year
		ori.l	#MXP_FLG_MOD_PARAM,mp2_id3v1_set_comment
		ori.l	#MXP_FLG_MOD_PARAM,mp2_id3v1_set_track

.end:		bra	mp2_get_module_type


no_MP2:		moveq	#MXP_ERROR,d0
		rts


;---Check:-------------------------------------------	;only for compatibility with older mxPlay versions ;)
mp2_check_module:
		bsr.w	mp2_get_module_type		; d0 will contain return code
		rts


;---Get play time:-----------------------------------
mp2_get_playtime:
		clr.l	d0
		move.l	mp2_filelenght,d1
			move.l	mp2_bitrate,d2
		mulu.w	#125,d2
		divu.w	d2,d1
		move.w	d1,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts


;---Init:--------------------------------------------
mp2_init:	moveq	#MXP_OK,d0
.exit:		rts


;---Set:---------------------------------------------
mp2_set:	clr.l	stop_flag

		move.l	mp2_filebuffer,mp2player+MP2_ADDRESS
		move.l	mp2_filelenght,mp2player+MP2_LENGTH

		tst.l	mp2_flg_extclock
		beq.s	.noset
		move.l	#44100,mp2player+MP2_EXTERNAL
		bra.s	.cont

.noset		move.l	#0,mp2player+MP2_EXTERNAL

.cont		move.l	#0,mp2player+MP2_REPEAT

		jsr	mp2player+MP2_START(pc)

		moveq	#MXP_OK,d0
		rts


;---Unset:-------------------------------------------
mp2_unset:	jsr	mp2player+MP2_STOP(pc)

		moveq	#MXP_OK,d0
		rts


;---Deinit:------------------------------------------
mp2_deinit:	moveq	#MXP_OK,d0
		rts


;---Module pause:------------------------------------
mp2_pause:	tst.l	stop_flag
		beq.s	.stop
		clr.l	stop_flag		;unpause

		move.w	#0,-(sp)
		move.w	#$77,-(sp)		;$77 - Dsp Hf0() 0-clear 1-set HSR
						;$78 - Dsp Hf1() 0-clear 1-set
		trap	#14
		addq.l	#4,sp

		bra.s	.start

.stop		move.l	#1,stop_flag		;pause
		move.w	#1,-(sp)
		move.w	#$77,-(sp)		;$77 - Dsp Hf0() 0-clear 1-set HSR
						;$78 - Dsp Hf1() 0-clear 1-set
		trap	#14
		addq.l	#4,sp

.start		moveq	#MXP_OK,d0
		rts


;---Subrouts:----------------------------------------
mp2_id3v2_get_module_id3v2:
		lea.l	mp2_module_n_a,a2
		cmp.l	#1,id3v2_flag
		bne.s	.end
		lea.l	mp2_module_yes,a2
.end		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

mp2_id3v2_get_module_title:
		lea.l	mp2_module_n_a,a2
		cmp.l	#1,id3v2_flag
		bne.s	.end
		lea.l	id3v2_TIT2,a2
.end		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

mp2_id3v2_get_module_artist:
		lea.l	mp2_module_n_a,a2
		cmp.l	#1,id3v2_flag
		bne.s	.end
		lea.l	id3v2_TPE1,a2
.end		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

mp2_id3v2_get_module_album:
		lea.l	mp2_module_n_a,a2
		cmp.l	#1,id3v2_flag
		bne.s	.end
		lea.l	id3v2_TALB,a2
.end		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

mp2_id3v2_get_module_year:
		lea.l	mp2_module_n_a,a2
		cmp.l	#1,id3v2_flag
		bne.s	.end
		lea.l	id3v2_TYER,a2
.end		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

mp2_id3v2_get_module_comment:
		lea.l	mp2_module_n_a,a2
		cmp.l	#1,id3v2_flag
		bne.s	.end
		lea.l	id3v2_COMM,a2
		adda.l	#4,a2			;skip 1+3 = Text encoding + Language
.end		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

mp2_id3v2_get_module_composer:
		lea.l	mp2_module_n_a,a2
		cmp.l	#1,id3v2_flag
		bne.s	.end
		lea.l	id3v2_TCOM,a2
.end		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

mp2_id3v2_get_module_oriartist:
		lea.l	mp2_module_n_a,a2
		cmp.l	#1,id3v2_flag
		bne.s	.end
		lea.l	id3v2_TOPE,a2
.end		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

mp2_id3v2_get_module_copyright:
		lea.l	mp2_module_n_a,a2
		cmp.l	#1,id3v2_flag
		bne.s	.end
		lea.l	id3v2_TCOP,a2
.end		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

mp2_id3v2_get_module_url:
		lea.l	mp2_module_n_a,a2
		cmp.l	#1,id3v2_flag
		bne.s	.end
		lea.l	id3v2_WXXX,a2
		adda.l	#1,a2			;skip Text encoding
.end		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

mp2_id3v2_get_module_encodedby:
		lea.l	mp2_module_n_a,a2
		cmp.l	#1,id3v2_flag
		bne.s	.end
		lea.l	id3v2_TENC,a2
.end		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

mp2_id3v2_get_module_track:
		lea.l	mp2_module_n_a,a2
		cmp.l	#1,id3v2_flag
		bne.s	.end
		lea.l	id3v2_TRCK,a2
.end		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts


mp2_id3v1_get_module_id3v1:
		lea.l	mp2_module_n_a,a2
		cmp.l	#1,id3v1_flag
		bne.s	.end
		lea.l	mp2_module_yes,a2
.end		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

mp2_id3v1_get_module_title:
		lea.l	mp2_module_n_a,a2
		cmp.l	#1,id3v1_flag
		bne.s	.end
		lea.l	id3v1_title,a2
.end		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

mp2_id3v1_get_module_artist:
		lea.l	mp2_module_n_a,a2
		cmp.l	#1,id3v1_flag
		bne.s	.end
		lea.l	id3v1_artist,a2
.end		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

mp2_id3v1_get_module_album:
		lea.l	mp2_module_n_a,a2
		cmp.l	#1,id3v1_flag
		bne.s	.end
		lea.l	id3v1_album,a2
.end		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

mp2_id3v1_get_module_year:
		lea.l	mp2_module_n_a,a2
		cmp.l	#1,id3v1_flag
		bne.s	.end
		lea.l	id3v1_year,a2
.end		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

mp2_id3v1_get_module_comment:
		lea.l	mp2_module_n_a,a2
		cmp.l	#1,id3v1_flag
		bne.s	.end
		lea.l	id3v1_comment,a2
.end		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

mp2_id3v1_get_module_track:
		lea.l	mp2_module_n_a,a2
		cmp.l	#1,id3v1_flag
		bne.s	.end
		lea.l	id3v1_track,a1
		adda.l	#2,a1
		tst.b	(a1)
		bne.s	.end
		lea.l	id3v1_track,a1
		movea.l	(a1),a2
.end		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts


mp2_get_module_file:
		lea.l	mp2_module_filename,a2
		move.l	a2,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts


mp2_get_module_type:
		move.l	mp2_filebuffer,a0
		move.w	(a0),d0
		and.w	#$fffe,d0
		cmp.w	#$fffc,d0
		bne.s	.no_MP2

		lea	mp2_formats,a0
		cmp.l	#1,id3v1_flag
		bne.s	.v2
		addq.l	#4,a0
		bra.s	.found
.v2		cmp.l	#1,id3v2_flag
		bne.s	.found
		adda.l	#8,a0

.found:		move.l	(a0),mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

.no_MP2:	moveq	#MXP_ERROR,d0
		rts


mp2_test_id3v1:	movea.l	filebuffer,a0
		move.l	filelenght,d0
		adda.l	d0,a0
		suba.l	#128,a0

		lea.l	id3v1_tag,a1		;have MP2 ID3v1???
		move.w	#3-1,d7
.loop		cmp.b	(a0)+,(a1)+
		bne	.no_id3v1
		dbra.w	d7,.loop

		move.l	#1,id3v1_flag		;if yes, set flag ON

		lea.l	id3v1_title,a1		;if yes, copy this infos into plug.
		move.w	#30-1,d7
.loop1		move.b	(a0)+,(a1)+
		dbra.w	d7,.loop1
		clr.b	(a1)

		lea.l	id3v1_artist,a1
		move.w	#30-1,d7
.loop2		move.b	(a0)+,(a1)+
		dbra.w	d7,.loop2
		clr.b	(a1)

		lea.l	id3v1_album,a1
		move.w	#30-1,d7
.loop3		move.b	(a0)+,(a1)+
		dbra.w	d7,.loop3
		clr.b	(a1)

		lea.l	id3v1_year,a1
		move.w	#4-1,d7
.loop4		move.b	(a0)+,(a1)+
		dbra.w	d7,.loop4
		clr.b	(a1)

		lea.l	id3v1_comment,a1
		move.w	#28-1,d7
.loop5		move.b	(a0)+,(a1)+
		dbra.w	d7,.loop5
		clr.b	(a1)

		tst.b	(a0)
		bne.s	.char

		move.l	#MXP_PAR_TYPE_CHAR,d0
		not.l	d0
		and.l	d0,mp2_id3v1_set_track
		ori.l	#MXP_PAR_TYPE_INT,mp2_id3v1_set_track
		bra.s	.skip

.char		move.l	#MXP_PAR_TYPE_INT,d0
		not.l	d0
		and.l	d0,mp2_id3v1_set_track
		ori.l	#MXP_PAR_TYPE_CHAR,mp2_id3v1_set_track

.skip		lea.l	id3v1_track,a1
		clr.w	(a1)+
		move.w	#2-1,d7
.loop6		move.b	(a0)+,(a1)+
		dbra.w	d7,.loop6
.end		clr.b	(a1)

		move.l	#128,d0			;if yes - correct mp2 lenght
		sub.l	d0,mp2_filelenght
		rts

.no_id3v1	clr.l	id3v1_flag		;if no - end
		rts


mp2_test_id3v2:	movea.l	filebuffer,a0
		lea.l	id3v2_tag,a1		;have MP2 ID3v2???

		move.w	#3-1,d7
.loop		cmp.b	(a0)+,(a1)+
		bne.w	no_id3v2
		dbra.w	d7,.loop

		move.l	#1,id3v2_flag		;if yes, set flag ON

		adda.l	#2,a0			;have ID3v2 foot?
		btst.b	#4,(a0)+
		beq.s	.nofoot
		move.l	#1,id3v2_foot_flag	;yes
		bra.s	.next1
.nofoot		move.l	#0,id3v2_foot_flag	;no

.next1:						;calc. lenght of ID3v2
		btst.b	#7,(a0)+		;before calc.,make test: is all numbers OK?
		bne.w	wrong_lenght
		btst.b	#7,(a0)+
		bne.w	wrong_lenght
		btst.b	#7,(a0)+
		bne.w	wrong_lenght
		btst.b	#7,(a0)+
		bne.w	wrong_lenght
		subq	#4,a0			;yes OK

		clr.l	d0			;calculate lenght of ID3
		move.b	(a0)+,d0
		lsl.l	#7,d0
		add.b	(a0)+,d0
		lsl.l	#7,d0
		add.b	(a0)+,d0
		lsl.l	#7,d0
		add.b	(a0)+,d0
		move.l	d0,id3v2_lenght


		movea.l	filebuffer,a6		;set start of MP2
		move.l	id3v2_lenght,d0
		add.l	#10,d0			;10 - lenght of ID3v2 header
		adda.l	d0,a6
		move.l	a6,mp2_filebuffer

		move.l	filelenght,a6
		suba.l	d0,a6
		move.l	a6,mp2_filelenght


test_frame	lea.l	id3v2_tags,a1		;search tag frames

.nextcmp	cmp.l	(a0)+,(a1)+
		bne.s	.unknown_frm
		clr.l	d5			;known_frame
		bra.s	.ok1

.unknown_frm:	subq.l	#4,a0
		addq.l	#4,a1
		tst.b	(a1)
		bne.s	.nextcmp
		addq.l	#4,a0

		move.l	#1,d5			;d5 - flag -> unknown frame

.ok1		btst.b	#7,(a0)+		;before calc.,make test: is all numbers OK?
		bne.w	wrong_lenght
		btst.b	#7,(a0)+
		bne.w	wrong_lenght
		btst.b	#7,(a0)+
		bne.w	wrong_lenght
		btst.b	#7,(a0)+
		bne.w	wrong_lenght
		subq.l	#4,a0			;yes OK

		clr.l	d0			;calculate lenght of frame
		move.b	(a0)+,d0
		lsl.l	#7,d0
		add.b	(a0)+,d0
		lsl.l	#7,d0
		add.b	(a0)+,d0
		lsl.l	#7,d0
		add.b	(a0)+,d0
		move.l	d0,frame_lenght

		tst.l	d5			;known frame?
		bne.s	.on_next_frm		;no
						;yes - copy content of frame
		move.l	(a1)+,a2
		adda.l	#3,a0			;2+1 = 2b flags + 1b $00


		cmp.l	#$100,frame_lenght	;if is lenght of frame>255 use only 255b
		blo.s	.oki
		move.l	#$ff,d7
		move.l	frame_lenght,d6
		sub.l	#$ff,d6
		move.l	d6,frm_too_long
		bra.s	.ok2

.oki		move.l	frame_lenght,d7
.ok2		subq.l	#2,d7			;move.w	#28-1,d7
.loop6		;tst.b	(a0)
		;beq	.end_of_content
		move.b	(a0)+,(a2)+
		dbra.w	d7,.loop6
		clr.b	(a2)			;terminate string
		bra	next_frame		;skip on test next frame

.end_of_content	clr.b	(a2)			;terminate string
		adda.l	d7,a0
		adda.l	#1,a0
		bra	next_frame

.on_next_frm	add.l	#4,a1			;set next type frame
		adda.l	#2,a0
		adda.l	frame_lenght,a0
next_frame	tst.l	frm_too_long
		beq.s	.ok
		adda.l	frm_too_long,a0
.ok		cmp.l	mp2_filebuffer,a0
		blo	test_frame		;!!! blo text_frame
		rts

wrong_lenght:
no_id3v2	move.l	filebuffer,mp2_filebuffer
		move.l	filelenght,mp2_filelenght
		rts


mp2_get_extclock:
		cmp.l	#1,mp2_flg_extclock
		beq.s	.off

.on:		move.l	#0,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

.off:		move.l	#1,mp2_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts


mp2_set_extclock:
		tst.l	mp2_header+MXP_PLUGIN_PARAMETER
		beq.b	.unset

.set:		move.l	#1,mp2_flg_extclock
		move.l	#44100,mp2player+MP2_EXTERNAL
		moveq	#MXP_OK,d0
		rts

.unset:		clr.l	mp2_flg_extclock
		move.l	#0,mp2player+MP2_EXTERNAL
		moveq	#MXP_OK,d0
		rts


;====================================================
		section	data

MP2_ADDRESS	=	28
MP2_LENGTH	=	32
MP2_FREQUENCY	=	36
MP2_EXTERNAL	=	40
MP2_REPEAT	=	44
MP2_START	=	48
MP2_STOP	=	52

mp2player	incbin	mp2inc.bin
		even

mp2_info:	dc.l	mp2_info_plugin_author
		dc.l	mp2_info_plugin_version
		dc.l	mp2_info_replay_name
		dc.l	mp2_info_replay_author
		dc.l	mp2_info_replay_version
		dc.l	MXP_FLG_USE_DSP|MXP_FLG_USE_DMA|MXP_FLG_USE_020


mp2_settings:
		dc.l	mp2_settings_module_file
mp2_set_file	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	mp2_get_module_file

		dc.l	mp2_settings_module_type
mp2_set_type	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_MOD_PARAM
		dc.l	0
		dc.l	mp2_get_module_type

;--- ID3v2 Tag: ----------------------------------
			dc.l	mp2_id3v2_settings_module_id3v2
mp2_id3v2_set_id3v2	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
			dc.l	0
			dc.l	mp2_id3v2_get_module_id3v2

			dc.l	mp2_id3v2_settings_module_title
mp2_id3v2_set_title	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
			dc.l	0
			dc.l	mp2_id3v2_get_module_title

			dc.l	mp2_id3v2_settings_module_artist
mp2_id3v2_set_artist	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
			dc.l	0
			dc.l	mp2_id3v2_get_module_artist

			dc.l	mp2_id3v2_settings_module_album
mp2_id3v2_set_album	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
			dc.l	0
			dc.l	mp2_id3v2_get_module_album

			dc.l	mp2_id3v2_settings_module_year
mp2_id3v2_set_year	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
			dc.l	0
			dc.l	mp2_id3v2_get_module_year

			dc.l	mp2_id3v2_settings_module_comment
mp2_id3v2_set_comment	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
			dc.l	0
			dc.l	mp2_id3v2_get_module_comment

			dc.l	mp2_id3v2_settings_module_composer
mp2_id3v2_set_composer	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
			dc.l	0
			dc.l	mp2_id3v2_get_module_composer

			dc.l	mp2_id3v2_settings_module_oriartist
mp2_id3v2_set_oriartist	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
			dc.l	0
			dc.l	mp2_id3v2_get_module_oriartist

			dc.l	mp2_id3v2_settings_module_copyright
mp2_id3v2_set_copyright	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
			dc.l	0
			dc.l	mp2_id3v2_get_module_copyright

			dc.l	mp2_id3v2_settings_module_url
mp2_id3v2_set_url	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
			dc.l	0
			dc.l	mp2_id3v2_get_module_url

			dc.l	mp2_id3v2_settings_module_encodedby
mp2_id3v2_set_encodedby	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
			dc.l	0
			dc.l	mp2_id3v2_get_module_encodedby

			dc.l	mp2_id3v2_settings_module_track
mp2_id3v2_set_track	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
			dc.l	0
			dc.l	mp2_id3v2_get_module_track

;--- ID3v1 Tag: ----------------------------------
			dc.l	mp2_id3v1_settings_module_id3v1
mp2_id3v1_set_id3v1	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
			dc.l	0
			dc.l	mp2_id3v1_get_module_id3v1

			dc.l	mp2_id3v1_settings_module_title
mp2_id3v1_set_title	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
			dc.l	0
			dc.l	mp2_id3v1_get_module_title

			dc.l	mp2_id3v1_settings_module_artist
mp2_id3v1_set_artist	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
			dc.l	0
			dc.l	mp2_id3v1_get_module_artist

			dc.l	mp2_id3v1_settings_module_album
mp2_id3v1_set_album	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
			dc.l	0
			dc.l	mp2_id3v1_get_module_album

			dc.l	mp2_id3v1_settings_module_year
mp2_id3v1_set_year	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
			dc.l	0
			dc.l	mp2_id3v1_get_module_year

			dc.l	mp2_id3v1_settings_module_comment
mp2_id3v1_set_comment	dc.l	MXP_PAR_TYPE_CHAR|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
			dc.l	0
			dc.l	mp2_id3v1_get_module_comment

			dc.l	mp2_id3v1_settings_module_track
mp2_id3v1_set_track	dc.l	MXP_PAR_TYPE_INT|MXP_FLG_INFOLINE|MXP_FLG_PLG_PARAM|MXP_FLG_MOD_PARAM
			dc.l	0
			dc.l	mp2_id3v1_get_module_track

			dc.l	mp2_settings_extclock
aon_set_getptim		dc.l	MXP_PAR_TYPE_BOOL|MXP_FLG_PLG_PARAM
			dc.l	mp2_set_extclock
			dc.l	mp2_get_extclock

			dc.l	0


mp2_extensions:	dc.l	mp2_extensions_mod
		dc.l	mp2_extensions_mod_name

		dc.l	0


mp2_formats:	dc.l	mp2_formats_MP2_name
		dc.l	mp2_formats_MP2v1_name
		dc.l	mp2_formats_MP2v2_name


mp2_settings_module_file:
		dc.b	"File",0
mp2_settings_module_type:
		dc.b	"Module type",0
mp2_settings_extclock:
		dc.b	"Ext.clck 44.1kHz",0

mp2_id3v2_settings_module_id3v2:
		dc.b	"ID3v2 Tag",0
mp2_id3v2_settings_module_title:
		dc.b	"v2 Title",0
mp2_id3v2_settings_module_artist:
		dc.b	"v2 Artist",0
mp2_id3v2_settings_module_album:
		dc.b	"v2 Album",0
mp2_id3v2_settings_module_year:
		dc.b	"v2 Year",0
mp2_id3v2_settings_module_comment:
		dc.b	"v2 Comment",0
mp2_id3v2_settings_module_composer:
		dc.b	"v2 Composer",0
mp2_id3v2_settings_module_oriartist:
		dc.b	"v2 Orig. Artist",0
mp2_id3v2_settings_module_copyright:
		dc.b	"v2 Copyright",0
mp2_id3v2_settings_module_url:
		dc.b	"v2 URL",0
mp2_id3v2_settings_module_encodedby:
		dc.b	"v2 Encoded by",0
mp2_id3v2_settings_module_track:
		dc.b	"v2 Track",0

mp2_id3v1_settings_module_id3v1:
		dc.b	"ID3v1 Tag",0
mp2_id3v1_settings_module_title:
		dc.b	"v1 Title",0
mp2_id3v1_settings_module_artist:
		dc.b	"v1 Artist",0
mp2_id3v1_settings_module_album:
		dc.b	"v1 Album",0
mp2_id3v1_settings_module_year:
		dc.b	"v1 Year",0
mp2_id3v1_settings_module_comment:
		dc.b	"v1 Comment",0
mp2_id3v1_settings_module_track:
		dc.b	"v1 Track",0

mp2_info_plugin_author:
		dc.b	"-XI-/Satantronic",0
mp2_info_plugin_version:
		dc.b	"0.10 19.12.2005 (ID3v1+2)",0
mp2_info_replay_name:
		dc.b	"MPEG 1 Audio Layer II",0
mp2_info_replay_author:
		dc.b	"NoBrain/NoCrew",0
mp2_info_replay_version:
		dc.b	"0.997",0


mp2_extensions_mod:
		dc.b	"MP2",0
mp2_extensions_mod_name:
		dc.b	"MP2 module",0


mp2_formats_MP2_name:
		dc.b	"MP2 (MPEG 1 Audio Layer II)",0

mp2_formats_MP2v1_name:
		dc.b	"MP2 (MPEG 1 Audio Layer II) with ID3v1",0

mp2_formats_MP2v2_name:
		dc.b	"MP2 (MPEG 1 Audio Layer II) with ID3v2",0


id3v1_tag	dc.b	"TAG",0
id3v2_tag	dc.b	"ID3",0


mp2_module_filename:
		dc.b	0
mp2_module_n_a:
		dc.b	"n/a",0
mp2_module_yes:
		dc.b	"yes",0

		even
;mp2_frequency:
mpeg1_freq	dc.b	"44100",0
		dc.b	"48000",0
		dc.b	"32000",0
mpeg2_freq	dc.b	"22500",0
		dc.b	"24000",0
		dc.b	"16000",0
		even

mpeg_freq	dc.l	44100,48000,32000,0		;MPEG 1
		dc.l	22500,24000,16000,0		;MPEG 2
		dc.l	11250,12000,8000,0		;MPEG 2.5

mpeg1_bitrate	dc.l	0,32,48,56,64,80,96,112,128,160,192,224,256,320,384,0

mpeg_framesize	dc.l	0,104,156,182,208,261,313,365,417,522,626,731,835,1044,1253,0
		dc.l	0,96,144,168,192,240,288,336,384,480,576,672,768,960,1152,0
		dc.l	0,144,216,252,288,360,432,504,576,720,864,1008,1152,1440,1728,0
		dc.l	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

id3v2_tags	dc.b	"TPE1"
		dc.l	id3v2_TPE1

		dc.b	"TIT2"
		dc.l	id3v2_TIT2

		dc.b	"TALB"
		dc.l	id3v2_TALB

		dc.b	"TYER"
		dc.l	id3v2_TYER

		dc.b	"COMM"
		dc.l	id3v2_COMM

		dc.b	"TRCK"
		dc.l	id3v2_TRCK

		dc.b	"TCOM"
		dc.l	id3v2_TCOM

		dc.b	"TOPE"
		dc.l	id3v2_TOPE

		dc.b	"TCOP"
		dc.l	id3v2_TCOP

		dc.b	"WXXX"
		dc.l	id3v2_WXXX

		dc.b	"TENC"
		dc.l	id3v2_TENC

		dc.b	0

		even
mp2_flg_extclock:
		dc.l	1
		even
;====================================================
		section	bss
		even
stop_flag	ds.l	1
id3v1_flag	ds.l	1
id3v2_flag	ds.l	1
id3v2_foot_flag	ds.l	1
id3v2_lenght	ds.l	1
frame_lenght	ds.l	1
frm_too_long	ds.l	1

filebuffer	ds.l	1
filelenght	ds.l	1
mp2_filebuffer	ds.l	1
mp2_filelenght	ds.l	1
mp2_bitrate	ds.l	1

id3v1_title	ds.b	30+1
id3v1_artist	ds.b	30+1
id3v1_album	ds.b	30+1
id3v1_year	ds.b	4+1
id3v1_comment	ds.b	30+1
id3v1_track	ds.l	1
		ds.b	1

id3v2_TIT2	ds.b	256+1	;Title
id3v2_TPE1	ds.b	256+1	;Artist
id3v2_TALB	ds.b	256+1	;Album
id3v2_TYER	ds.b	4+1	;Year
id3v2_COMM	ds.b	256+1	;Comment
id3v2_TRCK	ds.b	256+1	;Track
id3v2_TCOM	ds.b	256+1	;Composer
id3v2_TOPE	ds.b	256+1	;Orig.Artist
id3v2_TCOP	ds.b	256+1	;Copyright
id3v2_WXXX	ds.b	256+1	;URL
id3v2_TENC	ds.b	256+1	;Encoded by

		even


;====================================================
		section text
