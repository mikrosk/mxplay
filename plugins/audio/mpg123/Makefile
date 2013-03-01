TARGET	= mpg.mxp

AS	= vasm
CC	= m68k-atari-mint-gcc
STRIP	= m68k-atari-mint-strip -s
FLAGS	= m68k-atari-mint-flags -S
STACK	= m68k-atari-mint-stack --fix=128k

CPU	= -m68020-60
ASFLAGS	= -Faout -m68882 -m68030 -quiet
CFLAGS	= $(CPU) -Wall -O2 -fomit-frame-pointer -std=c99
LDFLAGS	= $(CPU) -lmpg123 -lm -nostartfiles

TIMER_A	= no

ifeq ($(TIMER_A),yes)
CFLAGS += -DTIMER_A_HANDLER
endif

default: $(TARGET)

mpg_asm.o: mpg_asm.S ../mxplay.inc
	$(AS) $(ASFLAGS) -o $@ mpg_asm.S

$(TARGET): mpg_asm.o mpg.o
	$(CC) -o $@ $^ $(LDFLAGS)
	$(STACK) $@

clean:
	rm -f *~ *.mxp *.o

release: $(TARGET)
	$(STRIP) $<
ifeq ($(TIMER_A),yes)
	$(FLAGS) $<
endif
	cp $< ..

aranym:
	rm -f *.o
	$(MAKE) TARGET=mpg_ara.mxp TIMER_A=yes release

cf:
	rm -f *.o
	$(MAKE) TARGET=mpg_cf.mxp CPU='-mcpu=5475' release

all: clean release aranym cf
