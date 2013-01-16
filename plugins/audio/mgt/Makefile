#TARGET	= mgt.mxp
TARGET	= mgt.prg

AS	= vasm
CC	= m68k-atari-mint-gcc
STRIP	= m68k-atari-mint-strip -s

CPU	= -m68020-60
ASFLAGS	= -Faout -m68030 -quiet
CFLAGS	= $(CPU) -Wall -O2 -fomit-frame-pointer -std=c99 -mshort -Wno-unused-value -g
LDFLAGS	= $(CPU) -g -Wl,--traditional-format #-nostartfiles

default: $(TARGET)

mgt_asm.o: mgt_asm.S ../mxplay.inc
	$(AS) -o $@ mgt_asm.S $(ASFLAGS)

mgt-play.o: mgt-play.S
	$(AS) -o $@ $^ $(ASFLAGS)

unpack.o: unpack.S
	$(AS) -o $@ $^ $(ASFLAGS)

mgt.o: mgt.c
	$(CC) -o $@ -c $^ $(CFLAGS)

#$(TARGET): mgt_asm.o mgt-play.o unpack.o mgt.c
$(TARGET): mgt-play.o unpack.o mgt.o
	$(CC) -o $@ $^ $(LDFLAGS)

clean:
	rm -f *~ $(TARGET) *.o

release: $(TARGET)
	$(STRIP) $<
	cp $< ..
