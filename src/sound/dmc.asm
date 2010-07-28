;
;    Copyright (C) 2004, 2005 Kent Hansen.
;
;    This file is part of Neotoxin.
;
;    Neotoxin is free software; you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation; either version 2 of the License, or
;    (at your option) any later version.
;
;    Neotoxin is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program; if not, write to the Free Software
;    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;

; Description:
; DMC audio stuff.

.codeseg

; exported API
.public play_dmc_sample
.public process_dmc_pattern_byte

.extrn fetch_pattern_byte:proc
.extrn set_all_tracks_speed:proc
.extrn dmc_sample_table:byte

.ifndef NO_MUTABLE_CHANNELS
.extrn mixer_get_muted_channels:proc
.endif

.proc process_dmc_pattern_byte
    ora     #0
    bmi     @@is_command
; FIXME: actual DMC playback should be commenced by the mixer...
.ifndef NO_MUTABLE_CHANNELS
    tay
    jsr     mixer_get_muted_channels
    and     #$10
    bne     +
    tya
    jsr     play_dmc_sample
  +
.endif
    clc
    rts
    @@is_command:
    ; only supported commands are "set speed" and "end row"
    cmp     #$F3
    beq     @@set_speed
    cmp     #$F4
    beq     @@end_row
    ; uh-oh, don't know how to handle this command
    clc
    rts
    @@set_speed:
    jsr     fetch_pattern_byte
    jsr     set_all_tracks_speed
    sec
    rts
    @@end_row:
    clc
    rts
.endp

; Plays a DMC sample.
; Params:   A = sample #
.proc play_dmc_sample
    asl
    asl
    tay
    lda     dmc_sample_table+0,y
    sta     $4010                   ; write sample frequency
    lda     dmc_sample_table+1,y
    sta     $4011                   ; write initial delta value
    lda     dmc_sample_table+2,y
    sta     $4012                   ; write sample address
    lda     dmc_sample_table+3,y
    sta     $4013                   ; write sample length
    lda     #$0F
    sta     $4015                   ; turn bit 4 off...
    lda     #$1F
    sta     $4015                   ; ... then on again
    rts
.endp

.end
