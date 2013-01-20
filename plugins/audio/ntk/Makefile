TARGET	= ntk.mxp

AS	= vasm

ASFLAGS	= -Ftos -m68030 -quiet -devpac -nocase -nosym -tos-flags=39	# super, fastload, altram, altalloc

default: $(TARGET)

$(TARGET): ntk.S
	$(AS) -o $@ $< $(ASFLAGS)

clean:
	rm -f *~ $(TARGET)

release: $(TARGET)
	chmod +x $<
	cp $< ..
