Save_v		macro
		bsr	Save_Video
		endm
Set_sb		macro
		bsr	Set_scr_adr
		endm
Set_v		macro
		move.l	\1,a0
		bsr	Restore2
		endm
Restore_v	macro
		bsr	Restore_Video
		endm

		xdef	Save_Video
		xdef	Restore_Video
		xdef	Fv
		xdef	Set_scr_adr
		xdef	ldouble
		xdef	set_f_pal
		xdef	Restore2

		;output	f:\video.o

					
Save_Video:	
		lea.l	save_video,a0		;store videomode
		move.l	$ffff8200.w,(a0)+	;vidhm
		move.w	$ffff820c.w,(a0)+	;vidl
		move.l	$ffff8282.w,(a0)+	;h-regs
		move.l	$ffff8286.w,(a0)+	;
		move.l	$ffff828a.w,(a0)+	;
		move.l	$ffff82a2.w,(a0)+	;v-regs
		move.l	$ffff82a6.w,(a0)+	;
		move.l	$ffff82aa.w,(a0)+	;
		move.w	$ffff82c0.w,(a0)+	;vco
		move.w	$ffff82c2.w,(a0)+	;c_s
		move.l	$ffff820e.w,(a0)+	;offset
		move.w	$ffff820a.w,(a0)+	;sync
		move.b  $ffff8256.w,(a0)+	;p_o
		clr.b   (a0)			;test of st(e) or falcon mode
		cmp.w   #$b0,$ffff8282.w	;hht kleiner $b0?
		sle     (a0)+			;flag setzen
		move.w	$ffff8266.w,(a0)+	;f_s
		move.w	$ffff8260.w,(a0)+	;st_s

		lea.l	$ffff9800,a0		;save falcon palette
		lea.l	save_pal,a1		;
		move.w	#256-1,d7		;
.colloop:	move.l	(a0)+,(a1)+		;
		dbra	d7,.colloop		;
		movem.l	$ffff8240,d0-d7		;save st palette
		movem.l	d0-d7,(a1)		;

		lea.l	save_video,a0		;store videomode
		move.l	$ffff8200.w,(a0)+	;vidhm
		move.w	$ffff820c.w,(a0)+	;vidl
		move.l	$ffff8282.w,(a0)+	;h-regs
		move.l	$ffff8286.w,(a0)+	;
		move.l	$ffff828a.w,(a0)+	;
		move.l	$ffff82a2.w,(a0)+	;v-regs
		move.l	$ffff82a6.w,(a0)+	;
		move.l	$ffff82aa.w,(a0)+	;
		move.w	$ffff82c0.w,(a0)+	;vco
		move.w	$ffff82c2.w,(a0)+	;c_s
		move.l	$ffff820e.w,(a0)+	;offset
		move.w	$ffff820a.w,(a0)+	;sync
		move.b  $ffff8256.w,(a0)+	;p_o
		clr.b   (a0)			;test of st(e) or falcon mode
		cmp.w   #$b0,$ffff8282.w	;hht kleiner $b0?
		sle     (a0)+			;flag setzen
		move.w	$ffff8266.w,(a0)+	;f_s
		move.w	$ffff8260.w,(a0)+	;st_s


		rts

Restore_Video:	movem.l	d0-a6,-(sp)
		lea.l	save_video,a0		;restore video
		clr.w   $ffff8266.w		;falcon-shift clear
		move.l	(a0)+,$ffff8200.w	;videobase_address:h&m
		move.w	(a0)+,$ffff820c.w	;l
		move.l	(a0)+,$ffff8282.w	;h-regs
		move.l	(a0)+,$ffff8286.w	;
		move.l	(a0)+,$ffff828a.w	;
		move.l	(a0)+,$ffff82a2.w	;v-regs
		move.l	(a0)+,$ffff82a6.w	;
		move.l	(a0)+,$ffff82aa.w	;
		move.w	(a0)+,$ffff82c0.w	;vco
		move.w	(a0)+,$ffff82c2.w	;c_s
		move.l	(a0)+,$ffff820e.w	;offset
		move.w	(a0)+,$ffff820a.w	;sync
	        move.b  (a0)+,$ffff8256.w	;p_o
	        tst.b   (a0)+   		;st(e) comptaible mode?
        	bne.s   .ok
		move.l	a0,-(sp)		;wait for vbl
		move.w	#37,-(sp)		;to avoid syncerrors
		trap	#14			;in falcon monomodes
		addq.l	#2,sp			;
		movea.l	(sp)+,a0		;
	       	move.w  (a0),$ffff8266.w	;falcon-shift
		bra.s	.video_restored
.ok:		move.w  2(a0),$ffff8260.w	;st-shift
		lea.l	save_video,a0
		move.w	32(a0),$ffff82c2.w	;c_s
		move.l	34(a0),$ffff820e.w	;offset		
.video_restored:

		lea.l	$ffff9800,a0		;restore falcon palette
		lea.l	save_pal,a1		;
		move.w	#256-1,d7		;
.loop2:		move.l	(a1)+,(a0)+		;
		dbra	d7,.loop2		;
		movem.l	(a1),d0-d7		;restore st palette
		movem.l	d0-d7,$ffff8240		;


		movem.l	(sp)+,d0-a6
		rts
Restore2:
		;move.b	(a0)+,$ffff8201.w		; Vid‚o (poids fort)
		;move.b	(a0)+,$ffff8203.w		; Vid‚o (poids moyen)
		;move.b	(a0)+,$ffff820d.w		; Vid‚o (poids faible)
		addq.l	#4,a0
		
;		move.b	(a0)+,$ffff820a.w		; Synchronisation vid‚o
		move.w	(a0)+,$ffff820e.w		; Offset pour prochaine ligne
		move.w	(a0)+,$ffff8210.w		; Largeur d'une ligne en mots
		move.b	(a0)+,d0				; R‚solution ST
		move.b	(a0)+,$ffff8265.w		; D‚calage Pixel
		move.w	(a0)+,d1				; R‚solution Falcon

		move.w	d1,$ffff8266.w			; Fixe R‚solution Falcon

No_STRez2:	move.w	(a0)+,$ffff8282.w		; HHT-Synchro
		move.w	(a0)+,$ffff8284.w		; Fin Bordure Droite
		move.w	(a0)+,$ffff8286.w		; D‚but Bordure Gauche
		move.w	(a0)+,$ffff8288.w		; D‚but Ligne
		move.w	(a0)+,$ffff828a.w		; Fin Ligne
		move.w	(a0)+,$ffff828c.w		; HSS-Synchro
		move.w	(a0)+,$ffff828e.w		; HFS ???
		move.w	(a0)+,$ffff8290.w		; HEE ???
		move.w	(a0)+,$ffff82a2.w		; VFT-Synchro
		move.w	(a0)+,$ffff82a4.w		; Fin Bordure Basse
		move.w	(a0)+,$ffff82a6.w		; D‚but Bordure Haute
		move.w	(a0)+,$ffff82a8.w		; D‚but Image
		move.w	(a0)+,$ffff82aa.w		; Fin Image
		move.w	(a0)+,$ffff82ac.w		; VSS-Synchro
		move.w	(a0)+,$ffff82c0.w		; Reconnaissance ST/Falcon
		move.w	(a0)+,$ffff82c2.w		; Informations r‚solution


		rts


Fv:		
		movem.l	d0-d7/a0-a6,-(sp)
			
		;move.l	,a0

		cmp.l	#'FVDO',(a0)+	;4 bytes header
		bne	.error
		
.ready:		addq.l	#2,a0
		
		move.l	(a0)+,$ff820e	;offset & vwrap
		move.w	(a0)+,$ff8266	;spshift
		move.l	#$ff8282,a1	;horizontal control registers
.loop1:		move	(a0)+,(a1)+
		cmp.l	#$ff8292,a1
		bne	.loop1
		move.l	#$ff82a2,a1	;vertical control registers
.loop2:		move	(a0)+,(a1)+
		cmp.l	#$ff82ae,a1
		bne	.loop2
		move	(a0)+,$ff82c2	;video control

		movem.l	(sp)+,d0-d7/a0-a6
		moveq	#0,d0
		rts

.error:		movem.l	(sp)+,d0-d7/a0-a6
		moveq	#-1,d0				
		rts

.wrongmon:	movem.l	(sp)+,d0-d7/a0-a6
		moveq	#-2,d0
		rts

Set_scr_adr:	movem.l	d0-a6,-(sp)
		;move.l	4+60(sp),a0
		move.l 	a0,d0
		;add.l	#$100,d0
		;and.l	#$ffffffff00,d0
	    	move.l	d0,d1
	    	lsr.w 	#8,d0
        	move.l 	d0,$ffff8200.w                               
        	move.b	d1,$ffff820d.w
		movem.l	(sp)+,d0-a6
		rts	



ldouble		or.w	#1,$ffff82c2.w
		rts		

wait_for_vbl	movem.l	d0-a6,-(sp)	
		move.w	#37,-(sp)
		trap	#14
		addq.l	#2,sp
		movem.l	(sp)+,d0-a6
		rts

		ds.w	10

set_f_pal2:	lea.l	$ffff9800.w,a1
		lea	(a1,d0.w*4),a1
		lea	(a0,d0.w*4),a0
		move.w	#256-1,d1
		sub.w	d0,d1
		move.w	d1,d0
		bra.b	Save_Falcon_Palette2
set_f_pal:
		lea.l	$ffff9800.w,a1			; Palette Falcon
		move.w	#256-1,d0				; 256 longs...
Save_Falcon_Palette2:
		move.l	(a0)+,(a1)+			; Sauve 1 couleur
		dbra		d0,Save_Falcon_Palette2	; Boucle les 256 longs !
		rts

		bss

save_video:	ds.b	32+12+2			;videl save
save_pal:	ds.l	256+8			;palette save
			
			text