TARGET	= dspmod.mxp

AS	= vasmm68k_mot

ASFLAGS	= -Ftos -m68020up -quiet -devpac -nosym -tos-flags=37	# super, fastload, altalloc

default: $(TARGET)

$(TARGET): mod_dsp.S
	$(AS) -o $@ $< $(ASFLAGS)

clean:
	rm -f *~ $(TARGET)

release: $(TARGET)
	chmod +x $<
	cp $< ..
