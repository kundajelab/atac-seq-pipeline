#!/usr/bin/env python

# ENCODE DCC bowtie2 wrapper
# Author: Jin Lee (leepc12@gmail.com)

import sys
import os
import argparse
from encode_lib_common import (
    log, ls_l, mkdir_p, rm_f, run_shell_cmd, strip_ext_fastq, strip_ext_tar,
    untar)


def parse_arguments():
    parser = argparse.ArgumentParser(prog='ENCODE DCC bowtie2 aligner.',
                                     description='')
    parser.add_argument('bowtie2_index_prefix_or_tar', type=str,
                        help='Path for prefix (or a tarball .tar) \
                            for reference bowtie2 index. \
                            Prefix must be like [PREFIX].1.bt2*. \
                            Tar ball must be packed without compression \
                            and directory by using command line \
                            "tar cvf [TAR] [TAR_PREFIX].*.bt2*".')
    parser.add_argument('fastqs', nargs='+', type=str,
                        help='List of FASTQs (R1 and R2). \
                            FASTQs must be compressed with gzip (with .gz).')
    parser.add_argument('--paired-end', action="store_true",
                        help='Paired-end FASTQs.')
    parser.add_argument(
        '--multimapping', default=0, type=int,
        help='Multimapping reads (for bowtie2 -k(m+1). '
             'This will be incremented in an actual bowtie2 command line'
             'e.g. --multimapping 3 will be bowtie2 -k 4')
    parser.add_argument('--nth', type=int, default=1,
                        help='Number of threads to parallelize.')
    parser.add_argument('--out-dir', default='', type=str,
                        help='Output directory.')
    parser.add_argument('--log-level', default='INFO',
                        choices=['NOTSET', 'DEBUG', 'INFO',
                                 'WARNING', 'CRITICAL', 'ERROR',
                                 'CRITICAL'],
                        help='Log level')
    args = parser.parse_args()

    # check if fastqs have correct dimension
    if args.paired_end and len(args.fastqs) != 2:
        raise argparse.ArgumentTypeError('Need 2 fastqs for paired end.')
    if not args.paired_end and len(args.fastqs) != 1:
        raise argparse.ArgumentTypeError('Need 1 fastq for single end.')

    log.setLevel(args.log_level)
    log.info(sys.argv)
    return args


def bowtie2_se(fastq, ref_index_prefix,
               multimapping, nth, out_dir):
    basename = os.path.basename(strip_ext_fastq(fastq))
    prefix = os.path.join(out_dir, basename)
    bam = '{}.bam'.format(prefix)
    align_log = '{}.align.log'.format(prefix)

    cmd = 'bowtie2 {} --mm --threads {} -x {} -U {} 2> {} '
    cmd += '| samtools view -Su /dev/stdin '
    cmd += '| samtools sort /dev/stdin -o {} -T {}'
    cmd = cmd.format(
        '-k {}'.format(multimapping+1) if multimapping else '',
        nth,
        ref_index_prefix,
        fastq,
        align_log,
        bam,
        prefix)
    run_shell_cmd(cmd)

    cmd2 = 'cat {}'.format(align_log)
    run_shell_cmd(cmd2)
    return bam, align_log


def bowtie2_pe(fastq1, fastq2, ref_index_prefix,
               multimapping, nth, out_dir):
    basename = os.path.basename(strip_ext_fastq(fastq1))
    prefix = os.path.join(out_dir, basename)
    bam = '{}.bam'.format(prefix)
    align_log = '{}.align.log'.format(prefix)

    cmd = 'bowtie2 {} -X2000 --mm --threads {} -x {} '
    cmd += '-1 {} -2 {} 2>{} | '
    cmd += 'samtools view -Su /dev/stdin | '
    cmd += 'samtools sort /dev/stdin -o {} -T {}'
    cmd = cmd.format(
        '-k {}'.format(multimapping+1) if multimapping else '',
        nth,
        ref_index_prefix,
        fastq1,
        fastq2,
        align_log,
        bam,
        prefix)
    run_shell_cmd(cmd)

    cmd2 = 'cat {}'.format(align_log)
    run_shell_cmd(cmd2)
    return bam, align_log


def chk_bowtie2_index(prefix):
    index_1 = '{}.1.bt2'.format(prefix)
    index_2 = '{}.1.bt2l'.format(prefix)
    if not (os.path.exists(index_1) or os.path.exists(index_2)):
        raise Exception("Bowtie2 index does not exists. " +
                        "Prefix = {}".format(prefix))


def main():
    # read params
    args = parse_arguments()

    log.info('Initializing and making output directory...')
    mkdir_p(args.out_dir)

    # declare temp arrays
    temp_files = []  # files to deleted later at the end

    # if bowtie2 index is tarball then unpack it
    if args.bowtie2_index_prefix_or_tar.endswith('.tar'):
        log.info('Unpacking bowtie2 index tar...')
        tar = args.bowtie2_index_prefix_or_tar
        # untar
        untar(tar, args.out_dir)
        bowtie2_index_prefix = os.path.join(
            args.out_dir, os.path.basename(strip_ext_tar(tar)))
        temp_files.append('{}.*.bt2'.format(
            bowtie2_index_prefix))
        temp_files.append('{}.*.bt2l'.format(
            bowtie2_index_prefix))
    else:
        bowtie2_index_prefix = args.bowtie2_index_prefix_or_tar

    # check if bowties indices are unpacked on out_dir
    chk_bowtie2_index(bowtie2_index_prefix)

    # bowtie2
    log.info('Running bowtie2...')
    if args.paired_end:
        bam, align_log = bowtie2_pe(
            args.fastqs[0], args.fastqs[1],
            bowtie2_index_prefix,
            args.multimapping, args.nth,
            args.out_dir)
    else:
        bam, align_log = bowtie2_se(
            args.fastqs[0],
            bowtie2_index_prefix,
            args.multimapping, args.nth,
            args.out_dir)

    log.info('Removing temporary files...')
    print(temp_files)
    rm_f(temp_files)

    log.info('Showing align log...')
    run_shell_cmd('cat {}'.format(align_log))

    log.info('Checking if BAM file is empty...')
    if not int(run_shell_cmd('samtools view -c {}'.format(bam))):
        raise ValueError('BAM file is empty, no reads found.')

    log.info('List all files in output directory...')
    ls_l(args.out_dir)

    log.info('All done.')


if __name__ == '__main__':
    main()
