TARGET	= dspmod.mxp

AS	= vasm

ASFLAGS	= -Ftos -m68030 -quiet -devpac -nosym -tos-flags=37	# super, fastload, altalloc

default: $(TARGET)

$(TARGET): mod_dsp.S
	$(AS) -o $@ $< $(ASFLAGS)

clean:
	rm -f *~ $(TARGET)

release: $(TARGET)
	chmod +x $<
	cp $< ..
