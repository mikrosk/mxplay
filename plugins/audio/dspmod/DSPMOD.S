
;
; DUMP
;
; May 9, 2005
; Anders Eriksson
; ae@dhs.nu
;
; Odd Skancke
; ozk@atari.org
;
; dspmod.s



dspmod_on:		equ	28
dspmod_off:		equ	32
dspmod_playeron:	equ	36
dspmod_playeroff:	equ	40
dspmod_playmusic:	equ	44
dspmod_playtime:	equ	48
dspmod_modtype:		equ	52
dspmod_fx:		equ	56
dspmod_not_used:	equ	60
dspmod_flags:		equ	61
dspmod_surrounddelay:	equ	62
dspmod_dsptracks:	equ	64
dspmod_playinfos:	equ	66
dspmod_samplesets:	equ	70

		section	text

dspmod_play_module:
		movea.l	dspmod_buffer,a0
		move.l	1080(a0),d0

		move.l	#"M.K.",d1
		cmp.l	d0,d1
		beq.w	.four
		move.l	#"M!K!",d1
		cmp.l	d0,d1
		beq.w	.four
		move.l	#"M&K&",d1
		cmp.l	d0,d1
		beq.w	.four
		move.l	#"FLT4",d1
		cmp.l	d0,d1
		beq.w	.four
		move.l	#"RASP",d1
		cmp.l	d0,d1
		beq.b	.four
		move.l	#"FA04",d1
		cmp.l	d0,d1
		beq.b	.four
		move.l	#"6CHN",d1
		cmp.l	d0,d1
		beq.b	.six
		move.l	#"CD61",d1
		cmp.l	d0,d1
		beq.b	.six
		move.l	#"06CH",d1
		cmp.l	d0,d1
		beq.b	.six
		move.l	#"FA06",d1
		cmp.l	d0,d1
		beq.b	.six
		move.l	#"8CHN",d1
		cmp.l	d0,d1
		beq.b	.eight
		move.l	#"CD81",d1
		cmp.l	d0,d1
		beq.b	.eight
		move.l	#"FLT8",d1
		cmp.l	d0,d1
		beq.b	.eight
		move.l	#"08CH",d1
		cmp.l	d0,d1
		beq.b	.eight
		move.l	#"OCTA",d1
		cmp.l	d0,d1
		beq.b	.eight
		move.l	#"FA08",d1
		cmp.l	d0,d1
		beq.b	.eight

.four:		move.l	#"M.K.",1080(a0)			;put general 4ch header
		move.b	#'4',dspmod_channels
		bra.b	.skip

.six:		move.l	#"CD61",1080(a0)			;put general 6ch header
		move.b	#'6',dspmod_channels
		bra.b	.skip

.eight:		move.l	#"CD81",1080(a0)			;put general 8ch header
		move.b	#'8',dspmod_channels

.skip:		lea.l	dspmod_voltab4,a1			;4channel volumetable
		bsr.w	dspmod_player+dspmod_modtype	;check mod type
		cmp.w	#4,d0					;if 4, start module
		beq.s	.ok					;
		lea.l	dspmod_voltab8,a1			;otherwise, use 8channel table

.ok:		bsr.w	dspmod_player+dspmod_playeron 	;start playing
		rts


dspmod_vbl:
		bsr.w	dspmod_player+44			;call player
		rts



dspmod_start:
		bsr.w	dspmod_player+dspmod_on 		;install player
		move.l	a0,dspmod_version

		move.w	#$200b,$ffff8932.w 			;DSP-Out-> DAC & DMA-In
		clr.b	$ffff8900.w     			;no DMA-Interrupts
		clr.b	$ffff8936.w     			;record 1 track
		move.b	#$40,$ffff8921.w 			;16 Bit

		move.b	#$80,$ffff8901.w 			;select record-frame-register
		move.l	dma_pointer,d0				;
		move.l	d0,d1					;
		move.b	d1,$ffff8907.w  			;Basis Low
		lsr.l	#8,d1					;
		move.b	d1,$ffff8905.w  			;Basis Mid
		lsr.l	#8,d1					;
		move.b	d1,$ffff8903.w  			;Basis High
		add.l	#8000,d0				;
		move.l	d0,d1					;
		move.b	d1,$ffff8913.w  			;End Low
		lsr.l	#8,d1					;
		move.b	d1,$ffff8911.w  			;End Mid
		lsr.l	#8,d1					;
		move.b	d1,$ffff890f.w  			;End High

		move.b	#$b0,$ffff8901.w 			;repeated record

		rts


dspmod_stop:
		clr.b	$ffff8901.w     			;DMA-Stop
		bsr.w	dspmod_player+dspmod_playeroff		;stop module
		bsr.w	dspmod_player+dspmod_off		;dsp system off
		rts

; Hello, evl.
; I was told that this program didnt work with XaAES - after starting this
; program, mouse clicks didnt work at all. Now, out of curiosity I looked
; at the sources, and what do I find? Yeah, you forcefeed your handler into
; a specific position, which, as luck will have it, works under n.aes.
; Extremely lucky indeed that no other apps use this list while using
; Dump.ttp ,-))
; XaAES, however, or rather moose.adi, also installs a vbl handler in the
; deferred vbl handler list, which was overwritten here. And when moose
; dont have any notion of time, it takes a VERY LONG time for it to timeout
; and deliver clicks to XaAES ;-))
;
; However, I have changed it so that it now works with XaAES, and in all
; cases other applications also wants a handler in the deferred vbl list,
; see below.
;
; Ozk

dspmod_end:	move.l	#dspmod_vbl,d0				;address of vbl function to...
		bsr.w	dspmod_deinstall_vbi			;..deinstall.
		;clr.l	$04d2.w					;remove vbl routine
		bsr.w	dspmod_stop				;stop player and restore dsp
		bsr.w	restoreaudio				;restore audio hardware
		rts



dspmod_begin:	bsr.w	saveaudio				;save audio hardware
		bsr.w	dspmod_start				;init dspmod
		bsr.w	dspmod_play_module			;start player
		move.l	#dspmod_vbl,d0				;address of vbl handler..
		bsr.w	dspmod_install_vbi			;..to install
		;move.l	#dspmod_vbl,$04d2.w			;place routine on vbl
		rts

; There is a pointer to a list of "deferred vbl handlers" at
; address $0456. The size of this list (in pointers) are found
; in $0454. The routines 'dspmod_install_vbi' and 'dspmod_desintall_vbi'
; correctly installs/deinstalls such handlers... almost. The only thing
; missing is creating a larger list if there are no free space left in
; list.

; -> D0 Function to install.
; <- D0 If successful, D0 still contains address of function.
;       If unsucessful, D0 is cleared.
dspmod_install_vbi:
		movem.l	d1/a0,-(sp)
		move.w	$0454.w,d1
		subq.w	#1,d1
		move.l	$0456.w,a0

.search:	tst.l	(a0)+
		beq.s	.found
		dbra	d1,.search
		bra.s	.fail
.found:		move.l	d0,-(a0)
		bra.s	.exit
.fail:		moveq	#0,d0
.exit:		movem.l	(sp)+,d1/a0
		rts

; -> D0 Function to deinstall.
; <- D0 If successful, D0 still contains address of function.
;       If unsucessful, D0 is cleared.
dspmod_deinstall_vbi:
		movem.l	d1/a0,-(sp)
		move.w	$0454.w,d1
		subq.w	#1,d1
		move.l	$0456.w,a0

.search:	cmp.l	(a0)+,d0
		beq.s	.found
		dbra	d1,.search
		bra.s	.fail
.found:		clr.l	-(a0)
		bra.s	.exit
.fail:		moveq	#0,d0
.exit:		movem.l	(sp)+,d1/a0
		rts


saveaudio:	lea.l	saveaudiobuf,a0
		move.w	$ffff8930.w,(a0)+
		move.w	$ffff8932.w,(a0)+
		move.b	$ffff8934.w,(a0)+
		move.b	$ffff8935.w,(a0)+
		move.b	$ffff8936.w,(a0)+
		move.b	$ffff8937.w,(a0)+
		move.b	$ffff8938.w,(a0)+
		move.b	$ffff8939.w,(a0)+
		move.w	$ffff893a.w,(a0)+
		move.b	$ffff893c.w,(a0)+
		move.b	$ffff8941.w,(a0)+
		move.b	$ffff8943.w,(a0)+
		move.b	$ffff8900.w,(a0)+
		move.b	$ffff8901.w,(a0)+
		move.b	$ffff8920.w,(a0)+
		move.b	$ffff8921.w,(a0)+
		rts

restoreaudio:	lea.l	saveaudiobuf,a0
		move.w	(a0)+,$ffff8930.w
		move.w	(a0)+,$ffff8932.w
		move.b	(a0)+,$ffff8934.w
		move.b	(a0)+,$ffff8935.w
		move.b	(a0)+,$ffff8936.w
		move.b	(a0)+,$ffff8937.w
		move.b	(a0)+,$ffff8938.w
		move.b	(a0)+,$ffff8939.w
		move.w	(a0)+,$ffff893a.w
		move.b	(a0)+,$ffff893c.w
		move.b	(a0)+,$ffff8941.w
		move.b	(a0)+,$ffff8943.w
		move.b	(a0)+,$ffff8900.w
		move.b	(a0)+,$ffff8901.w
		move.b	(a0)+,$ffff8920.w
		move.b	(a0)+,$ffff8921.w
		rts

dspmod_get_version:
		lea	dspmod_info,a0
		move.l	dspmod_version,(mxp_struct_info_replay_version,a0)
		rts

dspmod_get_interpolation:
		btst	#1,dspmod_player+dspmod_flags
		beq.b	.off

.on:		move.l	#1,dspmod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

.off:		move.l	#0,dspmod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

dspmod_set_interpolation:
		tst.l	dspmod_header+MXP_PLUGIN_PARAMETER
		beq.b	.unset

.set:		bset	#1,dspmod_player+dspmod_flags
		moveq	#MXP_OK,d0
		rts

.unset:		bclr	#1,dspmod_player+dspmod_flags
		moveq	#MXP_OK,d0
		rts

dspmod_get_surround:
		btst	#0,dspmod_player+dspmod_flags
		beq.b	.off

.on:		move.l	#1,dspmod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

.off:		move.l	#0,dspmod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

dspmod_set_surround:
		tst.l	dspmod_header+MXP_PLUGIN_PARAMETER
		beq.b	.unset

.set:		bset	#0,dspmod_player+dspmod_flags
		moveq	#MXP_OK,d0
		rts

.unset:		bclr	#0,dspmod_player+dspmod_flags
		moveq	#MXP_OK,d0
		rts

dspmod_get_module_name:
		move.l	dspmod_buffer,a0
		lea	dspmod_module_name,a1
		moveq	#20-1,d0
.loop:		move.b	(a0)+,(a1)+
		dbra	d0,.loop
		clr.b	(a1)				; terminate it (for sure)

		move.l	#dspmod_module_name,dspmod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

dspmod_get_module_channels:
		move.l	#dspmod_channels,dspmod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

dspmod_get_module_type:
		movea.l	dspmod_buffer,a0
		move.l	1080(a0),d0
		lea	dspmod_formats,a0
.loop:		movea.l	(a0)+,a1			; 'format' address
		tst.l	a1				; NULL?
		beq.b	.not_found
		cmp.l	(a1),d0
		beq.b	.found
		addq.l	#4,a0				; skip 'name' address
		bra.b	.loop

.found:		move.l	(a0),dspmod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

.not_found:	moveq	#MXP_ERROR,d0
		rts

dspmod_calc_playtime:
		movea.l	dspmod_buffer,a0
		bsr.w	dspmod_player+dspmod_playtime

		clr.l	d2				; d0.w: $MMSS (in BCD)
		clr.l	d3

		move.b	d0,d1				; d1.b: $SS
		and.b	#$0f,d1				; d1.b: $0S
		move.b	d1,d2

		lsr.w	#4,d0				; d0.w: $0MMS
		move.b	d0,d1				; d1.b: $MS
		and.b	#$0f,d1				; d1.b: $0S
		mulu.w	#10,d1
		add.l	d1,d2

		lsr.w	#4,d0				; d0.w: $00MM
		move.b	d0,d1				; d1.b: $MM
		and.b	#$0f,d1				; d1.b: $0M
		move.b	d1,d3

		lsr.w	#4,d0				; d0.w: $000M
		mulu.w	#10,d0
		add.l	d0,d3

		mulu.w	#60,d3				; mins * 60 = seconds
		add.l	d3,d2

		move.l	d2,dspmod_header+MXP_PLUGIN_PARAMETER
		moveq	#MXP_OK,d0
		rts

		section	data

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
		even

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
		even

		section	text
