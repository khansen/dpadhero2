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

.include "common/sprite.h"
.include "target.h"

.dataseg

spawn_star_timer .db
spawn_star_index .db
manhattan_length .db
prev .db

.codeseg

.public initialize_starfield
.public update_starfield

.proc initialize_starfield
    jsr initialize_target_lists

    lda #16
    sta spawn_star_timer
    lda #0
    sta spawn_star_index
    rts
.endp

.proc abs
    ora #0
    bpl +
    eor #$FF
    clc : adc #1
  + rts
.endp

.proc calculate_manhattan_length
    lda targets_1.pos_y.int,y
    jsr abs
    sta manhattan_length
    lda targets_1.pos_x.int,y
    jsr abs
    clc
    adc manhattan_length
    bcc +
    lda #255
  + sta manhattan_length
    rts
.endp

.proc draw_star
    ; left half
    jsr next_sprite_index
    tax
    lda manhattan_length
    cmp #127
    bcc +
    lda #127
  + lsr : lsr
    and #$FC
    ora #$60+1
    pha
    sta sprites.tile,x
    and #$18 : lsr : lsr : lsr
    ora #$20 ; behind bg
    sta sprites.attr,x
    lda targets_1.pos_y.int,y
    clc : adc #120
    sta sprites._y,x
    lda targets_1.pos_x.int,y
    clc : adc #128
    sta sprites._x,x
    ; right half
    jsr next_sprite_index
    tax
    pla
    ora #2
    sta sprites.tile,x
    and #$18 : lsr : lsr : lsr
    ora #$20 ; behind bg
    sta sprites.attr,x
    lda targets_1.pos_y.int,y
    clc : adc #120
    sta sprites._y,x
    lda targets_1.pos_x.int,y
    clc : adc #128+8
    sta sprites._x,x
    rts
.endp

.proc process_stars
    lda #$FF
    sta prev
    ldy active_targets_head

    @@loop:
    cpy #$FF ; end of list?
    bne @@do_target
    rts

    @@do_target:
    jsr move_target

    lda targets_1.pos_y.int,y
    clc : adc #128
    cmp #240
    bcs @@went_offscreen
    lda targets_1.pos_x.int,y
    clc : adc #128
    cmp #240
    bcs @@went_offscreen

    jsr calculate_manhattan_length
    jsr draw_star

    lda targets_2.next,y
    sty prev
    tay
    jmp @@loop

    @@went_offscreen:
    lda targets_2.next,y
    pha
    ; put on free list
    lda free_targets_list
    sta targets_2.next,y
    sty free_targets_list
    pla
    ; remove from active targets list
    cpy active_targets_tail
    bne +
    sta active_targets_tail
  + tay
    ldx prev
    cpx #$FF
    bne +
    sty active_targets_head
    jmp @@loop
  + sta targets_2.next,x
    jmp @@loop
.endp

.proc maybe_spawn_star
    dec spawn_star_timer
    beq +
    rts
  + lda #10
    sta spawn_star_timer
    ; grab target from free list
    ldx free_targets_list
    cpx #$FF
    bne +
    ; don't spawn, no free targets now
    rts
  + lda targets_2.next,x
    sta free_targets_list
    ; initialize
    lda #0
    sta targets_1.pos_y.frac,x
    sta targets_1.pos_x.frac,x
    lda spawn_star_index
    inc spawn_star_index
    and #$1F
    tay
    lda @@order_table,y
    pha
    and #$1F
    lsr : lsr : lsr
    tay
    lda @@quadrant_start_y_hi,y
    sta targets_1.pos_y.int,x
    lda @@quadrant_start_x_hi,y
    sta targets_1.pos_x.int,x
    pla
    pha
    and #7
    tay
    lda @@speed_y_lo,y
    sta targets_2.speed_y.frac,x
    lda @@speed_y_hi,y
    sta targets_2.speed_y.int,x
    lda @@speed_x_lo,y
    sta targets_2.speed_x.frac,x
    lda @@speed_x_hi,y
    sta targets_2.speed_x.int,x
    pla
    pha
    and #8
    beq +
    ; invert X speed
    lda targets_2.speed_x.frac,x
    eor #$FF
    clc : adc #1
    sta targets_2.speed_x.frac,x
    lda targets_2.speed_x.int,x
    eor #$FF
    adc #0
    sta targets_2.speed_x.int,x
  + pla
    and #$10
    beq +
    ; invert Y speed
    lda targets_2.speed_y.frac,x
    eor #$FF
    clc : adc #1
    sta targets_2.speed_y.frac,x
    lda targets_2.speed_y.int,x
    eor #$FF
    adc #0
    sta targets_2.speed_y.int,x
  + jmp add_to_active_targets_list
@@quadrant_start_x_hi:
.db 0,-16,0,-16
@@quadrant_start_y_hi:
.db 0,0,-24,-24
@@speed_y_lo:
.db $19,$39,$59,$79,$99,$B9,$D9,$F9
@@speed_y_hi:
.db $00,$00,$00,$00,$00,$00,$00,$00
@@speed_x_lo:
.db $FE,$F9,$EF,$E1,$CC,$B0,$86,$38
@@speed_x_hi:
.db $00,$00,$00,$00,$00,$00,$00,$00
@@order_table:
.if 0
.db 0+0,8+6,16+5,24+4
.db 0+3,8+2,16+7,24+7
.db 0+1,8+5,16+4,24+5
.db 0+6,8+7,16+0,24+2
.db 0+2,8+4,16+3,24+6
.db 0+5,8+0,16+1,24+1
.db 0+7,8+3,16+6,24+3
.db 0+4,8+1,16+2,24+0
.else
.db 0+0,8+1,16+2,24+3
.db 0+4,8+5,16+6,24+7
.db 0+1,8+2,16+3,24+0
.db 0+5,8+6,16+7,24+4
.db 0+2,8+3,16+0,24+1
.db 0+6,8+7,16+4,24+5
.db 0+3,8+0,16+1,24+2
.db 0+7,8+4,16+5,24+6
.endif
.endp

.proc update_starfield
    jsr process_stars
    jmp maybe_spawn_star
.endp

.end
