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

.ifndef PPUBUFFER_H
.define PPUBUFFER_H

; Exported symbols.
.extrn reset_ppu_buffer:proc
.extrn flush_ppu_buffer:proc
.extrn end_ppu_string:proc
.extrn begin_ppu_string:proc
.extrn put_ppu_string_byte:proc

.extrn ppu_buffer:byte
.extrn ppu_buffer_offset:byte

.endif
