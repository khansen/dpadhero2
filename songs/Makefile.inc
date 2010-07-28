SONG_OBJS = \
    $(BUILD_DIR)/endtheme.o \
    $(BUILD_DIR)/elevatortheme.o \
    $(BUILD_DIR)/starstheme.o \
    $(BUILD_DIR)/piecewintheme.o \
    $(BUILD_DIR)/creditwintheme.o \
    $(BUILD_DIR)/versuswintheme.o \
    $(BUILD_DIR)/spacetheme.o \
    $(BUILD_DIR)/titletheme.o \
    $(BUILD_DIR)/misery.o \
    $(BUILD_DIR)/smooth.o \
    $(BUILD_DIR)/count.o \
    $(BUILD_DIR)/ripepray.o \
    $(BUILD_DIR)/levva.o \
    $(BUILD_DIR)/burn.o \
    $(BUILD_DIR)/ocean.o \
    $(BUILD_DIR)/break.o

SONGS_DIR = songs

$(BUILD_DIR)/%.o: $(SONGS_DIR)/%.asm $(SONGS_DIR)/%.inc
	@$(CHK_DIR_EXISTS) $(BUILD_DIR) || $(MKDIR) $(BUILD_DIR) 
	$(XASM) $< -o $@

$(SONGS_DIR)/%.inc: $(SONGS_DIR)/%.xm $(SONGS_DIR)/%-instruments.map
	$(XM2NES) --instruments-map=$(SONGS_DIR)/$(*F)-instruments.map $< > $@
