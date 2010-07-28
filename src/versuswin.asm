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
.include "target.h"

.ifdef MMC
.if MMC == 3
.include "mmc/mmc3.h"
.endif
.endif

.dataseg

accept_input .db

.codeseg

.public versuswin_init
.public versuswin_main

.extrn draw_proceed_button:proc
.extrn pulse_buttons:proc
.extrn initialize_orb_parallax:proc
.extrn update_orb_parallax:proc

.extrn wipeout:proc
.extrn selected_song:byte
.extrn main_cycle:byte
.extrn frame_count:byte

.proc versuswin_init
    jsr wipeout

    lda #13 : jsr start_song

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

    ldcay @@bg_data : jsr write_ppu_data_at
    jsr print_message

    jsr set_black_palette
    ldcay @@palette
    jsr load_palette

    lda #0 : ldy #31
    jsr set_fade_range
    lda #6
    jsr set_fade_delay
    jsr start_fade_from_black

    lda #0 ; vertical
    jsr initialize_orb_parallax

    lda #44 : ldy #8
    jsr start_timer
    ldcay @@fanfare_done
    jsr set_timer_callback

    lda #0 : sta accept_input

    inc main_cycle

    jsr screen_on
    jmp nmi_on

    @@fanfare_done:
    jsr draw_proceed_button
    lda #1 : sta accept_input
    lda #14 : jmp start_song

@@bg_data:
; attributes
.db $23,$F7,$01,$FF
.db 0

@@palette:
.db $0f,$20,$20,$20
.db $0f,$20,$20,$20
.db $0f,$20,$20,$20
.db $0f,$06,$18,$38 ; button
.db $0f,$02,$22,$30 ; target - blue
.db $0f,$06,$16,$30 ; target - red
.db $0f,$0A,$2A,$20 ; target - green
.db $0f,$08,$28,$30 ; target - yellow
.endp

.proc print_message
    jsr get_winning_player
    cmp #$FF
    beq @@is_tie
    ldcay @@win_bg_data
    jsr write_ppu_data_at
    jmp print_winner_number
    @@is_tie:
    ldcay @@tie_bg_data
    jmp write_ppu_data_at

.charmap "font.tbl"
@@win_bg_data:
.db $21,$C8,$10
.char "CONGRATULATIONS,"
.db $22,$0B,$09
.char "PLAYER  !"
.db 0

@@tie_bg_data:
.db $21,$CA,11
.char "IT'S A TIE!"
.db $22,$06,20
.char "YOU ARE BOTH LOSERS!"
.db 0
.endp

; Returns the winning player (0 or 1),
; or -1 if there was a tie.
.proc get_winning_player
    lda player.energy_level+1
    ora player.energy_level+0
    beq @@tie
    lda player.energy_level+1
    beq + ; player 1 won
    lda #1 ; player 2 won
  + rts
    @@tie:
    lda #$FF
    rts
.endp

.proc print_winner_number
    ldy #$22 : lda #$12 : ldx #1
    jsr begin_ppu_string
    jsr get_winning_player
    clc : adc #$D1
    jsr put_ppu_string_byte
    jmp end_ppu_string
.endp

.proc versuswin_main
    jsr reset_sprites
    jsr update_orb_parallax
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
    lda #12 ; game over init
    sta main_cycle
    rts
.endp

.end
