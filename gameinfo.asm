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

; Bitmask of players who have confirmed their readiness
players_ready .db

.codeseg

.public gameinfo_init
.public gameinfo_main

.public pulse_buttons

.extrn wipeout:proc
.extrn is_clip_play:proc
.extrn main_cycle:byte
.extrn frame_count:byte
.extrn game_type:byte

.proc gameinfo_init
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

    ldcay @@bg_data
    jsr write_ppu_data_at

    jsr set_black_palette
    ldcay @@palette
    jsr load_palette

    lda #0 : ldy #31
    jsr set_fade_range
    lda #6
    jsr set_fade_delay
    jsr start_fade_from_black

    lda #0
    sta players_ready

    lda #0
    jsr start_song

    inc main_cycle

    jsr screen_on
    jsr nmi_on
    rts

@@palette:
.db $0f,$20,$20,$20
.db $0f,$20,$20,$20
.db $0f,$20,$20,$20
.db $0f,$06,$18,$38 ; button
.db $0f,$02,$22,$30 ; target - blue
.db $0f,$06,$16,$30 ; target - red
.db $0f,$08,$28,$30 ; target - yellow
.db $0f,$0A,$2A,$20 ; target - green

@@bg_data:
.charmap "font.tbl"
.db $20,$8A,10 : .char "PLAYER 1 ="
.db $20,$EA,10 : .char "PLAYER 2 ="
.db $21,$49,11 : .char "AUTO-SWAP ="

.db $22,$68,17 : .char "IN `YOUR` LANE(S)"

.db $23,$2B,4 : .char "PUSH"
; B + A
.db $23,$10,2,$AA,$AB
.db $23,$30,2,$BA,$BB
.db $23,$12,2,$AE,$AF
.db $23,$32,2,$BE,$BF
.db $23,$14,2,$AC,$AD
.db $23,$34,2,$BC,$BD

; attributes
.db $23,$F4,$42,$FF
.db 0
.endp

; Y = 0 ==> player 1, 1 ==> player 2, 2 ==> switch
.proc draw_orb
    ; calculate orb frame (0..7)
    tya
    asl : asl : asl
    adc frame_count
    pha
    asl : asl : asl
    pla
    and #$1C
    ora #1
    bcc +
    eor #$1C
  + pha
    ; left half
    jsr next_sprite_index
    tax
    pla
    pha
    sta sprites.tile,x
    tya
    sta sprites.attr,x
    lda @@orb_y_offset,y
    clc : adc #26
    sta sprites._y,x
    lda #168
    sta sprites._x,x
    ; right half
    jsr next_sprite_index
    tax
    pla
    ora #2
    sta sprites.tile,x
    tya
    sta sprites.attr,x
    lda @@orb_y_offset,y
    clc : adc #26
    sta sprites._y,x
    lda #168+8
    sta sprites._x,x
    rts
    @@orb_y_offset:
    .db 0,24,48
.endp

.proc draw_orbs
    ldy #0
    jsr draw_orb ; player 1
    ldy #1
    jsr draw_orb ; player 2
    ldy #2
    jmp draw_orb ; switch
.endp

; POW, star, clock
.proc draw_power_ups
    ldy #0
  - jsr next_sprite_index
    tax
    lda @@tile_indexes,y
    sta sprites.tile,x
    lda @@tile_attribs,y
    sta sprites.attr,x
    lda @@x_offsets,y
    clc : adc #96
    sta sprites._x,x
    lda #128
    sta sprites._y,x
    iny
    cpy #6
    bne -
    rts
@@x_offsets:
.db 0,8,24,32,48,56
@@tile_indexes:
.db $5D,$5F,$7D,$7F,$9D,$9F
@@tile_attribs:
.db 1,1,2,2,0,0
.endp

; Letter, fake skull
.proc draw_special_items
    lda game_type
    cmp #2
    bne +
    ; items not available in versus mode
    rts
  + jsr is_clip_play
    beq +
    ; items not available in clip play mode
    rts
  + ldy #0
  - jsr next_sprite_index
    tax
    lda @@tile_indexes,y
    sta sprites.tile,x
    lda @@tile_attribs,y
    sta sprites.attr,x
    lda @@x_offsets,y
    clc : adc #108
    sta sprites._x,x
    lda #104
    sta sprites._y,x
    iny
    cpy #4
    bne -
    rts
@@x_offsets:
.db 0,8,24,32
@@tile_indexes:
.db $3D,$3F,$1D,$1F
@@tile_attribs:
.db $80|0,$80|0,3,3
.endp

.proc pulse_buttons
    jsr palette_fade_in_progress
    beq +
    rts
  + lda frame_count
    and #7
    beq +
    rts
  + ldy #$3F : lda #$0D : ldx #1
    jsr begin_ppu_string
    lda frame_count
    lsr : lsr : lsr
    and #7
    tay
    lda @@color_table,y
    jsr put_ppu_string_byte
    jmp end_ppu_string
@@color_table:
.db $06,$16,$26,$20,$26,$16,$06,$06
.endp

.proc gameinfo_main
    jsr reset_sprites
    jsr draw_orbs
    jsr draw_power_ups
    jsr draw_special_items
    jsr pulse_buttons
    jsr check_input
    jmp check_if_all_ready
.endp

.proc check_input
    jsr palette_fade_in_progress
    beq +
    rts
  + lda players_ready
    lsr
    bcs +
    ; player 1 ready?
    lda joypad0
    and #(JOYPAD_BUTTON_B | JOYPAD_BUTTON_A)
    cmp #(JOYPAD_BUTTON_B | JOYPAD_BUTTON_A)
    bne +
    ; ready!
    lda players_ready
    ora #1
    sta players_ready
    ldcay @@player_1_ready_data
    jsr copy_string_to_ppu_buffer
    lda #6 : ldx #4
    jsr start_sfx
  + lda players_ready
    and #2
    bne +
    ; player 2 ready?
    lda joypad1
    and #(JOYPAD_BUTTON_B | JOYPAD_BUTTON_A)
    cmp #(JOYPAD_BUTTON_B | JOYPAD_BUTTON_A)
    bne +
    ; ready!
    lda players_ready
    ora #2
    sta players_ready
    ldcay @@player_2_ready_data
    jsr copy_string_to_ppu_buffer
    lda #6 : ldx #4
    jsr start_sfx
  + rts

.charmap "font.tbl"
@@player_1_ready_data:
.db $20,$98,3 : .char "OK!"
.db 0
@@player_2_ready_data:
.db $20,$F8,3 : .char "OK!"
.db 0
.endp

.proc check_if_all_ready
    lda players_ready
    cmp #3
    beq +
    rts
  +
.if 1;ndef NO_TRANSITIONS
    lda #0
    sta main_cycle

    lda #3 : ldy #6
    jsr start_timer
    ldcay @@fade_out
    jmp set_timer_callback

    @@fade_out:
    lda #10 : ldy #6
    jsr start_timer
    ldcay @@really_go
    jsr set_timer_callback
    jmp start_fade_to_black

    @@really_go:
.endif
    lda #7
    sta main_cycle
    rts
.endp

.end
