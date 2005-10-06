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
		org	p:$10
		movep	y:(r7)+,x:<<TX
		nop
		org	p:$12
		movep	y:(r7)+,x:<<TX
		nop

		org	p:$26
		jsr	mix_data
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
		movep	#>$4100,x:<<CRA	; Configuration SSI
		movep	#>$1f8,x:<<PCC
		btst	#4,x:<<SSISR
		movep	#>$1,x:<<PBC
		movep	#>$0,x:<<BCR
		movep	#>$3800,x:<<IPR	

		wait_transmit
		movep	#"PLS",x:HTX

		wait_receive
		movep	x:HTX,x0
		move	x0,x:buf_len	;get bufer len

		move	#>984,x0
		move	x0,x:buf_len

		move	#>mixbuf2,r7	;mix_ptr_2 is always in replay!!
		move	#-1,m7
		move	#mixbuf1,x0
		move	x0,x:now_play
		wait_receive
		movep	x:>>HTX,a

		movep	#>$5800,x:<<CRB	
		andi	#<$FC,mr		
		
		jmp	enrom

	;-----------------------------------
	;initialize buffers
	;	buf_1 is always work buffer
	;	buf_2 is always replayed

command_loop:	wait_receive
		movep	x:>>HTX,a
enrom:
		jset	#0,a1,mix_data
		jset	#1,a1,wait_buffers	;exchenge buffers
		
		jmp	command_loop	;unsupported command??

;--BUFERS SYNC ROUTINES---------------------------------------------------------
wait_buffers	move	x:now_play,a
		move	#>mixbuf1,x0
		cmp	x0,a
		jeq	mix_1_in_play

		move	#>984,b
		lsl	b	#mixbuf1,y1		;stereo!
		add	y1,b
		move	r7,y1		;end of mix bufer
				
check_r7_1	cmp	y1,b	r7,y1
		jge	check_r7_1

		move	#>mixbuf2,r7
		move	#>mixbuf1,x0
		move	x0,x:now_play
		
		jmp	command_loop

mix_1_in_play	move	#>984,b

		lsl	b	#>mixbuf2,y1		;stereo!
		add	y1,b
		move	r7,y1		;end of mix bufer
				
check_r7_2	cmp	y1,b	r7,y1
		jge	check_r7_2

		move	#>mixbuf1,r7
		move	#>mixbuf2,x0
		move	x0,x:now_play

		jmp	command_loop

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
;---RESET MIXING BUFFERS--------------------------------------------------------

;---MIXING PROCEDURES-----------------------------------------------------------
mix_data:		
		wait_transmit		;-->"hellow i'm here!!!!"
		movep	#>$cfdfaf,x:<<HTX

		move	x:now_play,r6

		move	#>984,y0
		move	#>$100*$100/2,x1
	
		do	y0,mix_loop

		wait_receive
		movep	x:>HTX,x0
		mpy	x0,x1,a		

		move	a0,y:(r6)+
		move	a0,y:(r6)+
mix_loop
					;tell me hunny that everything is OK...
		wait_transmit
		movep	#>$112233,x:<<HTX

		jmp	command_loop
p_end:
;----------------------------X MEMORY SPACE-------------------------------------
		org	x:$0		;internal x-memory
flags		dc	0
buf_len		dc	984
last_mix_hear	ds	1

now_play	ds	1

mix_ptr_1	dc	mixbuf1
mix_ptr_2	dc	mixbuf2

		org	x:p_end		;external x-memory
;----------------------------Y MEMORY SPACE------------------------------------
		org	y:$100
mixbuf1:	ds	4096/2
mixbuf2:	ds	4096/2

