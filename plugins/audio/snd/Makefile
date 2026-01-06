TARGET	= sndh.mxp

AS	= vasmm68k_mot

ASFLAGS	= -Ftos -m68020up -quiet -devpac -nosym -tos-flags=33	# super, fastload

default: $(TARGET)

$(TARGET): sndh.S
	$(AS) -o $@ $< $(ASFLAGS)

clean:
	rm -f *~ $(TARGET)

release: $(TARGET)
	chmod +x $<
	cp $< ..
