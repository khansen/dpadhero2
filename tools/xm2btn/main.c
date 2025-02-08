/*
    This file is part of xm2nes.

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

static char program_version[] = "xm2btn 1.0";

/* Prints usage message and exits. */
static void usage()
{
    printf(
        "Usage: xm2btn [--output=FILE]\n"
        "              [--verbose]\n"
        "              [--help] [--usage] [--version]\n"
        "              FILE\n");
    exit(0);
}

/* Prints help message and exits. */
static void help()
{
    printf("Usage: xm2btn [OPTION...] FILE\n"
           "xm2btn converts Fasttracker ][ eXtended Module (XM) files to D-pad Hero button data.\n\n"
           "Options:\n\n"
           "  --output=FILE                   Store output in FILE\n"
           "  --verbose                       Print progress information to standard output\n"  
           "  --help                          Give this help list\n"
           "  --usage                         Give a short usage message\n"
           "  --version                       Print program version\n");
    exit(0);
}

/* Prints version and exits. */
static void version()
{
    printf("%s\n", program_version);
    exit(0);
}

static void dump_statistics(const char *input_filename, int *target_counts, FILE *out)
{
    int difficulty;
    static const char *difficulty_strings[3] = { "EASY", "NORMAL", "HARD" };
    static const char *lane_strings[5] = { "L", "R", "S", "B", "A" };
    static const char *target_strings[8] = { "Orb ", "Skull", "POW ", "Star", "Clock", "Letter", "F-skull", "(nothing)" };
    fprintf(out, "***** Statistics for %s *****\n", input_filename);
    for (difficulty = 0; difficulty < 3; ++difficulty) {
        fprintf(out, "  %s\n", difficulty_strings[difficulty]);
        {
            int lane;
            fprintf(out, "\t");
            for (lane = 0; lane < 5; ++lane) {
                fprintf(out, "\t%s", lane_strings[lane]);
            }
            fprintf(out, "\tTotal\n");
        }
        {
            int target_type;
            for (target_type = 0; target_type < 7; ++target_type) {
                int lane;
                int total = 0;
                fprintf(out, "    %s", target_strings[target_type]);
                for (lane = 0; lane < 5; ++lane) {
                    int tc = target_counts[difficulty*5*8 + lane*8 + target_type];
                    total += tc;
                    fprintf(out, "\t%d", tc);
                }
                fprintf(out, "\t%d\n", total);
            }
        }
    }
}

/**
  Program entrypoint.
*/
int main(int argc, char *argv[])
{
    int verbose = 0;
    const char *input_filename = 0;
    const char *output_filename = 0;
    int target_counts[3*5*8*2]; /* difficulties x lanes x types */
    struct xm2btn_options options;
    options.label_prefix = 0;
    options.log = 0;
    options.target_counts = 0;
    /* Process arguments. */
    {
        char *p;
        while ((p = *(++argv))) {
            if (!strncmp("--", p, 2)) {
                const char *opt = &p[2];
                if (!strncmp("output=", opt, 7)) {
                    output_filename = &opt[7];
                } else if (!strncmp("dump-statistics", opt, 15)) {
                    options.log = 1;
                    memset(target_counts, 0, sizeof(target_counts));
                    options.target_counts = target_counts;
                } else if (!strcmp("verbose", opt)) {
                    verbose = 1;
                } else if (!strcmp("help", opt)) {
                    help();
                } else if (!strcmp("usage", opt)) {
                    usage();
                } else if (!strcmp("version", opt)) {
                    version();
                } else {
                    fprintf(stderr, "xm2btn: unrecognized option `%s'\n"
			    "Try `xm2btn --help' or `xm2btn --usage' for more information.\n", p);
                    return(-1);
                }
            } else {
                input_filename = p;
            }
        }
    }

    if (!input_filename) {
        fprintf(stderr, "xm2btn: no filename given\n"
                        "Try `xm2btn --help' or `xm2btn --usage' for more information.\n");
        return(-1);
    }

    {
        struct xm xm;
        FILE *out;
        if (!output_filename)
            out = stdout;
        else {
            out = fopen(output_filename, "wt");
            if (!out) {
                fprintf(stderr, "xm2btn: failed to open `%s' for writing\n", output_filename);
                return(-1);
            }
        }

        {
            FILE *in;
            in = fopen(input_filename, "rb");
            if (!in) {
                fprintf(stderr, "xm2btn: failed to open `%s' for reading\n", input_filename);
                return(-1);
            }
            if (verbose)
                fprintf(stdout, "Reading `%s'...\n", input_filename);
            xm_read(in, &xm);
            if (verbose)
                fprintf(stdout, "OK.\n");
        }

        if (verbose)
            xm_print_header(&xm.header, stdout);

        if (verbose)
            fprintf(stdout, "Converting...\n");

        {
            const char *begin;
            char *prefix;
            int len;
            /* Use basename of input filename as prefix */
            char *last_dot;
            begin = strrchr(input_filename, '/');
            if (begin)
                ++begin;
            else
                begin = input_filename;
            last_dot = strrchr(begin, '.');
            if (!last_dot)
                len = strlen(begin);
            else
                len = last_dot - begin;
            prefix = (char *)malloc(len + 2);
            prefix[len] = '_';
            prefix[len+1] = '\0';
            strncpy(prefix, begin, len);

            options.label_prefix = prefix;
            fprintf(out, "; Generated from %s by %s\n", input_filename, program_version);
            convert_xm_to_btn(&xm, &options, out);

            free(prefix);
        }

        if (options.log)
            dump_statistics(input_filename, target_counts, stdout);

        if (verbose)
            fprintf(stdout, "Done.\n");

        xm_destroy(&xm);
    }
    return 0;
}
