TARGET	= ntk.mxp

AS	= vasmm68k_mot

ASFLAGS	= -Ftos -m68020up -quiet -devpac -nocase -nosym -tos-flags=39	# super, fastload, altram, altalloc

default: $(TARGET)

$(TARGET): ntk.S
	$(AS) -o $@ $< $(ASFLAGS)

clean:
	rm -f *~ $(TARGET)

release: $(TARGET)
	chmod +x $<
	cp $< ..
