# makefile for mxPlay, support for both native- and cross-compiling

CROSS			= yes
TARGET			= mxplay.app

ifeq ($(CROSS),yes)
 prefix			= m68k-atari-mint-
else
 prefix			=
endif

CC			= ${prefix}gcc
AS			= ${prefix}as
STRIP			= ${prefix}strip -s
FLAGS			= ${prefix}flags -l -r -a -S

UPX			= upx
MAKE			= make

DEBUG_FLAGS		= -g -DDEBUG
OPT_FLAGS		= -O2 -fomit-frame-pointer
CFLAGS			= -Wall -Wshadow $(CPU_FLAGS)

SOBJS			= dsp_fix.S
COBJS			= main.c audio_plugins.c dialogs.c panel.c filelist.c misc.c av.c \
			  dd.c playlist.c file_select.c plugin_info.c timer.c module_info.c \
			  info_dialogs.c debug.c

OBJS			= $(COBJS:.c=.o) $(SOBJS:.s=.o)

LIBS			= -lcflib -lgem
CPU_FLAGS		= -m68020-60		# use 020+ and FPU code

ifeq ($(CONFIG),Release)
 CFLAGS += $(OPT_FLAGS)
endif

ifeq ($(CONFIG),Debug)
 CFLAGS += $(DEBUG_FLAGS)
 #CFLAGS += -DDISABLE_PLUGINS
endif

default: debug

$(TARGET): $(OBJS)
	$(CC) -o $@ $(OBJS) $(LIBS) $(CPU_FLAGS)

debug:
	$(MAKE) $(TARGET) CONFIG="Debug"
	$(FLAGS) $(TARGET)

release:
	$(MAKE) $(TARGET) CONFIG="Release"
	$(STRIP) $(TARGET)
	$(UPX) $(TARGET)
	$(FLAGS) $(TARGET)

clean:
	rm -f *.o *.bak *~ *.app
	rm -f plugins/audio/*~ #plugins/audio/*.mxp
	make -C plugins/audio/xmp clean
	make -C plugins/audio/asap clean
	#make -C plugins/audio/gt clean
