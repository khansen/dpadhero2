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

.codeseg

.public song_table

.extrn MUTE_song:label
.extrn titletheme_song:label
.extrn ocean_song:label
.extrn count_song:label
.extrn ripepray_song:label
.extrn break_song:label
.extrn misery_song:label
;.extrn gameovertheme_song:label
.extrn levva_song:label
.extrn burn_song:label
.extrn piecewintheme_song:label
.extrn starstheme_song:label
.extrn creditwintheme_song:label
.extrn versuswintheme_song:label
.extrn spacetheme_song:label
.extrn endtheme_song:label
.extrn elevatortheme_song:label
.extrn smooth_song:label

song_table:
.dw MUTE_song
.dw titletheme_song
.dw ocean_song
.dw count_song
.dw ripepray_song
.dw break_song
.dw misery_song
.dw MUTE_song ; gameovertheme_song
.dw levva_song
.dw burn_song
.dw piecewintheme_song
.dw starstheme_song
.dw creditwintheme_song
.dw versuswintheme_song
.dw spacetheme_song
.dw endtheme_song
.dw elevatortheme_song
.dw smooth_song

.end
