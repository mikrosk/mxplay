CC			= gcc
STRIP			= strip -s
COMPRESS		= upx
CHANGE_FLAGS		= flags -l -r -a
MAKE			= make

DEBUG_FLAGS		= -g
OPT_FLAGS		= -O2 -fomit-frame-pointer
CPU_FLAGS		= -m68020-60

INCLUDE_GEM_PATH	= /usr/GEM/include
LIB_GEM_PATH		= /usr/GEM/lib
LIBS			= -lcflib020 -lgem020

CFLAGS			= -Wall -Wshadow -I$(INCLUDE_GEM_PATH) $(CPU_FLAGS)

SOBJS			= dsp_fix.s vbl_timer_asm.s
COBJS			= main.c audio_plugins.c dialogs.c panel.c filelist.c misc.c av.c \
			  dd.c playlist.c file_select.c plugin_info.c vbl_timer.c module_info.c \
			  info_dialogs.c
			  
OBJS			= $(COBJS:.c=.o) $(SOBJS:.s=.o)

PROGRAM			= mxPlay-mint.app
PROGRAM_NO_MINT		= mxPlay.app


ifneq ($(TARGET),MiNT)
CFLAGS += -DNO_MINT
ASFLAGS += --defsym NO_MINT=1
endif

ifeq ($(CONFIG),Release)
CFLAGS += $(OPT_FLAGS)
endif

ifeq ($(CONFIG),Debug)
CFLAGS += $(DEBUG_FLAGS)
endif


all: mint

mint:
	$(MAKE) $(PROGRAM) CONFIG="Debug" TARGET="MiNT"

mint-release:
	$(MAKE) $(PROGRAM) CONFIG="Release" TARGET="MiNT"

nomint:
	$(MAKE) $(PROGRAM_NO_MINT) CONFIG="Debug" TARGET=""

nomint-release:
	$(MAKE) $(PROGRAM_NO_MINT) CONFIG="Release" TARGET=""
	
	
$(PROGRAM): $(OBJS)
	$(CC) -o $@ $(OBJS) -L$(LIB_GEM_PATH) $(LIBS)
	
$(PROGRAM_NO_MINT): $(OBJS)
	$(CC) -o $@ $(OBJS) -L$(LIB_GEM_PATH) $(LIBS)


strip:
	$(STRIP) $(PROGRAM)
	
strip-nomint:
	$(STRIP) $(PROGRAM_NO_MINT)
	
compress:
	$(COMPRESS) $(PROGRAM)
	
compress-nomint:
	$(COMPRESS) $(PROGRAM_NO_MINT)
	
flags:
	$(CHANGE_FLAGS) $(PROGRAM)
	
flags-nomint:
	$(CHANGE_FLAGS) $(PROGRAM_NO_MINT)

mint-dist:
	make mint-release
	make strip
	make compress
	#make flags

nomint-dist:
	make nomint-release
	make strip-nomint
	make compress-nomint
	#make flags-nomint
clean:
	rm -f *.o *.bak *.app
