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

public selected_song .byte

audio_state .byte
audio_timer .byte
text_state .byte
text_scroller_data .ptr
text_scroller_offset .byte
flash_counter .byte

.codeseg

.public songselect_init
.public songselect_main

.extrn wipeout:proc
.extrn count_bits:proc
.extrn print_value:proc
.extrn setup_normal_play:proc
.extrn songselect_bg_data:byte
.extrn target_data_table:label
.extrn bitmasktable:byte
.extrn main_cycle:byte
.extrn frame_count:byte
.extrn current_song:byte
.extrn game_type:byte
.extrn AC0:byte
.extrn AC1:byte
.extrn AC2:byte

.proc songselect_init
    jsr wipeout

.ifdef MMC
.if MMC == 3
    lda #8  : sta chr_banks[0]
    lda #10 : sta chr_banks[1]
    lda #12 : sta chr_banks[2]
    lda #13 : sta chr_banks[3]
    lda #14 : sta chr_banks[4]
    lda #15 : sta chr_banks[5]
    lda #5
    jsr swap_bank ; need it for songselect_bg_data
.endif
.endif

    ldcay songselect_bg_data
    jsr write_ppu_data_at

    lda player.beat_game
    bne +
    jsr draw_locked_songs
;    lda #$3F
;    sta player.acquired_pad_pieces
    jsr draw_acquired_pad_pieces

  + jsr set_black_palette
    ldcay @@palette
    jsr load_palette

    lda #0 : ldy #31
    jsr set_fade_range
    lda #6
    jsr set_fade_delay
    jsr start_fade_from_black

    lda player.beat_game
    bne +
    lda player.acquired_pad_pieces
    cmp #$3F
    beq @@acquired_all

  + jsr start_song_for_selection
    lda #0
    sta text_state
    sta text_scroller_offset
    inc main_cycle
    jmp +

    @@acquired_all:
    lda #0
    jsr start_song ; mute
    lda #16 : ldy #4
    jsr start_timer
    ldcay @@fade_out_bg
    jsr set_timer_callback
    lda #0
    sta main_cycle

  + jsr screen_on
    jsr nmi_on
    rts

    @@fade_out_bg:
    lda #0 : ldy #3
    jsr set_fade_range
    jsr start_fade_to_black
    lda #16 : ldy #4
    jsr start_timer
    ldcay @@scroll_pieces_to_center
    jmp set_timer_callback

    @@scroll_pieces_to_center:
    lda #240
    sta ppu.scroll_y
    @@scroll_pieces_to_center_step:
    dec ppu.scroll_y
    lda ppu.scroll_y
    cmp #200
    beq @@done_scrolling
    ldcay @@scroll_pieces_to_center_step
    jmp start_zerotimer_with_callback

    @@done_scrolling:
    lda #0
    sta selected_song
    lda #10 : ldy #4
    jsr start_timer
    ldcay @@move_next_piece
    jmp set_timer_callback

    @@move_next_piece:
    lda selected_song
    jsr hide_uncentered_piece
    lda selected_song
    jsr draw_centered_piece
    lda #1 : ldx #4
    jsr start_sfx
    inc selected_song
    lda selected_song
    cmp #6
    beq @@flash
    lda #14 : ldy #4
    jsr start_timer
    ldcay @@move_next_piece
    jmp set_timer_callback

    @@flash:
    lda #20
    sta flash_counter
    lda #14 : ldy #4
    jsr start_timer
    ldcay @@flash_it
    jmp set_timer_callback

    @@flash_it:
    ldy #$3F : lda #$00 : ldx #$44
    jsr begin_ppu_string
    lda flash_counter
    lsr
    ldy #$20
    bcc +
    ldy #$0F
  + tya
    jsr put_ppu_string_byte
    jsr end_ppu_string
    dec flash_counter
    beq @@done_flashing
    lda #6 : ldy #1
    jsr start_timer
    ldcay @@flash_it
    jmp set_timer_callback

    @@done_flashing:
    lda #12 : ldy #4
    jsr start_timer
    ldcay @@show_completed_pad
    jmp set_timer_callback

    @@show_completed_pad:
    jsr wipeout
    lda #34 : sta chr_banks[0]
    ldcay @@completed_pad_data
    jsr write_ppu_data_at
    lda #40 : ldy #4
    jsr start_timer
    ldcay @@fade_out_final
    jsr set_timer_callback
    lda #10: ldx #4
    jsr start_sfx
    jsr screen_on
    jmp nmi_on

    @@fade_out_final:
    lda #$0F
    sta palette+1
    sta palette+2
    sta palette+3
    lda #0 : ldy #31
    jsr set_fade_range
    lda #12
    jsr set_fade_delay
    jsr start_fade_to_black
    lda #20 : ldy #4
    jsr start_timer
    ldcay @@go_to_cutscene
    jmp set_timer_callback

    @@go_to_cutscene:
    lda #6
    jsr swap_bank
    lda #18
    sta main_cycle
    rts

@@palette:
.db $0f,$06,$16,$10 ; frame + texture
.db $0f,$27,$16,$20 ; rockers
.db $0f,$06,$00,$10 ; pad pieces
.db $0f,$20,$10,$00 ; text
.db $0f,$16,$27,$37,$0f,$20,$20,$20,$0f,$20,$20,$20,$0f,$20,$20,$20

@@completed_pad_data:
.incbin "graphics/completedpad.dat"
.db $23,$D8,$58,$AA
.db 0

.endp

.proc hide_uncentered_piece
    ; To hide the piece, set the palette to 0 (since it's faded out)
    asl
    tay
    lda @@bg_data_table,y
    pha
    lda @@bg_data_table+1,y
    tay
    pla
    jmp copy_string_to_ppu_buffer

@@bg_data_table:
.dw @@bg_data_0
.dw @@bg_data_1
.dw @@bg_data_2
.dw @@bg_data_3
.dw @@bg_data_4
.dw @@bg_data_5
@@bg_data_0:
.db $23,$C9,$01,$00
.db 0
@@bg_data_1:
.db $23,$CB,$42,$00
.db 0
@@bg_data_2:
.db $23,$CE,$01,$00
.db 0
@@bg_data_3:
.db $23,$D9,$01,$00
.db 0
@@bg_data_4:
.db $23,$DB,$42,$00
.db 0
@@bg_data_5:
.db $23,$DE,$01,$00
.db 0
.endp

.proc draw_centered_piece
    asl
    tay
    lda @@bg_data_table,y
    pha
    lda @@bg_data_table+1,y
    tay
    pla
    ldx #30
    jmp copy_bytes_to_ppu_buffer

@@bg_data_table:
.dw @@bg_data_0
.dw @@bg_data_1
.dw @@bg_data_2
.dw @@bg_data_3
.dw @@bg_data_4
.dw @@bg_data_5
@@bg_data_0:
.db $21,$0A,$44,$00
.db $21,$2A,$04,$80,$81,$82,$83
.db $21,$4A,$04,$84,$85,$86,$87
.db $21,$6A,$04,$88,$89,$8A,$8B
.db $23,$D2,$02,$88,$22
@@bg_data_1:
.db $21,$0E,$44,$00
.db $21,$2E,$04,$8C,$8D,$8E,$8F
.db $21,$4E,$04,$90,$91,$92,$93
.db $21,$6E,$04,$94,$95,$96,$97
.db $23,$D3,$02,$AA,$22
@@bg_data_2:
.db $21,$12,$44,$00
.db $21,$32,$04,$98,$99,$9A,$9B
.db $21,$52,$04,$9C,$9D,$9E,$9F
.db $21,$72,$04,$A0,$A1,$A2,$A3
.db $23,$D4,$02,$AA,$22
@@bg_data_3:
.db $21,$8A,$04,$A4,$A5,$A6,$A7
.db $21,$AA,$04,$A8,$A9,$AA,$AB
.db $21,$CA,$04,$AC,$AD,$AE,$AF
.db $21,$EA,$44,$00
.db $23,$DA,$02,$88,$AA
@@bg_data_4:
.db $21,$8E,$04,$B0,$B1,$B2,$B3
.db $21,$AE,$04,$B4,$B5,$B6,$B7
.db $21,$CE,$04,$B8,$B9,$BA,$BB
.db $21,$EE,$44,$00
.db $23,$DB,$02,$AA,$22
@@bg_data_5:
.db $21,$92,$04,$BC,$BD,$BE,$BF
.db $21,$B2,$04,$C0,$C1,$C2,$C3
.db $21,$D2,$04,$C4,$C5,$C6,$C7
.db $21,$F2,$44,$00
.db $23,$DC,$02,$AA,$22
.endp

.if 0
.proc select_first_selectable_song
    ldy #0
  - lda bitmasktable,y
    and player.acquired_pad_pieces
    bne +
    sty selected_song
    rts
  + iny
    cpy #6
    bne -
    rts
.endp
.endif

.proc draw_acquired_pad_pieces
    ldy #5
  - lda bitmasktable,y
    and player.acquired_pad_pieces
    beq +
    tya : pha
    asl
    tay
    lda @@bg_data_table,y
    pha
    lda @@bg_data_table+1,y
    tay
    pla
    jsr write_ppu_data_at
    pla : tay
  + dey
    bpl -
    rts

@@bg_data_table:
.dw @@bg_data_0
.dw @@bg_data_1
.dw @@bg_data_2
.dw @@bg_data_3
.dw @@bg_data_4
.dw @@bg_data_5
@@bg_data_0:
.db $20,$84,$44,$00
.db $20,$A4,$04,$80,$81,$82,$83
.db $20,$C4,$04,$84,$85,$86,$87
.db $20,$E4,$04,$88,$89,$8A,$8B
.db $23,$C9,$01,$AA
.db 0
@@bg_data_1:
.db $20,$8E,$44,$00
.db $20,$AE,$04,$8C,$8D,$8E,$8F
.db $20,$CE,$04,$90,$91,$92,$93
.db $20,$EE,$04,$94,$95,$96,$97
.db $23,$CB,$02,$88,$22
.db 0
@@bg_data_2:
.db $20,$98,$44,$00
.db $20,$B8,$04,$98,$99,$9A,$9B
.db $20,$D8,$04,$9C,$9D,$9E,$9F
.db $20,$F8,$04,$A0,$A1,$A2,$A3
.db $23,$CE,$01,$AA
.db 0
@@bg_data_3:
.db $21,$84,$44,$00
.db $21,$A4,$04,$A4,$A5,$A6,$A7
.db $21,$C4,$04,$A8,$A9,$AA,$AB
.db $21,$E4,$04,$AC,$AD,$AE,$AF
.db $23,$D9,$01,$AA
.db 0
@@bg_data_4:
.db $21,$8E,$44,$00
.db $21,$AE,$04,$B0,$B1,$B2,$B3
.db $21,$CE,$04,$B4,$B5,$B6,$B7
.db $21,$EE,$04,$B8,$B9,$BA,$BB
.db $23,$DB,$02,$88,$22
.db 0
@@bg_data_5:
.db $21,$98,$44,$00
.db $21,$B8,$04,$BC,$BD,$BE,$BF
.db $21,$D8,$04,$C0,$C1,$C2,$C3
.db $21,$F8,$04,$C4,$C5,$C6,$C7
.db $23,$DE,$01,$AA
.db 0
.endp

.proc draw_locked_songs
    ldy #5
  - lda player.unlocked_songs
    eor #$FF
    and bitmasktable,y
    beq +
    tya : pha
    asl
    tay
    lda @@bg_data_table,y
    pha
    lda @@bg_data_table+1,y
    tay
    pla
    jsr write_ppu_data_at
    pla : tay
  + dey
    bpl -
    rts

@@bg_data_table:
.dw @@bg_data_0
.dw @@bg_data_1
.dw @@bg_data_2
.dw @@bg_data_3
.dw @@bg_data_4
.dw @@bg_data_5
@@bg_data_0:
.db $20,$84,$04,$78,$79,$7A,$7B
.db $20,$A4,$04,$7C,$7D,$7E,$7F
.db $20,$C4,$04,$C8,$C9,$CA,$CB
.db $20,$E4,$04,$CC,$CD,$CE,$CF
;.db $23,$C9,$01,$AA
.db 0
@@bg_data_1:
.db $20,$8E,$04,$78,$79,$7A,$7B
.db $20,$AE,$04,$7C,$7D,$7E,$7F
.db $20,$CE,$04,$C8,$C9,$CA,$CB
.db $20,$EE,$04,$CC,$CD,$CE,$CF
;.db $23,$CB,$02,$88,$22
.db 0
@@bg_data_2:
.db $20,$98,$04,$78,$79,$7A,$7B
.db $20,$B8,$04,$7C,$7D,$7E,$7F
.db $20,$D8,$04,$C8,$C9,$CA,$CB
.db $20,$F8,$04,$CC,$CD,$CE,$CF
;.db $23,$CE,$01,$AA
.db 0
@@bg_data_3:
.db $21,$84,$04,$78,$79,$7A,$7B
.db $21,$A4,$04,$7C,$7D,$7E,$7F
.db $21,$C4,$04,$C8,$C9,$CA,$CB
.db $21,$E4,$04,$CC,$CD,$CE,$CF
;.db $23,$D9,$01,$AA
.db 0
@@bg_data_4:
.db $21,$8E,$04,$78,$79,$7A,$7B
.db $21,$AE,$04,$7C,$7D,$7E,$7F
.db $21,$CE,$04,$C8,$C9,$CA,$CB
.db $21,$EE,$04,$CC,$CD,$CE,$CF
;.db $23,$DB,$02,$88,$22
.db 0
@@bg_data_5:
.db $21,$98,$04,$78,$79,$7A,$7B
.db $21,$B8,$04,$7C,$7D,$7E,$7F
.db $21,$D8,$04,$C8,$C9,$CA,$CB
.db $21,$F8,$04,$CC,$CD,$CE,$CF
;.db $23,$DE,$01,$AA
.db 0
.endp

.proc draw_selection
    ; top-left corner
    jsr next_sprite_index
    tax
    lda #1
    sta sprites.tile,x
    ldy selected_song
    lda @@top_left_y,y
    sta sprites._y,x
    lda @@top_left_x,y
    sta sprites._x,x
    lda #0
    sta sprites.attr,x
    ; top-right corner
    jsr next_sprite_index
    tax
    lda #5
    sta sprites.tile,x
    ldy selected_song
    lda @@top_left_y,y
    sta sprites._y,x
    lda @@top_left_x,y
    clc : adc #34
    sta sprites._x,x
    lda #0
    sta sprites.attr,x
    ; bottom-right corner
    jsr next_sprite_index
    tax
    lda #3
    sta sprites.tile,x
    ldy selected_song
    lda @@top_left_y,y
    clc : adc #34
    sta sprites._y,x
    lda @@top_left_x,y
    clc : adc #34
    sta sprites._x,x
    lda #0
    sta sprites.attr,x
    ; bottom-left corner
    jsr next_sprite_index
    tax
    lda #7
    sta sprites.tile,x
    ldy selected_song
    lda @@top_left_y,y
    clc : adc #34
    sta sprites._y,x
    lda @@top_left_x,y
    sta sprites._x,x
    lda #0
    sta sprites.attr,x
    rts
@@top_left_x:
.db 27,107,187
.db 27,107,187
@@top_left_y:
.db 26,26,26
.db 90,90,90
.endp

.proc maybe_draw_selection
    lda frame_count
    lsr : lsr : lsr : lsr
    bcs +
    rts
  + jmp draw_selection
.endp

.proc start_song_for_selection
    ldy selected_song
    lda bitmasktable,y
    and player.unlocked_songs
    bne @@start_real_song
    ; song hasn't been unlocked - play song of mystery
    lda #6
    jsr swap_bank
    lda #6
    jmp @@start_it

    @@start_real_song:
    lda selected_song
    asl : asl : asl : asl
    tay
    lda target_data_table+1,y
    pha
    lda target_data_table+0,y
    jsr swap_bank
    pla

    @@start_it:
    jsr start_song
;    lda #$1C
;    jsr mixer_set_muted_channels
    lda #0
    jsr mixer_set_master_vol ; set volume to 0 - we will fade it in gradually
    lda #2
    sta audio_state ; go to "fade in" state
    lda #1
    sta audio_timer
    rts
.endp

.proc update_audio
    lda audio_state
    and #3
    beq @@play
    cmp #1
    beq @@start_song
    cmp #2
    beq @@fade_in

    ; fade out
    dec audio_timer
    beq +
    rts
  + jsr mixer_get_master_vol
    sec : sbc #$10
    bcs +
    lda #1
    sta audio_state ; go to "start song" state
    rts
  + jsr mixer_set_master_vol
    lda #1
    sta audio_timer
    rts

    @@start_song:
    jmp start_song_for_selection

    @@fade_in:
    dec audio_timer
    beq +
    rts
  + jsr mixer_get_master_vol
    clc : adc #$10
    bcc +
    lda #0
    sta audio_state ; go to "play" state
    rts
  + jsr mixer_set_master_vol
    lda #3
    sta audio_timer
    rts

    @@play:
    lda frame_count
    lsr
    bcs +
    rts
  + lsr
    bcs +
    rts
  + dec audio_timer
    beq +
    rts
  + lda #3
    sta audio_state ; go to "fade out" state
    lda #1
    sta audio_timer
    rts
.endp

.proc songselect_main
    jsr reset_sprites
    jsr maybe_draw_selection
    jsr update_audio
    jsr update_song_text
    jsr check_input
    rts
.endp

.proc update_song_text
    lda text_state
    beq @@erase_text
    cmp #1
    beq @@erase_more_text
    cmp #2
    beq @@delay
    cmp #3
    beq @@write_rocker_info
    cmp #4
    bne +
    jmp @@update_scroller
    ; nothing
  + rts

    @@erase_text:
    ; 1st row
    ldy #$22 : lda #$A4 : ldx #$58
    jsr begin_ppu_string
    lda #0
    jsr put_ppu_string_byte
    jsr end_ppu_string
    ; 2nd row
    ldy #$22 : lda #$C4 : ldx #$58
    jsr begin_ppu_string
    lda #0
    jsr put_ppu_string_byte
    jsr end_ppu_string

    inc text_state
    rts

    @@erase_more_text:
    ; 3rd row
    ldy #$22 : lda #$E4 : ldx #$58
    jsr begin_ppu_string
    lda #0
    jsr put_ppu_string_byte
    jsr end_ppu_string
    ; 4th row
    ldy #$23 : lda #$04 : ldx #$58
    jsr begin_ppu_string
    lda #0
    jsr put_ppu_string_byte
    jsr end_ppu_string

    lda #4
    sta flash_counter
    inc text_state ; delay
    rts

    @@delay:
    dec flash_counter
    beq +
    rts
  + inc text_state ; write info
    rts

    @@write_rocker_info:
    ldy selected_song
    lda bitmasktable,y
    and player.unlocked_songs
    bne @@write_unlocked_rocker_info
    ; it's not unlocked
    jsr print_cost_and_credit
    ; have enough credit?
    lda player.credit
    ldy selected_song
    cmp credit_limits,y
    bcs @@write_unlockable_rocker_info

    ; no unlock for you!
    ldcay @@unlock_unavailable_begin
    ldx #(@@unlock_unavailable_end-@@unlock_unavailable_begin)
    jsr copy_bytes_to_ppu_buffer

    lda #5
    sta text_state
    rts

    @@write_unlockable_rocker_info:
    ldcay @@unlock_info_begin
    ldx #(@@unlock_info_end-@@unlock_info_begin)
    jsr copy_bytes_to_ppu_buffer

    lda #5
    sta text_state
    rts

    @@write_unlocked_rocker_info:
    ; name
    lda selected_song
    asl
    tay
    lda @@rocker_name_data_table+0,y
    pha
    lda @@rocker_name_data_table+1,y
    tay
    pla
    jsr copy_string_to_ppu_buffer

    lda game_type
    cmp #2 ; versus?
    beq +
    jsr print_completed_challenges_count

    ; init text scroller
  + lda selected_song
    asl
    tay
    lda @@rocker_text_scroller_data_table+0,y
    sta text_scroller_data.lo
    lda @@rocker_text_scroller_data_table+1,y
    sta text_scroller_data.hi

    inc text_state ; update scroller

    @@update_scroller:
    lda frame_count
    and #$0F
    beq +
    rts
  + ldy #$23 : lda #$04 : ldx #24
    jsr begin_ppu_string
    ldy text_scroller_offset
    lda #24
  - pha
    lda [text_scroller_data],y
    cmp #$FF   ; EOD?
    bne +
    cpy text_scroller_offset
    php
    ldy #0
    lda [text_scroller_data],y
    plp
    bne +
    sty text_scroller_offset
  + jsr put_ppu_string_byte
    iny
    pla
    sec
    sbc #1
    bne -
    jsr end_ppu_string
    inc text_scroller_offset
    rts

.charmap "font.tbl"

@@unlock_info_begin:
.db $23,$05,17 : .char "PUSH A TO UNLOCK."
@@unlock_info_end:

@@unlock_unavailable_begin:
.db $23,$05,21 : .char "WIN TOKENS TO UNLOCK."
@@unlock_unavailable_end:

@@rocker_name_data_table:
.dw @@rocker_0_name_data
.dw @@rocker_1_name_data
.dw @@rocker_2_name_data
.dw @@rocker_3_name_data
.dw @@rocker_4_name_data
.dw @@rocker_5_name_data

@@rocker_0_name_data:
.db $22,$AC,8 : .char "LED MAN "
@@rocker_1_name_data:
.db $22,$AC,8 : .char "LOVE MAN"
@@rocker_2_name_data:
.db $22,$AC,8 : .char "WHIP MAN"
@@rocker_3_name_data:
.db $22,$AC,8 : .char "FREE MAN"
@@rocker_4_name_data:
.db $22,$AC,8 : .char "DETH MAN"
@@rocker_5_name_data:
.db $22,$AC,8 : .char "LIFE MAN"

@@rocker_text_scroller_data_table:
.dw @@rocker_0_text_scroller_data
.dw @@rocker_1_text_scroller_data
.dw @@rocker_2_text_scroller_data
.dw @@rocker_3_text_scroller_data
.dw @@rocker_4_text_scroller_data
.dw @@rocker_5_text_scroller_data

.charmap "font.tbl"
@@rocker_0_text_scroller_data:
.char " ORIGINAL SONG BY LED ZEPPELIN   RELEASED MARCH 28, 1973   WRITTEN BY LED ZEPPELIN   PRODUCED BY JIMMY PAGE                    "
;.char " ORIGINAL SONG BY GUNS N' ROSES   RELEASED JULY 21, 1987   WRITTEN BY IZZY STRADLIN, SLASH   PRODUCED BY MIKE CLINK                    "
.db $FF
@@rocker_1_text_scroller_data:
.char " ORIGINAL SONG BY ELVIS PRESLEY   RELEASED AUGUST 1, 1972   WRITTEN BY DENNIS LINDE   PRODUCED BY FELTON JARVIS                    "
.db $FF
@@rocker_2_text_scroller_data:
.char " ORIGINAL SONGS BY KONAMI   RELEASED JULY 12, 1991   WRITTEN BY HIDEHIRO FUNAUCHI                    "
.db $FF
@@rocker_3_text_scroller_data:
.char " ORIGINAL SONG BY QUEEN   RELEASED APRIL 2, 1984   WRITTEN BY JOHN DEACON   PRODUCED BY QUEEN, MACK                    "
.db $FF
@@rocker_4_text_scroller_data:
.char " ORIGINAL SONG BY MEGADETH   RELEASED JULY 14, 1992   WRITTEN BY DAVE MUSTAINE, MARTY FRIEDMAN   PRODUCED BY MAX NORMAN, DAVE MUSTAINE                    "
.db $FF
@@rocker_5_text_scroller_data:
.char " ORIGINAL SONG BY AAGE ALEKSANDERSEN OG SAMBANDET   WRITTEN BY AAGE ALEKSANDERSEN   RELEASED 1984                    "
.db $FF
.endp

; Number of credits needed to unlock songs
credit_limits:
.db 6,4,2,2,4,6

.proc print_cost_and_credit
    ldcay @@cost_message : jsr copy_string_to_ppu_buffer
    ; print cost
    ldy #$22 : lda #$AA : ldx #1
    jsr begin_ppu_string
    ldy selected_song
    lda credit_limits,y
    ora #$D0
    jsr put_ppu_string_byte
    jsr end_ppu_string

    lda player.credit
    cmp #10
    bcc +
    ldcay @@credit_message_two_digits : jsr copy_string_to_ppu_buffer
    jmp ++
  + ldcay @@credit_message_one_digit : jsr copy_string_to_ppu_buffer
    ; print credit
 ++ ldy #$BA : ldx #1
    lda player.credit
    cmp #10
    bcc +
    dey
    inx
  + sta AC0
    lda #0 : sta AC1 : sta AC2
    lda #$22
    jmp print_value

@@cost_message:
.db $22,$A5,5 : .char "COST="
@@credit_message_one_digit:
.db $22,$B3,7 : .char "CREDIT="
@@credit_message_two_digits:
.db $22,$B2,7 : .char "CREDIT="
.endp

.proc print_completed_challenges_count
    ldy selected_song
    lda player.completed_challenges,y
    jsr count_bits
    txa
    pha
    ldy #$22 : lda #$AC+12 : ldx #3
    jsr begin_ppu_string
    pla
    ora #$D0
    jsr put_ppu_string_byte
    lda #$F9 ; /
    jsr put_ppu_string_byte
    lda #$D8 ; 8
    jsr put_ppu_string_byte
    jmp end_ppu_string
.endp

.proc play_cursor_sfx
    lda #0
    ldx #4
    jmp start_sfx
.endp

.proc selection_changed
    jsr play_cursor_sfx

    lda #0
    sta text_state
    sta text_scroller_offset

    ldy selected_song
    lda bitmasktable,y
    and player.unlocked_songs
    bne +
    ; only if song of mystery isn't already playing
    lda current_song
    cmp #6
    bne +
    rts
  + lda #3
    sta audio_state ; go to "fade out" state
    lda #1
    sta audio_timer
    rts
.endp

.proc check_input
    jsr palette_fade_in_progress
    beq +
    rts
  + lda joypad0_posedge
    and #(JOYPAD_BUTTON_START | JOYPAD_BUTTON_A)
    bne @@choose
    lda joypad0_posedge
    and #JOYPAD_BUTTON_DOWN
    bne @@down
    lda joypad0_posedge
    and #JOYPAD_BUTTON_UP
    bne @@up
    lda joypad0_posedge
    and #(JOYPAD_BUTTON_SELECT | JOYPAD_BUTTON_RIGHT)
    bne @@right
    lda joypad0_posedge
    and #JOYPAD_BUTTON_LEFT
    bne @@left
    rts

    @@down:
    lda selected_song
    clc
    adc #3
    cmp #6
    bcc +
    sbc #6
  + sta selected_song
.if 0
    tay
    lda bitmasktable,y
    and player.acquired_pad_pieces
    bne @@right
.endif
    jmp selection_changed

    @@up:
    lda selected_song
    sec
    sbc #3
    bpl +
    clc
    adc #6
  + sta selected_song
.if 0
    tay
    lda bitmasktable,y
    and player.acquired_pad_pieces
    bne @@right
.endif
    jmp selection_changed

    @@right:
    inc selected_song
    lda selected_song
    cmp #6
    bne +
    lda #0
    sta selected_song
  +
.if 0
    tay
    lda bitmasktable,y
    and player.acquired_pad_pieces
    bne @@right
.endif
    jmp selection_changed

    @@left:
    dec selected_song
    lda selected_song
    bpl +
    lda #5
    sta selected_song
  +
.if 0
    tay
    lda bitmasktable,y
    and player.completed_songs
    bne @@left
.endif
    jmp selection_changed

    @@choose:
    ldy selected_song
    lda bitmasktable,y
    and player.unlocked_songs
    bne @@play
    ; unlockable?
    lda player.credit
    cmp credit_limits,y
    bcs @@unlock
    ; can't unlock
    lda #7 : ldx #4
    jmp start_sfx

    @@unlock:
.ifndef NO_TRANSITIONS
    ; ### need an unlock SFX
    lda #2 : ldx #4
    jsr start_sfx
    jmp +
.endif

    @@play:
.ifndef NO_TRANSITIONS
    lda #10 : ldx #4
    jsr start_sfx

    ; start fading out music
  + lda #0
    sta main_cycle

    @@start_fade_out_music_timer:
    lda #2 : ldy #3
    jsr start_timer
    ldcay @@fade_out_music
    jmp set_timer_callback

    @@fade_out_music:
    jsr mixer_get_master_vol
    sec
    sbc #$10
    cmp #$30
    bcc +
    jsr mixer_set_master_vol
    jmp @@start_fade_out_music_timer
  + ; done fading out music
    lda #0
    jsr start_song ; mute
    lda #6 : ldy #6
    jsr start_timer
    ldcay @@really_choose
    jsr set_timer_callback
    jmp start_fade_to_black

    @@really_choose:
.endif
    ldy selected_song
    lda bitmasktable,y
    and player.unlocked_songs
    beq @@really_unlock

    jsr setup_normal_play
    lda #6
    jsr swap_bank
    ldx game_type
    lda #20 ; challenges init
    cpx #2 ; versus?
    bne +
    lda #26 ; skip straight to game info
  + sta main_cycle
    rts

    @@really_unlock:
    lda bitmasktable,y
    ora player.unlocked_songs
    sta player.unlocked_songs
    lda player.credit
    sec
    sbc credit_limits,y
    sta player.credit

    ; back to song select
    lda #5
    sta main_cycle
    rts
.endp

.end
