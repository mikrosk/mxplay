TARGET	= ntk.mxp

AS	= vasm

ASFLAGS	= -Ftos -m68030 -quiet -devpac -nocase -nosym

default: $(TARGET)

$(TARGET): ntk.S
	$(AS) -o $@ $< $(ASFLAGS)

clean:
	rm -f *~ $(TARGET)

release: $(TARGET)
	chmod +x $<
	cp $< ..
