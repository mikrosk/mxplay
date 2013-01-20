TARGET	= sndh.mxp

AS	= vasm

ASFLAGS	= -Ftos -m68030 -quiet -devpac -unnamed-sections -nosym -tos-flags=33	# super, fastload

default: $(TARGET)

$(TARGET): sndh.S
	$(AS) -o $@ $< $(ASFLAGS)

clean:
	rm -f *~ $(TARGET)

release: $(TARGET)
	chmod +x $<
	cp $< ..
