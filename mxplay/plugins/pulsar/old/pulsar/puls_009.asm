FRM_DUMMY	equ	"DMY"	;this frame is void

FRM_MIX_8	equ	"M8R"	;frame ident as 8bit resampled
FRM_MIX_16	equ	"MFR"	;frame ident as 16bit resampled
FRM_MIX_8_2	equ	"M9R"	;frame ident as 8bit resampled
FRM_MIX_16_2	equ	"MF2"	;frame ident as 16bit resampled

FRM_REMIX_8	equ	"M8S"	;frame ident as 8bit packed sample data that have 2 be additionaly resampled
FRM_REMIX_16	equ	"MFS"	;as above but for 16 bit
FRM_VOID	equ	"NUL"	;wait for next frame

		include	g:\include\dsp.asm

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
		nop
		nop

		org	p:$12			;fast interrupt for sample replay
		movep	y:(r7)+,x:<<TX
		nop

		org	p:I_HSTRD
		movep	X:<<HTX,x:(r3)+		;fetch host port
		nop

		org	p:$26
		jsr	mixer_int

		org	p:$28
		jsr	clr_mix

		org	p:$40
;---MIXING PROCEDURES-----------------------------------------------------------
mixer_int:	

		;jsr	Save_Registers

		move	r7,a		;even sample ptr
		move	#>1,y0
		add	y0,a	#>$fffe,x0
		and	x0,a

		move	x:last_play,b
		and	x0,b
		move	b,x:output_ptr
		sub	b,a		a,x:last_play
		jpl	length_plus
		move	#>4096,x0
		add	x0,a
length_plus:
		lsr	a	;stereo...
		move	a,x:frame_length

		wait_transmit		;-->"hellow i'm here!!!!"
		movep	#>"MIX",x:<<HTX

		move	m7,m6
		move	m7,m5

		move	x:frame_length,y0	;tell how manny samples we're mixing (max!! -> can be smaller!)
		wait_transmit
		movep	y0,x:HTX

		move	#>FIRR_coeffs,r0
		move	#>FIRR_coeffs+10,r1

		do	#10,rec_coeffs
		wait_receive
		movep	x:HRX,x0
		move	x0,y:(r0)+
		move	x0,y:(r1)+
rec_coeffs
	;---SETUP HI INTS FOR RECEIVE------

		move	#>receive_length-1,m3
		move	#>receive_buf,r3
		move	m3,m0
		move	r3,x:frame_ptr
		nop
		nop
		bset	#M_HRIE,x:M_HCR		;enabel receive HI int

		andi	#>%11111100,mr
		nop
		nop

		bsr	clr_init

	;---MIXER MAIN LOOP----------------

		move	x:Nb_trax,x1

		do	x1,All_Channels

		jclr	#>3,X:<<M_HSR,*		;wait until buffer full

		bclr	#M_HRIE,x:M_HCR		;disable receive hi int
		nop
		nop

		move	x:frame_ptr,r0
		nop
		move	r3,x:frame_ptr

		wait_transmit
		movep	#>"OK0",x:<<HTX

		jset	#>3,X:<<M_HSR,*

		bset	#M_HRIE,x:M_HCR		;enable receive hi int

		move	x:(r0)+,x0
		
		move	#>FRM_DUMMY,a
		cmp	x0,a
		beq	MIX_VOID

		move	#>FRM_MIX_8,a
		cmp	x0,a
		bne	no_mix_8bit

;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
;		8 bit mixing with cpu resampling
;		2 times unrolled
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ

		bsr	get_volume

		move	x:output_ptr,r6

		move	y0,y:temp1
		move	y1,y:temp3
		
		move	r6,r5
		move	x:(r0)+,a
		tst	a
		beq	MIX_VOID

		move	#>$100*$100/2,x1
		move	#>$100/2,y0

		move	#>decode_buf,r4

		move	a,y:temp2

		move	#>$ff0000,y1

		lsr	a	#4,x0
		add	x0,a

		do	a,decode_8
		move	x:(r0)+,x0
		mpy	x0,y0,b
		mpy	x0,x1,a	b0,b
		and	y1,b	a0,a
		and	y1,a	b,y:(r4)+
		move	a,y:(r4)+
decode_8:

	;
		move	y:temp2,a
		move	y:temp1,y0
		move	y:temp3,y1
		move	#>decode_buf,r4

		do	a,mix_loop_8_t

		move	y:(r4)+,x0

		move	y:(r5)+,b
		macr	y1,x0,b		y:(r5)+,a	;volumize
		macr	y0,x0,a		b,y:(r6)+
		move	a,y:(r6)+
mix_loop_8_t:
		nop
		bra	MIX_VOID
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
no_mix_8bit	move	#>FRM_MIX_8_2,a
		cmp	x0,a
		bne	no_mix_8bit_sc1

;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
;		8 bit mixing with cpu resampling
;
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ

		bsr	get_volume

		move	x:output_ptr,r6

		move	r6,r5
		move	x:(r0)+,a
		tst	a
		beq	MIX_VOID

		move	#>$100*$100/2,x1

	;

		do	a,mix_loop_8_t_sc

		move	x:(r0)+,x0
		mpy	x0,x1,a	y:(r5)+,b
		move	a0,x0
		macr	y1,x0,b		y:(r5)+,a	;volumize
		macr	y0,x0,a		b,y:(r6)+
		move	a,y:(r6)+
mix_loop_8_t_sc:
		nop
		bra	MIX_VOID
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

no_mix_8bit_sc1	move	#>FRM_MIX_16,a
		cmp	x0,a
		bne	no_mix_16bit

;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
;		16 bit mixing with cpu resampling
;
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ

mix_16bit:	bsr	get_volume

		move	x:output_ptr,r6

		move	r6,r5
		move	#>$100/2,x1

		move	x:(r0)+,a	;get frame length
		tst	a
		beq	MIX_VOID

		nop
		do	a,_mix_loop_16_t

		move	y:add_to,a

		move	x:(r0)+,x0	

		mpy	x0,x1,a		y:(r5)+,b	;"decode"
		move	a0,x0
		macr	y1,x0,b		y:(r5)+,a	;volumize
		macr	y0,x0,a		b1,y:(r6)+
		move	a1,y:(r6)+
_mix_loop_16_t
		nop
		bra	MIX_VOID

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
no_mix_16bit	

MIX_VOID:	nop

All_Channels:	
		bclr	#M_HRIE,x:M_HCR		;disabel receive hi int

	;--MIXER "POSTPRODUCTION"------------

		jmp	around

		move	#>4096-1,m6
		;jmp	chj
	;-------FIRR FILTER------------------
		move	#>2,n6
		move	x:output_ptr,r6
		move	#>FIRR_coeffs,r4
		move	x:frame_length,b
		move	#>FIRR_states,r0

		move	#>20-1,m0
		move	#>10-1,m4

		do	b,do_firr

		nop
do_firr

around:

chj		move	#>$ffff,m0
		move	m0,m4
	;------------------------------------

		wait_transmit
		movep	#>"END",x:<<HTX

		bsr	Volume_Bost

		;jsr	Restore_Registers
		rti
;---GET VOLUME------------------------------------------------------------------
get_volume:	move	x:(r0)+,a
		move	x:(r0)+,x0	;get panning

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
		move	#>$100*$102,x0
	
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

;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
;
;    OK, first of all do all da initialization stuff that have to be done
;
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
start:
		move	#>$ffff,m0
		move	m0,m1
		move	m0,m5

		move	#>buffer_length-1,m7	;first reg bank

		movep	#>$4100,x:<<CRA	; Configuration SSI
		movep	#>$1f8,x:<<PCC
		btst	#4,x:<<SSISR
		movep	#>$1,x:<<PBC
		movep	#>$0,x:<<BCR
		movep	#>$3800,x:<<IPR	

		move	#>FIRR_states,r0
		clr	a
		rep	#20
		move	a,x:(r0)+

		bset	#>M_HCIE,x:HCR

		wait_transmit
		movep	#"PLS",x:HTX

		wait_receive
		movep	x:HTX,x0
		move	x0,x:Nb_trax

		move	#>mixbuf1,r7
		nop
		wait_receive
		movep	x:<<HTX,x0

		movep	#>$5800,x:<<CRB	
		andi	#<$FC,mr

		jmp	*
;נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
clr_mix:	move	#>mixbuf1,r0
		clr	a
		do	#>$1000/2,do_clr_mix
		move	a,y:(r0)+
		move	a,y:(r0)+
do_clr_mix:
		rti
;---------------------LAST ENTRY IN THE P MEMORY--------------------------------
;	since y memory is attached to p memory from p:0 (excluding internal
;	p: memory!) we have to know where our programs ends so we can set
;	y external adress above our program!
p_end:
;----------------------------X MEMORY SPACE-------------------------------------
		org	x:$0		;internal x-memory
FIRR_states	ds	20

Nb_trax		dc	0
flags		dc	0
buf_len		dc	1

Save_r0		ds	1
Saved_Registers	ds	17

frame_ptr	ds	1

frame_length	ds	1

last_play	dc	mixbuf1+2048
output_ptr	ds	1
		
		org	x:$1000
receive_buf:	dsm	receive_length
;----------------------------Y MEMORY SPACE------------------------------------
;		
		org	y:0
FIRR_coeffs:	ds	20

add_to		dc	0
adder		dc	0
temp1		dc	0
temp2		dc	0
temp3		dc	0

		org	y:p_end
		ds	16
decode_buf:	ds	2048

		org	y:$1000
mixbuf1:	dsm	buffer_length

