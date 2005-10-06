CC			= gcc
STRIP			= strip -s
COMPRESS		= upx
CHANGE_FLAGS		= flags -l -r -a
MAKE			= make

DEBUG_FLAGS		= -g
OPT_FLAGS		= -O2 -fomit-frame-pointer

INCLUDE_GEM_PATH	= /usr/GEM/include
LIB_GEM_PATH		= /usr/GEM/lib

CFLAGS			= -Wall -Wshadow -I$(INCLUDE_GEM_PATH) $(CPU_FLAGS)

SOBJS			= dsp_fix.s vbl_timer_asm.s
COBJS			= main.c audio_plugins.c dialogs.c panel.c filelist.c misc.c av.c \
			  dd.c playlist.c file_select.c plugin_info.c vbl_timer.c module_info.c \
			  info_dialogs.c
			  
OBJS			= $(COBJS:.c=.o) $(SOBJS:.s=.o)

PROGRAM			= mxPlay-mint.app
PROGRAM_NO_MINT		= mxPlay.app


ifneq ($(FPU),no)
CPU_FLAGS		= -m68020-60		# use 020+ and FPU code
LIBS			= -lcflib020 -lgem020	# for libc / mxPlay / gem libs
else
CPU_FLAGS		= -m68030		# use 030 code for mxPlay
LIBS			= -lcflib -lgem		# libc and gem libs are "normal"
endif

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
	$(CC) -o $@ $(OBJS) -L$(LIB_GEM_PATH) $(LIBS)
	
$(PROGRAM_NO_MINT): $(OBJS)
	$(CC) -o $@ $(OBJS) -L$(LIB_GEM_PATH) $(LIBS)

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
	make dist-mint FPU=no
	mv $(PROGRAM) ../mxPlayM.app
	make clean
	make dist-mint
	mv $(PROGRAM) ../mxPlayMF.app
	make clean
	make dist-nomint FPU=no
	mv $(PROGRAM_NO_MINT) ../mxPlay.app
	make clean
	make dist-nomint
	mv $(PROGRAM_NO_MINT) ../mxPlayF.app
	make clean
	
strip-mint:
	$(STRIP) $(PROGRAM)
	
strip-nomint:
	$(STRIP) $(PROGRAM_NO_MINT)
	
compress-mint:
	$(COMPRESS) $(PROGRAM)
	
compress-nomint:
	$(COMPRESS) $(PROGRAM_NO_MINT)
	
flags-mint:
	$(CHANGE_FLAGS) $(PROGRAM)
	
flags-nomint:
	$(CHANGE_FLAGS) $(PROGRAM_NO_MINT)

clean:
	rm -f *.o *.bak *.app
