; Graoumf Is Not So Damn Slow
;
; loader.s
;
; July 26, 2001
;
; Anders Eriksson
; ae@dhs.nu

		section	text

loader:		move.l	#dta,-(sp)				;fsetdta() set new dta
		move.w	#$1a,-(sp)				;
		trap	#1					;
		addq.l	#6,sp					;

		move.w	#0,-(sp)				;fsfirst() get fileinfo
		move.l	filename,-(sp)				;
		move.w	#$4e,-(sp)				;
		trap	#1					;
		addq.l	#8,sp					;

		tst.l	d0					;file found ?
		beq.s	.size					;yep

		moveq	#MXP_ERROR,d0				;no
		rts						;exit

.size:		move.l	dta+26,filelength			;get file-legth
		add.l	#50000,filelength			;graoumf convert area

		move.w	#3,-(sp)				;Mxalloc()
		move.l	filelength,-(sp)			;
		move.w	#$44,-(sp)				;
		trap	#1					;
		addq.l	#8,sp					;

		tst.l	d0					;enough mem?
		bne.s	.loadit					;yes

		moveq	#MXP_ERROR,d0				;no
		rts						;exit

.loadit:	move.l	d0,filebuffer				;store for loader & player

		move.w	#0,-(sp)				;fopen()
		move.l	filename,-(sp)				;
		move.w	#$3d,-(sp)				;
		trap	#1					;
		addq.l	#8,sp					;

.ok:		move.w	d0,filenumber				;filenumber
		move.l	filebuffer,-(sp)			;buffer
		move.l	filelength,-(sp)			;length
		move.w	filenumber,-(sp)			;filenumber
		move.w	#$3f,-(sp)				;
		trap	#1					;
		lea	12(sp),sp				;

		move.w	filenumber,-(sp)			;fclose()
		move.w	#$3e,-(sp)				;
		trap	#1					;
		addq.l	#4,sp					;

