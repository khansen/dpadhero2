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

config_player_index .db ; 0 or 1
lane_index .db
temp_button_mapping .db[5]

.codeseg

.public buttonconfig_init
.public buttonconfig_main

.extrn wipeout:proc
.extrn draw_lane_indicator:proc
.extrn button_mapping:byte
.extrn game_type:byte

.extrn pad3d_data:byte

.extrn main_cycle:byte
.extrn frame_count:byte

.proc buttonconfig_init
    jsr wipeout

;    lda #1
;    sta config_player_index

.ifdef MMC
.if MMC == 3
    lda #16 : sta chr_banks[0]
    lda #38 : sta chr_banks[1]
    lda #20 : sta chr_banks[2]
    lda #21 : sta chr_banks[3]
    lda #22 : sta chr_banks[4]
    lda #23 : sta chr_banks[5]
.endif
.endif

    jsr draw_bg

    jsr set_black_palette
    ldcay @@palette
    jsr load_palette

    lda #0 : ldy #31
    jsr set_fade_range
    lda #6
    jsr set_fade_delay
    jsr start_fade_from_black

    lda #0
    sta lane_index

    inc main_cycle

    jsr screen_on
    jsr nmi_on
    rts

@@palette:
; bg
.db $0f,$06,$36,$37 ; logo, hearts, VU
.db $0f,$1B,$12,$22
.db $0f,$2B,$20,$10 ; points, progress bar
.db $0f,$38,$10,$00 ; pad, VU
; sprites
.db $0f,$02,$22,$30 ; target - blue
.db $0f,$0A,$2A,$30 ; target - green
.db $0f,$08,$28,$30 ; target - yellow
.db $0f,$06,$16,$30 ; target - red
.endp

.proc draw_bg
    ldcay pad3d_data
    jsr write_ppu_data_at
    ldcay @@data
    jsr write_ppu_data_at
    lda game_type
    beq +
    rts
  + ldcay @@player_data
    jsr write_ppu_data_at
    ldy #$20 : lda #$93 : ldx #1
    jsr begin_ppu_string
    lda config_player_index
    clc : adc #$D1
    jsr put_ppu_string_byte
    jsr end_ppu_string
    jmp flush_ppu_buffer

@@data:
.charmap "font.tbl"
.db $20,$E7,19
.char "PUSH DESIRED BUTTON"
; L R U D SEL B A (buttons initially available)
.db $21,$C9,$0E,$B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7,$B8,$B9,$BA,$BB,$BC,$BD
.db $21,$E9,$0E,$C0,$C1,$C2,$C3,$C4,$C5,$C6,$C7,$C8,$C9,$CA,$CB,$CC,$CD
.db $23,$C0,$50,$FF
.db $23,$E8,$48,$F0
.db 0

@@player_data:
.db $20,$8C,6 : .char "PLAYER"
.db 0
.endp

; In: A = bitmask (only one 1)
; Out: Y = bit index (0..7)
.proc joypad_mask_to_button
    ldy #$FF
  - lsr
    iny
    bcc -
    rts
.endp

; In: A = physical button index (0..7)
; Out: CF=1 if mapped, CF=0 if not
.proc is_p1_physical_button_mapped
    ldy lane_index
  - dey
    bmi +
    cmp button_mapping,y
    bne -
    sec
    rts
  + clc
    rts
.endp

; In: A = physical button index (0..7)
; Out: CF=1 if mapped, CF=0 if not
.proc is_p2_physical_button_mapped
    ldy lane_index
  - dey
    bmi +
    cmp button_mapping+5,y
    bne -
    sec
    rts
  + clc
    rts
.endp

; In: A = physical button index (0..7)
; Out: CF=1 if mapped, CF=0 if not
.proc is_physical_button_mapped
    ldy config_player_index
    bne +
    jmp is_p1_physical_button_mapped
  + jmp is_p2_physical_button_mapped
.endp

; A = NES button (0..7)
.proc move_display_button
    pha
    ; erase the button from the on-screen available list
    tay
    lda @@display_button_index,y
    asl
    adc #$C9
    pha
    ; upper half
    ldy #$21 : ldx #$42
    jsr begin_ppu_string
    lda #0
    jsr put_ppu_string_byte
    jsr end_ppu_string
    ; lower half
    pla
    clc
    adc #$20
    ldy #$21 : ldx #$42
    jsr begin_ppu_string
    lda #0
    jsr put_ppu_string_byte
    jsr end_ppu_string

    ; draw button at its mapped position
    ldy lane_index
    lda @@virtual_button_offset,y
    clc
    adc #$80
    ldy #$22 : ldx #2
    jsr begin_ppu_string
    pla
    tay
    lda @@display_button_index,y
    asl
    adc #$B0
    sta ppu_buffer,x
    inx
    ora #1
    sta ppu_buffer,x
    inx
    jsr end_ppu_string
    ; lower half
    lda ppu_buffer-5,x
    tay
    lda ppu_buffer-4,x
    clc
    adc #$20
    ldx #2
    jsr begin_ppu_string
    lda ppu_buffer-5,x
    clc
    adc #$10
    sta ppu_buffer,x
    inx
    ora #1
    sta ppu_buffer,x
    inx
    jmp end_ppu_string

@@display_button_index:
.db 1,0,3,2,0,4,5,6

@@virtual_button_offset:
.db 3,10,15,21,27
.endp

.proc check_input
    ldy config_player_index
    lda joypad0_posedge,y
    bne +
    rts
  + and #JOYPAD_BUTTON_START
    bne @@start

    lda joypad0_posedge,y
    jsr joypad_mask_to_button
    tya
    pha ; save button index
    jsr is_physical_button_mapped
    bcc @@map_it
    ; this button is already mapped
    ; ### play error SFX?
    pla
    rts

    @@map_it:
    lda config_player_index
    asl : asl : adc config_player_index ; * 5
    ora lane_index
    tay
    pla ; restore button index
    ; ### use temp_button_mapping
    sta button_mapping,y

    jsr move_display_button

    inc lane_index
    lda lane_index
    cmp #5
    beq @@done
    rts

    @@done:
    ; ### ask for confirmation
    ; ### go back to game?
    lda #7
    sta main_cycle
    rts

    @@start:
    ; abort?
    rts
.endp

.proc highlight_current_lane
    lda frame_count
    and #2
    beq +
    ldy lane_index
    jsr draw_lane_indicator
  + rts
.endp

.proc buttonconfig_main
    jsr reset_sprites
    jsr highlight_current_lane
    jsr check_input
    rts
.endp

.end
