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

.dataseg

accept_input .db

.codeseg

.public piecewin_init
.public piecewin_main

.public draw_proceed_button

.extrn initialize_starfield:proc
.extrn update_starfield:proc
.extrn pulse_buttons:proc

.extrn wipeout:proc
.extrn selected_song:byte
.extrn main_cycle:byte
.extrn frame_count:byte

.proc piecewin_init
    jsr wipeout

.ifdef MMC
.if MMC == 3
    lda #8  : sta chr_banks[0]
    lda #10 : sta chr_banks[1]
    lda #20 : sta chr_banks[2]
    lda #21 : sta chr_banks[3]
    lda #22 : sta chr_banks[4]
    lda #23 : sta chr_banks[5]
.endif
.endif

    ldcay @@bg_data
    jsr write_ppu_data_at

    jsr draw_won_piece

    jsr set_black_palette
    ldcay @@palette
    jsr load_palette

    lda #0 : ldy #31
    jsr set_fade_range
    lda #6
    jsr set_fade_delay
    jsr start_fade_from_black

    jsr initialize_starfield

    lda #10
    jsr start_song

    lda #41 : ldy #8
    jsr start_timer
    ldcay @@accept_input
    jsr set_timer_callback

    lda #0
    sta accept_input

    inc main_cycle

    jsr screen_on
    jmp nmi_on

    @@accept_input:
    jsr draw_proceed_button
    lda #1
    sta accept_input
    lda #11
    jmp start_song

@@palette:
.db $0f,$20,$10,$00
.db $0f,$06,$00,$10
.db $0f,$06,$00,$10
.db $0f,$06,$18,$38 ; button
.db $0f,$05,$16,$18
.db $0f,$06,$17,$28
.db $0f,$07,$18,$38
.db $0f,$08,$28,$30 ; target - yellow

@@bg_data:
.charmap "font.tbl"
.db $21,$4A,$0B
.char "YOU WON THE"
.db $22,$4D,$06
.char "PIECE!"
; attributes
.db $23,$F7,$01,$FF
.db 0
.endp

.proc draw_proceed_button
    ; draw top half of A button
    ldy #$23 : lda #$5C : ldx #2 : jsr begin_ppu_string
    lda #$74 : jsr put_ppu_string_byte
    lda #$75 : jsr put_ppu_string_byte
    jsr end_ppu_string
    ; draw bottom half of A button
    ldy #$23 : lda #$7C : ldx #2 : jsr begin_ppu_string
    lda #$76 : jsr put_ppu_string_byte
    lda #$77 : jsr put_ppu_string_byte
    jmp end_ppu_string
.endp

.proc draw_won_piece
    lda selected_song
    asl
    tay
    lda @@bg_data_table,y
    pha
    lda @@bg_data_table+1,y
    tay
    pla
    jmp write_ppu_data_at

@@bg_data_table:
.dw @@bg_data_0
.dw @@bg_data_1
.dw @@bg_data_2
.dw @@bg_data_3
.dw @@bg_data_4
.dw @@bg_data_5
@@bg_data_0:
.db $21,$AE,$04,$80,$81,$82,$83
.db $21,$CE,$04,$84,$85,$86,$87
.db $21,$EE,$04,$88,$89,$8A,$8B
.db $23,$D8,$48,$AA
.db 0
@@bg_data_1:
.db $21,$AE,$04,$8C,$8D,$8E,$8F
.db $21,$CE,$04,$90,$91,$92,$93
.db $21,$EE,$04,$94,$95,$96,$97
.db $23,$D8,$48,$AA
.db 0
@@bg_data_2:
.db $21,$AE,$04,$98,$99,$9A,$9B
.db $21,$CE,$04,$9C,$9D,$9E,$9F
.db $21,$EE,$04,$A0,$A1,$A2,$A3
.db $23,$D8,$48,$AA
.db 0
@@bg_data_3:
.db $21,$AE,$04,$A4,$A5,$A6,$A7
.db $21,$CE,$04,$A8,$A9,$AA,$AB
.db $21,$EE,$04,$AC,$AD,$AE,$AF
.db $23,$D8,$48,$AA
.db 0
@@bg_data_4:
.db $21,$AE,$04,$B0,$B1,$B2,$B3
.db $21,$CE,$04,$B4,$B5,$B6,$B7
.db $21,$EE,$04,$B8,$B9,$BA,$BB
.db $23,$D8,$48,$AA
.db 0
@@bg_data_5:
.db $21,$AE,$04,$BC,$BD,$BE,$BF
.db $21,$CE,$04,$C0,$C1,$C2,$C3
.db $21,$EE,$04,$C4,$C5,$C6,$C7
.db $23,$D8,$48,$AA
.db 0
.endp

.proc piecewin_main
    jsr reset_sprites
    jsr update_starfield
    jmp maybe_process_input
.endp

.proc maybe_process_input
    lda accept_input
    bne +
    rts
  + jsr pulse_buttons
    lda joypad0_posedge
    and #(JOYPAD_BUTTON_START | JOYPAD_BUTTON_A)
    bne @@go
    rts

    @@go:
.ifndef NO_TRANSITIONS
    lda #0
    sta main_cycle

    lda #6 : ldx #4
    jsr start_sfx

    lda #10 : ldy #6
    jsr start_timer
    ldcay @@really_go
    jsr set_timer_callback
    jsr start_fade_to_black
    jmp start_audio_fade_out

    @@really_go:
.endif
    ; back to song select screen
    lda #5
    sta main_cycle
    rts
.endp

.end
