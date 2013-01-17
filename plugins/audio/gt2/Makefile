TARGET	= gt2.mxp

AS	= vasm

ASFLAGS	= -Ftos -m68030 -quiet -devpac -unnamed-sections -nosym -nocase -tos-flags=7

default: $(TARGET)

$(TARGET): gt2.S
	$(AS) -o $@ $< $(ASFLAGS)

clean:
	rm -f *~ $(TARGET)

release: $(TARGET)
	chmod +x $<
	cp $< ..
