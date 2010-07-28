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

.public elevatortheme_song

elevatortheme_instrument_table:
.dw env2 : .db $00,$00,$00,$22 : .db $00,$00 ; square
.dw env0 : .db $00,$00,$00,$00 : .db $00,$00 ; triangle
.dw env1 : .db $00,$00,$00,$00 : .db $00,$00 ; noise

env0:
.db $05
.db $00,$00,$FF,$05
.db $05,$00,$00,$00
.db $FF,$FF
env2:
.db $09
.db $01,$60,$00,$01
.db $01,$60,$00,$09
.db $FF,$00
env1:
.db $09
.db $00,$70,$00,$00
.db $FF,$FF

.include "elevatortheme.inc"

.end
