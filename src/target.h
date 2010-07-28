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

.ifndef TARGET_H
.define TARGET_H

.include "common/fixedpoint.h"

MAX_TARGETS .equ 32

; Holds the state of a falling target.
; Types:
; 0 - normal orb
; 1 - skull
; 2 - POW
; 3 - star
; 4 - clock
; 5 - letter (special orb)
; 6 - fake skull
; 7 - ???
.struc target_1
state .db    ; b2..0:lane, b5..b3:type, b7:exploding
pos_y .fp_8_8
pos_x .fp_8_8
pad0 .db
.ends

.struc target_2
speed_y .fp_8_8
speed_x .fp_8_8
duration .db ; number of rows it lasts
next .db     ; next target on linked list
.ends

.if sizeof target_1 != sizeof target_2
.error "target_1 and target_2 must have the same size"
.endif

.extrn free_targets_list:byte
.extrn active_targets_head:byte
.extrn active_targets_tail:byte
.extrn targets_1:target_1
.extrn targets_2:target_2

.extrn initialize_target_lists:proc
.extrn move_target:proc
.extrn add_to_active_targets_list:proc

.endif
