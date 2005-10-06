FRM_DUMMY	equ	0	;this frame is void

FRM_MIX_8	equ	1	;frame ident as 8bit resampled
FRM_MIX_16	equ	2	;frame ident as 16bit resampled

FRM_REMIX_8	equ	3	;frame ident as 8bit packed sample data that have 2 be additionaly resampled
FRM_REMIX_16	equ	4	;as above but for 16 bit


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
		org	p:$20
		movep	X:<<HTX,x:(r3)+		;fetch host port
		nop

		org	p:$22
		movep	x:(r4)+,X:<<HTX		;fetch host port
		nop

		org	p:$40
start:

		move	#>receive_buf,r3
		andi	#>%11111100,mr
		move	r3,r4
		nop
		nop
		bset	#0,x:$ffe8		;enabel receive hi int

		jclr	#>3,X:<<M_HSR,*		;wait until buffer empty

		bset	#1,x:$ffe8		;enabel receive hi int

		jmp	*

		org	x:$0
receive_buf:	ds	4096
