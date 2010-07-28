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

.extrn noop_cycle:proc
.extrn title_init:proc
.extrn title_main:proc
.extrn songselect_init:proc
.extrn songselect_main:proc
.extrn game_init:proc
.extrn game_main:proc
.extrn game_paused_main:proc
;.extrn buttonconfig_init:proc
;.extrn buttonconfig_main:proc
.extrn gameover_init:proc
.extrn gameover_main:proc
.extrn gamestats_init:proc
.extrn gamestats_main:proc
.extrn piecewin_init:proc
.extrn piecewin_main:proc
.extrn cutscene_init:proc
.extrn cutscene_main:proc
.extrn challenges_init:proc
.extrn challenges_main:proc
.extrn challengestats_init:proc
.extrn challengestats_main:proc
.extrn gameselect_init:proc
.extrn gameselect_main:proc
.extrn gameinfo_init:proc
.extrn gameinfo_main:proc
.extrn versuswin_init:proc
.extrn versuswin_main:proc
.extrn creditwin_init:proc
.extrn creditwin_main:proc
.extrn theend_init:proc
.extrn theend_main:proc

TC_SLOT noop_cycle
TC_SLOT title_init
TC_SLOT title_main
TC_SLOT noop_cycle ; difficultyselect_init
TC_SLOT noop_cycle ; difficultyselect_main
TC_SLOT songselect_init
TC_SLOT songselect_main
TC_SLOT game_init
TC_SLOT game_main
TC_SLOT game_paused_main
TC_SLOT noop_cycle ; buttonconfig_init
TC_SLOT noop_cycle ; buttonconfig_main
TC_SLOT gameover_init
TC_SLOT gameover_main
TC_SLOT gamestats_init
TC_SLOT gamestats_main
TC_SLOT piecewin_init
TC_SLOT piecewin_main
TC_SLOT cutscene_init
TC_SLOT cutscene_main
TC_SLOT challenges_init
TC_SLOT challenges_main
TC_SLOT challengestats_init
TC_SLOT challengestats_main
TC_SLOT gameselect_init
TC_SLOT gameselect_main
TC_SLOT gameinfo_init
TC_SLOT gameinfo_main
TC_SLOT versuswin_init
TC_SLOT versuswin_main
TC_SLOT creditwin_init
TC_SLOT creditwin_main
TC_SLOT theend_init
TC_SLOT theend_main
