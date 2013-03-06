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

DEBUG_FLAGS		= -g -DDEBUG -Wextra -Wno-sign-compare
OPT_FLAGS		= -O2 -fomit-frame-pointer -g
CFLAGS			= -Wall $(CPU_FLAGS) -Wno-multichar -std=c99 -D_BSD_SOURCE
ASFLAGS			= $(CPU_FLAGS)

SOBJS			= dsp_fix.S asm_routines.S
COBJS			= main.c audio_plugins.c dialogs.c panel.c filelist.c misc.c av.c \
			  dd.c playlist.c file_select.c plugin_info.c timer.c module_info.c \
			  info_dialogs.c debug.c system.c

OBJS			= $(COBJS:.c=.o) $(SOBJS:.S=.o)

LIBS			= -lcflib -lgem -lm #-Wl,--traditional-format
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
ifneq ($(TARGET), mxplay_cf.app)
	$(MAKE) -C plugins/audio release
endif
	$(MAKE) $(TARGET) CONFIG="Release"
	$(STRIP) $(TARGET)
ifneq ($(TARGET), mxplay_cf.app)
	$(UPX) $(TARGET)
	$(FLAGS) $(TARGET)
endif

clean:
	rm -f *.o *.bak *~ *.app
	$(MAKE) -C plugins/audio clean

cf:
	rm -f *.o
	$(MAKE) TARGET=mxplay_cf.app CPU_FLAGS='-mcpu=5475' release

all: clean release cf
