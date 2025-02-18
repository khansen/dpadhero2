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

.ifndef MIXER_H
.define MIXER_H

.include "tonal.h"
.include "envelope.h"
.include "sfx.h"
.include "apu.h"

.struc mixer_state
tonals      .tonal_state[4]
envelopes   .envelope_state[4]
sfx         .sfx_state[4]
master_vol  .byte
.ends

; Exported symbols.
.extrn mixer_tick:proc
.extrn mixer_rese:proct
.ifndef NO_MUTABLE_CHANNELS
.extrn mixer_get_muted_channels:proc
.extrn mixer_set_muted_channels:proc
.endif
.extrn mixer_get_master_vol:proc
.extrn mixer_set_master_vol:proc

.extrn mixer:mixer_state

.endif  ; !MIXER_H
