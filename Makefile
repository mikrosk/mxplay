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

DEBUG_FLAGS		= -g -DDEBUG -Wno-shadow
OPT_FLAGS		= -O2 -fomit-frame-pointer -g
CFLAGS			= -Wall -Wshadow $(CPU_FLAGS) -Wno-multichar
ASFLAGS			= $(CPU_FLAGS)

SOBJS			= dsp_fix.S asm_regs.S
COBJS			= main.c audio_plugins.c dialogs.c panel.c filelist.c misc.c av.c \
			  dd.c playlist.c file_select.c plugin_info.c timer.c module_info.c \
			  info_dialogs.c debug.c system.c

OBJS			= $(COBJS:.c=.o) $(SOBJS:.S=.o)

LIBS			= -lcflib -lgem -Wl,--traditional-format
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
	$(MAKE) -C plugins/audio release
	$(MAKE) $(TARGET) CONFIG="Release"
	$(STRIP) $(TARGET)
	$(UPX) $(TARGET)
	$(FLAGS) $(TARGET)

clean:
	rm -f *.o *.bak *~ *.app
	$(MAKE) -C plugins/audio clean
