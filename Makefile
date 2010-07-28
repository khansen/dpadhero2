PROGRAM = dpadhero2

CHK_DIR_EXISTS = test -d
MKDIR          = mkdir -p

AFLAGS = --debug -I. -I$(BASESRCDIR) -DMMC=3 -DBULLET_TIME_SUPPORT -DPATTERN_ROW_CALLBACK_SUPPORT -DORDER_SEEKING_SUPPORT -DNO_TOP_SCORE
LFLAGS = 

XASM = xasm $(AFLAGS)
XLNK = xlnk $(LFLAGS)
XM2NES = xm2nes
XM2BTN = ../tools/xm2btn/xm2btn

BUILD_DIR = build

BASESRCDIR = .

first: all

include $(BASESRCDIR)/common/Makefile.inc
include $(BASESRCDIR)/sound/Makefile.inc
include songs/Makefile.inc
include targetdata/Makefile.inc

OBJS = $(COMMON_OBJS) $(SOUND_OBJS) $(SONG_OBJS) $(TARGET_DATA_OBJS) \
    $(BUILD_DIR)/fade.o \
    $(BUILD_DIR)/palette.o \
    $(BUILD_DIR)/mmc3.o \
    $(BUILD_DIR)/sfxdata.o \
    $(BUILD_DIR)/songtable.o \
    $(BUILD_DIR)/dmcdata.o \
    $(BUILD_DIR)/title.o \
    $(BUILD_DIR)/gameselect.o \
    $(BUILD_DIR)/songselect.o \
    $(BUILD_DIR)/songselectdata.o \
    $(BUILD_DIR)/targetdatatable.o \
    $(BUILD_DIR)/ampdisplay.o \
    $(BUILD_DIR)/challenges.o \
    $(BUILD_DIR)/gameinfo.o \
    $(BUILD_DIR)/gameuidata.o \
    $(BUILD_DIR)/game.o \
    $(BUILD_DIR)/gamestats.o \
    $(BUILD_DIR)/gameover.o \
    $(BUILD_DIR)/creditwin.o \
    $(BUILD_DIR)/piecewin.o \
    $(BUILD_DIR)/versuswin.o \
    $(BUILD_DIR)/parallax.o \
    $(BUILD_DIR)/starfield.o \
    $(BUILD_DIR)/cutscene.o \
    $(BUILD_DIR)/multiply.o \
    $(BUILD_DIR)/theend.o \
    $(BUILD_DIR)/main.o

HEADERFILE = ines.hdr
CHRFILES = graphics/title-bg.chr \
    graphics/title-spr.chr \
    graphics/songselect-bg.chr \
    graphics/songselect-spr.chr \
    graphics/game.chr \
    graphics/gameselect-bg.chr \
    graphics/challenges-bg.chr \
    graphics/cutscene.chr \
    graphics/completedpad.chr \
    graphics/magazine-bg.chr \
    graphics/guitar-fender-8x8.chr \
    graphics/guitar-lespaul-8x8.chr \
    graphics/guitar-vortex-8x8.chr \
    graphics/paperfont.chr \
    graphics/rockface-spr.chr \
    graphics/kentando-bg.chr

SCRIPTFILE = link.s
BINFILE = $(PROGRAM).nes

all: $(BUILD_DIR)/$(BINFILE)

$(BUILD_DIR)/$(BINFILE): $(OBJS) $(CHRFILES) $(SCRIPTFILE) $(HEADERFILE)
	$(XLNK) $(SCRIPTFILE) -o $@

$(BUILD_DIR)/%.o: %.asm
	@$(CHK_DIR_EXISTS) $(BUILD_DIR) || $(MKDIR) $(BUILD_DIR)
	$(XASM) $< -o $@

$(BUILD_DIR)/mmc3.o: $(BASESRCDIR)/mmc/mmc3.asm
	@$(CHK_DIR_EXISTS) $(BUILD_DIR) || $(MKDIR) $(BUILD_DIR)
	$(XASM) $< -o $@

.PHONY: clean

clean:
	-rm -f $(BUILD_DIR)/$(BINFILE) $(OBJS)
