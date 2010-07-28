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

challenge_timer .db
challenge_count .db

.codeseg

.public challenges_init
.public challenges_main

.public challengestats_init
.public challengestats_main

.public brick_menu_bg

.extrn wipeout:proc
.extrn print_value:proc
.extrn count_bits:proc
.extrn main_cycle:byte
.extrn player:player_state
.extrn selected_song:byte
.extrn bitmasktable:byte
.extrn game_type:byte
.extrn rock_score_table:dword
.extrn AC0:byte
.extrn AC1:byte
.extrn AC2:byte

brick_menu_bg:
.incbin "graphics/challenges-bg.dat"
; attributes
.db $23,$C9,$46,$05
.db $23,$D1,$46,$50
.db $23,$D9,$46,$55
.db $23,$E1,$46,$55
.db $23,$E9,$46,$55
.db $23,$F1,$46,$05
.db 0

.proc challenges_init_common
    jsr wipeout

.ifdef MMC
.if MMC == 3
    lda #28 : sta chr_banks[0]
    lda #30 : sta chr_banks[1]
    lda #20 : sta chr_banks[2]
    lda #21 : sta chr_banks[3]
    lda #22 : sta chr_banks[4]
    lda #23 : sta chr_banks[5]
.endif
.endif

    lda #0
    jsr start_song

    ldcay brick_menu_bg
    jsr write_ppu_data_at
    ldcay @@bg_data
    jsr write_ppu_data_at

    jsr print_rock_score

    jsr dim_completed_challenges

    ldcay @@palette
    jsr load_palette
    lda #0 : ldy #31
    jsr set_fade_range
    lda #6
    jmp set_fade_delay

@@bg_data:
.charmap "font.tbl"
.db $20,$8B,$0A : .char "CHALLENGES"
.db $21,$47,$12 : .char "MAKE IT TO THE END"
.db $21,$87,$0A : .char "SCORE OVER"
.db $21,$C7,$0F : .char "STREAK OVER 100"
.db $22,$07,$10 : .char "SPELL D-PAD HERO"
.db $22,$47,$12 : .char "FIND 3 FAKE SKULLS"
.db $22,$87,$10 : .char "BLOW UP ALL POWS"
.db $22,$C7,$13 : .char "DON'T USE ANY ITEMS"
.db $23,$07,$13 : .char "END WITH MAX HEALTH"
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

; Prints the score that much be reached to complete
; the score challenge on the selected song.
.proc print_rock_score
    lda player.difficulty
    asl : asl : asl : asl : asl ; 8*4=32 bytes per difficulty
    adc selected_song ; four
    adc selected_song ; bytes
    adc selected_song ; per
    adc selected_song ; score
    tay
    lda rock_score_table+0,y : sta AC0
    lda rock_score_table+1,y : sta AC1
    lda rock_score_table+2,y : sta AC2
    ldx #5 : lda #$21 : ldy #$92
    jmp print_value
.endp

.proc challenges_init
    jsr challenges_init_common

    ldcay @@bg_data
    jsr write_ppu_data_at

    inc main_cycle

    jsr screen_on
    jsr nmi_on
    jmp start_fade_from_black

@@bg_data:
.charmap "font.tbl"
; B - BACK
.db $23,$64,$06 : .char "B-BACK"
; A - PLAY
.db $23,$76,$06 : .char "A-PLAY"
.db 0
.endp

.proc dim_completed_challenges
    ldy selected_song
    lda player.completed_challenges,y
    lsr
    bcc +
    ; dim 1st row
    pha
    ldy #$23 : lda #$D1 : ldx #$46
    jsr begin_ppu_string
    lda #$A0
    jsr @@finish_ppu_string
    pla
  + pha
    and #3
    beq +
    ; dim 2nd and/or 3rd row
    tay
    lda @@attrib_data,y
    pha
    ldy #$23 : lda #$D9 : ldx #$46
    jsr begin_ppu_string
    pla
    jsr @@finish_ppu_string
  + pla
    lsr : lsr
    pha
    and #3
    beq +
    ; dim 4th and/or 5th row
    tay
    lda @@attrib_data,y
    pha
    ldy #$23 : lda #$E1 : ldx #$46
    jsr begin_ppu_string
    pla
    jsr @@finish_ppu_string
  + pla
    lsr : lsr
    pha
    and #3
    beq +
    ; dim 6th and/or 7th row
    tay
    lda @@attrib_data,y
    pha
    ldy #$23 : lda #$E9 : ldx #$46
    jsr begin_ppu_string
    pla
    jsr @@finish_ppu_string
  + pla
    lsr : lsr : lsr
    bcc +
    ; dim 8th row
    ldy #$23 : lda #$F1 : ldx #$46
    jsr begin_ppu_string
    lda #$0A
    jsr @@finish_ppu_string
  + jmp flush_ppu_buffer

    @@finish_ppu_string:
    jsr put_ppu_string_byte
    jmp end_ppu_string

@@attrib_data:
.db $55,$5A,$A5,$AA
.endp

.proc check_input
    jsr palette_fade_in_progress
    beq +
    rts
  + lda joypad0_posedge
    and #(JOYPAD_BUTTON_START | JOYPAD_BUTTON_A)
    bne @@play
    lda joypad0_posedge
    and #JOYPAD_BUTTON_B
    bne @@go_back
    rts

    @@play:
.ifndef NO_TRANSITIONS
    lda #0
    sta main_cycle

    lda #6 : ldx #4
    jsr start_sfx

    lda #8 : ldy #6
    jsr start_timer
    ldcay @@really_play
    jsr set_timer_callback
    jmp start_fade_to_black

    @@really_play:
.endif
    lda game_type
    beq + ; normal
    lda #26 ; game info
    sta main_cycle
    rts
  + lda #7 ; game start
    sta main_cycle
    rts

    @@go_back:
.ifndef NO_TRANSITIONS
    lda #0
    sta main_cycle

    lda #8 : ldy #6
    jsr start_timer
    ldcay @@really_go_back
    jsr set_timer_callback
    jmp start_fade_to_black

    @@really_go_back:
.endif
    lda #5
    sta main_cycle
    rts
.endp

.proc challenges_main
    jsr reset_sprites
    jmp check_input
.endp

.proc challengestats_init
.if 0
    lda #$FF
    sta player.last_completed_challenges
    sta player.new_completed_challenges
    lda #8
    sta player.won_credit
.endif
    jsr challenges_init_common

    lda #0
    sta challenge_count
    lda #48
    sta challenge_timer

    inc main_cycle

    jsr screen_on
    jsr nmi_on
    jmp start_fade_from_black
.endp

.proc draw_challenge_status_sprites
    lda #0 ; challenge index
  - cmp challenge_count
    bne +
    rts
  + pha
    tay
    lda bitmasktable,y ; mask for challenge
    ldy selected_song
    and player.completed_challenges,y ; previously completed?
    bne ++
    ; left side
    jsr next_sprite_index
    tax
    lda #$11
    sta sprites.tile,x
    lda #35
    sta sprites._x,x
    pla
    pha
    asl : asl : asl : asl ; challenge index * 16
    adc #74
    sta sprites._y,x
    pla
    pha
    tay
    lda bitmasktable,y ; mask for challenge
    ldy selected_song
    and player.new_completed_challenges ; completed just now?
    beq +
    lda #1 ; palette for "completed"
  + sta sprites.attr,x

    ; right side
    jsr next_sprite_index
    tax
    lda #$13
    sta sprites.tile,x
    lda #35+8
    sta sprites._x,x
    pla
    pha
    asl : asl : asl : asl ; challenge index * 16
    adc #74
    sta sprites._y,x
    pla
    pha
    tay
    lda bitmasktable,y ; mask for challenge
    ldy selected_song
    and player.new_completed_challenges ; completed just now?
    beq +
    lda #1 ; palette for "completed"
  + sta sprites.attr,x
 ++ pla
    clc
    adc #1
    bne -
.endp

.proc process_next_challenge
    dec challenge_timer
    beq +
    rts
  + ldy selected_song
    lda player.completed_challenges,y
    ldy challenge_count
    inc challenge_count
    and bitmasktable,y ; challenge previously completed?
    beq +
    inc challenge_timer
    rts
  + lda player.new_completed_challenges
    and bitmasktable,y ; challenge completed now?
    php
    ldx #4
    lda #0 ; "bad" sfx
    plp
    beq +
    lda #6 ; "good" sfx
  + jsr start_sfx
    lda #32
    sta challenge_timer
    rts
.endp

.proc challengestats_main
    jsr reset_sprites
    jsr draw_challenge_status_sprites
    lda challenge_count
    cmp #8
    beq @@check_input
    jmp process_next_challenge

    @@check_input:
    lda joypad0_posedge
    and #(JOYPAD_BUTTON_START | JOYPAD_BUTTON_A)
    bne @@go
    rts

    @@go:
.ifndef NO_TRANSITIONS
    lda #0
    sta main_cycle

    lda #8 : ldy #6
    jsr start_timer
    ldcay @@really_go
    jsr set_timer_callback
    jmp start_fade_to_black

    @@really_go:
.endif
.if 0
    ; remember current score (restored upon continue)
    lda player.score+0
    sta player.checkpoint_score+0
    lda player.score+1
    sta player.checkpoint_score+1
    lda player.score+2
    sta player.checkpoint_score+2
.endif

    ; add the completed challenges for song
    ldy selected_song
    lda player.completed_challenges,y
    ora player.new_completed_challenges
    sta player.completed_challenges,y

    lda player.new_completed_challenges
    bne +
    lda #5 ; song select
    sta main_cycle
    rts
  + lda #30 ; credit win
    sta main_cycle
    rts
.endp

.end
