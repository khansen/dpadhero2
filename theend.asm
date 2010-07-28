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

completed_challenges_count .db

; 0 = normal, 1 = good, 2 = great, 3 = perfect
ending .db

.codeseg

.public theend_init
.public theend_main

.public compute_completed_challenges_count

.extrn wipeout:proc
.extrn count_bits:proc
.extrn print_value:proc
.extrn game_type:byte
.extrn main_cycle:byte
.extrn frame_count:byte
.extrn AC0:byte
.extrn AC1:byte
.extrn AC2:byte

.proc theend_init
    jsr wipeout

;    lda #2
;    sta player.difficulty

.ifdef MMC
.if MMC == 3
    lda #24 : sta chr_banks[0]
    lda #26 : sta chr_banks[1]
    lda #12 : sta chr_banks[2]
    lda #13 : sta chr_banks[3]
    lda #14 : sta chr_banks[4]
    lda #15 : sta chr_banks[5]
.endif
.endif

    lda #1
    sta player.beat_game

    jsr compute_completed_challenges_count
    jsr compute_ending

    ldcay @@bg_data : jsr write_ppu_data_at

    jsr draw_ending_specific_bg

    jsr set_black_palette
    ldcay @@palette : jsr load_palette

    lda #0 : ldy #3 : jsr set_fade_range
    lda #6 : jsr set_fade_delay
    jsr start_fade_from_black

    lda #15 : jsr start_song

    lda #28 : ldy #8 : jsr start_timer
    ldcay @@fade_in_middle : jsr set_timer_callback
    
    inc main_cycle

    jsr screen_on
    jmp nmi_on

    @@fade_in_middle:
    lda #4 : ldy #7
    jsr set_fade_range
    jsr start_fade_from_black
    lda #32 : ldy #8 : jsr start_timer
    ldcay @@fade_in_bottom : jmp set_timer_callback

    @@fade_in_bottom:
    lda #8 : ldy #11
    jsr set_fade_range
    jsr start_fade_from_black
    lda #56 : ldy #8 : jsr start_timer
    ldcay @@fade_out_text : jmp set_timer_callback

    @@fade_out_text:
    lda #0 : ldy #15
    jsr set_fade_range
    jsr start_fade_to_black
    lda #8 : ldy #8 : jsr start_timer
    ldcay @@switch_to_gfx_view : jmp set_timer_callback

    @@switch_to_gfx_view:
    jsr setup_magazine_chr_and_palette
    jsr draw_magazine_mugshot
    lda ppu.ctrl0
    eor #1 ; switch to other nametable
    sta ppu.ctrl0
    lda #0 : ldy #31
    jsr set_fade_range
    jsr start_fade_from_black
    lda #80 : ldy #8 : jsr start_timer
    ldcay @@fade_out_paper : jmp set_timer_callback

    @@fade_out_paper:
    lda #0 : ldy #31 : jsr set_fade_range
    jsr start_fade_to_black
    lda #8 : ldy #8 : jsr start_timer
    ldcay @@show_remaining_challenges_or_credits_screen : jmp set_timer_callback

    @@show_remaining_challenges_or_credits_screen:
    jsr wipeout

    lda completed_challenges_count
    cmp #6*8
    bne @@show_remaining_challenges

    ; show credits
    lda #48 : sta chr_banks[0]
    lda #50 : sta chr_banks[1]
    jsr draw_kentando
    ldcay @@credits_text : jsr write_ppu_data_at
    lda #$16 : sta palette+1
    lda #$27 : sta palette+2
    lda #$37 : sta palette+3
    jsr start_fade_from_black
    jsr screen_on
    jmp nmi_on

    @@show_remaining_challenges:
    lda #24 : sta chr_banks[0]
    lda #26 : sta chr_banks[1]
    ldcay @@remaining_challenges_bg_data : jsr write_ppu_data_at
    jsr draw_completed_challenges_count
    jsr draw_remaining_challenges_count
    ldcay @@palette : jsr load_palette
    jsr start_fade_from_black
    lda #80 : ldy #8 : jsr start_timer
    ldcay @@fade_out_to_song_select : jsr set_timer_callback
    jsr screen_on
    jmp nmi_on

    @@fade_out_to_song_select:
    jsr start_fade_to_black
    jsr start_audio_fade_out
    lda #9 : ldy #8 : jsr start_timer
    ldcay @@go_to_song_select : jmp set_timer_callback

    @@go_to_song_select:
    lda #5 : sta main_cycle
    rts

@@palette:
.db $0f,$07,$27,$37
.db $0f,$07,$27,$37
.db $0f,$07,$27,$37
.db $0f,$07,$27,$37
.db $0f,$06,$16,$20
.db $0f,$0A,$1A,$20
.db $0f,$00,$10,$20
.db $0f,$00,$10,$20

@@bg_data:
; attributes
.db $23,$D8,$50,$55
.db $23,$E8,$50,$AA
.db 0

.charmap "font.tbl"
@@credits_text:
.db $22,$C6,20 : .char "KENT AND ANDREAS SAY"
.db $23,$08,16 : .char "`YOU ARE GREAT!`"
.db 0

@@remaining_challenges_bg_data:
.db $21,$07,18 : .char "YOU HAVE COMPLETED"
.db $21,$49,17 : .char "OF 48 CHALLENGES."
.db $21,$CC,8  : .char "NOT BAD!"
.db $22,$47,18 : .char "HERE'S YOUR CHANCE"
.db $22,$88,15 : .char "TO COMPLETE THE"
.db $22,$CB,9  : .char "FINAL X!!"
.db 0

.endp

.proc draw_completed_challenges_count
    lda completed_challenges_count : sta AC0
    lda #0 : sta AC1 : sta AC2
    ldx #2 : lda #$21 : ldy #$46
    jmp print_value
.endp

.proc draw_remaining_challenges_count
    lda #6*8
    sec : sbc completed_challenges_count
    sta AC0
    ldx #1
    cmp #10
    bcc +
    inx
  + lda #0 : sta AC1 : sta AC2
    lda #$22 : ldy #$D1
    jmp print_value
.endp

.proc setup_magazine_chr_and_palette
    lda #$80 : sta chr_addr_toggle
    lda #44 : sta chr_banks[0] ; rock faces (I)
    lda #46 : sta chr_banks[1] ; rock faces (II)
    lda #36 : sta chr_banks[2] ; magazine template
    lda #37 : clc : adc player.difficulty : sta chr_banks[3] ; magazine title
    lda #40 : clc : adc player.difficulty : sta chr_banks[4] ; guitar
    lda #43 : sta chr_banks[5] ; heading

    lda player.difficulty
    asl : asl : asl : asl : asl ; * 32 (palette size)
    adc #<@@magazine_palettes
    pha
    lda #0 : adc #>@@magazine_palettes
    tay
    pla
    jmp load_palette

@@magazine_palettes:
; people
.db $0f,$16,$3C,$20 ; template
.db $0f,$16,$12,$38 ; title
.db $0f,$15,$27,$36 ; guitar
.db $0f,$12,$12,$12
.db $0f,$0f,$07,$27 ; mugshot
.db $0f,$0A,$1A,$20
.db $0f,$00,$10,$20
.db $0f,$00,$10,$20
; time
.db $0f,$16,$3A,$20 ; template
.db $0f,$16,$27,$32 ; title
.db $0f,$14,$24,$34 ; guitar
.db $0f,$00,$00,$00
.db $0f,$0f,$07,$27 ; mugshot
.db $0f,$0A,$1A,$20
.db $0f,$00,$10,$20
.db $0f,$00,$10,$20
; rolling stone
.db $0f,$16,$36,$20 ; template
.db $0f,$14,$25,$35 ; title
.db $0f,$12,$22,$32 ; guitar
.db $0f,$00,$00,$00
.db $0f,$0f,$07,$27 ; mugshot
.db $0f,$0A,$1A,$20
.db $0f,$00,$10,$20
.db $0f,$00,$10,$20
.endp

.proc theend_main
;    jsr reset_sprites
    rts
.endp

; Sums the number of completed challenges for all songs.
.proc compute_completed_challenges_count
    lda #0
    sta completed_challenges_count
    ldy #5
  - tya : pha
    lda player.completed_challenges,y
    jsr count_bits
    txa
    clc : adc completed_challenges_count
    sta completed_challenges_count
    pla : tay
    dey
    bpl -
    lda completed_challenges_count
    rts
.endp

; Computes ending based on difficulty and total number of completed challenges.
.proc compute_ending
    lda player.difficulty
    asl : tay
    lda completed_challenges_count
    cmp #6*8
    beq @@perfect_ending
    cmp @@challenge_limits+0,y
    bcs @@great_ending
    cmp @@challenge_limits+1,y
    bcs @@good_ending
    ; normal ending
    lda #0 : sta ending
    rts
    @@good_ending:
    lda #1 : sta ending
    rts
    @@great_ending:
    lda #2 : sta ending
    rts
    @@perfect_ending:
    lda #3 : sta ending
    rts

@@challenge_limits:
.db 38,28 ; easy
.db 40,32 ; normal
.db 44,40 ; hard
.endp

.proc draw_ending_specific_bg
    jsr draw_ending_specific_text
    jmp draw_ending_specific_gfx
.endp

.proc draw_ending_specific_text
    lda player.difficulty
    asl : asl
    ora ending
    asl
    tay
    lda @@data_table+0,y
    pha
    lda @@data_table+1,y
    tay
    pla
    jmp write_ppu_data_at

@@data_table:
.dw @@easy_normal_ending_data, @@easy_good_ending_data, @@easy_great_ending_data, @@easy_perfect_ending_data
.dw @@normal_normal_ending_data, @@normal_good_ending_data, @@normal_great_ending_data, @@normal_perfect_ending_data
.dw @@hard_normal_ending_data, @@hard_good_ending_data, @@hard_great_ending_data, @@hard_perfect_ending_data

.charmap "font.tbl"
@@easy_normal_ending_data:
; easy - normal ending
.db $20,$84,24 : .char "YOU HAVE PROVEN YOURSELF"
.db $20,$C4,23 : .char "TO BE A PROMISING D-PAD"
.db $21,$04,8  : .char "WIELDER."

.db $21,$84,23 : .char "WITH MORE PRACTICE, YOU"
.db $21,$C4,21 : .char "CAN REALIZE YOUR TRUE"
.db $22,$04,18 : .char "TAPPING POTENTIAL."

.db $22,$84,21 : .char "AS IT STANDS, YOU ARE"
.db $22,$C4,24 : .char "EXPENDABLE AND IN DANGER"
.db $23,$04,22 : .char "OF BEING OVERTHROWN BY"
.db $23,$44,18 : .char "ANOTHER PERFORMER."
.db 0

@@easy_good_ending_data:
.db $20,$84,24 : .char "YOU HAVE PROVEN YOURSELF"
.db $20,$C4,22 : .char "TO BE A VERY PROMISING"
.db $21,$04,21 : .char "D-PAD WIELDER INDEED."

.db $21,$84,23 : .char "WITH MORE PRACTICE, YOU"
.db $21,$C4,21 : .char "CAN REALIZE YOUR TRUE"
.db $22,$04,18 : .char "TAPPING POTENTIAL."

.db $22,$84,23 : .char "UNTIL THEN, YOU'RE JUST"
.db $22,$C4,22 : .char "ANOTHER ROOKIE WITHOUT"
.db $23,$04,22 : .char "ANY FOLLOWING TO SPEAK"
.db $23,$44,3  : .char "OF."
.db 0

@@easy_great_ending_data:
.db $20,$84,24 : .char "YOU HAVE PROVEN YOURSELF"
.db $20,$C4,24 : .char "TO BE THE MOST PROMISING"
.db $21,$04,21 : .char "ROOKIE D-PAD WIELDER!"

.db $21,$84,22 : .char "THE BUZZ IS SPREADING,"
.db $21,$C4,23 : .char "AND EXPERTS PREDICT YOU"
.db $22,$04,21 : .char "HAVE A BRIGHT FUTURE."

.db $22,$84,21 : .char "IS IT YOUR DESTINY TO"
.db $22,$C4,23 : .char "BECOME THE D-PAD'S TRUE"
.db $23,$04,7  : .char "MASTER?"
.db 0

@@easy_perfect_ending_data:
.db $20,$84,24 : .char "YOU HAVE PROVEN YOURSELF"
.db $20,$C4,23 : .char "TO BE THE MOST TALENTED"
.db $21,$04,25 : .char "D-PAD WIELDER IN HISTORY!"

.db $21,$84,21 : .char "THANK YOU FOR PLAYING"
.db $21,$C4,21 : .char "WITH SUCH PASSION AND"
.db $22,$04,11 : .char "DEDICATION."

.db $22,$84,23 : .char "WE HEREBY CHALLENGE YOU"
.db $22,$C4,22 : .char "TO PLAY A PERFECT GAME"
.db $23,$04,17 : .char "ON THE ''NORMAL''"
.db $23,$44,8  : .char "SETTING!"
.db 0

@@normal_normal_ending_data:
.db $20,$84,24 : .char "YOU HAVE PROVEN YOURSELF"
.db $20,$C4,23 : .char "TO BE A RUN-OF-THE-MILL"
.db $21,$04,14 : .char "D-PAD WIELDER."

.db $21,$84,23 : .char "WITH MORE PRACTICE, YOU"
.db $21,$C4,22 : .char "SHOULD BE ABLE TO RISE"
.db $22,$04,8  : .char "IN RANK."

.db $22,$84,22 : .char "AS IT STANDS, YOU WILL"
.db $22,$C4,21 : .char "NOT BE ABLE TO MAKE A"
.db $23,$04,18 : .char "LIVING OUT OF YOUR"
.db $23,$44,12 : .char "PERFORMANCE."
.db 0

@@normal_good_ending_data:
.db $20,$84,24 : .char "YOU HAVE PROVEN YOURSELF"
.db $20,$C4,22 : .char "TO BE A SLIGHTLY ABOVE"
.db $21,$04,22 : .char "AVERAGE D-PAD WIELDER."

.db $21,$84,24 : .char "D-PAD KARAOKE BAR GUESTS"
.db $21,$C4,23 : .char "WILL NOT BE OFFENDED BY"
.db $22,$04,20 : .char "YOUR STAGE PRESENCE."

.db $22,$84,24 : .char "IF YOU ARE SERIOUS ABOUT"
.db $22,$C4,26 : .char "PURSUING THIS AS A CAREER,"
.db $23,$04,25 : .char "YOU MUST HONE YOUR SKILLS"
.db $23,$44,8  : .char "FURTHER."
.db 0

@@normal_great_ending_data:
.db $20,$84,24 : .char "YOU HAVE PROVEN YOURSELF"
.db $20,$C4,22 : .char "TO BE A SEMI-PRO D-PAD"
.db $21,$04,8  : .char "WIELDER!"

.db $21,$84,22 : .char "THE MEDIA IS NOTICING,"
.db $21,$C4,25 : .char "AND THERE IS EVEN A RUMOR"
.db $22,$04,25 : .char "ABOUT A CONTRACT SIGNING."

.db $22,$84,25 : .char "WITH SOME REFINEMENT, YOU"
.db $22,$C4,24 : .char "WILL BE ABLE TO JOIN THE"
.db $23,$04,23 : .char "PRESTIGIOUS ELITE GROUP"
.db $23,$44,14 : .char "OF PERFORMERS."
.db 0

@@normal_perfect_ending_data:
.db $20,$84,24 : .char "YOU HAVE PROVEN YOURSELF"
.db $20,$C4,23 : .char "TO BE A PRO AMONG SEMI-"
.db $21,$04,19 : .char "PRO D-PAD WIELDERS!"

.db $21,$84,21 : .char "THANK YOU FOR PLAYING"
.db $21,$C4,21 : .char "WITH SUCH PASSION AND"
.db $22,$04,11 : .char "DEDICATION."

.db $22,$84,23 : .char "WE HEREBY CHALLENGE YOU"
.db $22,$C4,22 : .char "TO PLAY A PERFECT GAME"
.db $23,$04,17 : .char "ON THE ''EXPERT''"
.db $23,$44,8  : .char "SETTING!"
.db 0

@@hard_normal_ending_data:
.db $20,$84,24 : .char "YOU HAVE PROVEN YOURSELF"
.db $20,$C4,22 : .char "TO BE A HIGHLY SKILLED"
.db $21,$04,14 : .char "D-PAD WIELDER."

.db $21,$84,25 : .char "ARTISTS ACROSS THE NATION"
.db $21,$C4,25 : .char "WOULD LIKE TO COLLABORATE"
.db $22,$04,9  : .char "WITH YOU."

.db $22,$84,21 : .char "HOWEVER, FOR ALL YOUR"
.db $22,$C4,22 : .char "ACCOMPLISHMENTS, THERE"
.db $23,$04,17 : .char "IS STILL ROOM FOR"
.db $23,$44,12 : .char "IMPROVEMENT."
.db 0

@@hard_good_ending_data:
.db $20,$84,24 : .char "YOU HAVE PROVEN YOURSELF"
.db $20,$C4,19 : .char "TO BE A WORLD-CLASS"
.db $21,$04,14 : .char "D-PAD WIELDER."

.db $21,$84,24 : .char "YOUR LATEST RELEASE WENT"
.db $21,$C4,19 : .char "MULTI-PLATINUM IN A"
.db $22,$04,16 : .char "MATTER OF HOURS."

.db $22,$84,24 : .char "WHILE YOU PROBABLY WON'T"
.db $22,$C4,25 : .char "BE REMEMBERED TWO HUNDRED"
.db $23,$04,23 : .char "YEARS FROM NOW, YOU PUT"
.db $23,$44,16 : .char "ON A GREAT SHOW."
.db 0

@@hard_great_ending_data:
.db $20,$84,24 : .char "YOU HAVE PROVEN YOURSELF"
.db $20,$C4,22 : .char "TO BE THE D-PAD'S TRUE"
.db $21,$04,24 : .char "MASTER. CONGRATULATIONS!"

.db $21,$84,24 : .char "WITH YOUR TAPPING SKILLS"
.db $21,$C4,24 : .char "YOU HAVE BROUGHT HARMONY"
.db $22,$04,20 : .char "TO THIS HARSH WORLD."

.db $22,$84,23 : .char "BUT HOW LONG WILL IT BE"
.db $22,$C4,19 : .char "BEFORE THE D-PAD IS"
.db $23,$04,21 : .char "CHALLENGED BY ANOTHER"
.db $23,$44,14 : .char "CONTROLLER...?"
.db 0

@@hard_perfect_ending_data:
.db $20,$84,24 : .char "YOU HAVE PROVEN YOURSELF"
.db $20,$C4,24 : .char "TO BE THE HERO ABOVE ALL"
.db $21,$04,23 : .char "D-PAD HEROES. AMAZING!!"

.db $21,$84,21 : .char "THANK YOU FOR PLAYING"
.db $21,$C4,24 : .char "WITH SUCH PASSION, FOCUS"
.db $22,$04,15 : .char "AND DEDICATION."

.db $22,$84,21 : .char "THERE IS NOTHING LEFT"
.db $22,$C4,24 : .char "FOR YOU TO CONQUER HERE."
.db $23,$04,19 : .char "SEE YOU IN THE NEXT"
.db $23,$44,5  : .char "GAME!"
.db 0
.endp

.proc draw_magazine_mugshot
    lda player.difficulty
    asl : asl
    ora ending
    asl : asl : asl : asl
    pha
    ; 0,0
    jsr next_sprite_index : tax
    pla : pha
    ora #1 : sta sprites.tile,x
    lda #127 : sta sprites._y,x
    lda #48 : sta sprites._x,x
    lda #0 : sta sprites.attr,x
    ; 1,0
    jsr next_sprite_index : tax
    pla : pha
    ora #3 : sta sprites.tile,x
    lda #127 : sta sprites._y,x
    lda #56 : sta sprites._x,x
    lda #0 : sta sprites.attr,x
    ; 2,0
    jsr next_sprite_index : tax
    pla : pha
    ora #5 : sta sprites.tile,x
    lda #127 : sta sprites._y,x
    lda #64 : sta sprites._x,x
    lda #0 : sta sprites.attr,x
    ; 3,0
    jsr next_sprite_index : tax
    pla : pha
    ora #7 : sta sprites.tile,x
    lda #127 : sta sprites._y,x
    lda #72 : sta sprites._x,x
    lda #0 : sta sprites.attr,x
    ; 0,1
    jsr next_sprite_index : tax
    pla : pha
    ora #9 : sta sprites.tile,x
    lda #127+16 : sta sprites._y,x
    lda #48 : sta sprites._x,x
    lda #0 : sta sprites.attr,x
    ; 1,1
    jsr next_sprite_index : tax
    pla : pha
    ora #11 : sta sprites.tile,x
    lda #127+16 : sta sprites._y,x
    lda #56 : sta sprites._x,x
    lda #0 : sta sprites.attr,x
    ; 2,1
    jsr next_sprite_index : tax
    pla : pha
    ora #13 : sta sprites.tile,x
    lda #127+16 : sta sprites._y,x
    lda #64 : sta sprites._x,x
    lda #0 : sta sprites.attr,x
    ; 3,1
    jsr next_sprite_index : tax
    pla
    ora #15 : sta sprites.tile,x
    lda #127+16 : sta sprites._y,x
    lda #72 : sta sprites._x,x
    lda #0 : sta sprites.attr,x
    rts
.endp

.proc draw_magazine_heading
    lda player.difficulty
    asl : asl
    ora ending
    asl : tax
    lda @@heading_table+1,x
    tay
    lda @@heading_table+0,x
    jmp write_ppu_data_at

@@heading_table:
.dw @@heading_0
.dw @@heading_1
.dw @@heading_2
.dw @@heading_3
.dw @@heading_4
.dw @@heading_5
.dw @@heading_6
.dw @@heading_7
.dw @@heading_8
.dw @@heading_9
.dw @@heading_10
.dw @@heading_11
.dw @@heading_12
.dw @@heading_13
.dw @@heading_14
.dw @@heading_15
.dw @@heading_16

.charmap "font.tbl"
@@heading_0:
.db $25,$6B,10 : .char "TAPPED_OUT"
.db $25,$8B,10 : .char "IN_THE_END"
.db 0
@@heading_1:
.db $25,$6A,12 : .char "`HE'S_A_REAL"
.db $25,$89,14 : .char "CONTROL_FREAK`"
.db 0
@@heading_2:
.db $25,$6A,11 : .char "PAD_OF_JOY,"
.db $25,$89,14 : .char "LAD_OF_COY-NES"
.db 0
@@heading_3:
.db $25,$6A,11 : .char "YOUNG_BRAVE"
.db $25,$8B,9  : .char "D-PADAWAN"
.db 0
@@heading_4:
.db $25,$6B,10 : .char "D-PRESSING"
.db $25,$8E,4  : .char "SHOW"
.db 0
@@heading_5:
.db $25,$6C,7  : .char "PADS_TO"
.db $25,$8C,8  : .char "THE_NADS"
.db 0
@@heading_6:
.db $25,$6A,12 : .char "AN_ALL_NIGHT"
.db $25,$89,14 : .char "BUTTON_MASH-UP"
.db 0
@@heading_7:
.db $25,$6A,12 : .char "KNOB_FONDLER"
.db $25,$89,14 : .char "EXTRAORDINAIRE"
.db 0
@@heading_8:
.db $25,$6D,6  : .char "PAD_TO"
.db $25,$8C,7  : .char "DA_BONE"
.db 0
@@heading_9:
.db $25,$69,13 : .char "THE_GOOD,_THE"
.db $25,$89,14 : .char "PAD_&_THE_UGLY"
.db 0
@@heading_10:
.db $25,$6C,8  : .char "PADISTIC"
.db $25,$8A,12 : .char "PERFORMANCE!"
.db 0
@@heading_11:
.db $25,$6B,9  : .char "PADOPHILE"
.db $25,$89,13 : .char "ON_THE_LOOSE!"
.db 0
@@heading_12:
.db $25,$6E,4  : .char "CAME"
.db $25,$8B,10 : .char "UNBUTTONED"
.db 0
@@heading_13:
.db $25,$69,14 : .char "A_CURIOUS_CASE"
.db $25,$8B,10 : .char "OF_BUTTONS"
.db 0
@@heading_14:
.db $25,$6D,6  : .char "OUT_OF"
.db $25,$8A,11 : .char "CONTROLLERS"
.db 0
@@heading_15:
.db $25,$6C,7  : .char "BUTTONS"
.db $25,$8B,9  : .char "UNPLUGGED"
.db 0
@@heading_16:
.db $25,$6A,13 : .char "PAD_OF_GLORY,"
.db $25,$8A,12 : .char "END_OF_STORY"
.db 0
.endp

.proc draw_ending_specific_gfx
    ldcay @@magazine_template_data : jsr write_ppu_data_at
    jmp draw_magazine_heading

@@magazine_template_data:
.incbin "graphics/magazine-bg.dat"
; title
.db $24,$88,$10,$40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4A,$4B,$4C,$4D,$4E,$4F
.db $24,$A8,$10,$50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5A,$5B,$5C,$5D,$5E,$5F
.db $24,$C8,$10,$60,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6A,$6B,$6C,$6D,$6E,$6F
.db $24,$E8,$10,$70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$7B,$7C,$7D,$7E,$7F
; guitar
.db $26,$10,$08,$80,$81,$82,$83,$84,$85,$86,$87
.db $26,$30,$08,$88,$89,$8A,$8B,$8C,$8D,$8E,$8F
.db $26,$50,$08,$90,$91,$92,$93,$94,$95,$96,$97
.db $26,$70,$08,$98,$99,$9A,$9B,$9C,$9D,$9E,$9F
.db $26,$90,$08,$A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7
.db $26,$B0,$08,$A8,$A9,$AA,$AB,$AC,$AD,$AE,$AF
.db $26,$D0,$08,$B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7
.db $26,$F0,$08,$B8,$B9,$BA,$BB,$BC,$BD,$BE,$BF
; attributes
.db $27,$CA,$44,$55 ; title
.db $27,$E4,$42,$AA ; guitar
.db $27,$EC,$42,$AA ; guitar
.db 0
.endp

.proc draw_kentando
    lda #0
  - pha
    asl : ora #8
    pha
    lda #$21 : adc #0
    tay
    pla
    ldx #$10
    jsr begin_ppu_string
    pla : pha
    clc : adc #$20
    ldy #$10
 -- jsr put_ppu_string_byte
    adc #1
    dey
    bne --
    jsr end_ppu_string
    jsr flush_ppu_buffer
    pla
    clc : adc #$10
    cmp #$A0
    bne -
    rts
.endp

.end
