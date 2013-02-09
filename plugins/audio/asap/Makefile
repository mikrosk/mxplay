TARGET	= asap.mxp

AS	= vasm
CC	= m68k-atari-mint-gcc
STRIP	= m68k-atari-mint-strip -s
FLAGS	= m68k-atari-mint-flags -S

CPU	= -m68020-60
ASFLAGS	= -Faout -m68882 -m68030 -quiet
CFLAGS	= $(CPU) -Wall -O2 -fomit-frame-pointer -std=c99
LDFLAGS	= $(CPU) -lasap -nostartfiles

TIMER_A	= no

ifeq ($(TIMER_A),yes)
CFLAGS += -DTIMER_A_HANDLER
endif

default: $(TARGET)

asap_asm.o: asap_asm.S ../mxplay.inc
	$(AS) $(ASFLAGS) -o $@ asap_asm.S

$(TARGET): asap_asm.o asap.o
	$(CC) -o $@ $^ $(LDFLAGS)

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
	$(MAKE) TARGET=asap_ara.mxp TIMER_A=yes release

cf:
	rm -f *.o
	$(MAKE) TARGET=asap_cf.mxp CPU='-mcpu=5475' release

all: clean release aranym cf
