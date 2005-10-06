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
		movep	#>$3800,x:<<IPR	; IPL 3 pour l'interruption SSI

		move	#>4096*2-1,m7
		move	#>4096*2-1,m6
		move	#>mixbuf1,r7
		nop
		nop
		movep	#>$5800,x:<<CRB	; Autorise l'envoi de donn‚es sous interruptions
		andi	#<$FC,mr		; Toutes les interruptions sont autoris‚es

		wait_transmit
		movep	#"PLS",x:HTX

		wait_receive
		movep	x:HTX,x0
		move	x0,x:buf_len	;get bufer len

		move	#>984,x0
		move	x0,x:buf_len
	;-----------------------------------
	;initialize buffers
	;	buf_1 is always work buffer
	;	buf_2 is always replayed

exchange_loop
		jmp	exchange_loop
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

		btst	#0,x:flags
		jcs	ok_initial_mix

wait_r7		move	r7,a
		jset	#0,a1,wait_r7		;wait for even val

		move	a,r6
		move	#>984*2,n6
		nop
		;move	(r6)-n6

		move	#>$ffffff,x0
		move	x0,x:flags
		jmp	do_mix

ok_initial_mix
		move	x:last_mix_hear,r6
do_mix
		move	#>984,y0

		move	#>$100*$100/2,x1
	
		do	y0,mix_loop

		wait_receive
		movep	x:>HTX,x0
		mpy	x0,x1,a		

		move	a0,y:(r6)+
		move	a0,y:(r6)+
mix_loop
		nop
		move	r6,x:last_mix_hear
					;tell me hunny that everything is OK...
		wait_transmit
		movep	#>$112233,x:<<HTX

		;jmp	mix_data

		rti
p_end:
;----------------------------X MEMORY SPACE-------------------------------------
		org	x:$0		;internal x-memory
flags		dc	0
buf_len		dc	984
last_mix_hear	ds	1

		org	x:p_end		;external x-memory
;----------------------------Y MEMORY SPACE------------------------------------
		org	y:0	
mixbuf1:	ds	4096*2
