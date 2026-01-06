TARGET	= mpg.mxp

AS	= vasmm68k_mot
CC	= m68k-atari-mintelf-gcc
STRIP	= m68k-atari-mintelf-strip -s
FLAGS	= m68k-atari-mintelf-flags -S

CPU	= -m68020-60
ASFLAGS	= -Felf -m68020up -quiet
CFLAGS	= $(CPU) -Wall -O2 -fomit-frame-pointer -std=c99
LDFLAGS	= $(CPU) -lmpg123 -lm -nostartfiles

TIMER_A	= no
DESTDIR = ..

ifeq ($(TIMER_A),yes)
CFLAGS += -DTIMER_A_HANDLER
endif

default: $(TARGET)

mpg_asm.o: mpg_asm.S ../mxplay.inc
	$(AS) $(ASFLAGS) -o $@ mpg_asm.S

$(TARGET): mpg_asm.o mpg.o
	$(CC) -o $@ $^ $(LDFLAGS)

clean:
	rm -f *~ *.mxp *.o

release: $(TARGET)
	$(STRIP) $<
ifeq ($(TIMER_A),yes)
	$(FLAGS) $<
endif
	cp $< $(DESTDIR)

aranym:
	rm -f *.o
	$(MAKE) TARGET=mpg_ara.mxp TIMER_A=yes DESTDIR=../aranym release

cf:
	rm -f *.o
	$(MAKE) TARGET=mpg_cf.mxp CPU='-mcpu=5475' DESTDIR=../firebee release

all: clean release aranym cf
