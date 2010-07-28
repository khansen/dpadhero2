;
;    Copyright (C) 2010 Kent Hansen.
;
;    This program is free software; you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation; either version 3 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;

.include "common/fade.h"
.include "common/joypad.h"
.include "common/ldc.h"
.include "common/palette.h"
.include "common/ppu.h"
.include "common/ppubuffer.h"
.include "common/sprite.h"
.include "common/timer.h"
.include "sound/mixer.h"
.include "sound/sound.h"
.include "sound/sfx.h"
.include "player.h"

.ifdef MMC
.if MMC == 3
.include "mmc/mmc3.h"
.endif
.endif

.dataseg

current_menu_item .db

.codeseg

.public gameover_init
.public gameover_main

.extrn wipeout:proc
.extrn is_clip_play:proc
.extrn setup_clip_play:proc
.extrn go_to_title_screen:proc
.extrn brick_menu_bg_data:byte
.extrn game_type:byte
.extrn main_cycle:byte
.extrn frame_count:byte

.proc gameover_init
    jsr wipeout

.ifdef MMC
.if MMC == 3
    lda #24 : sta chr_banks[0]
    lda #26 : sta chr_banks[1]
    lda #12 : sta chr_banks[2]
    lda #13 : sta chr_banks[3]
    lda #14 : sta chr_banks[4]
    lda #15 : sta chr_banks[5]
.endif
.endif

    ldcay brick_menu_bg_data : jsr write_ppu_data_at
    jsr draw_menu

    jsr set_black_palette
    ldcay @@palette : jsr load_palette

    lda #0 : ldy #31
    jsr set_fade_range
    lda #6
    jsr set_fade_delay
    jsr start_fade_from_black

    lda #0 : jsr start_song

    lda #0 : sta current_menu_item

    inc main_cycle

    jsr screen_on
    jsr nmi_on
    rts

@@palette:
.db $0f,$06,$16,$37 ; bricks and frame
.db $0f,$20,$20,$20 ; white text
.db $0f,$00,$00,$00 ; gray text
.db $0f,$00,$10,$20
.db $0f,$06,$16,$20
.db $0f,$0A,$1A,$20
.db $0f,$00,$10,$20
.db $0f,$00,$10,$20
.endp

.proc draw_menu
    jsr is_clip_play
    bne +
    ldcay @@normal_data : jmp write_ppu_data_at
  + ldcay @@clip_data : jmp write_ppu_data_at

.charmap "font.tbl"
@@normal_data:
.db $21,$AC,10 : .char "PLAY AGAIN"
.db $21,$EC,11 : .char "CHANGE SONG"
.db $22,$2C,4 : .char "QUIT"
.db 0

@@clip_data:
.db $21,$AC,10 : .char "PLAY AGAIN"
.db $21,$EC,4 : .char "QUIT"
.db 0
.endp

.proc gameover_main
    jsr reset_sprites
    jsr draw_selection
    jsr check_input
    rts
.endp

.proc draw_selection
    jsr next_sprite_index
    tax
    lda #$11
    sta sprites.tile,x
    lda current_menu_item
    asl : asl : asl : asl
    adc #103
    sta sprites._y,x
    lda #84
    sta sprites._x,x
    lda #0
    sta sprites.attr,x
    rts
.endp

.proc play_cursor_sfx
    lda #0
    ldx #4
    jmp start_sfx
.endp

.proc get_menu_item_count
    jsr is_clip_play
    bne +
    lda #3
    rts
  + lda #2
    rts
.endp

.proc previous_menu
    rts
.endp

.proc previous_menu_item
    dec current_menu_item
    bpl +
    jsr get_menu_item_count
    sec : sbc #1
    sta current_menu_item
  + jmp play_cursor_sfx
.endp

.proc next_menu_item
    inc current_menu_item
    jsr get_menu_item_count
    cmp current_menu_item
    bne +
    lda #0
    sta current_menu_item
  + jmp play_cursor_sfx
.endp

.proc select_menu_item
.ifndef NO_TRANSITIONS
    lda #0
    sta main_cycle

    lda #6 : ldx #4
    jsr start_sfx

    lda #8 : ldy #6
    jsr start_timer
    ldcay @@really_select
    jsr set_timer_callback
    jmp start_fade_to_black

    @@really_select:
.endif
    jsr is_clip_play
    bne @@select_clip_menu_item
    ; select normal menu item
    lda current_menu_item
    beq @@play_again_normal_selected
    cmp #1
    beq @@song_select_selected
    @@quit_selected:
    jmp go_to_title_screen
    @@play_again_normal_selected:
    lda #20 ; challenges init
    ldx game_type
    cpx #2 ; versus?
    bne +
    lda #26 ; skip straight to game info
  + sta main_cycle
    rts
    @@song_select_selected:
    lda #5
    sta main_cycle
    rts

    @@select_clip_menu_item:
    lda current_menu_item
    bne @@quit_selected
    ; play clip again selected
    jsr setup_clip_play
    lda #7 ; game start
    ldy game_type
    beq + ; 1 player
    lda #26 ; game info
  + sta main_cycle
    rts
.endp

.proc check_input
    jsr palette_fade_in_progress
    beq +
    rts
  + lda joypad0_posedge
    and #(JOYPAD_BUTTON_START | JOYPAD_BUTTON_A)
    bne @@select
    lda joypad0_posedge
    and #JOYPAD_BUTTON_UP
    bne @@up
    lda joypad0_posedge
    and #(JOYPAD_BUTTON_DOWN | JOYPAD_BUTTON_SELECT)
    bne @@down
    lda joypad0_posedge
    and #JOYPAD_BUTTON_B
    bne @@back
    rts

    @@back:
    jmp previous_menu
    @@up:
    jmp previous_menu_item
    @@down:
    jmp next_menu_item
    @@select:
    jmp select_menu_item
    rts
.endp

.end
