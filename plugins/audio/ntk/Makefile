TARGET	= ntk.mxp

AS	= vasm

ASFLAGS	= -Ftos -m68030 -quiet

default: $(TARGET)

$(TARGET): ntk.S
	$(AS) -o $@ $< $(ASFLAGS)

clean:
	rm -f *~ $(TARGET)

release: $(TARGET)
	chmod +x $<
	cp $< ..
