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
.include "player.h"
.include "target.h"

.dataseg

; 0 = vertical, 1 = horizontal
orbientation .db

spawn_orb_timer .db
spawn_orb_index .db
prev .db

.codeseg

.extrn frame_count:byte

.public initialize_orb_parallax
.public update_orb_parallax

; A = orbientation (0 = vertical, 1 = horizontal)
.proc initialize_orb_parallax
    sta orbientation
    jsr initialize_target_lists
    lda #16
    sta spawn_orb_timer
    lda #0
    sta spawn_orb_index
    rts
.endp

.proc get_winning_player
    lda player.energy_level+1
    beq + ; player 1 won
    lda #1 ; player 2 won
  + rts
.endp

.proc draw_orb
    ; left half
    jsr next_sprite_index
    tax
    lda targets_1.state,y
    and #7 ; size
    asl : asl
    ora #1
    sta sprites.tile,x
    lda targets_1.state,y
    pha
    and #7 ; size
    cmp #3
    pla
    ror : lsr : lsr
    eor #$20
    and #$23 ; sprite priority + palette
    pha
    sta sprites.attr,x
    lda targets_1.pos_y.int,y
    sta sprites._y,x
    lda targets_1.pos_x.int,y
    sta sprites._x,x
    ; right half
    jsr next_sprite_index
    tax
    lda targets_1.state,y
    and #7 ; size
    asl : asl
    ora #3
    sta sprites.tile,x
    pla
    sta sprites.attr,x
    lda targets_1.pos_y.int,y
    sta sprites._y,x
    lda targets_1.pos_x.int,y
    clc : adc #8
    sta sprites._x,x
    rts
.endp

.proc process_orbs
    lda #$FF
    sta prev
    ldy active_targets_head

    @@loop:
    cpy #$FF ; end of list?
    bne @@do_target
    rts

    @@do_target:
    jsr move_target
    jsr draw_orb

    lda orbientation
    beq +
    ; horizontal
    lda targets_1.pos_x.int,y
    cmp #4
    bcc @@went_offscreen
    bcs @@next
    ; vertical
  + lda targets_1.pos_y.int,y
    cmp #$F8
    bcs @@went_offscreen

    @@next:
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

.proc maybe_spawn_orb
    dec spawn_orb_timer
    beq +
    rts
  + lda #8
    ldy orbientation
    beq +
    lda #12
  + sta spawn_orb_timer
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
    lda #240
    ldy orbientation
    bne +
    sta targets_1.pos_y.int,x
    jmp ++
  + sta targets_1.pos_x.int,x
 ++ lda spawn_orb_index
    inc spawn_orb_index
    pha
    ldy orbientation
    beq +
    and #7
    tay
    lda @@pos_y_hi,y
    jmp ++
  + asl : asl : asl : asl : asl ; * 32
    adc #8
 ++ ldy orbientation
    beq +
    sta targets_1.pos_y.int,x
    jmp ++
  + sta targets_1.pos_x.int,x
 ++ pla
    and #7
    tay
    lda @@size_table,y
    sta targets_1.state,x
    tay
    lda orbientation
    beq +
    ; horizontal
    lda @@size_speed_lo,y
    sta targets_2.speed_x.frac,x
    lda @@size_speed_hi,y
    sta targets_2.speed_x.int,x
    lda #0
    sta targets_2.speed_y.frac,x
    sta targets_2.speed_y.int,x
    jmp ++
    ; vertical
  + lda @@size_speed_lo,y
    sta targets_2.speed_y.frac,x
    lda @@size_speed_hi,y
    sta targets_2.speed_y.int,x
    lda #0
    sta targets_2.speed_x.frac,x
    sta targets_2.speed_x.int,x
 ++ lda orbientation
    beq +
    lda frame_count
    clc : adc spawn_orb_index
    and #$18
    bpl ++
  + jsr get_winning_player
    and #3 ; use as palette
    asl : asl : asl
 ++ ora targets_1.state,x
    sta targets_1.state,x
    jmp add_to_active_targets_list
@@size_table:
.db 2,4,0,7,1,6,3,5
@@size_speed_lo:
.db $40,$00,$C0,$80,$40,$00,$C0,$80
@@size_speed_hi:
.db $FF,$FF,$FE,$FE,$FE,$FE,$FD,$FD
@@pos_y_hi:
.db 8,24,40,56,120,168,184,208
.endp

.proc update_orb_parallax
    jsr process_orbs
    jmp maybe_spawn_orb
.endp

.end
