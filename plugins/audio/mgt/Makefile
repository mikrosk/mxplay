TARGET	= mgt.mxp

AS	= vasmm68k_mot
CC	= m68k-atari-mintelf-gcc
STRIP	= m68k-atari-mintelf-strip -s
FLAGS	= m68k-atari-mintelf-flags -S

CPU	= -m68020-60
ASFLAGS	= -Felf -m68020up -quiet
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
	$(FLAGS) $<
	cp $< ..
