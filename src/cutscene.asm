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

.ifdef MMC
.if MMC == 3
.include "mmc/mmc3.h"
.endif
.endif

.codeseg

.public cutscene_init
.public cutscene_main

.extrn wipeout:proc
.extrn setup_clip_play:proc
.extrn game_type:byte
.extrn main_cycle:byte
.extrn frame_count:byte

.proc cutscene_init
    jsr wipeout

.ifdef MMC
.if MMC == 3
    lda #16 : sta chr_banks[0]
    lda #32 : sta chr_banks[1]
    lda #20 : sta chr_banks[2]
    lda #21 : sta chr_banks[3]
    lda #22 : sta chr_banks[4]
    lda #23 : sta chr_banks[5]
.endif
.endif

    ldcay @@bg_data
    jsr write_ppu_data_at

    jsr set_black_palette
    ldcay @@palette
    jsr load_palette

    lda #12 : ldy #31
    jsr set_fade_range
    lda #7
    jsr set_fade_delay
    jsr start_fade_from_black

    lda #48 : ldy #6
    jsr start_timer
    ldcay @@fade_out_sky
    jsr set_timer_callback

    lda #17 : jsr start_song

    inc main_cycle

    jsr screen_on
    jmp nmi_on

    @@fade_out_sky:
    lda #12 : ldy #31
    jsr set_fade_range
    lda #1 : ldy #12
    jsr start_timer
    ldcay @@fade_out_sky_2
    jsr set_timer_callback
    jmp fade_out_step

    @@fade_out_sky_2:
    jsr fade_out_step
    lda #1 : ldy #12
    jsr start_timer
    ldcay @@fade_in_pad
    jmp set_timer_callback

    @@fade_in_pad:
    lda #0 : ldy #3
    jsr set_fade_range
    lda #12
    jsr set_fade_delay
    jsr start_fade_from_black
    lda #20 : ldy #12
    jsr start_timer
    ldcay @@fade_in_text
    jmp set_timer_callback

    @@fade_in_text:
    lda #4 : ldy #7
    jsr set_fade_range
    jsr start_fade_from_black
    lda #22 : ldy #12
    jsr start_timer
    ldcay @@fade_out
    jmp set_timer_callback

    @@fade_out:
    lda #10 : ldy #8
    jsr start_timer
    ldcay @@start_final_battle
    jsr set_timer_callback
    lda #$02 : sta palette+13 : sta palette+13+4
    lda #$01 : sta palette+14 : sta palette+14+4
    lda #$00 : sta palette+15 : sta palette+15+4
    lda #0 : ldy #31
    jsr set_fade_range
    jmp start_fade_to_black

    @@start_final_battle:
    jsr setup_clip_play
    lda #7 ; game start
    ldy game_type
    beq + ; 1 player
    lda #26 ; game info
  + sta main_cycle
    rts

@@palette:
.db $0f,$37,$27,$16 ; pad
.db $0f,$20,$20,$20 ; text
.db $0f,$00,$10,$20
.db $0f,$22,$21,$20 ; sky
.db $0f,$22,$21,$20 ; sky
.db $0f,$20,$20,$20
.db $0f,$20,$20,$20
.db $0f,$20,$20,$20

@@bg_data:
.incbin "graphics/skymoon.dat"
.incbin "graphics/padpad.dat"
.charmap "font.tbl"
.db $23,$0A,14
.char "NICELY DONE..."
.db $23,$46,21
.char "NOW PROVE YOUR WORTH!"
; attributes
.db $23,$C8,$48,$F0 ; sky
.db $23,$D0,$50,$FF ; sky
.db $23,$F0,$48,$55 ; text
.db 0
.endp

.proc cutscene_main
    jsr reset_sprites
    jmp draw_sky_edges
.endp

.proc draw_sky_edges
    ldy #0
  - jsr next_sprite_index
    tax
    lda @@sprite_data,y : iny
    sta sprites._x,x
    lda @@sprite_data,y : iny
    sta sprites._y,x
    lda @@sprite_data,y : iny
    sta sprites.tile,x
    lda @@sprite_data,y : iny
    sta sprites.attr,x
    cpy #(@@sprite_data_end-@@sprite_data)
    bne -
    rts
@@sprite_data:
; left side
.db 0,127,$F7,0
.db 8,127,$F9,0
.db 0,127+16,$FB,0
; right side
.db 256-8,127,$F7,$40
.db 256-16,127,$F9,$40
.db 256-8,127+16,$FB,$40
@@sprite_data_end:
.endp

.end
