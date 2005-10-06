		include	g:\include\intequ.asm

		include	g:\include\ioequ.asm

		org 	p:$0

		jmp 	start
;------------------------------------------------------------------------------
CRA	equ	$ffec	;SSI Control Register A
CRB	equ	$ffed	;SSI Control Register B
SSISR	equ	$ffee	;SSI Status Register
SSITSR	equ	$ffee	;SSI Time Slot Register
RX	equ	$ffef	;SSI Serial Receive data/shift register
TX	equ	$ffef	;SSI Serial Transmit data/shift register
SCR	equ	$fff0	;SCI Control Register
SSR	equ	$fff1	;SCI Status Register
SCCR	equ	$fff2	;SCI Clock Control Register
STXA	equ	$fff3	;SCI Transmit data Address Register
SRX	equ	$fff4	;SCI Receive data register (4-5-6)
STX	equ	$fff4	;SCI Transmit data register (4-5-6)
IPR	equ	$ffff	;Interrupt Priority Register
;-----------------------------------EQUATES-------------------------------------
PBC	equ	$ffe0	;Port B Control register
PCC	equ	$ffe1	;Port C Control register
PBDDR	equ	$ffe2	;Port B Data Direction Register
PCDDR	equ	$ffe3	;Port C Data Direction Register
PBD	equ	$ffe4	;Port B Data register
PCD	equ	$ffe5	;Port C Data register
HCR	equ	$ffe8	;Host Control Register
HSR	equ	$ffe9	;Host Status Register
hsr	equ	$ffe9
HRX	equ	$ffeb	;Host Receive Register
hrx	equ	$ffeb
HTX	equ	$ffeb	;Host Transmit Register
htx	equ	$ffeb
BCR	equ	$fffe	;Port A Bus Control Register
HCIE	equ	2
OFF	equ	0
ON	equ	1
receive	equ	0
transmit equ	1

buffer_length	equ	4096
receive_length	equ	4096
;--------------------------------MACROS-----------------------------------------
wait_receive	MACRO
		jclr	#0,x:<<HSR,*
		ENDM

wait_transmit	MACRO
		jclr	#1,x:<<HSR,*
		ENDM
hc_send:	macro
		movep	\1,x:<<HTX
		endm
hc_get:		macro
		movep	x:HTX,\1
		endm
;--------------------------------INT'S------------------------------------------
		org	p:$10			;fast interrupt for sample replay
		;movep	y:(r7)+,x:<<TX
		nop
		nop
		org	p:$12			;fast interrupt for sample replay
		movep	y:(r7)+,x:<<TX
		nop

		org	p:$26
		jsr	mixer_int

		org	p:$28
		jsr	clr_y
;--------------------------------MAIN PROGRAM-----------------------------------
		org	p:$40
start		
		move	#>$ffff,m0
		move	m0,m1
		move	m0,m5

		move	#>buffer_length-1,m7	;first reg bank
		move	#>receive_length-1,m3	;second reg bank

		movep	#>$4100,x:<<CRA	; Configuration SSI
		movep	#>$1f8,x:<<PCC
		btst	#4,x:<<SSISR
		movep	#>$1,x:<<PBC
		movep	#>$0,x:<<BCR
		movep	#>$3800,x:<<IPR	

		bset	#>HCIE,x:HCR

		wait_transmit
		movep	#"PLS",x:HTX

		wait_receive
		movep	x:HTX,x0
		move	x0,x:Nb_trax

		move	#>mixbuf1,r7
		move	#>receive_buf,r3
		nop
		wait_receive
		movep	x:<<HTX,x0

		movep	#>$5800,x:<<CRB	
		andi	#<$FC,mr

		jmp	*

;---MIXING PROCEDURES-----------------------------------------------------------
mixer_int:	
		jsr	Save_Registers

		move	r7,a		;even sample ptr
		move	#>$fffffe,x0
		and	x0,a

		move	x:last_play,b
		and	x0,b
		move	b,x:output_ptr
		sub	b,a		a,x:last_play
		jpl	length_plus
		move	#>4096,x0
		add	x0,a
length_plus:
		lsr	a		;stereo...
		move	a,x:frame_length

		wait_transmit		;-->"hellow i'm here!!!!"
		movep	#>"MIX",x:<<HTX

		move	#>buffer_length-1,m6
		move	#>buffer_length-1,m5

		move	x:frame_length,y0	;tell how manny samples we're mixing (max!! -> can be smaller!)
		wait_transmit
		movep	y0,x:HTX

		jsr	clr_init

	;---MIXER MAIN LOOP----------------

		move	x:Nb_trax,a
		tst	a
		jeq	Mix_trax
		
		do	a,Mix_trax
		move	#>mix_jump_tree,r0
		wait_receive
		movep	x:>>HTX,n0
		nop
		move	x:(r0+n0),r1
		nop
		jsr	(r1)
		nop
Mix_trax
					;tell me hunny that everything is OK...
	;--MIXER "POSTPRODUCTION"------------

	;-------FIRR FILTER------------------

	;------------------------------------

		wait_transmit
		movep	#>"END",x:<<HTX

		jsr	Volume_Bost

		jsr	Restore_Registers
		rti
;---MIX 8bit--------------------------------------------------------------------
mix_8bit:	jsr	get_volume

		move	x:output_ptr,r6
		
		move	r6,r5
		move	#>$100*$100/2,x1

_8bit_mix_loop:				;I hope this to work!
		wait_receive
		movep	x:<<HTX,a	;get frame length
		tst	a
		jeq	_8bit_mix_end

		nop
		do	a,_mix_loop_8_t

		wait_receive
		movep	x:>HTX,x0
		mpy	x0,x1,a		y:(r5)+,b	;"decode"
		move	a0,x0
		macr	y1,x0,b		y:(r5)+,a	;volumize
		macr	y0,x0,a		b1,y:(r6)+
		move	a1,y:(r6)+
_mix_loop_8_t
		nop
		jmp	_8bit_mix_loop
_8bit_mix_end:	
		move	#>"OK!",x0
		jsr	Host_send

		rts

;---MIX 16bit-------------------------------------------------------------------
mix_16bit:	jsr	get_volume

		move	x:output_ptr,r6

		move	r6,r5
		move	#>$100/2,x1

_16bit_mix_loop:
		wait_receive
		movep	x:<<HTX,a	;get frame length
		tst	a
		jeq	_16bit_mix_end
		nop
	
		do	a,_mix_loop_16_t

		wait_receive
		movep	x:>HTX,x0
		mpy	x0,x1,a		y:(r5)+,b	;"decode"
		move	a0,x0
		macr	y1,x0,b		y:(r5)+,a	;volumize
		macr	y0,x0,a		b1,y:(r6)+
		move	a1,y:(r6)+
_mix_loop_16_t
		nop
		jmp	_16bit_mix_loop
_16bit_mix_end	
		move	#>"OK!",x0
		jsr	Host_send

		rts
;---GET VOLUME------------------------------------------------------------------
get_volume:	wait_receive
		movep	x:<<HTX,a	;get volume

		wait_receive
		movep	x:<<HTX,x0	;get panning

		add	x0,a	a,b
		rep	#7
		lsl	a
		sub	x0,b	a,y1
		rep	#7
		lsl	b
		move	b,y0

		rts
;---VOLUME BOST-----------------------------------------------------------------------
Volume_Bost:	move	x:output_ptr,r6
		move	x:frame_length,n0

		move	r6,r5
		move	#>$100*$100,x0
	
		do	n0,do_bost
		move	y:(r6)+,y0
		mpy	x0,y0,a	y:(r6)+,y1
		mpy	x0,y1,b	#>$7fff,y0

		;move	#>-$7fff,y1

		cmp	y0,a1	#>-$7fff,y1
		tgt	y0,a
		cmp	y1,a1
		tlt	y1,a

		;move	#>$100/2,x1

		cmp	y0,b1	#>$100/2,x1
		tgt	y0,b
		cmp	y1,b1	
		tlt	y1,b

		move	a,y0
		mpy	x1,y0,a
		move	b,y1
		mpy	x1,y1,b	a0,y:(r5)+

		move	b0,y:(r5)+

		nop
do_bost

		rts
;---DUMMY-----------------------------------------------------------------------
dummy:	
		rts
;---CLEAR BUFFER----------------------------------------------------------------
clr_init:	move	x:output_ptr,r6

		clr	b	x:frame_length,a

		do	a,clr_up_l
		move	b,y:(r6)+
		move	b,y:(r6)+
clr_up_l
		rts
;---CLR MIXING BUFFERS----------------------------------------------------------
clr_y:		move	#>mixbuf1,r0
		clr	a
		rep	#4096/2
		move	a,y:(r0)+
		rep	#4096/2
		move	a,y:(r0)+
		rti
;---SIGNED INTEGER DIVISION-----------------------------------------------------
div_a		asl	a	 	a1,x0
		abs	a
		move	a1,a0					
		move	#0,a1
		andi	#$fe,ccr
		rep	#24
		div	y0,a					
		tfr	y0,b		#0,a1
		tst	b		x0,b
		jpl	no_neg
		neg	a
no_neg		tst	b
		jpl	no_neg2
		neg	a
no_neg2		move	a0,a
		rts
;---SAVE DSP REGISTERS----------------------------------------------------------
Save_Registers:		move		r0,X:Save_r0
		move		#Saved_Registers,r0
		nop
		move		r1,X:(r0)+
		move		r2,X:(r0)+
		move		r4,X:(r0)+
		move		r5,X:(r0)+
		move		r6,X:(r0)+
		move		m6,X:(r0)+
		move		x0,X:(r0)+
		move		x1,X:(r0)+
		move		y0,X:(r0)+
		move		y1,X:(r0)+
		move		a0,X:(r0)+
		move		a1,X:(r0)+
		move		a2,X:(r0)+
		move		b0,X:(r0)+
		move		b1,X:(r0)+
		move		b2,X:(r0)
		rts
;---RESTORE DSP REGISTERS-------------------------------------------------------
Restore_Registers:
		move		#Saved_Registers,r0
		nop
		move		X:(r0)+,r1
		move		X:(r0)+,r2
		move		X:(r0)+,r4
		move		X:(r0)+,r5
		move		X:(r0)+,r6
		move		X:(r0)+,m6
		move		X:(r0)+,x0
		move		X:(r0)+,x1
		move		X:(r0)+,y0
		move		X:(r0)+,y1
		move		X:(r0)+,a0
		move		X:(r0)+,a1
		move		X:(r0)+,a2
		move		X:(r0)+,b0
		move		X:(r0)+,b1
		move		X:(r0),b2
		move		X:Save_r0,r0
		rts
;-------------------------------------------------------------------------------
Host_get	;jclr	#0,X:<<M_HSR,Host_get
		;movep	X:<<M_HRX,x0
		;rts
Host_send	jclr	#1,X:<<HSR,Host_send
		movep	x0,X:<<HTX
		rts
;---------------------LAST ENTRY IN THE P MEMORY--------------------------------
;	since y memory is attached to p memory from p:0 (excluding internal
;	p: memory!) we have to know where our programs ends so we can set
;	y external adress above our program!
p_end:
;----------------------------X MEMORY SPACE-------------------------------------
		org	x:$0		;internal x-memory

Nb_trax		dc	0
flags		dc	0
buf_len		dc	984

Save_r0		ds	1
Saved_Registers	ds	17

frame_length	ds	1

last_play	dc	mixbuf1+2048
output_ptr	ds	1

mix_jump_tree	dc	dummy
		dc	mix_8bit
		dc	mix_16bit
		
		org	x:4096
receive_buf:	dsm	4096
;----------------------------Y MEMORY SPACE------------------------------------
;		
		org	y:0

		org	y:4096
mixbuf1:	dsm	4096

