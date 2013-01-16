TARGET	= mgt.mxp

AS	= vasm
CC	= m68k-atari-mint-gcc
STRIP	= m68k-atari-mint-strip -s

CPU	= -m68020-60
ASFLAGS	= -Faout -m68030 -quiet
CFLAGS	= $(CPU) -Wall -O2 -fomit-frame-pointer -std=c99 -Wno-unused-value
LDFLAGS	= $(CPU) -nostartfiles

default: $(TARGET)

mgt_asm.o: mgt_asm.S ../mxplay.inc
	$(AS) -o $@ mgt_asm.S $(ASFLAGS)

mgt-play.o: mgt-play.S
	$(AS) -o $@ $^ $(ASFLAGS)

mgt.o: mgt.c
	$(CC) -o $@ -c $^ $(CFLAGS)

$(TARGET): mgt_asm.o mgt-play.o mgt.o
	$(CC) -o $@ $^ $(LDFLAGS)

clean:
	rm -f *~ $(TARGET) *.o

release: $(TARGET)
	$(STRIP) $<
	cp $< ..
