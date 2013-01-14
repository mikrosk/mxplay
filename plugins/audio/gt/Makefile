TARGET	= gt.mxp

AS	= vasm

ASFLAGS	= -Ftos -m68882 -m68030 -quiet

default: $(TARGET)

$(TARGET): gt.s ../mxplay.inc
	$(AS) $(ASFLAGS) -o $@ gt.s

clean:
	rm -f *~ $(TARGET)

release: $(TARGET)
	cp $< ..
