#!/usr/bin/env python

# ENCODE DCC tag-align splitter py wrapper
# Author: Jin Lee (leepc12@gmail.com)

import sys
import os
import argparse
from encode_lib_common import (
    assert_file_not_empty, get_num_lines, log, ls_l, mkdir_p, rm_f,
    run_shell_cmd, strip_ext_ta)


def parse_arguments():
    parser = argparse.ArgumentParser(
        prog='ENCODE DCC TAG-ALIGN splitter.')
    parser.add_argument('ta', type=str,
                        help='Path for TAGALIGN file.')
    parser.add_argument('--split-read-len', required=True,
                        help='Read length to split TA.')
    parser.add_argument('--out-dir', default='', type=str,
                        help='Output directory.')
    parser.add_argument('--log-level', default='INFO',
                        choices=['NOTSET', 'DEBUG', 'INFO',
                                 'WARNING', 'CRITICAL', 'ERROR',
                                 'CRITICAL'],
                        help='Log level')
    args = parser.parse_args()

    log.setLevel(args.log_level)
    log.info(sys.argv)
    return args


def split_ta(ta, split_read_len, out_dir):
    """Split TAG-ALIGN according to given "split_read_len"
        |x| > a : x > a OR x < -a
        |x| <= a: x <= a AND x >= -a
    """
    prefix = os.path.join(out_dir,
                          os.path.basename(strip_ext_ta(ta)))
    ta_high = '{}.high.tagAlign.gz'.format(prefix)
    ta_low = '{}.low.tagAlign.gz'.format(prefix)

    cmd1 = 'zcat -f {ta} | '
    cmd1 += 'awk \'{{if ($3-$2>{read_len} || $3-$2<-{read_len}) print $0}}\' | '
    cmd1 += 'gzip -nc > {out}'
    cmd1 = cmd1.format(
        ta=ta,
        read_len=split_read_len,
        out=ta_high)
    run_shell_cmd(cmd1)

    cmd2 = 'zcat -f {ta} | '
    cmd2 += 'awk \'{{if ($3-$2<={read_len} && $3-$2>=-{read_len}) print $0}}\' | '
    cmd2 += 'gzip -nc > {out}'
    cmd2 = cmd2.format(
        ta=ta,
        read_len=split_read_len,
        out=ta_low)
    run_shell_cmd(cmd2)

    return ta_high, ta_low


def main():
    # read params
    args = parse_arguments()
    log.info('Initializing and making output directory...')
    mkdir_p(args.out_dir)

    log.info('Splitting TAG-ALIGN...')
    ta_high, ta_low = split_ta(args.ta, args.split_read_len, args.out_dir)

    log.info('List all files in output directory...')
    ls_l(args.out_dir)

    log.info('Checking if output is empty...')
    assert_file_not_empty(ta_high)
    assert_file_not_empty(ta_low)

    log.info('All done.')


if __name__ == '__main__':
    main()
