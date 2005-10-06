		org 	p:$0

		;jmp	mix_data

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
;--------------------------------MACROS-----------------------------------------
wait_receive	MACRO
		jclr	#0,x:<<HSR,*
		ENDM
wait_transmit	MACRO
		jclr	#1,x:<<HSR,*
		ENDM
;--------------------------------INT'S------------------------------------------
		org	p:$10			;fast interrupt for sample replay
		movep	y:(r7)+,x:<<TX
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

		move	#>mixbuf1,r0
		clr	a
		rep	#4096/2
		move	a,y:(r0)+
		rep	#4096/2
		move	a,y:(r0)+

		move	#>$ffff,m0
		move	m0,m1
		move	m0,m4
		move	m0,m5
		move	m0,m6
		move	m0,m7
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
		move	x0,x:buf_len	;get initial bufer len

		move	#>mixbuf2,r7	
		move	#-1,m7
		move	#mixbuf1,x0
		move	x0,x:now_play

		wait_receive
		movep	x:<<HTX,x0

		movep	#>$5800,x:<<CRB	
		andi	#<$FC,mr

wa		jmp	wa
;--BUFERS SYNC ROUTINES---------------------------------------------------------
wait_buffers	move	x:now_play,b
		move	#>mixbuf1,y1
		cmp	y1,b
		jeq	mix_1_in_play

		move	x:buf_len,b
		lsl	b	#mixbuf1,y1		;stereo!
		add	y1,b
		move	r7,y1		;end of mix bufer
				
check_r7_1	cmp	y1,b	r7,y1
		jge	check_r7_1

even_2		
		;btst	#0,r7
		;jcs	even_2

		move	#>mixbuf2,r7
		move	#>mixbuf1,x0
		move	x0,x:now_play

		rts

		bset	#>1,x:flags
		
		jmp	wait_buffers

mix_1_in_play	move	x:buf_len,b

		lsl	b	#>mixbuf2,y1		;stereo!
		add	y1,b
		move	r7,y1		;end of mix bufer
				
check_r7_2	cmp	y1,b	r7,y1
		jge	check_r7_2

even_1		
		;btst	#0,r7
		;jcs	even_1

		move	#>mixbuf1,r7
		move	#>mixbuf2,x0
		move	x0,x:now_play

		rts

		bset	#>1,x:flags

		jmp	wait_buffers
;--INITIALIZE SSI INTERFACE-----------------------------------------------------
;
initialize_ssi
		movep	#$3c00,x:<<IPR		; Control Reg A
		movep	#$4100,x:<<CRA		; Control Reg B
		movep	#$5800,x:<<CRB		; Port C control
		movep	#$1f8,x:<<PCC		; Port C Data Direction
		;movep	#>0,x:<<PCDDR
		andi	#$fc,mr
		rts
;---MIXING PROCEDURES-----------------------------------------------------------
mixer_int:	
		jsr	wait_buffers
		jsr	Save_Registers

		wait_transmit		;-->"hellow i'm here!!!!"
		movep	#>$cfdfaf,x:<<HTX

		;jsr	wait_buffers

		wait_receive
		movep	x:HTX,y0
		move	y0,x:buf_len

		move	#>mix_jump_tree,r0
		wait_receive
		movep	x:>>HTX,n0
		nop
		move	y:(r0+n0),r1
		nop
		jsr	(r1)
					;tell me hunny that everything is OK...
		wait_transmit
		movep	#>$112233,x:<<HTX

		;jsr	wait_buffers
		jsr	Restore_Registers
		rti
;---MIX 8bit--------------------------------------------------------------------
mix_8bit:	wait_receive
		movep	x:<<HTX,a	;get volume

		wait_receive
		movep	x:<<HTX,x0	;get panning

		andi	#0,ccr

		add	x0,a	a,b
		rep	#7
		lsl	a
		sub	x0,b	a,y1
		rep	#7
		lsl	b
		move	b,y0

		wait_receive
		movep	x:<<HTX,n0	;get frame length

		move	x:now_play,r6

		move	#>$100*$100/2,x1
	
		do	n0,mix_loop

		wait_receive
		movep	x:>HTX,x0
		mpy	x0,x1,a		;"decode"
		move	a0,x0
		mpyr	y1,x0,a		;volumize
		mpyr	y0,x0,a		a1,y:(r6)+
		move	a1,y:(r6)+
mix_loop
		nop
		rts
;---DUMMY-----------------------------------------------------------------------
dummy:	
		rts
;---CLR MIXING BUFFERS----------------------------------------------------------
clr_y:		move	#>mixbuf1,r0
		clr	a
		rep	#4096/2
		move	a,y:(r0)+
		rep	#4096/2
		move	a,y:(r0)+
		rti
;---SAVE DSP REGISTERS----------------------------------------------------------
Save_Registers:		move		r0,X:Save_r0
		move		#Saved_Registers,r0
		nop
		move		r1,X:(r0)+
		move		r2,X:(r0)+
		move		r3,X:(r0)+
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
		move		X:(r0)+,r3
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
;---------------------LAST ENTRY IN THE P MEMORY--------------------------------
;	since x memory is attached to p memory from p:0 (excluding internal
;	p: memory!) we have to know where our programs ends so we can set
;	x external adress above our program!
p_end:
;----------------------------X MEMORY SPACE-------------------------------------
		org	x:$0		;internal x-memory
flags		dc	0
buf_len		dc	984

Save_r0		ds	1
Saved_Registers	ds	17

now_play	ds	1

mix_ptr_1	dc	mixbuf1
mix_ptr_2	dc	mixbuf2

		org	x:p_end		;external x-memory
;----------------------------Y MEMORY SPACE------------------------------------
;		INTERNAL:
		org	y:$0
mix_jump_tree	dc	dummy
		dc	mix_8bit	;<- mix 8bit sample
;----------------------------Y MEMORY SPACE------------------------------------
;		EXTERNAL:

		org	y:$100
mixbuf1:	ds	4096/2
mixbuf2:	ds	4096/2