*
* CACHE.S
*
*	Cache equates. You'll need devpac 3 for this one, I think.
*
* ex.	move.l	#ENABLE_CACHE+ENABLE_DATA_CACHE+WRITE_ALLOCATE,d0
*	movec	d0,CACR		; turns on the caches
*


ENABLE_CACHE		EQU 1   ; Enable instruction cache
FREEZE_CACHE		EQU 2   ; Freeze instruction cache
CLEAR_INST_CACHE_ENTRY	EQU 4   ; Clear instruction cache entry
CLEAR_INST_CACHE	EQU 8   ; Clear instruction cache
INST_BURST_ENABLE	EQU 16  ; Instruction burst enable
ENABLE_DATA_CACHE	EQU 256 ; Enable data cache
FREEZE_DATA_CACHE	EQU 512 ; Freeze data cache
CLEAR_DATA_CACHE_ENTRY	EQU 1024 ; Clear data cache entry
CLEAR_DATA_CACHE	EQU 2048 ; Clear data cache
DATA_BURST_ENABLE	EQU 4096 ; Instruction burst enable
WRITE_ALLOCATE		EQU 8192 ; Write allocate 


enable_data	macro
		movec	cacr,d0
		or.w	#DATA_BURST_ENABLE+CLEAR_DATA_CACHE+WRITE_ALLOCATE+ENABLE_DATA_CACHE,d0
		movec	d0,cacr
		endm

enable_code	macro
		movec	cacr,d0
		or.w	#ENABLE_CACHE+CLEAR_INST_CACHE+INST_BURST_ENABLE+WRITE_ALLOCATE,d0
		bclr	#1,d0		;cleer freez cache
		movec	d0,cacr
		endm

flush_code	macro
		movec	cacr,d0
		bset	#7,d0		;cleer freez cache
		movec	d0,cacr
		endm

flush_data	macro
		movec	cacr,d0
		bset	#12,d0		;cleer freez cache
		movec	d0,cacr
		endm

disable_data	macro
		movec	cacr,d0
		bclr	#7,d0		;cleer freez cache
		movec	d0,cacr
		endm

disable_code	macro
		movec	cacr,d0
		bclr	#0,d0		;cleer freez cache
		movec	d0,cacr
		endm