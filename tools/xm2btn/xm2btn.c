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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "xm.h"
#include "xm2btn.h"

enum MarkState {
    NoMark,
    BeginMark,
    Marking,
    EndMark
};

/* Converts the given slot to target types. */
static void slot_to_targets(const struct xm_pattern_slot *slot, int *target_types)
{
    int lane_count = 0;
    int lane_indexes[2]; /* Max 2 targets */
    int i;
    for (i = 0; i < 5; ++i)
        target_types[i] = -1;
    if (!slot->note)
        return;
    /* Note determines which lanes are used */
    switch ((slot->note - 1) % 12) {
        case 0: /* C = left */
            lane_indexes[lane_count++] = 0;
            break;
        case 1: /* C# = left + B */
            lane_indexes[lane_count++] = 0;
            lane_indexes[lane_count++] = 3;
            break;
        case 2: /* D = right */
            lane_indexes[lane_count++] = 1;
            break;
        case 3: /* D# = left + A */
            lane_indexes[lane_count++] = 0;
            lane_indexes[lane_count++] = 4;
            break;
        case 4: /* E = select */
            lane_indexes[lane_count++] = 2;
            break;
        case 5: /* F = B */
            lane_indexes[lane_count++] = 3;
            break;
        case 6: /* F# = right + B */
            lane_indexes[lane_count++] = 1;
            lane_indexes[lane_count++] = 3;
            break;
        case 7: /* G = A */
            lane_indexes[lane_count++] = 4;
            break;
        case 8: /* G# = right + A */
            lane_indexes[lane_count++] = 1;
            lane_indexes[lane_count++] = 4;
            break;
        case 9: /* A, A#, B = B + A */
        case 10:
        case 11:
            lane_indexes[lane_count++] = 3;
            lane_indexes[lane_count++] = 4;
            break;
    }
    /* Effect parameter determines target type */
    assert(lane_count <= 2);
    for (i = 0; i < lane_count; ++i) {
        int type = (i == 0) ? (slot->effect_param >> 4) : (slot->effect_param & 0xF);
        target_types[lane_indexes[i]] = type;
    }
}

static int first_target_lane(int lanes_specifier)
{
    switch (lanes_specifier) {
        case 1: return 0;
        case 2: return 1;
        case 3: return 2;
        case 4: return 3;
        case 5: return 4;
        case 6: return 0;
        case 7: return 0;
        case 8: return 1;
        case 9: return 1;
        case 10: return 3;
    }
    return -1;
}

static int second_target_lane(int lanes_specifier)
{
    switch (lanes_specifier) {
        case 6: return 3;
        case 7: return 4;
        case 8: return 3;
        case 9: return 4;
        case 10: return 4;
    }
    return -1;
}

static int targets_to_lanes_specifier(const int *target_types)
{
    int mask = 0;
    int i;
    for (i = 0; i < 5; ++i) {
        if (target_types[i] != -1)
            mask |= 1 << i;
    }
    switch (mask) {
        case 0x00:
            return 0;
        case 0x01:
            return 1;
        case 0x02:
            return 2;
        case 0x04:
            return 3;
        case 0x08:
            return 4;
        case 0x10:
            return 5;
        case 0x09:
            return 6;
        case 0x11:
            return 7;
        case 0x0A:
            return 8;
        case 0x12:
            return 9;
        case 0x18:
            return 10;
        default:
            assert(0);
    }
    return 0;
}

struct output_stream {
    FILE *fp;
    int bit_index;
    unsigned char bits;
    int column;
};

static void output_stream_init(struct output_stream *stream, FILE *fp)
{
    stream->fp = fp;
    stream->bit_index = 0;
    stream->bits = 0;
    stream->column = 0;
}

static void output_stream_put_helper(struct output_stream *stream)
{
    if (stream->column == 16) {
        if (stream->fp)
            fprintf(stream->fp, "\n");
        stream->column = 0;
    }
    if (stream->fp)
        fprintf(stream->fp, "%s$%.2X", (stream->column == 0) ? ".db " : ",", stream->bits);
    ++stream->column;
    stream->bits = 0;
}

static void output_stream_put_bits(struct output_stream *stream, int n, int v)
{
    int i;
    /*    fprintf(stdout, "output %d %X\n", n, v); */
    for (i = n-1; i >= 0; --i) {
        if (!(stream->bit_index & 7) && stream->bit_index)
            output_stream_put_helper(stream);
        stream->bits |= ((v & (1 << i)) >> i) << (7 - (stream->bit_index & 7));
        ++stream->bit_index;
    }
}

static void output_stream_flush(struct output_stream *stream)
{
    if (!stream->bit_index)
        return;
    output_stream_put_helper(stream);
}

static void output_delay(struct output_stream *stream, int delay, int *pospos)
{
    int buf[256];
    int pos = 0;
    assert(delay);
    while (delay) {
        static int factors[8] = { 1, 2, 4, 8, 12, 16, 24, 32 };
        int i;
        for (i = 7; i >= 0; --i) {
            int rem = delay % factors[i];
            if (!rem) {
                assert(pos < 256);
                buf[pos++] = i;
                delay -= factors[i];
                break;
            }
        }
    }

    {
        int i;
        for (i = pos-1; i > 0; --i) {
            output_stream_put_bits(stream, 3, buf[i]);
            /* Insert empty row (effectively extending the delay) */
            output_stream_put_bits(stream, 4, 0);
            ++(*pospos);
        }
        output_stream_put_bits(stream, 3, buf[0]);
    }
}

static void log_target(int difficulty, int order_pos, int row, int lane, int type,
                       int *target_counts)
{
    ++target_counts[difficulty*5*8 + lane*8 + type];
}

struct marker_info {
    int data_offset;
    int order_pos;
    int pattern_row;
};

static void init_marker(struct marker_info *m, int data_offset, int order_pos, int pattern_row)
{
    m->data_offset = data_offset;
    m->order_pos = order_pos;
    m->pattern_row = pattern_row;
}

/**
  Converts the given \a xm to D-Pad hero button data; writes the 6502
  assembly language representation of the song to \a out.
*/
void convert_xm_to_btn(const struct xm *xm, const struct xm2btn_options *options, FILE *out)
{
    int difficulty;
    static const int channel_base = 5; /* Our data begins in channel 5 */
    static const char *difficulty_strings[3] = { "easy", "normal", "hard" };
    for (difficulty = 0; difficulty < 3; ++difficulty) {
        int pass;
        int pos;
        int marker_count = 0;
        struct marker_info markers[64];
        enum MarkState mark_state = NoMark;
        int marker_pos;
        /* The 1st pass counts the number of items */
        /* The 2nd pass outputs the data */
        for (pass = 0; pass < 2; ++pass) {
            int order_pos;
            int aux_delay = 0;
            struct output_stream stream;
            output_stream_init(&stream, (pass == 1) ? out : 0);
            /* 1st marker is always beginning of song */
            init_marker(&markers[marker_count++], 0, 0, 0);
            if (pass == 1) {
                /* Output the header */
                int items_per_chunk;
                static const int chunk_count = 40; /* Total number of progress chunks (UI-dependent) */
                int length = pos;
                items_per_chunk = length / chunk_count;
                assert(items_per_chunk < 256);
                fprintf(out, "%s%s:\n", options->label_prefix, difficulty_strings[difficulty]);
                fprintf(out, ".db $%.2X,$%.2X\n", xm->header.default_tempo + 1, items_per_chunk);
                fprintf(out, ".dw %s%s_data\n", options->label_prefix, difficulty_strings[difficulty]);
                /* Markers */
                {
                    int i;
                    for (i = 0; i < marker_count; ++i) {
                        const struct marker_info *m = &markers[i];
                        fprintf(out, ".dw $%.4X : .db $%.2X,$%.2X\n",
                                m->data_offset, m->order_pos, m->pattern_row);
                    }
                }

                fprintf(out, "%s%s_data:\n", options->label_prefix, difficulty_strings[difficulty]);
            }
            pos = 0;
            for (order_pos = 0; order_pos < xm->header.song_length; ++order_pos) {
                int row;
                int first = 1;
                int delay = 0;
                const struct xm_pattern *pattern = &xm->patterns[xm->header.pattern_order_table[order_pos]];
                for (row = 0; row < pattern->row_count; ++row) {
                    int target_types[5];
                    int lanes;
                    const struct xm_pattern_slot *row_data = &pattern->data[row * xm->header.channel_count];
                    const struct xm_pattern_slot *slot = row_data + channel_base + difficulty;
                    if (slot->effect_type == 7) {
                        /* Marker begin/end */
                        if (mark_state == NoMark) {
                            mark_state = BeginMark;
                        } else {
                            if (mark_state != Marking) {
                                fprintf(stderr, "bad marker at order %.2X, row %.2X, difficulty %d\n",
                                    order_pos, row, difficulty);
                            }
                            assert(mark_state == Marking);
                            mark_state = EndMark;
                        }
                    }
                    slot_to_targets(slot, target_types);
                    lanes = targets_to_lanes_specifier(target_types);
                    if (lanes) {
                        if (aux_delay != 0) {
                            /* "Flush" delay from previous pattern */
                            output_delay(&stream, aux_delay, &pos);
                            aux_delay = 0;
                        }
                        if (delay != 0) {
                            if (first) {
                                if (mark_state == BeginMark) {
                                    marker_pos = pos;
                                    if (pass == 0)
                                        init_marker(&markers[marker_count++], stream.bit_index, order_pos, /*row=*/0);
                                    mark_state = Marking;
                                } else if (mark_state == EndMark) {
                                    output_stream_put_bits(&stream, 4, 0xE); /* end-marker */
                                    mark_state = NoMark;
                                }
                                output_stream_put_bits(&stream, 4, 0); /* empty row */
                                ++pos;
                            }
                            output_delay(&stream, delay, &pos);
                        }
                        if (mark_state == BeginMark) {
                            marker_pos = pos;
                            if (pass == 0)
                                init_marker(&markers[marker_count++], stream.bit_index, order_pos, row);
                            mark_state = Marking;
                        } else if (mark_state == EndMark) {
                            output_stream_put_bits(&stream, 4, 0xE); /* end-marker */
                            mark_state = NoMark;
                        }
                        output_stream_put_bits(&stream, 4, lanes);
                        {
                            int l1 = first_target_lane(lanes);
                            assert(l1 != -1);
                            int t1 = target_types[l1];
                            output_stream_put_bits(&stream, 1, t1 ? 1 : 0); /* extended or normal */
                            if (t1)
                                output_stream_put_bits(&stream, 3, t1 - 1);
                            if (pass && options->log) {
                                log_target(difficulty, order_pos, row, l1, t1,
                                           options->target_counts);
                            }
                        }
                        if (lanes > 5) {
                            int l2 = second_target_lane(lanes);
                            assert(l2 != -1);
                            int t2 = target_types[l2];
                            output_stream_put_bits(&stream, 1, t2 ? 1 : 0); /* extended or normal */
                            if (t2)
                                output_stream_put_bits(&stream, 3, t2 - 1);
                            if (pass && options->log) {
                                log_target(difficulty, order_pos, row, l2, t2,
                                           options->target_counts);
                            }
                        }
                        ++pos;
                        delay = 1;
                        first = 0;
                    } else {
                        ++delay;
                    }
                }
                aux_delay = delay;
            }
            /* Terminate data: delay=0, end-of-data-marker=0x0F */
            output_stream_put_bits(&stream, 3, 0);
            output_stream_put_bits(&stream, 4, 0x0F);
            output_stream_flush(&stream);
            if (pass == 1)
                fprintf(out, "\n");
        }
    }
}
