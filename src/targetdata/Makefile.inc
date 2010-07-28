TARGET_DATA_OBJS = \
    $(BUILD_DIR)/breaktargets.o \
    $(BUILD_DIR)/oceantargets.o \
    $(BUILD_DIR)/counttargets.o \
    $(BUILD_DIR)/levvatargets.o \
    $(BUILD_DIR)/burntargets.o \
    $(BUILD_DIR)/ripetargets.o

TARGET_DATA_DIR = targetdata

$(BUILD_DIR)/%.o: $(TARGET_DATA_DIR)/%.asm $(TARGET_DATA_DIR)/%.inc
	@$(CHK_DIR_EXISTS) $(BUILD_DIR) || $(MKDIR) $(TARGET_DATA_DIR)
	$(XASM) $< -o $@

$(TARGET_DATA_DIR)/%.inc: $(TARGET_DATA_DIR)/%.xm
	$(XM2BTN) --dump-statistics $< --output=$@
