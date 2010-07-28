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

.ifndef FADE_H
.define FADE_H

; Exported symbols.
.extrn set_fade_range:proc
.extrn set_fade_delay:proc
.extrn start_fade_from_black:proc
.extrn start_fade_from_white:proc
.extrn start_fade_to_black:proc
.extrn start_fade_to_white:proc
.extrn fade_out_step:proc
.extrn fade_in_step:proc
.extrn palette_to_temp_palette:proc
.extrn palette_fade_in_progress:proc

.endif
