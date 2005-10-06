host_get	macro	register
		jclr	#0,x:<<M_HSR,*
		movep	x:M_HTX,register
		endm
host_put	macro	register
		jclr	#1,x:<<M_HSR,*
		movep	register,x:<<M_HTX
		endm


sbranch	macro	lab1
	jsr	lab1
	endm

m	macro	src,dest
	move	sec,dest
	endm

branch	macro	lab1
	jmp	lab1
	endm
bne	macro	lab1
	jne	lab1
	endm
beq	macro	lab1
	jeq	lab1
	endm
blt	macro	lab1
	jlt	lab1
	endm
bgt	macro	lab1
	jgt	lab1
	endm
ble	macro	lab1
	jle	lab1
	endm
bge	macro	lab1
	jge	lab1
	endm
bcc	macro	lab1
	jcc	lab1
	endm
bcs	macro	lab1
	jcs	lab1
	endm
bpl	macro	lab1
	jpl	lab1
	endm
bmi	macro	lab1
	jmi	lab1
	endm