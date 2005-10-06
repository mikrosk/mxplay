		include	sys_lib.s
		include	dsp.s

		setup
		super	#0

		Dsp_ExecProg #DSP_start,#(DSP_end-DSP_start)/3,#0

		;lea	l_rx,a0
		lea	datas,a1
		moveq	#16-1,d7

loop		put_host	(a1)+
		dbf	d7,loop

		bset	#3,icr.w

		moveq	#16-1,d7
loop2		
		get_host	d0
		dbf	d7,loop2

		pterm

datas:		dc.l	1,2,3,4,5,6,7,8,9
		dc.l	$aa,$bb,$cc,$aa,$bb,$ee,$ff,$99

DSP_start:	incbin	g:\pulsar\io_test.p56
DSP_end:
