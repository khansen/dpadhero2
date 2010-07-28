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

.include "common/ppubuffer.h"
.include "sound/mixer.h"

.dataseg

channel_index .db
temp_sound_status .db

.codeseg

.public update_ampdisplay

.extrn sound_status:byte
.extrn volume_table:byte

.proc update_ampdisplay_step
    ; Only one channel's display is updated per frame.
    lda channel_index
    bne +
    lda sound_status
    sta temp_sound_status
  + tay
    lda @@channel_offsets,y
    tax
.ifndef NO_MUTABLE_CHANNELS
    lsr temp_sound_status
.endif
    lda mixer.tonals.period.lo,x
    ora mixer.tonals.period.hi,x
    beq ++
    lda mixer.envelopes.master,x
.ifndef NO_MUTABLE_CHANNELS
    bcc +
    lda #0 ; the channel is muted
  +
.endif
 ++ and #$F0
    ora mixer.envelopes.vol.int,x
    tay
    lda volume_table,y
    ora mixer.master_vol
    tay
    lda volume_table,y ; 0..15
    asl
    cmp #17
    bcc +
    lda #16
  + pha
    ldy #$21 : ldx #$84
    lda channel_index
    clc
    adc #$03
    jsr begin_ppu_string
    pla
    asl
    asl
    tay
    lda @@display_tiles+0,y
    jsr put_ppu_string_byte
    lda @@display_tiles+1,y
    jsr put_ppu_string_byte
.if 1
; 16 levels
    lda @@display_tiles+2,y
    jsr put_ppu_string_byte
    lda @@display_tiles+3,y
    jsr put_ppu_string_byte
.endif
    jsr end_ppu_string

    inc channel_index
    lda channel_index
    and #3
    sta channel_index
    rts

@@channel_offsets:
.db sizeof tonal_state * 0
.db sizeof tonal_state * 1
.db sizeof tonal_state * 2
.db sizeof tonal_state * 3
.db sizeof tonal_state * 4

@@display_tiles:
.if 0
; 9 levels
.db $88,$88
.db $88,$89
.db $88,$8A
.db $88,$8B
.db $88,$8C
.db $89,$8C
.db $8A,$8C
.db $8B,$8C
.db $8C,$8C
.else
; 17 levels
.db $88,$88,$88,$88 ; 0
.db $88,$88,$88,$89 ; 1
.db $88,$88,$88,$8A ; 2
.db $88,$88,$88,$8B ; 3
.db $88,$88,$88,$8C ; 4
.db $88,$88,$89,$8C ; 5
.db $88,$88,$8A,$8C ; 6
.db $88,$88,$8B,$8C ; 7
.db $88,$88,$8C,$8C ; 8
.db $88,$89,$8C,$8C ; 9
.db $88,$8A,$8C,$8C ; 10
.db $88,$8B,$8C,$8C ; 11
.db $88,$8C,$8C,$8C ; 12
.db $89,$8C,$8C,$8C ; 13
.db $8A,$8C,$8C,$8C ; 14
.db $8B,$8C,$8C,$8C ; 15
.db $8C,$8C,$8C,$8C ; 16
.endif
.endp

.proc update_ampdisplay
    jsr update_ampdisplay_step
    jmp update_ampdisplay_step
.endp

.end
