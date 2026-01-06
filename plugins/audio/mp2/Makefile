TARGET	= mp2.mxp

AS	= vasmm68k_mot

ASFLAGS	= -Ftos -m68020up -quiet -devpac -tos-flags=39	# super, fastload, altram, altalloc

default: $(TARGET)

$(TARGET): mp2.S
	$(AS) -o $@ $< $(ASFLAGS)

clean:
	rm -f *~ $(TARGET)

release: $(TARGET)
	chmod +x $<
	cp $< ..
