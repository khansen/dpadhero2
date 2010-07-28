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

.ifndef SOUND_H
.define SOUND_H

; Exported symbols.
.extrn start_song:proc
.extrn maybe_start_song:proc
.extrn update_sound:proc
.extrn pause_music:proc
.extrn unpause_music:proc
.extrn is_music_paused:proc
.extrn start_audio_fade_out:proc
.extrn current_song:byte

.endif
