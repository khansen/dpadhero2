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

.codeseg

.public gamestats_init
.public gamestats_main

.extrn wipeout:proc
.extrn print_value:proc
.extrn divide:proc
.extrn count_bits:proc
.extrn is_clip_play:proc
.extrn brick_menu_bg:byte
.extrn main_cycle:byte
.extrn player:player_state
.extrn selected_song:byte
.extrn bitmasktable:byte
.extrn AC0:byte
.extrn AC1:byte
.extrn AC2:byte
.extrn MULR:byte
.extrn MULND:byte
.extrn MULTIPLY:label
.extrn PROD:byte
.extrn AUX0:byte
.extrn AUX1:byte
.extrn AUX2:byte

.proc gamestats_init
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

    ldcay @@palette
    jsr load_palette

    jsr print_stats

    lda #0 : ldy #31
    jsr set_fade_range
    lda #6
    jsr set_fade_delay

    inc main_cycle

    jsr screen_on
    jsr nmi_on
    jmp start_fade_from_black

@@bg_data:
.if 0
.incbin "graphics/stats-bg.dat"
; attributes
.db $23,$C9,$46,$55
.db $23,$D1,$46,$05
.db $23,$E1,$46,$05
.db $23,$E9,$46,$50
.endif

.charmap "font.tbl"
.db $20,$8B,$0A : .char "STATISTICS"
.db $21,$46,$04 : .char "HITS"
.db $21,$86,$06 : .char "MISSES"
.db $21,$C6,$06 : .char "ERRORS"
.db $22,$26,$05 : .char "SCORE"
.db $22,$86,$0A : .char "TOP STREAK"
.db $22,$E6,$0A : .char "COMPLETION"
.db $22,$F9,$01 : .char "%"
.db 0

@@palette:
.db $0f,$06,$16,$37,$0f,$20,$20,$20,$0f,$00,$10,$20,$0f,$00,$10,$20
.db $0f,$00,$10,$20,$0f,$00,$10,$20,$0f,$00,$10,$20,$0f,$00,$10,$20
.endp

.proc print_stats
    lda player.hit_count+0 : sta AC0
    lda player.hit_count+1 : sta AC1
    lda #0 : sta AC2
    ldx #3 : lda #$21 : ldy #$57
    jsr print_value

    lda player.missed_count+0 : sta AC0
    lda player.missed_count+1 : sta AC1
    lda #0 : sta AC2
    ldx #3 : lda #$21 : ldy #$97
    jsr print_value

    lda player.err_count+0 : sta AC0
    lda player.err_count+1 : sta AC1
    lda #0 : sta AC2
    ldx #4 : lda #$21 : ldy #$D6
    jsr print_value

    lda player.score+0 : sta AC0
    lda player.score+1 : sta AC1
    lda player.score+2 : sta AC2
    ldx #5 : lda #$22 : ldy #$35
    jsr print_value

    lda player.longest_streak+0 : sta AC0
    lda player.longest_streak+1 : sta AC1
    lda #0 : sta AC2
    ldx #3 : lda #$22 : ldy #$97
    jsr print_value

    ; completion %: (hit_count * 100) / (hit_count + missed_count)
    ; part 1: multiply
    lda player.hit_count+0
    sta MULR+0
    lda player.hit_count+1
    sta MULR+1
    lda #0
    sta MULR+2
    sta MULR+3
    lda #100
    sta MULND+0
    lda #0
    sta MULND+1
    sta MULND+2
    sta MULND+3
    jsr MULTIPLY
    ; part 2: divide
    lda PROD+0
    sta AC0
    lda PROD+1
    sta AC1
    lda PROD+2
    sta AC2
    lda player.hit_count+0
    clc
    adc player.missed_count+0
    sta AUX0
    lda player.hit_count+1
    adc player.missed_count+1
    sta AUX1
    lda #0
    sta AUX2
    jsr divide
    ; figure out number of digits
    ldx #1
    lda AC0
    cmp #10
    bcc +
    inx
  + cmp #100
    bcc +
    inx
  + txa
    sec
    sbc #3
    eor #$FF
    clc
    adc #$F6+1   ; 3 - number of digits + X
    tay
    lda #$22
    jsr print_value
    rts
.endp

.proc check_input
    lda joypad0_posedge
    and #(JOYPAD_BUTTON_START | JOYPAD_BUTTON_A)
    bne @@go
    rts

    @@go:
    lda #0
    sta main_cycle

    lda #8 : ldy #6
    jsr start_timer
    ldcay @@really_go
    jsr set_timer_callback
    jmp start_fade_to_black

    @@really_go:
    jsr is_clip_play
    beq +
    lda #32 ; the end!
    sta main_cycle
    rts
    ; go to challenge stats screen
  + lda #22
    sta main_cycle
    rts
.endp

.proc gamestats_main
    jsr reset_sprites
    jsr check_input
    rts
.endp

.end
