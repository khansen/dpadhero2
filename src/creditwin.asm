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

.public creditwin_init
.public creditwin_main

.extrn initialize_orb_parallax:proc
.extrn update_orb_parallax:proc
.extrn pulse_buttons:proc
.extrn draw_proceed_button:proc

.extrn wipeout:proc
.extrn count_bits:proc
.extrn compute_completed_challenges_count:proc
.extrn selected_song:byte
.extrn main_cycle:byte
.extrn frame_count:byte
.extrn bitmasktable:byte

.proc creditwin_init
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

    ldcay @@bg_data : jsr write_ppu_data_at
    jsr print_won_credit_message
    jsr print_status_message

    jsr set_black_palette
    ldcay @@palette : jsr load_palette

    lda #0 : ldy #31
    jsr set_fade_range
    lda #6 : jsr set_fade_delay
    jsr start_fade_from_black

    lda #1 ; horizontal
    jsr initialize_orb_parallax

    lda #9 : ldy #8
    jsr start_timer
    ldcay @@accept_input
    jsr set_timer_callback

    lda #0
    sta accept_input

    lda #12
    jsr start_song

    inc main_cycle

    jsr screen_on
    jmp nmi_on

    @@accept_input:
    jsr draw_proceed_button
    lda #1
    sta accept_input
    lda #0
    jmp start_song

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
.db $0f,$08,$28,$30 ; target - yellow
.db $0f,$0A,$2A,$20 ; target - green
.endp

.proc print_won_credit_message
    ldcay @@single_credit_message
    ldx player.won_credit
    cpx #1
    beq +
    ldcay @@multiple_credits_message
  + jsr write_ppu_data_at
    jmp print_won_credit

.charmap "font.tbl"
@@single_credit_message:
.db $21,$68,$10 : .char "YOU WON   TOKEN!" : .db 0
@@multiple_credits_message:
.db $21,$68,$11 : .char "YOU WON   TOKENS!" : .db 0
.endp

.proc print_won_credit
    ldy #$21 : lda #$70 : ldx #1
    jsr begin_ppu_string
    lda player.won_credit
    ora #$D0
    jsr put_ppu_string_byte
    jmp end_ppu_string
.endp

.proc print_status_message
    ldy selected_song
    lda player.completed_challenges,y
    jsr count_bits
    cpx #8
    beq @@print_completed_all_challenges_message
    txa
    ldy player.difficulty
    sec : sbc pad_piece_challenge_limits,y
    bmi @@print_missing_pad_piece_challenges_message

    ; still some challenges remaining
    txa
    clc : adc #$F8 ; -8
    eor #$FF : clc : adc #1
    pha
    ldy #$21 : lda #$C6 : ldx #1
    jsr begin_ppu_string
    pla
    pha
    ora #$D0
    jsr put_ppu_string_byte
    jsr end_ppu_string
    pla
    tax
    ldcay @@single_challenge_remaining_message
    cpx #1
    beq +
    ldcay @@multiple_challenges_remaining_message
  + jmp write_ppu_data_at

    @@print_missing_pad_piece_challenges_message:
    eor #$FF : clc : adc #1
    pha
    ldy #$21 : lda #$C5 : ldx #1
    jsr begin_ppu_string
    pla
    pha
    ora #$D0
    jsr put_ppu_string_byte
    jsr end_ppu_string
    pla
    tax
    ldcay @@pad_piece_single_missing_challenge_message
    cpx #1
    beq +
    ldcay @@pad_piece_multiple_missing_challenges_message
  + jmp write_ppu_data_at

    @@print_completed_all_challenges_message:
    ldcay @@completed_all_challenges_message : jmp write_ppu_data_at

.charmap "font.tbl"
@@pad_piece_single_missing_challenge_message:
.db $21,$C7,$13 : .char "MORE CHALLENGE MUST"
.db $22,$06,$14 : .char "BE COMPLETED TO EARN"
.db $22,$49,$0E : .char "THE PAD PIECE."
.db 0

@@pad_piece_multiple_missing_challenges_message:
.db $21,$C7,$14 : .char "MORE CHALLENGES MUST"
.db $22,$06,$14 : .char "BE COMPLETED TO EARN"
.db $22,$49,$0E : .char "THE PAD PIECE."
.db 0

@@single_challenge_remaining_message:
.db $21,$C8,$11 : .char "CHALLENGE REMAINS"
.db $22,$05,$16 : .char "FOR THIS SONG. CAN YOU"
.db $22,$4A,$0C : .char "COMPLETE IT?"
.db 0

@@multiple_challenges_remaining_message:
.db $21,$C8,$11 : .char "CHALLENGES REMAIN"
.db $22,$05,$16 : .char "FOR THIS SONG. CAN YOU"
.db $22,$47,$12 : .char "COMPLETE THEM ALL?"
.db 0

@@completed_all_challenges_message:
.db $21,$C8,$10 : .char "ALL 8 CHALLENGES"
.db $22,$07,$12 : .char "COMPLETED FOR THIS"
.db $22,$48,$10 : .char "SONG! GREAT JOB!"
.db 0
.endp

.proc creditwin_main
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

    lda #8 : ldy #6
    jsr start_timer
    ldcay @@really_go
    jsr set_timer_callback
    jmp start_fade_to_black

    @@really_go:
.endif
    ; add credit for newly completed challenges
    lda player.won_credit
    clc
    adc player.credit
    sta player.credit

    ldy selected_song
    lda bitmasktable,y
    and player.acquired_pad_pieces ; have the pad piece for this song?
    beq +
    lda player.beat_game
    beq ++
    ; completed all challenges now?
    jsr compute_completed_challenges_count
    cmp #6*8
    bne ++
    ; special ending
    lda #32
    sta main_cycle
    rts
 ++
  - lda #5 ; song select
    sta main_cycle
    rts

    ; check if piece should be awarded
  + lda player.completed_challenges,y
    jsr count_bits
    txa
    ldy player.difficulty
    cmp pad_piece_challenge_limits,y
    bcc -
    ; get a new pad piece
    ldy selected_song
    lda bitmasktable,y
    ora player.acquired_pad_pieces
    sta player.acquired_pad_pieces

    ; go to piece win screen
    lda #16
    sta main_cycle
    rts
.endp

pad_piece_challenge_limits:
.db 3 ; easy
.db 4 ; normal
.db 6 ; hard

.end
