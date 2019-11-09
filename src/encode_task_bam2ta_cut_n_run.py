#!/usr/bin/env python

# ENCODE DCC BAM 2 TAGALIGN wrapper (for cut-n-run)
# Author: Jin Lee (leepc12@gmail.com)

import sys
import os
import argparse
from encode_lib_common import (
    assert_file_not_empty, log, ls_l, mkdir_p, rm_f, run_shell_cmd,
    strip_ext_bam, strip_ext_ta)
from encode_lib_genomic import (
    samtools_name_sort)


def parse_arguments():
    parser = argparse.ArgumentParser(prog='ENCODE DCC BAM 2 TAGALIGN (cut-n-run).',
                                     description='')
    parser.add_argument('bam', type=str,
                        help='Path for BAM file.')
    parser.add_argument('--split-fraglen', type=int,
                        help='Split original TA into high/low according to 9th column '
                             'of samtools view.')
    parser.add_argument('--disable-tn5-shift', action="store_true",
                        help='Disable TN5 shifting for DNase-Seq.')
    parser.add_argument('--mito-chr-name', default='chrM',
                        help='Mito chromosome name.')
    parser.add_argument('--paired-end', action="store_true",
                        help='Paired-end BAM')
    parser.add_argument('--out-dir', default='', type=str,
                        help='Output directory.')
    parser.add_argument('--nth', type=int, default=1,
                        help='Number of threads to parallelize.')
    parser.add_argument('--log-level', default='INFO',
                        choices=['NOTSET', 'DEBUG', 'INFO',
                                 'WARNING', 'CRITICAL', 'ERROR',
                                 'CRITICAL'],
                        help='Log level')
    args = parser.parse_args()

    log.setLevel(args.log_level)
    log.info(sys.argv)
    return args


def bam2ta_se(bam, split_fraglen, out_dir):
    prefix = os.path.join(out_dir,
                          os.path.basename(strip_ext_bam(bam)))
    ta = '{}.org.tagAlign.gz'.format(prefix)
    ta_high = '{}.high.tagAlign.gz'.format(prefix)
    ta_low = '{}.low.tagAlign.gz'.format(prefix)

    cmd = 'bedtools bamtobed -i {} | '
    cmd += 'awk \'BEGIN{{OFS="\\t"}}{{$4="N";$5="1000";print $0}}\' | '
    cmd += 'gzip -nc > {}'
    cmd = cmd.format(
        bam,
        ta)
    run_shell_cmd(cmd)

    if split_fraglen:
        tmp_header = ta + '.tmp.header.sam'

        cmd_header = 'samtools view {bam} -H > {out}'.format(
            bam=bam,
            out=tmp_header)
        run_shell_cmd(cmd_header)

        tmp_bam_high = ta_high + '.tmp.bam'

        cmd_high =  'samtools view {bam} | awk \'{{if($9>{fraglen} || $9<-{fraglen}) print $0}}\' | '
        cmd_high += 'cat {header} - | samtools view -bS - > {out}'
        cmd_high = cmd_high.format(
            bam=bam,
            fraglen=split_fraglen,
            header=tmp_header,
            out=tmp_bam_high)
        run_shell_cmd(cmd_high)

        cmd_high = 'bedtools bamtobed -i {bam} | '
        cmd_high += 'awk \'BEGIN{{OFS="\\t"}}{{$4="N";$5="1000";print $0}}\' | '
        cmd_high += 'gzip -nc > {out}'
        cmd_high = cmd_high.format(
            bam=tmp_bam_high,
            out=ta_high)
        run_shell_cmd(cmd_high)

        tmp_bam_low = ta_low + '.tmp.bam'

        cmd_low =  'samtools view {bam} | awk \'{{if($9<={fraglen} && $9>=-{fraglen}) print $0}}\' | '
        cmd_low += 'cat {header} - | samtools view -bS - > {out}'
        cmd_low = cmd_low.format(
            bam=bam,
            fraglen=split_fraglen,
            header=tmp_header,
            out=tmp_bam_low)
        run_shell_cmd(cmd_low)

        cmd_low = 'bedtools bamtobed -i {bam} | '
        cmd_low += 'awk \'BEGIN{{OFS="\\t"}}{{$4="N";$5="1000";print $0}}\' | '
        cmd_low += 'gzip -nc > {out}'
        cmd_low = cmd_low.format(
            bam=tmp_bam_low,
            out=ta_low)
        run_shell_cmd(cmd_low)

        rm_f([tmp_bam_high, tmp_bam_low, tmp_header])
    else:
        ta_high = None
        ta_low = None

    return ta, ta_high, ta_low


def bam2ta_pe(bam, split_fraglen, nth, out_dir):
    prefix = os.path.join(out_dir,
                          os.path.basename(strip_ext_bam(bam)))
    ta = '{}.org.tagAlign.gz'.format(prefix)
    ta_high = '{}.high.tagAlign.gz'.format(prefix)
    ta_low = '{}.low.tagAlign.gz'.format(prefix)

    # intermediate files
    bedpe = '{}.org.bedpe.gz'.format(prefix)
    bedpe_high = '{}.high.bedpe.gz'.format(prefix)
    bedpe_low = '{}.low.bedpe.gz'.format(prefix)
    nmsrt_bam = samtools_name_sort(bam, nth, out_dir)

    cmd1 = 'LC_COLLATE=C bedtools bamtobed -bedpe -mate1 -i {bam} | '
    cmd1 += 'gzip -nc > {out}'
    cmd1 = cmd1.format(
        bam=nmsrt_bam,
        out=bedpe)
    run_shell_cmd(cmd1)

    cmd2 = 'zcat -f {} | '
    cmd2 += 'awk \'BEGIN{{OFS="\\t"}}'
    cmd2 += '{{printf "%s\\t%s\\t%s\\tN\\t1000\\t%s\\n'
    cmd2 += '%s\\t%s\\t%s\\tN\\t1000\\t%s\\n",'
    cmd2 += '$1,$2,$3,$9,$4,$5,$6,$10}}\' | '
    cmd2 += 'gzip -nc > {}'
    cmd2 = cmd2.format(
        bedpe,
        ta)
    run_shell_cmd(cmd2)

    if split_fraglen:
        tmp_header = ta + '.tmp.header.sam'
        cmd_header = 'samtools view {bam} -H > {out}'.format(
            bam=bam,
            out=tmp_header)
        run_shell_cmd(cmd_header)

        tmp_bam_high = ta_high + '.tmp.bam'

        cmd1_high =  'samtools view {bam} | awk \'{{if($9>{fraglen} || $9<-{fraglen}) print $0}}\' | '
        cmd1_high += 'cat {header} - | samtools view -bS - > {out}'
        cmd1_high = cmd1_high.format(
            bam=nmsrt_bam,
            fraglen=split_fraglen,
            header=tmp_header,
            out=tmp_bam_high)
        run_shell_cmd(cmd1_high)

        cmd1_high = 'LC_COLLATE=C bedtools bamtobed -bedpe -mate1 -i {bam} | '
        cmd1_high += 'gzip -nc > {out}'
        cmd1_high = cmd1_high.format(
            bam=tmp_bam_high,
            out=bedpe_high)
        run_shell_cmd(cmd1_high)

        cmd2_high = 'zcat -f {} | '
        cmd2_high += 'awk \'BEGIN{{OFS="\\t"}}'
        cmd2_high += '{{printf "%s\\t%s\\t%s\\tN\\t1000\\t%s\\n'
        cmd2_high += '%s\\t%s\\t%s\\tN\\t1000\\t%s\\n",'
        cmd2_high += '$1,$2,$3,$9,$4,$5,$6,$10}}\' | '
        cmd2_high += 'gzip -nc > {}'
        cmd2_high = cmd2_high.format(
            bedpe_high,
            ta_high)
        run_shell_cmd(cmd2_high)

        tmp_bam_low = ta_low + '.tmp.bam'

        cmd1_low =  'samtools view {bam} | awk \'{{if($9<={fraglen} && $9>=-{fraglen}) print $0}}\' | '
        cmd1_low += 'cat {header} - | samtools view -bS - > {out}'
        cmd1_low = cmd1_low.format(
            bam=nmsrt_bam,
            fraglen=split_fraglen,
            header=tmp_header,
            out=tmp_bam_low)
        run_shell_cmd(cmd1_low)

        cmd1_low = 'LC_COLLATE=C bedtools bamtobed -bedpe -mate1 -i {bam} | '
        cmd1_low += 'gzip -nc > {out}'
        cmd1_low = cmd1_low.format(
            bam=tmp_bam_low,
            out=bedpe_low)
        run_shell_cmd(cmd1_low)

        cmd2_low = 'zcat -f {} | '
        cmd2_low += 'awk \'BEGIN{{OFS="\\t"}}'
        cmd2_low += '{{printf "%s\\t%s\\t%s\\tN\\t1000\\t%s\\n'
        cmd2_low += '%s\\t%s\\t%s\\tN\\t1000\\t%s\\n",'
        cmd2_low += '$1,$2,$3,$9,$4,$5,$6,$10}}\' | '
        cmd2_low += 'gzip -nc > {}'
        cmd2_low = cmd2_low.format(
            bedpe_low,
            ta_low)
        run_shell_cmd(cmd2_low)        

        rm_f([tmp_bam_high, tmp_bam_low, tmp_header])
        rm_f([bedpe_high, bedpe_low])        
    else:
        ta_high = None
        ta_low = None

    rm_f([bedpe, nmsrt_bam])
    return ta, ta_high, ta_low


def tn5_shift_ta(ta, out_dir):
    prefix = os.path.join(out_dir,
                          os.path.basename(strip_ext_ta(ta)))
    shifted_ta = '{}.tn5.tagAlign.gz'.format(prefix)

    cmd = 'zcat -f {} | '
    cmd += 'awk \'BEGIN {{OFS = "\\t"}}'
    cmd += '{{ if ($6 == "+") {{$2 = $2 + 4}} '
    cmd += 'else if ($6 == "-") {{$3 = $3 - 5}} print $0}}\' | '
    cmd += 'gzip -nc > {}'
    cmd = cmd.format(
        ta,
        shifted_ta)
    run_shell_cmd(cmd)
    return shifted_ta


def main():
    # read params
    args = parse_arguments()

    log.info('Initializing and making output directory...')
    mkdir_p(args.out_dir)

    # declare temp arrays
    temp_files = []  # files to deleted later at the end

    log.info('Converting BAM to TAGALIGN...')
    if args.paired_end:
        ta, ta_h, ta_l = bam2ta_pe(args.bam, args.split_fraglen, args.nth, args.out_dir)
    else:
        ta, ta_h, ta_l = bam2ta_se(args.bam, args.split_fraglen, args.out_dir)

    if args.disable_tn5_shift:
        final_ta = ta
        if args.split_fraglen: 
            final_ta_h = ta_h
            final_ta_l = ta_l
    else:
        log.info("TN5-shifting TAGALIGN...")
        final_ta = tn5_shift_ta(ta, args.out_dir)
        temp_files.append(ta)
        if args.split_fraglen: 
            final_ta_h = tn5_shift_ta(
                ta_h,
                os.path.dirname(ta_h))
            final_ta_l = tn5_shift_ta(
                ta_l,
                os.path.dirname(ta_h))
            temp_files.append(ta_h)
            temp_files.append(ta_l)

    log.info('Checking if output is empty...')
    assert_file_not_empty(final_ta)
    if args.split_fraglen: 
        assert_file_not_empty(final_ta_h)
        assert_file_not_empty(final_ta_l)

    log.info('Removing temporary files...')
    rm_f(temp_files)

    log.info('List all files in output directory...')
    ls_l(args.out_dir)

    log.info('All done.')


if __name__ == '__main__':
    main()
