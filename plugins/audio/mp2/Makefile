TARGET	= mp2.mxp

AS	= vasm

ASFLAGS	= -Ftos -m68030 -quiet -devpac -tos-flags=39	# super, fastload, altram, altalloc

default: $(TARGET)

$(TARGET): mp2.S
	$(AS) -o $@ $< $(ASFLAGS)

clean:
	rm -f *~ $(TARGET)

release: $(TARGET)
	chmod +x $<
	cp $< ..
