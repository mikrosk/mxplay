TARGET	= dspmod.mxp

AS	= vasm

ASFLAGS	= -Ftos -m68030 -quiet -devpac

default: $(TARGET)

$(TARGET): mod_dsp.S
	$(AS) -o $@ $< $(ASFLAGS)

clean:
	rm -f *~ $(TARGET)

release: $(TARGET)
	chmod +x $<
	cp $< ..
