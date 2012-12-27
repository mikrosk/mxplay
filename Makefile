# makefile for mxPlay, support for both native- and cross-compiling

CROSS=yes

ifeq ($(CROSS),yes)
 prefix			= m68k-atari-mint-
else
 prefix			= 
endif

CC			= ${prefix}gcc
AS			= ${prefix}as
STRIP			= ${prefix}strip -s
FLAGS			= ${prefix}flags -l -r -a

UPX			= upx
MAKE			= make

DEBUG_FLAGS		= -g
OPT_FLAGS		= -O2 -fomit-frame-pointer
CFLAGS			= -Wall -Wshadow $(CPU_FLAGS)

SOBJS			= dsp_fix.S vbl_timer_asm.S
COBJS			= main.c audio_plugins.c dialogs.c panel.c filelist.c misc.c av.c \
			  dd.c playlist.c file_select.c plugin_info.c vbl_timer.c module_info.c \
			  info_dialogs.c
			  
OBJS			= $(COBJS:.c=.o) $(SOBJS:.s=.o)

PROGRAM			= mxPlay-mint.app
PROGRAM_NO_MINT		= mxPlay.app

LIBS			= -lcflib -lgem
CPU_FLAGS		= -m68020-60		# use 020+ and FPU code

ifneq ($(TARGET),MiNT)
 CFLAGS += -DNO_MINT
 ASFLAGS += --defsym NO_MINT=1
endif

ifeq ($(CONFIG),Release)
 CFLAGS += $(OPT_FLAGS)
endif

ifeq ($(CONFIG),Debug)
 CFLAGS += $(DEBUG_FLAGS)
 #CFLAGS += -DDISABLE_PLUGINS
endif


all: mint

$(PROGRAM): $(OBJS)
	$(CC) -o $@ $(OBJS) $(LIBS) $(CPU_FLAGS)
	
$(PROGRAM_NO_MINT): $(OBJS)
	$(CC) -o $@ $(OBJS) $(LIBS) $(CPU_FLAGS)

mint:
	$(MAKE) $(PROGRAM) CONFIG="Debug" TARGET="MiNT"

release-mint:
	$(MAKE) $(PROGRAM) CONFIG="Release" TARGET="MiNT"

nomint:
	$(MAKE) $(PROGRAM_NO_MINT) CONFIG="Debug" TARGET=""

release-nomint:
	$(MAKE) $(PROGRAM_NO_MINT) CONFIG="Release" TARGET=""

dist-mint:
	make release-mint
	make strip-mint
	make compress-mint
	make flags-mint

dist-nomint:
	make release-nomint
	make strip-nomint
	make compress-nomint
	make flags-nomint

# real lameness
dist-all:
	make clean
	make dist-mint
	mv $(PROGRAM) ../mxPlayM.app
	make clean
	make dist-nomint
	mv $(PROGRAM_NO_MINT) ../mxPlay.app
	
strip-mint:
	$(STRIP) $(PROGRAM)
	
strip-nomint:
	$(STRIP) $(PROGRAM_NO_MINT)
	
compress-mint:
	$(UPX) $(PROGRAM)
	
compress-nomint:
	$(UPX) $(PROGRAM_NO_MINT)
	
flags-mint:
	$(FLAGS) $(PROGRAM)
	
flags-nomint:
	$(FLAGS) $(PROGRAM_NO_MINT)

clean:
	rm -f *.o *.bak *~ *.app
