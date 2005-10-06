host_get	macro	register
		jclr	#0,x:<<M_HSR,*
		movep	x:<<M_HTX,register
		endm

host_put	macro	register
		jclr	#1,x:<<M_HSR,*
		movep	\1,x:<<M_HTX
		endm

bsr	macro
	jsr	\1
	endm
bra	macro
	jmp	\1
	endm
bne	macro
	jne	\1
	endm
beq	macro
	jeq	\1
	endm
blt	macro
	jlt	\1
	endm
bgt	macro
	jgt	\1
	endm
ble	macro
	jle	\1
	endm
bge	macro
	jge	\1
	endm
bcc	macro
	jcc	\1
	endm
bcs	macro
	jcs	\1
	endm
bpl	macro
	jpl	\1
	endm
bmi	macro
	jmi	\1
	endm