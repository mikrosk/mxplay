TARGET	= ace.mxp

AS	= vasm

ASFLAGS	= -Ftos -m68030 -quiet -devpac -unnamed-sections -nosym -tos-flags=39	# super, fastload, altram, altalloc

default: $(TARGET)

$(TARGET): ace.S
	$(AS) -o $@ $< $(ASFLAGS)

clean:
	rm -f *~ $(TARGET)

release: $(TARGET)
	chmod +x $<
	cp $< ..
