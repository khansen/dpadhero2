;
;    Copyright (C) 2009 Kent Hansen.
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
.include "sound/sfx.h"
.include "sound/sound.h"
.include "sound/mixer.h"

.ifdef MMC
.if MMC == 3
.include "mmc/mmc3.h"
.endif
.endif

.dataseg

tmp .db
flash_counter .db

.codeseg

.public title_init
.public title_main

.extrn wipeout:proc
.extrn go_to_game_type_select:proc
.extrn main_cycle:byte
.extrn volume_table:byte
.extrn frame_count:byte

.proc title_init
    jsr wipeout
    lda ppu.ctrl0
    ora #PPU_CTRL0_SPRITE_SIZE_8x16
    ora #1 ; initially display the 2nd nametable
    sta ppu.ctrl0

.ifdef MMC
.if MMC == 3
    lda #0 : sta chr_banks[0]
    lda #30 : sta chr_banks[1] ; for font
    lda #4 : sta chr_banks[2]
    lda #5 : sta chr_banks[3]
    lda #6 : sta chr_banks[4]
    lda #7 : sta chr_banks[5]
.endif
.endif

    ldcay @@title_data : jsr write_ppu_data_at

    jsr set_black_palette
    ldcay @@palette
    jsr load_palette

    lda #5: ldy #5 : jsr start_timer
    ldcay @@fade_in_logo : jsr set_timer_callback

    lda #0 : sta main_cycle

    jsr screen_on
    jsr nmi_on
    rts

    @@fade_in_logo:
    lda #1 : jsr start_song
    lda #0 : ldy #31 : jsr set_fade_range
    lda #7 : jsr set_fade_delay
    jsr start_fade_from_black

    lda #20 : ldy #7 : jsr start_timer
    ldcay @@logo_done
    jmp set_timer_callback

    @@logo_done:
    jsr start_fade_to_black
    lda #12 : ldy #7 : jsr start_timer
    ldcay @@logo_faded_out
    jmp set_timer_callback

    @@logo_faded_out:
    jsr screen_off
    ldcay @@slogan_data
    jsr write_ppu_data_at
    jsr screen_on
    jsr start_fade_from_black
    lda #20 : ldy #7 : jsr start_timer
    ldcay @@slogan_done
    jmp set_timer_callback

    @@slogan_done:
    jsr start_fade_to_black
    lda #12 : ldy #7 : jsr start_timer
    ldcay @@slogan_faded_out
    jmp set_timer_callback

    @@slogan_faded_out:
    lda ppu.ctrl0
    and #~1 ; switch to the title screen nametable
    sta ppu.ctrl0
    lda #2 : sta chr_banks[1]
    jsr start_fade_from_black
    lda #4 : ldy #6 : jsr start_timer
    ldcay @@title_ready
    jmp set_timer_callback

    @@title_ready:
    lda #2 : sta main_cycle
    rts

@@palette:
.db $0f,$16,$27,$10 ; main logo
.db $0f,$16,$27,$10 ; II
.db $0f,$20,$20,$20 ; text
.db $0f,$20,$20,$20
.db $0f,$20,$20,$20,$0f,$20,$20,$20,$0f,$20,$20,$20,$0f,$20,$20,$20

@@title_data:
.incbin "graphics/titlelogo.dat"
; PUSH START
.db $22,$EB,$0A,$F9,$FA,$FB,$FD,$00,$FB,$FC,$FE,$FF,$FC
; attribute table
.db $23,$D6,$42,$55
.db $23,$DE,$42,$55
.db $23,$E6,$42,$55
.db $23,$E8,$48,$A0

.charmap "font.tbl"
.db $2D,$CA,12
.char "DPADHERO.COM"
.db $2F,$D8,$48,$55
.db $2E,$0C,8
.char "PRESENTS"
.db $2F,$D8,$50,$AA
.db 0

@@slogan_data:
.db $2D,$CA,12
.char " A LINK TO  "
.db $2E,$0A,11
.char "THE PADS..."
.db 0
.endp

.proc fade_it
    ldx #(3*sizeof tonal_state)
    lda mixer.envelopes.master,x
    and #$F0
    ora mixer.envelopes.vol.int,x
    tay
    lda volume_table,y
    ora mixer.master_vol
    tay
    lda volume_table,y
    bne +
    lda #3
  + cmp #8
    bcc +
    lda #7
  + pha
    ldy #$3F : lda #$05 : ldx #3
    jsr begin_ppu_string
    pla
    tay
    lda @@color_delta,y
    sta tmp
    ldy #0
  - lda tmp
    php
    clc
    adc palette+5,y
    plp
    bmi +
    cmp #$40
    bcc ++
    lda #$30
    jmp ++
  + cmp #$40
    bcc ++
    lda #$0F
 ++ jsr put_ppu_string_byte
    iny
    cpy #3
    bne -
    jmp end_ppu_string
@@color_delta:
.db $D0,$E0,$F0,$00,$00,$10,$10,$20
.endp

.proc twinkle_cross
    lda frame_count
    lsr : lsr
    and #31
    tax
    ldy @@frame_offset_table,x
  - lda @@sprite_data,y
    cmp #$FF
    bne +
    rts
  + pha
    jsr next_sprite_index
    tax
    pla
    sta sprites._y,x
    iny
    lda @@sprite_data,y
    sta sprites._x,x
    iny
    lda @@sprite_data,y
    sta sprites.tile,x
    iny
    lda @@sprite_data,y
    sta sprites.attr,x
    iny
    bne -
@@frame_offset_table:
.db @@nullframe-@@sprite_data
.db @@nullframe-@@sprite_data
.db @@nullframe-@@sprite_data
.db @@nullframe-@@sprite_data
.db @@frame0-@@sprite_data
.db @@frame1-@@sprite_data
.db @@frame2-@@sprite_data
.db @@frame3-@@sprite_data
.db @@frame4-@@sprite_data
.db @@frame5-@@sprite_data
.db @@frame6-@@sprite_data
.db @@frame7-@@sprite_data
.db @@frame8-@@sprite_data
.db @@frame9-@@sprite_data
.db @@frame10-@@sprite_data
.db @@frame11-@@sprite_data
.db @@frame11-@@sprite_data
.db @@frame10-@@sprite_data
.db @@frame9-@@sprite_data
.db @@frame8-@@sprite_data
.db @@frame7-@@sprite_data
.db @@frame6-@@sprite_data
.db @@frame5-@@sprite_data
.db @@frame4-@@sprite_data
.db @@frame3-@@sprite_data
.db @@frame2-@@sprite_data
.db @@frame1-@@sprite_data
.db @@frame0-@@sprite_data
.db @@nullframe-@@sprite_data
.db @@nullframe-@@sprite_data
.db @@nullframe-@@sprite_data
.db @@nullframe-@@sprite_data
@@sprite_data:
@@frame11:
.db 56,79,$31,0
.db 56,79+8,$33,0
.db 56,79+16,$35,0
.db 56+16,79+8,$37,0
.db $FF
@@frame10:
.db 56,79,$29,0
.db 56,79+8,$2B,0
.db 56,79+16,$2D,0
.db 56+16,79+8,$2F,0
.db $FF
@@frame9:
.db 56,79,$21,0
.db 56,79+8,$23,0
.db 56,79+16,$25,0
.db 56+16,79+8,$27,0
.db $FF
@@frame8:
.db 56,79,$19,0
.db 56,79+8,$1B,0
.db 56,79+16,$1D,0
.db 56+16,79+8,$1F,0
.db $FF
@@frame7:
.db 60,83,$15,0
.db 60,83+8,$17,0
.db $FF
@@frame6:
.db 60,83,$11,0
.db 60,83+8,$13,0
.db $FF
@@frame5:
.db 60,83,$0D,0
.db 60,83+8,$0F,0
.db $FF
@@frame4:
.db 60,83,$09,0
.db 60,83+8,$0B,0
.db $FF
@@frame3:
.db 60,87,$07,0
.db $FF
@@frame2:
.db 60,87,$05,0
.db $FF
@@frame1:
.db 60,87,$03,0
.db $FF
@@frame0:
.db 60,87,$01,0
@@nullframe:
.db $FF
.endp

.proc title_main
    jsr reset_sprites
    jsr fade_it
    jsr twinkle_cross
    lda joypad0_posedge
    and #JOYPAD_BUTTON_START
    bne @@start
    rts

    @@start:
.ifndef NO_TRANSITIONS
    lda #2 : ldx #4
    jsr start_sfx

    lda #0 : sta main_cycle

    ; start "flash PUSH START" effect
    lda #14
    sta flash_counter

    @@flash_it:
    jsr mixer_get_master_vol
    sec
    sbc #$10
    bcs +
    lda #0
  + jsr mixer_set_master_vol

    dec flash_counter
    ldy #$3F : lda #$09 : ldx #$01
    jsr begin_ppu_string
    lda flash_counter
    lsr
    ldy #$0F
    bcs +
    ldy #$20
  + tya
    jsr put_ppu_string_byte
    jsr end_ppu_string
    lda flash_counter
    bne @@start_flash_timer
    ; done flashing
    lda #0
    jsr start_song ; mute
    lda #7
    ldy #7
    jsr start_timer
    lda #<@@really_start
    ldy #>@@really_start
    jsr set_timer_callback
    jmp start_fade_to_black

    @@start_flash_timer:
    lda #3 : ldy #3
    jsr start_timer
    lda #<@@flash_it
    ldy #>@@flash_it
    jmp set_timer_callback

    @@really_start:
.endif
    jmp go_to_game_type_select
.endp

.end
