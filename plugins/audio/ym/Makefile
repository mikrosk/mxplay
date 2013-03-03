TARGET	= ym.mxp

AS	= vasm
CC	= m68k-atari-mint-gcc
CXX	= m68k-atari-mint-g++
STRIP	= m68k-atari-mint-strip -s
FLAGS	= m68k-atari-mint-flags -S

CPU	= -m68020-60
ASFLAGS	= -Faout -m68882 -m68030 -quiet
CFLAGS	= $(CPU) -Wall -O2 -fomit-frame-pointer -std=c99
CXXFLAGS= $(filter-out -std=c99, $(CFLAGS)) -Wno-write-strings
LDFLAGS	= $(CPU) -nostartfiles

TIMER_A	= no
DESTDIR = ..

ifeq ($(TIMER_A),yes)
CFLAGS += -DTIMER_A_HANDLER
endif

default: $(TARGET)

ym_asm.o: ym_asm.S ../mxplay.inc
	$(AS) $(ASFLAGS) -o $@ ym_asm.S

$(TARGET): ym_asm.o ym.o StSoundLibrary/digidrum.o StSoundLibrary/Ym2149Ex.o StSoundLibrary/Ymload.o StSoundLibrary/YmMusic.o StSoundLibrary/YmUserInterface.o StSoundLibrary/LZH/LzhLib.o
	$(CXX) -o $@ $^ $(LDFLAGS)

clean:
	rm -f *~ *.mxp *.o StSoundLibrary/*.o StSoundLibrary/LZH/*.o

release: $(TARGET)
	$(STRIP) $<
ifeq ($(TIMER_A),yes)
	$(FLAGS) $<
endif
	cp $< $(DESTDIR)

aranym:
	rm -f *.o
	$(MAKE) TARGET=ym_ara.mxp TIMER_A=yes DESTDIR=../aranym release

cf:
	rm -f *.o
	$(MAKE) TARGET=ym_cf.mxp CPU='-mcpu=5475' DESTDIR=../firebee release

all: clean release aranym cf
