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

.public difficultyselect_init
.public difficultyselect_main

.extrn wipeout:proc
.extrn main_cycle:byte
.extrn frame_count:byte

.proc difficultyselect_init
    jsr wipeout

.ifdef MMC
.if MMC == 3
    lda #24 : sta chr_banks[0]
    lda #26 : sta chr_banks[1]
    lda #0  : sta chr_banks[2]
    lda #0  : sta chr_banks[3]
    lda #0  : sta chr_banks[4]
    lda #0  : sta chr_banks[5]
.endif
.endif

    ldcay @@bg_data
    jsr write_ppu_data_at

    jsr set_black_palette
    ldcay @@palette
    jsr load_palette

    lda #0
    ldy #31
    jsr set_fade_range
    lda #7
    jsr set_fade_delay
    jsr start_fade_from_black

    lda #6
    jsr start_song

    lda #1
    sta player.difficulty ; normal is default

    inc main_cycle

    jsr screen_on
    jsr nmi_on
    rts

@@palette:
.db $0f,$06,$16,$27,$0f,$27,$00,$20,$0f,$06,$00,$10,$0f,$00,$10,$20
.db $0f,$0C,$00,$20,$0f,$20,$20,$20,$0f,$20,$20,$20,$0f,$20,$20,$20

@@bg_data:
.incbin "graphics/difficultyselect-bg.dat"
; attribute table
.db $23,$C1,$43,$55
.db $23,$C9,$43,$55
.db $23,$D1,$43,$55
.db $23,$D9,$43,$55
.db $23,$E1,$43,$55
.db $23,$E9,$43,$55
.db $23,$F1,$43,$55
.db 0
.endp

.proc difficultyselect_main
    jsr reset_sprites
    lda frame_count
    lsr : lsr : lsr : lsr
    jsr draw_selection
    jsr check_input
    rts
.endp

; CF: 0 = normal, 1 = other
.proc draw_selection
; To highlight the selection, we flip the palette of the current row.
; Each row is 6 tiles tall.
    php
; upper tiles
    ldy player.difficulty
    lda @@attrib_length,y
    tax
    lda @@attrib_addr_lo,y
    ldy #$23
    jsr begin_ppu_string
    ldy player.difficulty
    lda @@attrib_data_1st,y
    tay
    plp
    php
    bcs +
    ldy #0
  + tya
    jsr put_ppu_string_byte
    jsr end_ppu_string
; lower tiles
    ldy player.difficulty
    lda @@attrib_length,y
    tax
    lda @@attrib_addr_lo,y
    clc
    adc #8
    ldy #$23
    jsr begin_ppu_string
    ldy player.difficulty
    lda @@attrib_data_2nd,y
    tay
    plp
    bcs +
    ldy #0
  + tya
    jsr put_ppu_string_byte
    jsr end_ppu_string
    rts
@@attrib_length:
.db $42,$43,$42
@@attrib_addr_lo:
.db $CC,$DC,$DC+16
@@attrib_data_1st:
.db $FF,$FF,$F0
@@attrib_data_2nd:
.db $FF,$0F,$FF
.endp

.proc play_cursor_sfx
    lda #0
    ldx #4
    jmp start_sfx
.endp

.proc check_input
    lda joypad0_posedge
    and #(JOYPAD_BUTTON_START | JOYPAD_BUTTON_A)
    bne @@select_difficulty
    lda joypad0_posedge
    and #JOYPAD_BUTTON_UP
    bne @@up
    lda joypad0_posedge
    and #(JOYPAD_BUTTON_DOWN | JOYPAD_BUTTON_SELECT)
    bne @@down
.if 0
    lda joypad0_posedge
    bne @@next_speed_level
.endif
    rts

.if 0
    @@next_speed_level:
    inc player.speed_level
    lda player.speed_level
    cmp #8
    bne +
    lda #0
    sta player.speed_level
  + jmp play_cursor_sfx
.endif

    @@up:
    clc
    jsr draw_selection ; make sure old selection is disabled
    dec player.difficulty
    bpl +
    lda #2
    sta player.difficulty
  + jmp play_cursor_sfx

    @@down:
    clc
    jsr draw_selection ; make sure old selection is disabled
    inc player.difficulty
    lda player.difficulty
    cmp #3
    bne +
    lda #0
    sta player.difficulty
  + jmp play_cursor_sfx

    @@select_difficulty:
    sec
    jsr draw_selection ; make sure it's drawn selected

.ifndef NO_TRANSITIONS
    lda #1
    ldx #4
    jsr start_sfx

    ; start fading out music

    lda #0
    sta main_cycle

    @@start_fade_out_music_timer:
    lda #3
    ldy #3
    jsr start_timer
    lda #<@@fade_out_music
    ldy #>@@fade_out_music
    jmp set_timer_callback

    @@fade_out_music:
    jsr mixer_get_master_vol
    sec
    sbc #$10
    bcc +
    jsr mixer_set_master_vol
    jmp @@start_fade_out_music_timer
  + ; done fading out music
    lda #0
    jsr start_song ; mute
    lda #6
    ldy #6
    jsr start_timer
    lda #<@@really_select
    ldy #>@@really_select
    jsr set_timer_callback
    jmp start_fade_to_black

    @@really_select:
.endif
    ; song select screen
    lda #5
    sta main_cycle
    rts
.endp

.end
