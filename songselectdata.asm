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

.public songselect_bg_data

songselect_bg_data:
.incbin "graphics/songselect-bg.dat"
; attribute table
.db $23,$C9,$01,$55 : .db $23,$CB,$02,$44,$11 : .db $23,$CE,$01,$55
.db $23,$D9,$01,$55 : .db $23,$DB,$02,$44,$11 : .db $23,$DE,$01,$55
.db $23,$E9,$46,$FF : .db $23,$F1,$46,$0F
.db 0

.end
