TARGET	= gt2.mxp

AS	= vasmm68k_mot

ASFLAGS	= -Ftos -m68020up -quiet -devpac -nosym -nocase -tos-flags=39	# super, fastload, altram, altalloc

default: $(TARGET)

$(TARGET): gt2.S
	$(AS) -o $@ $< $(ASFLAGS)

clean:
	rm -f *~ $(TARGET)

release: $(TARGET)
	chmod +x $<
	cp $< ..
