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

.ifndef SEQUENCER_H
.define SEQUENCER_H

; Exported symbols.
.extrn sequencer_tick:proc
.extrn sequencer_load:proc
.extrn fetch_pattern_byte:proc
.extrn set_track_speed:proc
.extrn set_all_tracks_speed:proc
.ifdef PATTERN_ROW_CALLBACK_SUPPORT
.extrn set_pattern_row_callback:proc
.endif
.ifdef ORDER_SEEKING_SUPPORT
.extrn sequencer_seek_order_relative:proc
.endif

.endif
