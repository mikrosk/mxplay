TARGET	= asap.mxp

AS	= vasm
CC	= m68k-atari-mint-gcc
STRIP	= m68k-atari-mint-strip -s
FLAGS	= m68k-atari-mint-flags -S

CPU	= -m68020-60
ASFLAGS	= -Faout -m68882 -m68030 -quiet
CFLAGS	= $(CPU) -Wall -O2 -fomit-frame-pointer -std=c99
LDFLAGS	= $(CPU) -lasap -nostartfiles

default: $(TARGET)

asap_asm.o: asap_asm.S ../mxplay.inc
	$(AS) $(ASFLAGS) -o $@ asap_asm.S

$(TARGET): asap_asm.o asap.o
	$(CC) -o $@ $^ $(LDFLAGS)

clean:
	rm -f *~ $(TARGET) *.o

release: $(TARGET)
	$(STRIP) $<
	$(FLAGS) $<
	cp $< ..
