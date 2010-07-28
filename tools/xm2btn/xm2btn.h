/*
    This file is part of xm2btn.

    xm2btn is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    xm2btn is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with xm2btn.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef XM2BTN_H
#define XM2BTN_H

struct xm2btn_options {
    const char *label_prefix;
    int log;
    int *target_counts;
};

void convert_xm_to_btn(const struct xm *, const struct xm2btn_options *, FILE *);

#endif
