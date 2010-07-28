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

; 0
;   0 new game
;   1 setup
; 1 new game
;   0 1 player
;   1 2 players
; 2 difficulty (1 player)
;   0 easy
;   1 normal
;   2 hard
; 3 2 players
;   0 co-op
;   1 versus
; 4 difficulty (2 players)
;   0 easy
;   1 normal
;   2 hard
; 5 setup
;   0 controller 1
;   1 controller 2
current_menu .db
current_menu_item .db
; 0 = erase, 1 = draw, 1 = accepting input
menu_state .db
selected_controller .db

; 0 = 1 player, 1 = 2 player co-op, 2 = 2 player vs
game_type .db
.public game_type

.codeseg

.public gameselect_init
.public gameselect_main

.public brick_menu_bg_data

.extrn wipeout:proc
.extrn main_cycle:byte
.extrn frame_count:byte

.proc gameselect_init
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
    ldcay @@bg_data : jsr write_ppu_data_at

    jsr set_black_palette
    ldcay @@palette
    jsr load_palette

    lda #0 : ldy #31
    jsr set_fade_range
    lda #6
    jsr set_fade_delay
    jsr start_fade_from_black

    lda #0 ; main
    jsr load_menu

    lda #6 : jsr start_song

    inc main_cycle

    jsr screen_on
    jsr nmi_on
    rts

@@bg_data:
.charmap "font.tbl"
.db $22,$E6,$06 : .char "B-BACK"
.db $22,$F6,$04 : .char "A-OK"
.db 0

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

brick_menu_bg_data:
.incbin "graphics/gameselect-bg.dat"
; attributes
.db $23,$DA,$44,$55
.db $23,$E2,$44,$55
.db 0

.proc gameselect_main
    jsr reset_sprites
    jsr update_menu
    rts
.endp

; A = menu to load
.proc load_menu
    sta current_menu
    lda #0
    sta current_menu_item
    sta menu_state
    rts
.endp

.proc update_menu
    lda menu_state
    beq @@erase
    cmp #1
    beq @@draw
    ; accepting input
    jsr draw_selection
    jsr check_input
    rts

    @@erase:
    ldy #$21 : lda #$AC : ldx #$4C : jsr begin_ppu_string : lda #0 : jsr put_ppu_string_byte : jsr end_ppu_string
    ldy #$21 : lda #$EC : ldx #$4C : jsr begin_ppu_string : lda #0 : jsr put_ppu_string_byte : jsr end_ppu_string
    ldy #$22 : lda #$2C : ldx #$4C : jsr begin_ppu_string : lda #0 : jsr put_ppu_string_byte : jsr end_ppu_string
    inc menu_state ; draw
    rts

    @@draw:
    lda current_menu
    asl : asl : asl : tay
    lda menu_data_table+4,y ; PPU data size
    tax
    lda menu_data_table+2,y ; PPU data lo
    pha
    lda menu_data_table+3,y ; PPU data hi
    tay
    pla
    jsr copy_bytes_to_ppu_buffer
    inc menu_state ; accepting input
    rts
.endp

menu_data_table:
; parent menu, number of items, PPU data ptr, PPU data size, selected callback, padding
;.db -1, 2 : .dw main_menu_data : .db main_menu_data_end-main_menu_data : .dw main_menu_item_selected : .db 0
.db -1, 2 : .dw new_game_menu_data : .db new_game_menu_data_end-new_game_menu_data : .dw new_game_menu_item_selected : .db 0
.db 0, 3 : .dw difficulty_menu_data : .db difficulty_menu_data_end-difficulty_menu_data : .dw difficulty_menu_item_selected : .db 0
.db 0, 2 : .dw two_player_menu_data : .db two_player_menu_data_end-two_player_menu_data : .dw two_player_menu_item_selected : .db 0
.db 2, 3 : .dw difficulty_menu_data : .db difficulty_menu_data_end-difficulty_menu_data : .dw difficulty_menu_item_selected : .db 0
.if 0
.db 0, 2 : .dw setup_menu_data : .db setup_menu_data_end-setup_menu_data : .dw setup_menu_item_selected : .db 0
.db 5, 2 : .dw controller_menu_data : .db controller_menu_data_end-controller_menu_data : .dw controller_menu_item_selected : .db 0
.db 6, 2 : .dw map_buttons_menu_data : .db map_buttons_menu_data_end-map_buttons_menu_data : .dw map_buttons_menu_item_selected : .db 0
.db 7, 2 : .dw defaults_menu_data : .db defaults_menu_data_end-defaults_menu_data : .dw defaults_menu_item_selected : .db 0
.endif

.charmap "font.tbl"
.if 0
main_menu_data:
.db $21,$AC,8 : .char "NEW GAME"
.db $21,$EC,5 : .char "SETUP"
main_menu_data_end:
.endif

new_game_menu_data:
.db $21,$AC,8 : .char "1 PLAYER"
.db $21,$EC,9 : .char "2 PLAYERS"
new_game_menu_data_end:

difficulty_menu_data:
.db $21,$AC,8 : .char "BEGINNER" ; "easy"
.db $21,$EC,6 : .char "NORMAL"
.db $22,$2C,6 : .char "EXPERT" ; "hard"
difficulty_menu_data_end:

two_player_menu_data:
.db $21,$AC,5 : .char "CO-OP"
.db $21,$EC,6 : .char "VERSUS"
two_player_menu_data_end:

.if 0
setup_menu_data:
.db $21,$AC,12 : .char "CONTROLLER 1"
.db $21,$EC,12 : .char "CONTROLLER 2"
setup_menu_data_end:

controller_menu_data:
.db $21,$AC,4 : .char "TEST"
.db $21,$EC,11 : .char "MAP BUTTONS"
controller_menu_data_end:

map_buttons_menu_data:
.db $21,$AC,8 : .char "DEFAULTS"
.db $21,$EC,6 : .char "CUSTOM"
map_buttons_menu_data_end:

defaults_menu_data:
.db $21,$AC,7 : .char "NES PAD"
.db $21,$EC,8 : .char "KEYBOARD"
defaults_menu_data_end:
.endif

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
    lda #0 : ldx #4
    jmp start_sfx
.endp

.proc play_select_sfx
    lda #6 : ldx #4
    jmp start_sfx
.endp

.proc play_back_sfx
    lda #8 : ldx #4
    jmp start_sfx
.endp

.proc previous_menu
    lda current_menu
    asl : asl : asl : tay
    lda menu_data_table,y
    bmi +
    jsr load_menu
  + jmp play_back_sfx
.endp

.proc previous_menu_item
    dec current_menu_item
    bpl +
    lda current_menu
    asl : asl : asl : tay
    lda menu_data_table+1,y ; number of items
    sta current_menu_item
    dec current_menu_item
  + jmp play_cursor_sfx
.endp

.proc next_menu_item
    lda current_menu
    asl : asl : asl : tay
    inc current_menu_item
    lda current_menu_item
    cmp menu_data_table+1,y ; number of items
    bcc +
    lda #0
    sta current_menu_item
  + jmp play_cursor_sfx
.endp

.proc select_menu_item
    jsr play_select_sfx
    lda current_menu
    asl : asl : asl : tay
    lda menu_data_table+5,y ; function ptr lo
    pha
    lda menu_data_table+6,y ; function ptr hi
    tay
    pla
    jmp call_fptr
.endp

.if 0
.proc main_menu_item_selected
    lda current_menu_item
    beq @@new_game_selected
    ; setup selected
    lda #5
    jmp load_menu
    @@new_game_selected:
    lda #1 ; new game
    jmp load_menu
.endp
.endif

.proc new_game_menu_item_selected
    lda current_menu_item
    beq @@one_player_selected
    ; two players selected
    lda #2
    jmp load_menu
    @@one_player_selected:
    lda #0
    sta game_type
    lda #1 ; difficulty
    jsr load_menu
    lda #1
    sta current_menu_item ; normal is default
    rts
.endp

.proc difficulty_menu_item_selected
    lda current_menu_item
    sta player.difficulty
    jmp start_game
.endp

.proc two_player_menu_item_selected
    lda current_menu_item
    sta game_type
    inc game_type
    lda #3 ; difficulty
    jsr load_menu
    lda #1
    sta current_menu_item ; normal is default
    rts
.endp

.if 0
.proc setup_menu_item_selected
    lda current_menu_item
    sta selected_controller
    lda #6
    jmp load_menu
.endp

.proc controller_menu_item_selected
    lda current_menu_item
    beq @@test_selected
    ; map buttons selected
    lda #7
    jmp load_menu
    @@test_selected:
    rts
.endp

.proc map_buttons_menu_item_selected
    lda current_menu_item
    beq @@defaults_selected
    ; map buttons selected
    rts
    @@defaults_selected:
    lda #8
    jmp load_menu
.endp

.proc defaults_menu_item_selected
    ldx #4
    lda selected_controller
    beq +
    ldx #9
  + lda current_menu_item
    beq @@nes_pad_selected
    ; keyboard selected
    jsr set_emu_button_mapping
    jmp +
    @@nes_pad_selected:
    jsr set_default_button_mapping
    ; back to controller menu
  + lda #6
    jmp load_menu
.endp
.endif

.proc start_game
.ifndef NO_TRANSITIONS
    lda #1 : ldx #4
    jsr start_sfx

    lda #0
    sta main_cycle

    lda #13 : ldy #6
    jsr start_timer
    ldcay @@really_start
    jsr set_timer_callback
    jsr start_audio_fade_out
    jmp start_fade_to_black

    @@really_start:
.endif
    ldy #0   ; default: no songs unlocked
    lda game_type
    cmp #2 ; versus?
    bne +
    ldy #$3F ; in versus mode, all songs are unlocked
  + sty player.unlocked_songs

.ifdef LIFE_SUPPORT
    lda #2
    sta player.life_count
.endif
    lda #0
    sta player.completed_challenges+0
    sta player.completed_challenges+1
    sta player.completed_challenges+2
    sta player.completed_challenges+3
    sta player.completed_challenges+4
    sta player.completed_challenges+5
    sta player.acquired_pad_pieces
    sta player.beat_game
    ldy player.difficulty
    lda @@initial_credit,y
    sta player.credit

    lda #5 ; song select
    sta main_cycle
    rts

@@initial_credit:
.db 8 ; easy
.db 4 ; normal
.db 2 ; hard
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
.endp

.end
