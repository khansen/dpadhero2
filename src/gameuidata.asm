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

.public game_ui_data
.public pad3d_data

game_ui_data:
.incbin "graphics/vu.dat"
.incbin "graphics/logosmall.dat"
.incbin "graphics/lanes.dat"
.incbin "graphics/leftpipe.dat"
.incbin "graphics/rightpipe.dat"
; EQ - shares some tiles with VU
.db $20,$C1,$08,$90,$A1,$A1,$91,$92,$A1,$A1,$93
.db $20,$E1,$08,$A5,$00,$00,$00,$00,$00,$00,$AB
.db $21,$01,$08,$A5,$98,$00,$00,$00,$00,$98,$AB
.db $21,$21,$08,$B0,$98,$00,$00,$00,$00,$98,$B1
.db $21,$41,$08,$A5,$98,$00,$00,$00,$00,$98,$AB
.db $21,$61,$08,$A5,$98,$00,$00,$00,$00,$98,$AB
.db $21,$81,$08,$A5,$97,$97,$97,$97,$97,$97,$AB
.db $21,$A1,$08,$94,$95,$95,$95,$95,$95,$95,$96
; attribute table
.db $23,$C0,$03,$00,$00,$AA ; : .db $23,$C3,$45,$AA
.db $23,$C8,$43,$F0 : .db $23,$CB,$42,$50 : .db $23,$CD,$43,$F0
.db $23,$D0,$01,$33 : .db $23,$D2,$04,$BB,$AA,$AA,$EF : .db $23,$D6,$42,$FF
.db $23,$D8,$03,$FF,$FF,$AB : .db $23,$DB,$42,$AA : .db $23,$DD,$03,$AE,$FF,$FF
.db 0

pad3d_data:
.incbin "graphics/board3d.dat"
.db $23,$E0,$60,$FF ; attributes
.db 0

.end
