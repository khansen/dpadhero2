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

.codeseg

.extrn set_default_button_mapping:proc
.extrn go_to_title_screen:proc

.public init
.public noop_cycle

; Program entrypoint.
.proc init
    jsr set_defaults
    jmp go_to_title_screen
.endp

.proc set_defaults
    ldx #4
    jsr set_default_button_mapping
;    jsr set_emu_button_mapping
;    jsr set_guitar_button_mapping
    ldx #9
    jsr set_default_button_mapping
;    jsr set_emu_button_mapping
;    jsr set_guitar_button_mapping
    rts
.endp

.proc noop_cycle
    rts
.endp

.end
