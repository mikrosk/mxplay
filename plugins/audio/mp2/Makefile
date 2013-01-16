TARGET	= mp2.mxp

AS	= vasm

ASFLAGS	= -Ftos -m68030 -quiet -devpac

default: $(TARGET)

$(TARGET): mp2.S
	$(AS) -o $@ $< $(ASFLAGS)

clean:
	rm -f *~ $(TARGET)

release: $(TARGET)
	chmod +x $<
	cp $< ..
