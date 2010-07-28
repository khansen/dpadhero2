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

.public target_data_table

.extrn breaktargets_easy:label
.extrn breaktargets_normal:label
.extrn breaktargets_hard:label

.extrn oceantargets_easy:label
.extrn oceantargets_normal:label
.extrn oceantargets_hard:label

.extrn counttargets_easy:label
.extrn counttargets_normal:label
.extrn counttargets_hard:label

.extrn ripetargets_easy:label
.extrn ripetargets_normal:label
.extrn ripetargets_hard:label

.extrn levvatargets_easy:label
.extrn levvatargets_normal:label
.extrn levvatargets_hard:label

.extrn burntargets_easy:label
.extrn burntargets_normal:label
.extrn burntargets_hard:label

target_data_table:
; Bank, song, song start delay, data pointers
.db 0, 2, 31, 20, 15, 12, 10, 8, 7, 6 : .dw oceantargets_easy, oceantargets_normal, oceantargets_hard
.db 5, 9, 25, 17, 13, 10, 8, 7, 6, 5 : .dw burntargets_easy, burntargets_normal, burntargets_hard
.db 2, 4, 22, 15, 11, 9, 7, 6, 5, 4 : .dw ripetargets_easy, ripetargets_normal, ripetargets_hard
.db 3, 5, 22, 15, 11, 9, 7, 6, 5, 4 : .dw breaktargets_easy, breaktargets_normal, breaktargets_hard
.db 1, 3, 25, 17, 13, 10, 8, 7, 6, 5 : .dw counttargets_easy, counttargets_normal, counttargets_hard
.db 4, 8, 25, 17, 13, 10, 8, 7, 6, 5 : .dw levvatargets_easy, levvatargets_normal, levvatargets_hard

.end
