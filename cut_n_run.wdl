# Cut-n-run pipeline
# Author: Jin Lee (leepc12@gmail.com)

#CAPER docker quay.io/encode-dcc/cut-n-run-pipeline:dev-v0.1.0
#CAPER singularity docker://quay.io/encode-dcc/cut-n-run-pipeline:dev-v0.1.0
#CROO out_def https://storage.googleapis.com/encode-pipeline-output-definition/cut_n_run.croo.json

workflow cut_n_run {
	# pipeline version
	String pipeline_ver = 'dev-v0.2.0'

	# general sample information
	String title = 'Untitled'
	String description = 'No description'

	# endedness for input data
	Boolean? paired_end				# to define endedness for all replciates
									#	if defined, this will override individual endedness below
	Array[Boolean] paired_ends = []	# to define endedness for individual replicate
	Boolean? ctl_paired_end
	Array[Boolean] ctl_paired_ends = []

	# genome TSV
	# 	you can define any genome parameters either in this TSV
	#	or individually in an input JSON file
	# 	individually defined parameters will override those defined in this TSV	
	File? genome_tsv 				# reference genome data TSV file including
									# all genome-specific file paths and parameters
	# individual genome parameters
	String? genome_name				# genome name
	File? ref_fa					# reference fasta (*.fa.gz)
	File? ref_mito_fa				# mito-only reference fasta (*.fa.gz)
	File? bwa_idx_tar 				# bwa index tar (uncompressed .tar)
	File? bwa_mito_idx_tar 			# bwa mito-only index tar (uncompressed .tar)
	File? bowtie2_idx_tar 			# bowtie2 index tar (uncompressed .tar)
	File? bowtie2_mito_idx_tar 		# bowtie2 mito-only index tar (uncompressed .tar)
	File? custom_aligner_idx_tar 	# custom aligner's index tar (uncompressed .tar)
	File? custom_aligner_mito_idx_tar 	# custom aligner's mito-only index tar (uncompressed .tar)
	File? chrsz 					# 2-col chromosome sizes file
	File? blacklist 				# blacklist BED (peaks overlapping will be filtered out)
	File? blacklist2 				# 2nd blacklist (will be merged with 1st one)
	String? mito_chr_name
	String? regex_bfilt_peak_chr_name
	String? gensz 					# genome sizes (hs for human, mm for mouse or sum of 2nd col in chrsz)
	File? tss 						# TSS BED file
	File? dnase 					# open chromatin region BED file
	File? prom 						# promoter region BED file
	File? enh 						# enhancer region BED file
	File? reg2map 					# file with cell type signals
	File? reg2map_bed 				# file of regions used to generate reg2map signals
	File? roadmap_meta 				# roadmap metedata

	# parameters for pipeline
	String pipeline_type = 'cut_n_run'

	String aligner = 'bowtie2' 		# supported aligner: bowtie2
	File? custom_align_py 			# custom align python script

	String peak_caller = 'macs2'
	String peak_type = 'narrowPeak'
	File? custom_call_peak_py 		# custom call_peak python script

	# important flags for pipeline
	Boolean align_only = false		# disable all post-align analyses (peak-calling, overlap, idr, ...)
	Boolean true_rep_only = false 	# disable all analyses involving pseudo replicates (including overlap/idr)
	Boolean enable_xcor = false 	# enable cross-corr analysis
	Boolean enable_count_signal_track = true # generate count signal track
	Boolean enable_idr = true 		# enable IDR analysis on raw peaks
	Boolean enable_preseq = false
	Boolean enable_fraglen_stat = false
	Boolean enable_tss_enrich = false
	Boolean enable_annot_enrich = false
	Boolean enable_jsd = true 		# enable JSD plot generation (deeptools fingerprint)
	Boolean enable_gc_bias = false

	# parameters for aligner and filter
	Int multimapping = 0			# for samples with multimapping reads
	String dup_marker = 'picard'	# picard, sambamba
	Boolean no_dup_removal = false 	# keep all dups in final BAM
	Int? mapq_thresh				# threshold for low MAPQ reads removal
	Int mapq_thresh_bwa = 30
	Int mapq_thresh_bowtie2 = 30
	Array[String] filter_chrs = ['chrM', 'MT']
									# array of chromosomes to be removed from nodup/filt BAM
									# chromosomes will be removed from both BAM header/contents
									# e.g. (default: mito-chrs) ['chrM', 'MT']
	Int subsample_reads = 0			# subsample TAGALIGN (0: no subsampling)
	Int xcor_subsample_reads = 25000000 # subsample TAG-ALIGN for xcor only (not used for other downsteam analyses)
	Int split_read_len = 0			# split TAG-ALIGN into two (high/low) according to read length.
									# 0 = no splitting

	# parameters for peak calling
	Boolean always_use_pooled_ctl = false # always use pooled control for all exp rep.
	Float ctl_depth_ratio = 1.2 	# if ratio between controls is higher than this
									# then always use pooled control for all exp rep.
	# parameters for peak calling
	Int cap_num_peak = 300000		# cap number of raw peaks for each replicate
	Float pval_thresh = 0.01		# p.value threshold for peak caller
	Int smooth_win = 73				# size of smoothing window for peak caller
	Float idr_thresh = 0.05			# IDR threshold

	# resources
	#	these variables will be automatically ignored if they are not supported by platform
	# 	"disks" is for cloud platforms (Google Cloud Platform, DNAnexus) only

	Int align_cpu = 4
	Int align_mem_mb = 20000
	Int align_time_hr = 48
	String align_disks = 'local-disk 400 HDD'

	Int filter_cpu = 2
	Int filter_mem_mb = 20000
	Int filter_time_hr = 24
	String filter_disks = 'local-disk 400 HDD'

	Int bam2ta_cpu = 2
	Int bam2ta_mem_mb = 10000
	Int bam2ta_time_hr = 6
	String bam2ta_disks = 'local-disk 100 HDD'

	Int spr_mem_mb = 16000

	Int jsd_cpu = 2
	Int jsd_mem_mb = 12000
	Int jsd_time_hr = 6
	String jsd_disks = 'local-disk 200 HDD'

	Int xcor_cpu = 2
	Int xcor_mem_mb = 16000
	Int xcor_time_hr = 6
	String xcor_disks = 'local-disk 100 HDD'

	Int call_peak_cpu = 1
	Int call_peak_mem_mb = 16000
	Int call_peak_time_hr = 24
	String call_peak_disks = 'local-disk 200 HDD'

	Int macs2_signal_track_mem_mb = 16000
	Int macs2_signal_track_time_hr = 24
	String macs2_signal_track_disks = 'local-disk 200 HDD'

	Int preseq_mem_mb = 16000

	String filter_picard_java_heap = '4G'
	String preseq_picard_java_heap = '6G'
	String fraglen_stat_picard_java_heap = '6G'
	String gc_bias_picard_java_heap = '6G'

	# input file definition
	# supported types: fastq, bam, nodup_bam (or filtered bam), ta (tagAlign), peak
	# 	pipeline can start from any type of inputs
	# 	leave all other types undefined
	# 	you can define up to 10 replicates

 	# fastqs
	Array[File] fastqs_rep1_R1 = []		# FASTQs to be merged for rep1 R1
	Array[File] fastqs_rep1_R2 = [] 	# do not define if single-ended
	Array[File] fastqs_rep2_R1 = [] 	# do not define if unreplicated
	Array[File] fastqs_rep2_R2 = []		# ...
	Array[File] fastqs_rep3_R1 = []
	Array[File] fastqs_rep3_R2 = []
	Array[File] fastqs_rep4_R1 = []
	Array[File] fastqs_rep4_R2 = []
	Array[File] fastqs_rep5_R1 = []
	Array[File] fastqs_rep5_R2 = []
	Array[File] fastqs_rep6_R1 = []
	Array[File] fastqs_rep6_R2 = []
	Array[File] fastqs_rep7_R1 = []
	Array[File] fastqs_rep7_R2 = []
	Array[File] fastqs_rep8_R1 = []
	Array[File] fastqs_rep8_R2 = []
	Array[File] fastqs_rep9_R1 = []
	Array[File] fastqs_rep9_R2 = []
	Array[File] fastqs_rep10_R1 = []
	Array[File] fastqs_rep10_R2 = []

	Array[File] ctl_fastqs_rep1_R1 = []		# Control FASTQs to be merged for rep1 R1
	Array[File] ctl_fastqs_rep1_R2 = [] 	# do not define if single-ended
	Array[File] ctl_fastqs_rep2_R1 = [] 	# do not define if unreplicated
	Array[File] ctl_fastqs_rep2_R2 = []		# ...
	Array[File] ctl_fastqs_rep3_R1 = []
	Array[File] ctl_fastqs_rep3_R2 = []
	Array[File] ctl_fastqs_rep4_R1 = []
	Array[File] ctl_fastqs_rep4_R2 = []
	Array[File] ctl_fastqs_rep5_R1 = []
	Array[File] ctl_fastqs_rep5_R2 = []
	Array[File] ctl_fastqs_rep6_R1 = []
	Array[File] ctl_fastqs_rep6_R2 = []
	Array[File] ctl_fastqs_rep7_R1 = []
	Array[File] ctl_fastqs_rep7_R2 = []
	Array[File] ctl_fastqs_rep8_R1 = []
	Array[File] ctl_fastqs_rep8_R2 = []
	Array[File] ctl_fastqs_rep9_R1 = []
	Array[File] ctl_fastqs_rep9_R2 = []
	Array[File] ctl_fastqs_rep10_R1 = []
	Array[File] ctl_fastqs_rep10_R2 = []

	# other input types (bam, nodup_bam, ta). they are per replicate
	Array[File?] bams = []
	Array[File?] ctl_bams = [] 		# [rep_id]
	Array[File?] nodup_bams = [] 	# [rep_id]
	Array[File?] ctl_nodup_bams = [] # [rep_id]
	Array[File?] tas = []			# [rep_id]
	Array[File?] ctl_tas = []		# [rep_id]

	# optional read length array. used it pipeline starts from BAM or TA
	Array[Int?] read_len = [] 		# [rep_id]. read length for each rep

	####################### pipeline starts here #######################
	# DO NOT DEFINE ANY VARIABLES DECLARED BELOW IN AN INPUT JSON FILE #
	# THEY ARE TEMPORARY/INTERMEDIATE SYSTEM VARIABLES                 #
	####################### pipeline starts here #######################
	
	# read genome data and paths
	if ( defined(genome_tsv) ) {
		call read_genome_tsv { input: genome_tsv = genome_tsv }
	}
	File? ref_fa_ = if defined(ref_fa) then ref_fa
		else read_genome_tsv.ref_fa
	File? bwa_idx_tar_ = if defined(bwa_idx_tar) then bwa_idx_tar
		else read_genome_tsv.bwa_idx_tar
	File? bwa_mito_idx_tar_ = if defined(bwa_mito_idx_tar) then bwa_mito_idx_tar
		else read_genome_tsv.bwa_mito_idx_tar
	File? bowtie2_idx_tar_ = if defined(bowtie2_idx_tar) then bowtie2_idx_tar
		else read_genome_tsv.bowtie2_idx_tar
	File? bowtie2_mito_idx_tar_ = if defined(bowtie2_mito_idx_tar) then bowtie2_mito_idx_tar
		else read_genome_tsv.bowtie2_mito_idx_tar
	File? custom_aligner_idx_tar_ = if defined(custom_aligner_idx_tar) then custom_aligner_idx_tar
		else read_genome_tsv.custom_aligner_idx_tar
	File? custom_aligner_mito_idx_tar_ = if defined(custom_aligner_mito_idx_tar) then custom_aligner_mito_idx_tar
		else read_genome_tsv.custom_aligner_mito_idx_tar
	File? chrsz_ = if defined(chrsz) then chrsz
		else read_genome_tsv.chrsz
	String? gensz_ = if defined(gensz) then gensz
		else read_genome_tsv.gensz
	File? blacklist1_ = if defined(blacklist) then blacklist
		else read_genome_tsv.blacklist
	File? blacklist2_ = if defined(blacklist2) then blacklist2
		else read_genome_tsv.blacklist2		
	# merge multiple blacklists
	# two blacklists can have different number of columns (3 vs 6)
	# so we limit merged blacklist's columns to 3
	Array[File] blacklists = select_all([blacklist1_, blacklist2_])
	if ( length(blacklists) > 1 ) {
		call pool_ta as pool_blacklist { input:
			tas = blacklists,
			col = 3,
		}
	}
	File? blacklist_ = if length(blacklists) > 1 then pool_blacklist.ta_pooled
		else if length(blacklists) > 0 then blacklists[0]
		else blacklist2_
	String? mito_chr_name_ = if defined(mito_chr_name) then mito_chr_name
		else read_genome_tsv.mito_chr_name
	String? regex_bfilt_peak_chr_name_ = if defined(regex_bfilt_peak_chr_name) then regex_bfilt_peak_chr_name
		else read_genome_tsv.regex_bfilt_peak_chr_name
	String? genome_name_ = if defined(genome_name) then genome_name
		else if defined(read_genome_tsv.genome_name) then read_genome_tsv.genome_name
		else basename(select_first([genome_tsv, ref_fa_, chrsz_, 'None']))

	# read additional annotation data
	File? tss_ = if defined(tss) then tss
		else read_genome_tsv.tss
	File? dnase_ = if defined(dnase) then dnase
		else read_genome_tsv.dnase
	File? prom_ = if defined(prom) then prom
		else read_genome_tsv.prom
	File? enh_ = if defined(enh) then enh
		else read_genome_tsv.enh
	File? reg2map_ = if defined(reg2map) then reg2map
		else read_genome_tsv.reg2map
	File? reg2map_bed_ = if defined(reg2map_bed) then reg2map_bed
		else read_genome_tsv.reg2map_bed
	File? roadmap_meta_ = if defined(roadmap_meta) then roadmap_meta
		else read_genome_tsv.roadmap_meta

	### temp vars (do not define these)
	String aligner_ = if defined(custom_align_py) then 'custom' else aligner
	String peak_caller_ = if defined(custom_call_peak_py) then 'custom' else peak_caller
	String peak_type_ = peak_type
	String idr_rank_ = if peak_caller_=='spp' then 'signal.value'
						else if peak_caller_=='macs2' then 'p.value'
						else 'p.value'
	Int cap_num_peak_ = cap_num_peak
	Int mapq_thresh_ = if aligner=='bowtie2' then select_first([mapq_thresh, mapq_thresh_bowtie2])
						else select_first([mapq_thresh, mapq_thresh_bwa])

	# temporary 2-dim fastqs array [rep_id][merge_id]
	Array[Array[File]] fastqs_R1 = 
		if length(fastqs_rep10_R1)>0 then
			[fastqs_rep1_R1, fastqs_rep2_R1, fastqs_rep3_R1, fastqs_rep4_R1, fastqs_rep5_R1,
			fastqs_rep6_R1, fastqs_rep7_R1, fastqs_rep8_R1, fastqs_rep9_R1, fastqs_rep10_R1]
		else if length(fastqs_rep9_R1)>0 then
			[fastqs_rep1_R1, fastqs_rep2_R1, fastqs_rep3_R1, fastqs_rep4_R1, fastqs_rep5_R1,
			fastqs_rep6_R1, fastqs_rep7_R1, fastqs_rep8_R1, fastqs_rep9_R1]
		else if length(fastqs_rep8_R1)>0 then
			[fastqs_rep1_R1, fastqs_rep2_R1, fastqs_rep3_R1, fastqs_rep4_R1, fastqs_rep5_R1,
			fastqs_rep6_R1, fastqs_rep7_R1, fastqs_rep8_R1]
		else if length(fastqs_rep7_R1)>0 then
			[fastqs_rep1_R1, fastqs_rep2_R1, fastqs_rep3_R1, fastqs_rep4_R1, fastqs_rep5_R1,
			fastqs_rep6_R1, fastqs_rep7_R1]
		else if length(fastqs_rep6_R1)>0 then
			[fastqs_rep1_R1, fastqs_rep2_R1, fastqs_rep3_R1, fastqs_rep4_R1, fastqs_rep5_R1,
			fastqs_rep6_R1]
		else if length(fastqs_rep5_R1)>0 then
			[fastqs_rep1_R1, fastqs_rep2_R1, fastqs_rep3_R1, fastqs_rep4_R1, fastqs_rep5_R1]
		else if length(fastqs_rep4_R1)>0 then
			[fastqs_rep1_R1, fastqs_rep2_R1, fastqs_rep3_R1, fastqs_rep4_R1]
		else if length(fastqs_rep3_R1)>0 then
			[fastqs_rep1_R1, fastqs_rep2_R1, fastqs_rep3_R1]
		else if length(fastqs_rep2_R1)>0 then
			[fastqs_rep1_R1, fastqs_rep2_R1]
		else if length(fastqs_rep1_R1)>0 then
			[fastqs_rep1_R1]
		else []
	# no need to do that for R2 (R1 array will be used to determine presense of fastq for each rep)
	Array[Array[File]] fastqs_R2 = 
		[fastqs_rep1_R2, fastqs_rep2_R2, fastqs_rep3_R2, fastqs_rep4_R2, fastqs_rep5_R2,
		fastqs_rep6_R2, fastqs_rep7_R2, fastqs_rep8_R2, fastqs_rep9_R2, fastqs_rep10_R2]

	# temporary 2-dim ctl fastqs array [rep_id][merge_id]
	Array[Array[File]] ctl_fastqs_R1 = 
		if length(ctl_fastqs_rep10_R1)>0 then
			[ctl_fastqs_rep1_R1, ctl_fastqs_rep2_R1, ctl_fastqs_rep3_R1, ctl_fastqs_rep4_R1, ctl_fastqs_rep5_R1,
			ctl_fastqs_rep6_R1, ctl_fastqs_rep7_R1, ctl_fastqs_rep8_R1, ctl_fastqs_rep9_R1, ctl_fastqs_rep10_R1]
		else if length(ctl_fastqs_rep9_R1)>0 then
			[ctl_fastqs_rep1_R1, ctl_fastqs_rep2_R1, ctl_fastqs_rep3_R1, ctl_fastqs_rep4_R1, ctl_fastqs_rep5_R1,
			ctl_fastqs_rep6_R1, ctl_fastqs_rep7_R1, ctl_fastqs_rep8_R1, ctl_fastqs_rep9_R1]
		else if length(ctl_fastqs_rep8_R1)>0 then
			[ctl_fastqs_rep1_R1, ctl_fastqs_rep2_R1, ctl_fastqs_rep3_R1, ctl_fastqs_rep4_R1, ctl_fastqs_rep5_R1,
			ctl_fastqs_rep6_R1, ctl_fastqs_rep7_R1, ctl_fastqs_rep8_R1]
		else if length(ctl_fastqs_rep7_R1)>0 then
			[ctl_fastqs_rep1_R1, ctl_fastqs_rep2_R1, ctl_fastqs_rep3_R1, ctl_fastqs_rep4_R1, ctl_fastqs_rep5_R1,
			ctl_fastqs_rep6_R1, ctl_fastqs_rep7_R1]
		else if length(ctl_fastqs_rep6_R1)>0 then
			[ctl_fastqs_rep1_R1, ctl_fastqs_rep2_R1, ctl_fastqs_rep3_R1, ctl_fastqs_rep4_R1, ctl_fastqs_rep5_R1,
			ctl_fastqs_rep6_R1]
		else if length(ctl_fastqs_rep5_R1)>0 then
			[ctl_fastqs_rep1_R1, ctl_fastqs_rep2_R1, ctl_fastqs_rep3_R1, ctl_fastqs_rep4_R1, ctl_fastqs_rep5_R1]
		else if length(ctl_fastqs_rep4_R1)>0 then
			[ctl_fastqs_rep1_R1, ctl_fastqs_rep2_R1, ctl_fastqs_rep3_R1, ctl_fastqs_rep4_R1]
		else if length(ctl_fastqs_rep3_R1)>0 then
			[ctl_fastqs_rep1_R1, ctl_fastqs_rep2_R1, ctl_fastqs_rep3_R1]
		else if length(ctl_fastqs_rep2_R1)>0 then
			[ctl_fastqs_rep1_R1, ctl_fastqs_rep2_R1]
		else if length(ctl_fastqs_rep1_R1)>0 then
			[ctl_fastqs_rep1_R1]
		else []
	# no need to do that for R2 (R1 array will be used to determine presense of fastq for each rep)
	Array[Array[File]] ctl_fastqs_R2 = 
		[ctl_fastqs_rep1_R2, ctl_fastqs_rep2_R2, ctl_fastqs_rep3_R2, ctl_fastqs_rep4_R2, ctl_fastqs_rep5_R2,
		ctl_fastqs_rep6_R2, ctl_fastqs_rep7_R2, ctl_fastqs_rep8_R2, ctl_fastqs_rep9_R2, ctl_fastqs_rep10_R2]

	# temporary variables to get number of replicates
	# 	WDLic implementation of max(A,B,C,...)
	Int num_rep_fastq = length(fastqs_R1)
	Int num_rep_bam = if length(bams)<num_rep_fastq then num_rep_fastq
		else length(bams)
	Int num_rep_nodup_bam = if length(nodup_bams)<num_rep_bam then num_rep_bam
		else length(nodup_bams)
	Int num_rep_ta = if length(tas)<num_rep_nodup_bam then num_rep_nodup_bam
		else length(tas)
	Int num_rep = num_rep_ta

	# temporary variables to get number of controls
	Int num_ctl_fastq = length(ctl_fastqs_R1)
	Int num_ctl_bam = if length(ctl_bams)<num_ctl_fastq then num_ctl_fastq
		else length(ctl_bams)
	Int num_ctl_nodup_bam = if length(ctl_nodup_bams)<num_ctl_bam then num_ctl_bam
		else length(ctl_nodup_bams)
	Int num_ctl_ta = if length(ctl_tas)<num_ctl_nodup_bam then num_ctl_nodup_bam
		else length(ctl_tas)
	Int num_ctl = num_ctl_ta

	# sanity check for inputs
	if ( num_rep == 0 && num_ctl == 0 ) {
		call raise_exception as error_input_data  { input:
			msg = 'No FASTQ/BAM/TAG-ALIGN/PEAK defined in your input JSON. Check if your FASTQs are defined as "cut_n_run.fastqs_repX_RY". DO NOT MISS suffix _R1 even for single ended FASTQ.'
		}
	}
	if ( !defined(chrsz_) ) {
		call raise_exception as error_genome_database { input:
			msg = 'No genome database found in your input JSON. Did you define "cut_n_run.genome_tsv" correctly?'
		}
	}

	# align each replicate
	scatter(i in range(num_rep)) {
		# to override endedness definition for individual replicate
		# 	paired_end will override paired_ends[i]
		Boolean? paired_end_ = if !defined(paired_end) && i<length(paired_ends) then paired_ends[i]
			else paired_end

		Boolean has_input_of_align = i<length(fastqs_R1) && length(fastqs_R1[i])>0
		Boolean has_output_of_align = i<length(bams) && defined(bams[i])
		if ( has_input_of_align && !has_output_of_align ) {
			call align { input :
				fastqs_R1 = fastqs_R1[i],
				fastqs_R2 = fastqs_R2[i],
				paired_end = paired_end_,

				aligner = aligner_,
				mito_chr_name = mito_chr_name_,
				chrsz = chrsz_,
				custom_align_py = custom_align_py,
				multimapping = multimapping,
				idx_tar = if aligner=='bwa' then bwa_idx_tar_
					else if aligner=='bowtie2' then bowtie2_idx_tar_
					else custom_aligner_idx_tar_,
				# resource
				cpu = align_cpu,
				mem_mb = align_mem_mb,
				time_hr = align_time_hr,
				disks = align_disks,
			}
		}
		File? bam_ = if has_output_of_align then bams[i] else align.bam

		# mito only mapping to get frac mito qc
		Boolean has_input_of_align_mito = has_input_of_align &&
			(aligner=='bowtie2' && defined(bowtie2_mito_idx_tar_) ||
			 aligner=='bwa' && defined(bwa_mito_idx_tar_) ||
			 defined(custom_aligner_mito_idx_tar_))
		if ( has_input_of_align_mito ) {
			call align as align_mito { input :
				fastqs_R1 = fastqs_R1[i],
				fastqs_R2 = fastqs_R2[i],
				paired_end = paired_end_,

				aligner = aligner_,
				mito_chr_name = mito_chr_name_,
				chrsz = chrsz_,
				custom_align_py = custom_align_py,
				multimapping = multimapping,
				idx_tar = if aligner=='bwa' then bwa_mito_idx_tar_
					else if aligner=='bowtie2' then bowtie2_mito_idx_tar_
					else custom_aligner_mito_idx_tar_,
				# resource
				cpu = align_cpu,
				mem_mb = align_mem_mb,
				time_hr = align_time_hr,
				disks = align_disks,
			}
		}

		if ( defined(align.non_mito_samstat_qc) && defined(align_mito.samstat_qc) ) {
			call frac_mito { input:
				non_mito_samstat = align.non_mito_samstat_qc,
				mito_samstat = align_mito.samstat_qc
			}
		}

		Boolean has_input_of_filter = has_output_of_align || defined(align.bam)
		Boolean has_output_of_filter = i<length(nodup_bams) && defined(nodup_bams[i])
		# skip if we already have output of this step
		if ( has_input_of_filter && !has_output_of_filter ) {
			call filter { input :
				bam = bam_,
				paired_end = paired_end_,
				dup_marker = dup_marker,
				mapq_thresh = mapq_thresh_,
				filter_chrs = filter_chrs,
				chrsz = chrsz_,
				no_dup_removal = no_dup_removal,
				multimapping = multimapping,
				mito_chr_name = mito_chr_name_,

				cpu = filter_cpu,
				mem_mb = filter_mem_mb,
				picard_java_heap = filter_picard_java_heap,
				time_hr = filter_time_hr,
				disks = filter_disks,
			}
		}
		File? nodup_bam_ = if has_output_of_filter then nodup_bams[i] else filter.nodup_bam

		Boolean has_input_of_bam2ta = has_output_of_filter || defined(filter.nodup_bam)
		Boolean has_output_of_bam2ta = i<length(tas) && defined(tas[i])
		if ( has_input_of_bam2ta && !has_output_of_bam2ta ) {
			call bam2ta { input :
				bam = nodup_bam_,
				disable_tn5_shift = false,
				subsample = subsample_reads,
				paired_end = paired_end_,
				mito_chr_name = mito_chr_name_,

				cpu = bam2ta_cpu,
				mem_mb = bam2ta_mem_mb,
				time_hr = bam2ta_time_hr,
				disks = bam2ta_disks,
			}
		}
		File? ta_ = if has_output_of_bam2ta then tas[i] else bam2ta.ta

		Boolean has_input_of_split_ta_by_read_len = defined(ta_)
		if ( has_input_of_split_ta_by_read_len ) {
			call split_ta_by_read_len { input :
				ta = ta_,
				split_read_len = split_read_len,
			}
		}
		File? ta_high_ = split_ta_by_read_len.ta_high
		File? ta_low_ = split_ta_by_read_len.ta_low

		Boolean has_input_of_xcor = has_output_of_align || defined(align.bam)
		if ( has_input_of_xcor && enable_xcor ) {
			call filter as filter_no_dedup { input :
				bam = bam_,
				paired_end = paired_end_,
				dup_marker = dup_marker,
				mapq_thresh = mapq_thresh_,
				filter_chrs = filter_chrs,
				chrsz = chrsz_,
				no_dup_removal = true,
				multimapping = multimapping,
				mito_chr_name = mito_chr_name_,

				cpu = filter_cpu,
				mem_mb = filter_mem_mb,
				picard_java_heap = filter_picard_java_heap,
				time_hr = filter_time_hr,
				disks = filter_disks,
			}
			call bam2ta as bam2ta_no_dedup { input :
				bam = filter_no_dedup.nodup_bam,  # output name is nodup but it's not deduped
				disable_tn5_shift = if pipeline_type=='atac' then false else true,
				subsample = 0,
				paired_end = paired_end_,
				mito_chr_name = mito_chr_name_,

				cpu = bam2ta_cpu,
				mem_mb = bam2ta_mem_mb,
				time_hr = bam2ta_time_hr,
				disks = bam2ta_disks,
			}
			# subsample tagalign (non-mito) and cross-correlation analysis
			call xcor { input :
				ta = bam2ta_no_dedup.ta,
				subsample = xcor_subsample_reads,
				paired_end = paired_end_,
				mito_chr_name = mito_chr_name_,

				cpu = xcor_cpu,
				mem_mb = xcor_mem_mb,
				time_hr = xcor_time_hr,
				disks = xcor_disks,
			}
		}

		Boolean has_input_of_spr = has_output_of_bam2ta || defined(bam2ta.ta)
		if ( has_input_of_spr && !align_only && !true_rep_only ) {
			call spr { input :
				ta = ta_,
				paired_end = paired_end_,
				mem_mb = spr_mem_mb,
			}
			call spr as spr_high { input :
				ta = ta_high_,
				paired_end = paired_end_,
				mem_mb = spr_mem_mb,
			}
			call spr as spr_low { input :
				ta = ta_low_,
				paired_end = paired_end_,
				mem_mb = spr_mem_mb,
			}
		}

		Boolean has_input_of_count_signal_track = has_output_of_bam2ta || defined(bam2ta.ta)
		if ( has_input_of_count_signal_track && enable_count_signal_track ) {
			# generate count signal track
			call count_signal_track { input :
				ta = ta_,
				chrsz = chrsz_,
			}
		}
		# tasks factored out from ATAqC
		Boolean has_input_of_tss_enrich = defined(nodup_bam_) && defined(tss_) && (
			defined(align.read_len_log) || i<length(read_len) && defined(read_len[i]) )
		if ( enable_tss_enrich && has_input_of_tss_enrich ) {
			Int? read_len_ = if i<length(read_len) && defined(read_len[i]) then read_len[i]
				else read_int(align.read_len_log)
			call tss_enrich { input :
				read_len = read_len_,
				nodup_bam = nodup_bam_,
				tss = tss_,
				chrsz = chrsz_,
			}
		}
		if ( enable_fraglen_stat && paired_end_ && defined(nodup_bam_) ) {
			call fraglen_stat_pe { input :
				nodup_bam = nodup_bam_,
				picard_java_heap = fraglen_stat_picard_java_heap,				
			}
		}
		if ( enable_preseq && defined(bam_) ) {
			call preseq { input :
				bam = bam_,
				paired_end = paired_end_,
				mem_mb = preseq_mem_mb,
				picard_java_heap = preseq_picard_java_heap,
			}
		}
		if ( enable_gc_bias && defined(nodup_bam_) && defined(ref_fa_) ) {
			call gc_bias { input :
				nodup_bam = nodup_bam_,
				ref_fa = ref_fa_,
				picard_java_heap = gc_bias_picard_java_heap,
			}
		}
		if ( enable_annot_enrich && defined(ta_) && defined(blacklist_) && defined(dnase_) && defined(prom_) && defined(enh_) ) {
			call annot_enrich { input :
				ta = ta_,
				blacklist = blacklist_,
				dnase = dnase_,
				prom = prom_,
				enh = enh_,
			}
		}
	}

	# align each control
	scatter(i in range(num_ctl)) {
		# to override endedness definition for individual control
		# 	ctl_paired_end will override ctl_paired_ends[i]
		Boolean? ctl_paired_end_ = if !defined(ctl_paired_end) && i<length(ctl_paired_ends) then ctl_paired_ends[i]
			else if defined(ctl_paired_end) then ctl_paired_end
			else paired_end

		Boolean has_input_of_align_ctl = i<length(ctl_fastqs_R1) && length(ctl_fastqs_R1[i])>0
		Boolean has_output_of_align_ctl = i<length(ctl_bams) && defined(ctl_bams[i])
		if ( has_input_of_align_ctl && !has_output_of_align_ctl ) {
			call align as align_ctl { input :
				fastqs_R1 = ctl_fastqs_R1[i],
				fastqs_R2 = ctl_fastqs_R2[i],
				paired_end = ctl_paired_end_,

				aligner = aligner_,
				mito_chr_name = mito_chr_name_,
				chrsz = chrsz_,
				custom_align_py = custom_align_py,
				multimapping = multimapping,
				idx_tar = if aligner=='bwa' then bwa_idx_tar_
					else if aligner=='bowtie2' then bowtie2_idx_tar_
					else custom_aligner_idx_tar_,
				# resource
				cpu = align_cpu,
				mem_mb = align_mem_mb,
				time_hr = align_time_hr,
				disks = align_disks,
			}
		}
		File? ctl_bam_ = if has_output_of_align_ctl then ctl_bams[i] else align_ctl.bam

		Boolean has_input_of_filter_ctl = has_output_of_align_ctl || defined(align_ctl.bam)
		Boolean has_output_of_filter_ctl = i<length(ctl_nodup_bams) && defined(ctl_nodup_bams[i])
		if ( has_input_of_filter_ctl && !has_output_of_filter_ctl ) {
			call filter as filter_ctl { input :
				bam = ctl_bam_,
				paired_end = ctl_paired_end_,
				multimapping = multimapping,				
				dup_marker = dup_marker,
				mapq_thresh = mapq_thresh_,
				filter_chrs = filter_chrs,
				chrsz = chrsz_,
				no_dup_removal = no_dup_removal,
				mito_chr_name = mito_chr_name_,

				cpu = filter_cpu,
				mem_mb = filter_mem_mb,
				picard_java_heap = filter_picard_java_heap,
				time_hr = filter_time_hr,
				disks = filter_disks,
			}
		}
		File? ctl_nodup_bam_ = if has_output_of_filter_ctl then ctl_nodup_bams[i] else filter_ctl.nodup_bam

		Boolean has_input_of_bam2ta_ctl = has_output_of_filter_ctl || defined(filter_ctl.nodup_bam)
		Boolean has_output_of_bam2ta_ctl = i<length(ctl_tas) && defined(ctl_tas[i])
		if ( has_input_of_bam2ta_ctl && !has_output_of_bam2ta_ctl ) {
			call bam2ta as bam2ta_ctl { input :
				bam = ctl_nodup_bam_,
				subsample = subsample_reads,
				paired_end = ctl_paired_end_,
				mito_chr_name = mito_chr_name_,
				disable_tn5_shift = false,

				cpu = bam2ta_cpu,
				mem_mb = bam2ta_mem_mb,
				time_hr = bam2ta_time_hr,
				disks = bam2ta_disks,
			}
		}
		File? ctl_ta_ = if has_output_of_bam2ta_ctl then ctl_tas[i] else bam2ta_ctl.ta
	}

	# if there are TAs for ALL replicates then pool them
	Boolean has_all_inputs_of_pool_ta = length(select_all(ta_))==num_rep
	if ( has_all_inputs_of_pool_ta && num_rep>1 ) {
		# pool tagaligns from true replicates
		call pool_ta { input :
			tas = ta_,
		}
		call pool_ta as pool_ta_high { input :
			tas = ta_high_,
		}
		call pool_ta as pool_ta_low { input :
			tas = ta_low_,
		}
	}

	# if there are pr1 TAs for ALL replicates then pool them
	Boolean has_all_inputs_of_pool_ta_pr1 = length(select_all(spr.ta_pr1))==num_rep
	if ( has_all_inputs_of_pool_ta_pr1 && num_rep>1 && !align_only && !true_rep_only ) {
		# pool tagaligns from pseudo replicate 1
		call pool_ta as pool_ta_pr1 { input :
			tas = spr.ta_pr1,
		}
		call pool_ta as pool_ta_pr1_high { input :
			tas = spr_high.ta_pr1,
		}
		call pool_ta as pool_ta_pr1_low { input :
			tas = spr_low.ta_pr1,
		}
	}

	# if there are pr2 TAs for ALL replicates then pool them
	Boolean has_all_inputs_of_pool_ta_pr2 = length(select_all(spr.ta_pr2))==num_rep
	if ( has_all_inputs_of_pool_ta_pr1 && num_rep>1 && !align_only && !true_rep_only ) {
		# pool tagaligns from pseudo replicate 2
		call pool_ta as pool_ta_pr2 { input :
			tas = spr.ta_pr2,
		}
		call pool_ta as pool_ta_pr2_high { input :
			tas = spr_high.ta_pr2,
		}
		call pool_ta as pool_ta_pr2_low { input :
			tas = spr_low.ta_pr2,
		}
	}

	# if there are CTL TAs for ALL replicates then pool them
	Boolean has_all_inputs_of_pool_ta_ctl = length(select_all(ctl_ta_))==num_ctl
	if ( has_all_inputs_of_pool_ta_ctl && num_ctl>1 ) {
		# pool tagaligns from true replicates
		call pool_ta as pool_ta_ctl { input :
			tas = ctl_ta_,
		}
	}

	Boolean has_input_of_jsd = defined(blacklist_) &&
		length(select_all(nodup_bam_))==num_rep
	if ( has_input_of_jsd && num_rep > 0 && enable_jsd ) {
		# fingerprint and JS-distance plot
		call jsd { input :
			nodup_bams = nodup_bam_,
			blacklist = blacklist_,
			mapq_thresh = mapq_thresh_,

			cpu = jsd_cpu,
			mem_mb = jsd_mem_mb,
			time_hr = jsd_time_hr,
			disks = jsd_disks,
		}
	}

	Boolean has_all_input_of_choose_ctl = length(select_all(ta_))==num_rep
		&& length(select_all(ctl_ta_))==num_ctl && num_ctl > 0
	if ( has_all_input_of_choose_ctl ) {
		# choose appropriate control for each exp IP replicate
		# outputs:
		# 	choose_ctl.idx : control replicate index for each exp replicate 
		#					-1 means pooled ctl replicate
		call choose_ctl { input:
			tas = ta_,
			ctl_tas = ctl_ta_,
			ta_pooled = pool_ta.ta_pooled,
			ctl_ta_pooled = pool_ta_ctl.ta_pooled,
			always_use_pooled_ctl = always_use_pooled_ctl,
			ctl_depth_ratio = ctl_depth_ratio,
		}
	}
	# make control ta array [[1,2,3,4]] -> [[1],[2],[3],[4]], will be zipped with exp ta array latter
	Array[Array[File]] chosen_ctl_tas =
		if has_all_input_of_choose_ctl then transpose(select_all([choose_ctl.chosen_ctl_tas]))
		else [[],[],[],[],[],[],[],[],[],[]]


	# actually not an array
	Array[File?] chosen_ctl_ta_pooled = if !has_all_input_of_choose_ctl then []
		else if num_ctl < 2 then [ctl_ta_[0]] # choose first (only) control
		else select_all([pool_ta_ctl.ta_pooled]) # choose pooled control

	Boolean has_input_of_count_signal_track_pooled = defined(pool_ta.ta_pooled)
	if ( has_input_of_count_signal_track_pooled && enable_count_signal_track && num_rep>1 ) {
		call count_signal_track as count_signal_track_pooled { input :
			ta = pool_ta.ta_pooled,
			chrsz = chrsz_,
		}
	}

	# we have all tas and ctl_tas (optional for histone chipseq) ready, let's call peaks
	scatter(i in range(num_rep)) {
		Boolean has_input_of_call_peak = defined(ta_[i])
		if ( has_input_of_call_peak && !align_only ) {
			call call_peak { input :
				peak_caller = peak_caller_,
				peak_type = peak_type_,
				smooth_win = smooth_win,
				custom_call_peak_py = custom_call_peak_py,
				tas = flatten([[ta_[i]], chosen_ctl_tas[i]]),
				gensz = gensz_,
				chrsz = chrsz_,
				cap_num_peak = cap_num_peak_,
				pval_thresh = pval_thresh,
				blacklist = blacklist_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,

				cpu = call_peak_cpu,
				mem_mb = call_peak_mem_mb,
				disks = call_peak_disks,
				time_hr = call_peak_time_hr,
			}
			call call_peak as call_peak_high { input :
				peak_caller = peak_caller_,
				peak_type = peak_type_,
				smooth_win = smooth_win,
				custom_call_peak_py = custom_call_peak_py,
				tas = flatten([[ta_high_[i]], chosen_ctl_tas[i]]),
				gensz = gensz_,
				chrsz = chrsz_,
				cap_num_peak = cap_num_peak_,
				pval_thresh = pval_thresh,
				blacklist = blacklist_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,

				cpu = call_peak_cpu,
				mem_mb = call_peak_mem_mb,
				disks = call_peak_disks,
				time_hr = call_peak_time_hr,
			}
			call call_peak as call_peak_low { input :
				peak_caller = peak_caller_,
				peak_type = peak_type_,
				smooth_win = smooth_win,
				custom_call_peak_py = custom_call_peak_py,
				tas = flatten([[ta_low_[i]], chosen_ctl_tas[i]]),
				gensz = gensz_,
				chrsz = chrsz_,
				cap_num_peak = cap_num_peak_,
				pval_thresh = pval_thresh,
				blacklist = blacklist_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,

				cpu = call_peak_cpu,
				mem_mb = call_peak_mem_mb,
				disks = call_peak_disks,
				time_hr = call_peak_time_hr,
			}
		}
		File? peak_ = call_peak.peak
		File? peak_high_ = call_peak_high.peak
		File? peak_low_ = call_peak_low.peak

		# signal track
		if ( has_input_of_call_peak && !align_only ) {
			call macs2_signal_track { input :
				tas = flatten([[ta_[i]], chosen_ctl_tas[i]]),
				gensz = gensz_,
				chrsz = chrsz_,
				pval_thresh = pval_thresh,
				smooth_win = smooth_win,

				mem_mb = macs2_signal_track_mem_mb,
				disks = macs2_signal_track_disks,
				time_hr = macs2_signal_track_time_hr,
			}
		}

		# call peaks on 1st pseudo replicated tagalign
		Boolean has_input_of_call_peak_pr1 = defined(spr.ta_pr1[i])
		if ( has_input_of_call_peak_pr1 && !true_rep_only ) {
			call call_peak as call_peak_pr1 { input :
				peak_caller = peak_caller_,
				peak_type = peak_type_,
				smooth_win = smooth_win,
				custom_call_peak_py = custom_call_peak_py,
				tas = flatten([[spr.ta_pr1[i]], chosen_ctl_tas[i]]),
				gensz = gensz_,
				chrsz = chrsz_,
				cap_num_peak = cap_num_peak_,
				pval_thresh = pval_thresh,
				blacklist = blacklist_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
	
				cpu = call_peak_cpu,
				mem_mb = call_peak_mem_mb,
				disks = call_peak_disks,
				time_hr = call_peak_time_hr,
			}
			call call_peak as call_peak_pr1_high { input :
				peak_caller = peak_caller_,
				peak_type = peak_type_,
				smooth_win = smooth_win,
				custom_call_peak_py = custom_call_peak_py,
				tas = flatten([[spr_high.ta_pr1[i]], chosen_ctl_tas[i]]),
				gensz = gensz_,
				chrsz = chrsz_,
				cap_num_peak = cap_num_peak_,
				pval_thresh = pval_thresh,
				blacklist = blacklist_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
	
				cpu = call_peak_cpu,
				mem_mb = call_peak_mem_mb,
				disks = call_peak_disks,
				time_hr = call_peak_time_hr,
			}
			call call_peak as call_peak_pr1_low { input :
				peak_caller = peak_caller_,
				peak_type = peak_type_,
				smooth_win = smooth_win,
				custom_call_peak_py = custom_call_peak_py,
				tas = flatten([[spr_low.ta_pr1[i]], chosen_ctl_tas[i]]),
				gensz = gensz_,
				chrsz = chrsz_,
				cap_num_peak = cap_num_peak_,
				pval_thresh = pval_thresh,
				blacklist = blacklist_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
	
				cpu = call_peak_cpu,
				mem_mb = call_peak_mem_mb,
				disks = call_peak_disks,
				time_hr = call_peak_time_hr,
			}
		}
		File? peak_pr1_ = call_peak_pr1.peak
		File? peak_pr1_high_ = call_peak_pr1_high.peak
		File? peak_pr1_low_ = call_peak_pr1_low.peak

		# call peaks on 2nd pseudo replicated tagalign
		Boolean has_input_of_call_peak_pr2 = defined(spr.ta_pr2[i])
		if ( has_input_of_call_peak_pr2 && !true_rep_only ) {
			call call_peak as call_peak_pr2 { input :
				peak_caller = peak_caller_,
				peak_type = peak_type_,
				smooth_win = smooth_win,
				custom_call_peak_py = custom_call_peak_py,
				tas = flatten([[spr.ta_pr2[i]], chosen_ctl_tas[i]]),
				gensz = gensz_,
				chrsz = chrsz_,
				cap_num_peak = cap_num_peak_,
				pval_thresh = pval_thresh,
				blacklist = blacklist_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,

				cpu = call_peak_cpu,
				mem_mb = call_peak_mem_mb,
				disks = call_peak_disks,
				time_hr = call_peak_time_hr,
			}
			call call_peak as call_peak_pr2_high { input :
				peak_caller = peak_caller_,
				peak_type = peak_type_,
				smooth_win = smooth_win,
				custom_call_peak_py = custom_call_peak_py,
				tas = flatten([[spr_high.ta_pr2[i]], chosen_ctl_tas[i]]),
				gensz = gensz_,
				chrsz = chrsz_,
				cap_num_peak = cap_num_peak_,
				pval_thresh = pval_thresh,
				blacklist = blacklist_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,

				cpu = call_peak_cpu,
				mem_mb = call_peak_mem_mb,
				disks = call_peak_disks,
				time_hr = call_peak_time_hr,
			}
			call call_peak as call_peak_pr2_low { input :
				peak_caller = peak_caller_,
				peak_type = peak_type_,
				smooth_win = smooth_win,
				custom_call_peak_py = custom_call_peak_py,
				tas = flatten([[spr_low.ta_pr2[i]], chosen_ctl_tas[i]]),
				gensz = gensz_,
				chrsz = chrsz_,
				cap_num_peak = cap_num_peak_,
				pval_thresh = pval_thresh,
				blacklist = blacklist_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,

				cpu = call_peak_cpu,
				mem_mb = call_peak_mem_mb,
				disks = call_peak_disks,
				time_hr = call_peak_time_hr,
			}
		}
		File? peak_pr2_ = call_peak_pr2.peak
		File? peak_pr2_high_ = call_peak_pr2_high.peak
		File? peak_pr2_low_ = call_peak_pr2_low.peak
	}

	Boolean has_input_of_call_peak_pooled = defined(pool_ta.ta_pooled)
	if ( has_input_of_call_peak_pooled && !align_only && num_rep>1 ) {
		# call peaks on pooled replicate
		# always call peaks for pooled replicate to get signal tracks
		call call_peak as call_peak_pooled { input :
			peak_caller = peak_caller_,
			peak_type = peak_type_,
			smooth_win = smooth_win,
			custom_call_peak_py = custom_call_peak_py,
			tas = flatten([select_all([pool_ta.ta_pooled]), chosen_ctl_ta_pooled]),
			gensz = gensz_,
			chrsz = chrsz_,
			cap_num_peak = cap_num_peak_,
			pval_thresh = pval_thresh,
			blacklist = blacklist_,
			regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,

			cpu = call_peak_cpu,
			mem_mb = call_peak_mem_mb,
			disks = call_peak_disks,
			time_hr = call_peak_time_hr,
		}
		call call_peak as call_peak_pooled_high { input :
			peak_caller = peak_caller_,
			peak_type = peak_type_,
			smooth_win = smooth_win,
			custom_call_peak_py = custom_call_peak_py,
			tas = flatten([select_all([pool_ta_high.ta_pooled]), chosen_ctl_ta_pooled]),
			gensz = gensz_,
			chrsz = chrsz_,
			cap_num_peak = cap_num_peak_,
			pval_thresh = pval_thresh,
			blacklist = blacklist_,
			regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,

			cpu = call_peak_cpu,
			mem_mb = call_peak_mem_mb,
			disks = call_peak_disks,
			time_hr = call_peak_time_hr,
		}
		call call_peak as call_peak_pooled_low { input :
			peak_caller = peak_caller_,
			peak_type = peak_type_,
			smooth_win = smooth_win,
			custom_call_peak_py = custom_call_peak_py,
			tas = flatten([select_all([pool_ta_low.ta_pooled]), chosen_ctl_ta_pooled]),
			gensz = gensz_,
			chrsz = chrsz_,
			cap_num_peak = cap_num_peak_,
			pval_thresh = pval_thresh,
			blacklist = blacklist_,
			regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,

			cpu = call_peak_cpu,
			mem_mb = call_peak_mem_mb,
			disks = call_peak_disks,
			time_hr = call_peak_time_hr,
		}
	}
	File? peak_pooled_ = call_peak_pooled.peak
	File? peak_pooled_high_ = call_peak_pooled_high.peak
	File? peak_pooled_low_ = call_peak_pooled_low.peak

	# macs2 signal track for pooled rep
	if ( has_input_of_call_peak_pooled && !align_only && num_rep>1 ) {
		call macs2_signal_track as macs2_signal_track_pooled { input :
			tas = flatten([select_all([pool_ta.ta_pooled]), chosen_ctl_ta_pooled]),
			gensz = gensz_,
			chrsz = chrsz_,
			pval_thresh = pval_thresh,
			smooth_win = smooth_win,

			mem_mb = macs2_signal_track_mem_mb,
			disks = macs2_signal_track_disks,
			time_hr = macs2_signal_track_time_hr,
		}
	}

	Boolean has_input_of_call_peak_ppr1 = defined(pool_ta_pr1.ta_pooled)
	if ( has_input_of_call_peak_ppr1 && !align_only && !true_rep_only && num_rep>1 ) {
		# call peaks on 1st pooled pseudo replicates
		call call_peak as call_peak_ppr1 { input :
			peak_caller = peak_caller_,
			peak_type = peak_type_,
			smooth_win = smooth_win,
			custom_call_peak_py = custom_call_peak_py,
			tas = flatten([select_all([pool_ta_pr1.ta_pooled]), chosen_ctl_ta_pooled]),
			gensz = gensz_,
			chrsz = chrsz_,
			cap_num_peak = cap_num_peak_,
			pval_thresh = pval_thresh,
			blacklist = blacklist_,
			regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,

			cpu = call_peak_cpu,
			mem_mb = call_peak_mem_mb,
			disks = call_peak_disks,
			time_hr = call_peak_time_hr,
		}
		call call_peak as call_peak_ppr1_high { input :
			peak_caller = peak_caller_,
			peak_type = peak_type_,
			smooth_win = smooth_win,
			custom_call_peak_py = custom_call_peak_py,
			tas = flatten([select_all([pool_ta_pr1_high.ta_pooled]), chosen_ctl_ta_pooled]),
			gensz = gensz_,
			chrsz = chrsz_,
			cap_num_peak = cap_num_peak_,
			pval_thresh = pval_thresh,
			blacklist = blacklist_,
			regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,

			cpu = call_peak_cpu,
			mem_mb = call_peak_mem_mb,
			disks = call_peak_disks,
			time_hr = call_peak_time_hr,
		}
		call call_peak as call_peak_ppr1_low { input :
			peak_caller = peak_caller_,
			peak_type = peak_type_,
			smooth_win = smooth_win,
			custom_call_peak_py = custom_call_peak_py,
			tas = flatten([select_all([pool_ta_pr1_low.ta_pooled]), chosen_ctl_ta_pooled]),
			gensz = gensz_,
			chrsz = chrsz_,
			cap_num_peak = cap_num_peak_,
			pval_thresh = pval_thresh,
			blacklist = blacklist_,
			regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,

			cpu = call_peak_cpu,
			mem_mb = call_peak_mem_mb,
			disks = call_peak_disks,
			time_hr = call_peak_time_hr,
		}
	}
	File? peak_ppr1_ = call_peak_ppr1.peak
	File? peak_ppr1_high_ = call_peak_ppr1_high.peak
	File? peak_ppr1_low_ = call_peak_ppr1_low.peak

	Boolean has_input_of_call_peak_ppr2 = defined(pool_ta_pr2.ta_pooled)
	if ( has_input_of_call_peak_ppr2 && !align_only && !true_rep_only && num_rep>1 ) {
		# call peaks on 2nd pooled pseudo replicates
		call call_peak as call_peak_ppr2 { input :
			peak_caller = peak_caller_,
			peak_type = peak_type_,
			smooth_win = smooth_win,
			custom_call_peak_py = custom_call_peak_py,
			tas = flatten([select_all([pool_ta_pr2.ta_pooled]), chosen_ctl_ta_pooled]),
			gensz = gensz_,
			chrsz = chrsz_,
			cap_num_peak = cap_num_peak_,
			pval_thresh = pval_thresh,
			blacklist = blacklist_,
			regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,

			cpu = call_peak_cpu,
			mem_mb = call_peak_mem_mb,
			disks = call_peak_disks,
			time_hr = call_peak_time_hr,
		}
		call call_peak as call_peak_ppr2_high { input :
			peak_caller = peak_caller_,
			peak_type = peak_type_,
			smooth_win = smooth_win,
			custom_call_peak_py = custom_call_peak_py,
			tas = flatten([select_all([pool_ta_pr2_high.ta_pooled]), chosen_ctl_ta_pooled]),
			gensz = gensz_,
			chrsz = chrsz_,
			cap_num_peak = cap_num_peak_,
			pval_thresh = pval_thresh,
			blacklist = blacklist_,
			regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,

			cpu = call_peak_cpu,
			mem_mb = call_peak_mem_mb,
			disks = call_peak_disks,
			time_hr = call_peak_time_hr,
		}
		call call_peak as call_peak_ppr2_low { input :
			peak_caller = peak_caller_,
			peak_type = peak_type_,
			smooth_win = smooth_win,
			custom_call_peak_py = custom_call_peak_py,
			tas = flatten([select_all([pool_ta_pr2_low.ta_pooled]), chosen_ctl_ta_pooled]),
			gensz = gensz_,
			chrsz = chrsz_,
			cap_num_peak = cap_num_peak_,
			pval_thresh = pval_thresh,
			blacklist = blacklist_,
			regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,

			cpu = call_peak_cpu,
			mem_mb = call_peak_mem_mb,
			disks = call_peak_disks,
			time_hr = call_peak_time_hr,
		}
	}
	File? peak_ppr2_ = call_peak_ppr2.peak
	File? peak_ppr2_high_ = call_peak_ppr2_high.peak
	File? peak_ppr2_low_ = call_peak_ppr2_low.peak

	# do IDR/overlap on all pairs of two replicates (i,j)
	# 	where i and j are zero-based indices and 0 <= i < j < num_rep
	Array[Pair[Int, Int]] pairs_ = cross(range(num_rep),range(num_rep))
	scatter( pair in pairs_ ) {
		Pair[Int, Int]? null_pair
		Pair[Int, Int]? pairs__ = if pair.left<pair.right then pair else null_pair
	}
	Array[Pair[Int, Int]] pairs = select_all(pairs__)

	if ( !align_only ) {
		scatter( pair in pairs ) {
			# pair.left = 0-based index of 1st replicate
			# pair.right = 0-based index of 2nd replicate
			# Naive overlap on every pair of true replicates
			call overlap { input :
				prefix = 'rep'+(pair.left+1)+'_vs_rep'+(pair.right+1),
				peak1 = peak_[pair.left],
				peak2 = peak_[pair.right],
				peak_pooled = peak_pooled_,
				peak_type = peak_type_,
				blacklist = blacklist_,
				chrsz = chrsz_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
				ta = pool_ta.ta_pooled,
			}
			call overlap as overlap_high { input :
				prefix = 'rep'+(pair.left+1)+'_vs_rep'+(pair.right+1),
				peak1 = peak_high_[pair.left],
				peak2 = peak_high_[pair.right],
				peak_pooled = peak_pooled_high_,
				peak_type = peak_type_,
				blacklist = blacklist_,
				chrsz = chrsz_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
				ta = pool_ta_high.ta_pooled,
			}
			call overlap as overlap_low { input :
				prefix = 'rep'+(pair.left+1)+'_vs_rep'+(pair.right+1),
				peak1 = peak_low_[pair.left],
				peak2 = peak_low_[pair.right],
				peak_pooled = peak_pooled_low_,
				peak_type = peak_type_,
				blacklist = blacklist_,
				chrsz = chrsz_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
				ta = pool_ta_low.ta_pooled,
			}
		}
	}

	if ( enable_idr && !align_only ) {
		scatter( pair in pairs ) {
			# pair.left = 0-based index of 1st replicate
			# pair.right = 0-based index of 2nd replicate
			# IDR on every pair of true replicates
			call idr { input :
				prefix = 'rep'+(pair.left+1)+'_vs_rep'+(pair.right+1),
				peak1 = peak_[pair.left],
				peak2 = peak_[pair.right],
				peak_pooled = peak_pooled_,
				idr_thresh = idr_thresh,
				peak_type = peak_type_,
				rank = idr_rank_,
				blacklist = blacklist_,
				chrsz = chrsz_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
				ta = pool_ta.ta_pooled,
			}
			call idr as idr_high { input :
				prefix = 'rep'+(pair.left+1)+'_vs_rep'+(pair.right+1),
				peak1 = peak_high_[pair.left],
				peak2 = peak_high_[pair.right],
				peak_pooled = peak_pooled_high_,
				idr_thresh = idr_thresh,
				peak_type = peak_type_,
				rank = idr_rank_,
				blacklist = blacklist_,
				chrsz = chrsz_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
				ta = pool_ta_high.ta_pooled,
			}
			call idr as idr_low { input :
				prefix = 'rep'+(pair.left+1)+'_vs_rep'+(pair.right+1),
				peak1 = peak_low_[pair.left],
				peak2 = peak_low_[pair.right],
				peak_pooled = peak_pooled_low_,
				idr_thresh = idr_thresh,
				peak_type = peak_type_,
				rank = idr_rank_,
				blacklist = blacklist_,
				chrsz = chrsz_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
				ta = pool_ta_low.ta_pooled,
			}
		}
	}

	# overlap on pseudo-replicates (pr1, pr2) for each true replicate
	if ( !align_only && !true_rep_only ) {
		scatter( i in range(num_rep) ) {
			call overlap as overlap_pr { input :
				prefix = 'rep'+(i+1)+'-pr1_vs_rep'+(i+1)+'-pr2',
				peak1 = peak_pr1_[i],
				peak2 = peak_pr2_[i],
				peak_pooled = peak_[i],
				peak_type = peak_type_,
				blacklist = blacklist_,
				chrsz = chrsz_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
				ta = ta_[i],
			}
			call overlap as overlap_pr_high { input :
				prefix = 'rep'+(i+1)+'-pr1_vs_rep'+(i+1)+'-pr2',
				peak1 = peak_pr1_high_[i],
				peak2 = peak_pr2_high_[i],
				peak_pooled = peak_high_[i],
				peak_type = peak_type_,
				blacklist = blacklist_,
				chrsz = chrsz_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
				ta = ta_high_[i],
			}
			call overlap as overlap_pr_low { input :
				prefix = 'rep'+(i+1)+'-pr1_vs_rep'+(i+1)+'-pr2',
				peak1 = peak_pr1_low_[i],
				peak2 = peak_pr2_low_[i],
				peak_pooled = peak_low_[i],
				peak_type = peak_type_,
				blacklist = blacklist_,
				chrsz = chrsz_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
				ta = ta_low_[i],
			}
		}
	}

	if ( !align_only && !true_rep_only && enable_idr ) {
		scatter( i in range(num_rep) ) {
			# IDR on pseduo replicates
			call idr as idr_pr { input :
				prefix = 'rep'+(i+1)+'-pr1_vs_rep'+(i+1)+'-pr2',
				peak1 = peak_pr1_[i],
				peak2 = peak_pr2_[i],
				peak_pooled = peak_[i],
				idr_thresh = idr_thresh,
				peak_type = peak_type_,
				rank = idr_rank_,
				blacklist = blacklist_,
				chrsz = chrsz_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
				ta = ta_[i],
			}
			call idr as idr_pr_high { input :
				prefix = 'rep'+(i+1)+'-pr1_vs_rep'+(i+1)+'-pr2',
				peak1 = peak_pr1_high_[i],
				peak2 = peak_pr2_high_[i],
				peak_pooled = peak_high_[i],
				idr_thresh = idr_thresh,
				peak_type = peak_type_,
				rank = idr_rank_,
				blacklist = blacklist_,
				chrsz = chrsz_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
				ta = ta_high_[i],
			}
			call idr as idr_pr_low { input :
				prefix = 'rep'+(i+1)+'-pr1_vs_rep'+(i+1)+'-pr2',
				peak1 = peak_pr1_low_[i],
				peak2 = peak_pr2_low_[i],
				peak_pooled = peak_low_[i],
				idr_thresh = idr_thresh,
				peak_type = peak_type_,
				rank = idr_rank_,
				blacklist = blacklist_,
				chrsz = chrsz_,
				regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
				ta = ta_low_[i],
			}
		}
	}

	if ( !align_only && !true_rep_only && num_rep>1 ) {
		# Naive overlap on pooled pseudo replicates
		call overlap as overlap_ppr { input :
			prefix = 'pooled-pr1_vs_pooled-pr2',
			peak1 = peak_ppr1_,
			peak2 = peak_ppr2_,
			peak_pooled = peak_pooled_,
			peak_type = peak_type_,
			blacklist = blacklist_,
			chrsz = chrsz_,
			regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
			ta = pool_ta.ta_pooled,
		}
		call overlap as overlap_ppr_high { input :
			prefix = 'pooled-pr1_vs_pooled-pr2',
			peak1 = peak_ppr1_high_,
			peak2 = peak_ppr2_high_,
			peak_pooled = peak_pooled_high_,
			peak_type = peak_type_,
			blacklist = blacklist_,
			chrsz = chrsz_,
			regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
			ta = pool_ta_high.ta_pooled,
		}
		call overlap as overlap_ppr_low { input :
			prefix = 'pooled-pr1_vs_pooled-pr2',
			peak1 = peak_ppr1_low_,
			peak2 = peak_ppr2_low_,
			peak_pooled = peak_pooled_low_,
			peak_type = peak_type_,
			blacklist = blacklist_,
			chrsz = chrsz_,
			regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
			ta = pool_ta_low.ta_pooled,
		}
	}

	if ( !align_only && !true_rep_only && num_rep>1 ) {
		# IDR on pooled pseduo replicates
		call idr as idr_ppr { input :
			prefix = 'pooled-pr1_vs_pooled-pr2',
			peak1 = peak_ppr1_,
			peak2 = peak_ppr2_,
			peak_pooled = peak_pooled_,
			idr_thresh = idr_thresh,
			peak_type = peak_type_,
			rank = idr_rank_,
			blacklist = blacklist_,
			chrsz = chrsz_,
			regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
			ta = pool_ta.ta_pooled,
		}
		call idr as idr_ppr_high { input :
			prefix = 'pooled-pr1_vs_pooled-pr2',
			peak1 = peak_ppr1_high_,
			peak2 = peak_ppr2_high_,
			peak_pooled = peak_pooled_high_,
			idr_thresh = idr_thresh,
			peak_type = peak_type_,
			rank = idr_rank_,
			blacklist = blacklist_,
			chrsz = chrsz_,
			regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
			ta = pool_ta_high.ta_pooled,
		}
		call idr as idr_ppr_low { input :
			prefix = 'pooled-pr1_vs_pooled-pr2',
			peak1 = peak_ppr1_low_,
			peak2 = peak_ppr2_low_,
			peak_pooled = peak_pooled_low_,
			idr_thresh = idr_thresh,
			peak_type = peak_type_,
			rank = idr_rank_,
			blacklist = blacklist_,
			chrsz = chrsz_,
			regex_bfilt_peak_chr_name = regex_bfilt_peak_chr_name_,
			ta = pool_ta_low.ta_pooled,
		}
	}

	# reproducibility QC for overlap/IDR peaks
	if ( !align_only && !true_rep_only && num_rep > 0 ) {
		# reproducibility QC for overlapping peaks
		call reproducibility as reproducibility_overlap { input :
			prefix = 'overlap',
			peaks = overlap.bfilt_overlap_peak,
			peaks_pr = overlap_pr.bfilt_overlap_peak,
			peak_ppr = overlap_ppr.bfilt_overlap_peak,
			peak_type = peak_type_,
			chrsz = chrsz_,
		}
		call reproducibility as reproducibility_overlap_high { input :
			prefix = 'overlap',
			peaks = overlap_high.bfilt_overlap_peak,
			peaks_pr = overlap_pr_high.bfilt_overlap_peak,
			peak_ppr = overlap_ppr_high.bfilt_overlap_peak,
			peak_type = peak_type_,
			chrsz = chrsz_,
		}
		call reproducibility as reproducibility_overlap_low { input :
			prefix = 'overlap',
			peaks = overlap_low.bfilt_overlap_peak,
			peaks_pr = overlap_pr_low.bfilt_overlap_peak,
			peak_ppr = overlap_ppr_low.bfilt_overlap_peak,
			peak_type = peak_type_,
			chrsz = chrsz_,
		}
	}

	if ( !align_only && !true_rep_only && num_rep > 0 && enable_idr ) {
		# reproducibility QC for IDR peaks
		call reproducibility as reproducibility_idr { input :
			prefix = 'idr',
			peaks = idr.bfilt_idr_peak,
			peaks_pr = idr_pr.bfilt_idr_peak,
			peak_ppr = idr_ppr.bfilt_idr_peak,
			peak_type = peak_type_,
			chrsz = chrsz_,
		}
		call reproducibility as reproducibility_idr_high { input :
			prefix = 'idr',
			peaks = idr_high.bfilt_idr_peak,
			peaks_pr = idr_pr_high.bfilt_idr_peak,
			peak_ppr = idr_ppr_high.bfilt_idr_peak,
			peak_type = peak_type_,
			chrsz = chrsz_,
		}
		call reproducibility as reproducibility_idr_low { input :
			prefix = 'idr',
			peaks = idr_low.bfilt_idr_peak,
			peaks_pr = idr_pr_low.bfilt_idr_peak,
			peak_ppr = idr_ppr_low.bfilt_idr_peak,
			peak_type = peak_type_,
			chrsz = chrsz_,
		}
	}

	# Generate final QC report and JSON
	call qc_report { input :
		pipeline_ver = pipeline_ver,
		title = title,
		description = description,
		genome = genome_name_,
		multimapping = multimapping,
		paired_ends = paired_end_,
		ctl_paired_ends = ctl_paired_end_,
		pipeline_type = pipeline_type,
		aligner = aligner_,
		peak_caller = peak_caller_,
		cap_num_peak = cap_num_peak_,
		idr_thresh = idr_thresh,
		pval_thresh = pval_thresh,
		xcor_subsample_reads = xcor_subsample_reads,

		samstat_qcs = align.samstat_qc,
		nodup_samstat_qcs = filter.samstat_qc,

		frac_mito_qcs = frac_mito.frac_mito_qc,
		dup_qcs = filter.dup_qc,
		lib_complexity_qcs = filter.lib_complexity_qc,
		xcor_plots = xcor.plot_png,
		xcor_scores = xcor.score,

		jsd_plot = jsd.plot,
		jsd_qcs = jsd.jsd_qcs,

		frip_qcs = call_peak.frip_qc,
		frip_qcs_pr1 = call_peak_pr1.frip_qc,
		frip_qcs_pr2 = call_peak_pr2.frip_qc,

		frip_qc_pooled = call_peak_pooled.frip_qc,
		frip_qc_ppr1 = call_peak_ppr1.frip_qc,
		frip_qc_ppr2 = call_peak_ppr2.frip_qc,

		idr_plots = idr.idr_plot,
		idr_plots_pr = idr_pr.idr_plot,
		idr_plot_ppr = idr_ppr.idr_plot,
		frip_idr_qcs = idr.frip_qc,
		frip_idr_qcs_pr = idr_pr.frip_qc,
		frip_idr_qc_ppr = idr_ppr.frip_qc,
		frip_overlap_qcs = overlap.frip_qc,
		frip_overlap_qcs_pr = overlap_pr.frip_qc,
		frip_overlap_qc_ppr = overlap_ppr.frip_qc,
		idr_reproducibility_qc = reproducibility_idr.reproducibility_qc,
		overlap_reproducibility_qc = reproducibility_overlap.reproducibility_qc,

		annot_enrich_qcs = annot_enrich.annot_enrich_qc,
		tss_enrich_qcs = tss_enrich.tss_enrich_qc,
		tss_large_plots = tss_enrich.tss_large_plot,
		fraglen_dist_plots = fraglen_stat_pe.fraglen_dist_plot,
		fraglen_nucleosomal_qcs = fraglen_stat_pe.nucleosomal_qc,
		gc_plots = gc_bias.gc_plot,
		preseq_plots = preseq.preseq_plot,
		picard_est_lib_size_qcs = preseq.picard_est_lib_size_qc,

		peak_region_size_qcs = call_peak.peak_region_size_qc,
		peak_region_size_plots = call_peak.peak_region_size_plot,
		num_peak_qcs = call_peak.num_peak_qc,

		idr_opt_peak_region_size_qc = reproducibility_idr.peak_region_size_qc,
		idr_opt_peak_region_size_plot = reproducibility_overlap.peak_region_size_plot,
		idr_opt_num_peak_qc = reproducibility_idr.num_peak_qc,

		overlap_opt_peak_region_size_qc = reproducibility_overlap.peak_region_size_qc,
		overlap_opt_peak_region_size_plot = reproducibility_overlap.peak_region_size_plot,
		overlap_opt_num_peak_qc = reproducibility_overlap.num_peak_qc,
	}

	if ( !align_only ) {
		call qc_report as qc_report_high { input :
			pipeline_ver = pipeline_ver,
			title = title + ' (high)',
			description = description + ' (high)',
			genome = genome_name_,
			multimapping = multimapping,
			paired_ends = paired_end_,
			ctl_paired_ends = ctl_paired_end_,
			pipeline_type = pipeline_type,
			aligner = aligner_,
			peak_caller = peak_caller_,
			cap_num_peak = cap_num_peak_,
			idr_thresh = idr_thresh,
			pval_thresh = pval_thresh,
			xcor_subsample_reads = xcor_subsample_reads,

			samstat_qcs = [],
			nodup_samstat_qcs = [],

			frac_mito_qcs = [],
			dup_qcs = [],
			lib_complexity_qcs = [],
			xcor_plots = [],
			xcor_scores = [],

			annot_enrich_qcs = [],
			tss_enrich_qcs = [],
			tss_large_plots = [],
			fraglen_dist_plots = [],
			fraglen_nucleosomal_qcs = [],
			gc_plots = [],
			preseq_plots = [],
			picard_est_lib_size_qcs = [],

			frip_qcs = call_peak_high.frip_qc,
			frip_qcs_pr1 = call_peak_pr1_high.frip_qc,
			frip_qcs_pr2 = call_peak_pr2_high.frip_qc,

			frip_qc_pooled = call_peak_pooled_high.frip_qc,
			frip_qc_ppr1 = call_peak_ppr1_high.frip_qc,
			frip_qc_ppr2 = call_peak_ppr2_high.frip_qc,

			idr_plots = idr_high.idr_plot,
			idr_plots_pr = idr_pr_high.idr_plot,
			idr_plot_ppr = idr_ppr_high.idr_plot,
			frip_idr_qcs = idr_high.frip_qc,
			frip_idr_qcs_pr = idr_pr_high.frip_qc,
			frip_idr_qc_ppr = idr_ppr_high.frip_qc,
			frip_overlap_qcs = overlap_high.frip_qc,
			frip_overlap_qcs_pr = overlap_pr_high.frip_qc,
			frip_overlap_qc_ppr = overlap_ppr_high.frip_qc,
			idr_reproducibility_qc = reproducibility_idr_high.reproducibility_qc,
			overlap_reproducibility_qc = reproducibility_overlap_high.reproducibility_qc,

			peak_region_size_qcs = call_peak_high.peak_region_size_qc,
			peak_region_size_plots = call_peak_high.peak_region_size_plot,
			num_peak_qcs = call_peak_high.num_peak_qc,

			idr_opt_peak_region_size_qc = reproducibility_idr_high.peak_region_size_qc,
			idr_opt_peak_region_size_plot = reproducibility_overlap_high.peak_region_size_plot,
			idr_opt_num_peak_qc = reproducibility_idr_high.num_peak_qc,

			overlap_opt_peak_region_size_qc = reproducibility_overlap_high.peak_region_size_qc,
			overlap_opt_peak_region_size_plot = reproducibility_overlap_high.peak_region_size_plot,
			overlap_opt_num_peak_qc = reproducibility_overlap_high.num_peak_qc,
		}
		call qc_report as qc_report_low { input :
			pipeline_ver = pipeline_ver,
			title = title + ' (low)',
			description = description + ' (low)',
			genome = genome_name_,
			multimapping = multimapping,
			paired_ends = paired_end_,
			ctl_paired_ends = ctl_paired_end_,
			pipeline_type = pipeline_type,
			aligner = aligner_,
			peak_caller = peak_caller_,
			cap_num_peak = cap_num_peak_,
			idr_thresh = idr_thresh,
			pval_thresh = pval_thresh,
			xcor_subsample_reads = xcor_subsample_reads,

			samstat_qcs = [],
			nodup_samstat_qcs = [],

			frac_mito_qcs = [],
			dup_qcs = [],
			lib_complexity_qcs = [],
			xcor_plots = [],
			xcor_scores = [],

			annot_enrich_qcs = [],
			tss_enrich_qcs = [],
			tss_large_plots = [],
			fraglen_dist_plots = [],
			fraglen_nucleosomal_qcs = [],
			gc_plots = [],
			preseq_plots = [],
			picard_est_lib_size_qcs = [],

			frip_qcs = call_peak_low.frip_qc,
			frip_qcs_pr1 = call_peak_pr1_low.frip_qc,
			frip_qcs_pr2 = call_peak_pr2_low.frip_qc,

			frip_qc_pooled = call_peak_pooled_low.frip_qc,
			frip_qc_ppr1 = call_peak_ppr1_low.frip_qc,
			frip_qc_ppr2 = call_peak_ppr2_low.frip_qc,

			idr_plots = idr_low.idr_plot,
			idr_plots_pr = idr_pr_low.idr_plot,
			idr_plot_ppr = idr_ppr_low.idr_plot,
			frip_idr_qcs = idr_low.frip_qc,
			frip_idr_qcs_pr = idr_pr_low.frip_qc,
			frip_idr_qc_ppr = idr_ppr_low.frip_qc,
			frip_overlap_qcs = overlap_low.frip_qc,
			frip_overlap_qcs_pr = overlap_pr_low.frip_qc,
			frip_overlap_qc_ppr = overlap_ppr_low.frip_qc,
			idr_reproducibility_qc = reproducibility_idr_low.reproducibility_qc,
			overlap_reproducibility_qc = reproducibility_overlap_low.reproducibility_qc,

			peak_region_size_qcs = call_peak_low.peak_region_size_qc,
			peak_region_size_plots = call_peak_low.peak_region_size_plot,
			num_peak_qcs = call_peak_low.num_peak_qc,

			idr_opt_peak_region_size_qc = reproducibility_idr_low.peak_region_size_qc,
			idr_opt_peak_region_size_plot = reproducibility_overlap_low.peak_region_size_plot,
			idr_opt_num_peak_qc = reproducibility_idr_low.num_peak_qc,

			overlap_opt_peak_region_size_qc = reproducibility_overlap_low.peak_region_size_qc,
			overlap_opt_peak_region_size_plot = reproducibility_overlap_low.peak_region_size_plot,
			overlap_opt_num_peak_qc = reproducibility_overlap_low.num_peak_qc,
		}
	}
	output {
		File report = qc_report.report
		File qc_json = qc_report.qc_json
		Boolean qc_json_ref_match = qc_report.qc_json_ref_match
	}
}

task align {
	Array[File] fastqs_R1 		# [merge_id]
	Array[File] fastqs_R2

	Boolean paired_end

	# for task align
	String aligner
	String mito_chr_name
	File chrsz			# 2-col chromosome sizes file
	File? custom_align_py
	File idx_tar		# reference index tar or tar.gz
	Int multimapping

	# resource
	Int cpu
	Int mem_mb
	Int time_hr
	String disks

	# tmp vars for task trim_adapter
	Array[Array[File]] tmp_fastqs = if paired_end then transpose([fastqs_R1, fastqs_R2])
				else transpose([fastqs_R1])
	command {
		set -e

		# check if pipeline dependencies can be found
		if [[ -z "$(which encode_task_merge_fastq.py 2> /dev/null || true)" ]]
		then
		  echo -e "\n* Error: pipeline dependencies not found." 1>&2
		  echo 'Conda users: Did you activate Conda environment (conda activate encode-chip-seq-pipeline)?' 1>&2
		  echo '    Or did you install Conda and environment correctly (bash scripts/install_conda_env.sh)?' 1>&2
		  echo 'GCP/AWS/Docker users: Did you add --docker flag to Caper command line arg?' 1>&2
		  echo 'Singularity users: Did you add --singularity flag to Caper command line arg?' 1>&2
		  echo -e "\n" 1>&2
		  exit 3
		fi
		python3 $(which encode_task_merge_fastq.py) \
			${write_tsv(tmp_fastqs)} \
			${if paired_end then '--paired-end' else ''} \
			${'--nth ' + 1}

		# align on trimmed/merged fastqs
		if [ '${aligner}' == 'bowtie2' ]; then
			python3 $(which encode_task_bowtie2.py) \
				${idx_tar} \
				R1/*.fastq.gz \
				${if paired_end then 'R2/*.fastq.gz' else ''} \
				${if paired_end then '--paired-end' else ''} \
				${'--multimapping ' + multimapping} \
				${'--nth ' + cpu}
		else
			python3 ${custom_align_py} \
				${idx_tar} \
				R1/*.fastq.gz \
				${if paired_end then 'R2/*.fastq.gz' else ''} \
				${if paired_end then '--paired-end' else ''} \
				${'--multimapping ' + multimapping} \
				${'--nth ' + cpu}
		fi

		python3 $(which encode_task_post_align.py) \
			R1/*.fastq.gz $(ls *.bam) \
			${'--mito-chr-name ' + mito_chr_name} \
			${'--chrsz ' + chrsz} \
			${'--nth ' + cpu}
		rm -rf R1 R2
	}
	output {
		File bam = glob('*.bam')[0]
		File bai = glob('*.bai')[0]
		File samstat_qc = glob('*.samstats.qc')[0]
		File non_mito_samstat_qc = glob('non_mito/*.samstats.qc')[0]
		File read_len_log = glob('*.read_length.txt')[0]
	}
	runtime {
		cpu : cpu
		memory : '${mem_mb} MB'
		time : time_hr
		disks : disks
		preemptible: 0
	}
}

task frac_mito {
	File non_mito_samstat
	File mito_samstat

	command {
		python3 $(which encode_task_frac_mito.py) \
			${non_mito_samstat} ${mito_samstat}
	}
	output {
		File frac_mito_qc = glob('*.frac_mito.qc')[0]
	}
	runtime {
		cpu : 1
		memory : '8000 MB'
		time : 1
		disks : 'local-disk 100 HDD'
	}
}

task filter {
	File bam
	Boolean paired_end
	Int multimapping
	String dup_marker 			# picard.jar MarkDuplicates (picard) or 
								# sambamba markdup (sambamba)
	Int mapq_thresh				# threshold for low MAPQ reads removal
	Array[String] filter_chrs 	# chrs to be removed from final (nodup/filt) BAM
	File chrsz					# 2-col chromosome sizes file
	Boolean no_dup_removal 		# no dupe reads removal when filtering BAM
	String mito_chr_name

	Int cpu
	Int mem_mb
	String picard_java_heap
	Int time_hr
	String disks

	command {
		python3 $(which encode_task_filter.py) \
			${bam} \
			${if paired_end then '--paired-end' else ''} \
			${'--multimapping ' + multimapping} \
			${'--dup-marker ' + dup_marker} \
			${'--mapq-thresh ' + mapq_thresh} \
			--filter-chrs ${sep=' ' filter_chrs} \
			${'--chrsz ' + chrsz} \
			${if no_dup_removal then '--no-dup-removal' else ''} \
			${'--mito-chr-name ' + mito_chr_name} \
			${'--nth ' + cpu} \
			${'--picard-java-heap ' + picard_java_heap}
	}
	output {
		File nodup_bam = glob('*.bam')[0]
		File nodup_bai = glob('*.bai')[0]
		File samstat_qc = glob('*.samstats.qc')[0]
		File dup_qc = glob('*.dup.qc')[0]
		File lib_complexity_qc = glob('*.lib_complexity.qc')[0]
	}
	runtime {
		cpu : cpu
		memory : '${mem_mb} MB'
		time : time_hr
		disks : disks
	}
}

task bam2ta {
	File bam
	Boolean paired_end
	Boolean disable_tn5_shift 	# no tn5 shifting (it's for dnase-seq)
	String mito_chr_name 		# mito chromosome name
	Int subsample 				# number of reads to subsample TAGALIGN
								# this affects all downstream analysis
	Int cpu
	Int mem_mb
	Int time_hr
	String disks

	command {
		python3 $(which encode_task_bam2ta.py) \
			${bam} \
			${if paired_end then '--paired-end' else ''} \
			${if disable_tn5_shift then '--disable-tn5-shift' else ''} \
			${'--mito-chr-name ' + mito_chr_name} \
			${'--subsample ' + subsample} \
			${'--nth ' + cpu}
	}
	output {
		File ta = glob('*.tagAlign.gz')[0]
	}
	runtime {
		cpu : cpu
		memory : '${mem_mb} MB'
		time : time_hr
		disks : disks
	}
}

task spr { # make two self pseudo replicates
	File ta
	Boolean paired_end

	Int mem_mb

	command {
		python3 $(which encode_task_spr.py) \
			${ta} \
			${if paired_end then '--paired-end' else ''}
	}
	output {
		File ta_pr1 = glob('*.pr1.tagAlign.gz')[0]
		File ta_pr2 = glob('*.pr2.tagAlign.gz')[0]
	}
	runtime {
		cpu : 1
		memory : '${mem_mb} MB'
		time : 1
		disks : 'local-disk 50 HDD'
	}
}

task split_ta_by_read_len {
	File ta
	Int split_read_len

	command {
		python3 $(which encode_task_split_ta_by_read_len.py) \
			${ta} \
			${'--split-read-len ' + split_read_len}
	}
	output {
		File ta_high = glob('*.high.tagAlign.gz')[0]
		File ta_low = glob('*.low.tagAlign.gz')[0]
	}
	runtime {
		cpu : 1
		memory : '4096 MB'
		time : 1
		disks : 'local-disk 100 HDD'
	}
}

task pool_ta {
	Array[File?] tas 	# TAG-ALIGNs to be merged
	Int? col 			# number of columns in pooled TA

	command {
		python3 $(which encode_task_pool_ta.py) \
			${sep=' ' tas} \
			${'--col ' + col}
	}
	output {
		File ta_pooled = glob('*.tagAlign.gz')[0]
	}
	runtime {
		cpu : 1
		memory : '4000 MB'
		time : 1
		disks : 'local-disk 50 HDD'
	}
}

task xcor {
	File ta
	Boolean paired_end
	String mito_chr_name
	Int subsample  # number of reads to subsample TAGALIGN
				# this will be used for xcor only
				# will not affect any downstream analysis
	Int cpu
	Int mem_mb	
	Int time_hr
	String disks

	command {
		python3 $(which encode_task_xcor.py) \
			${ta} \
			${if paired_end then '--paired-end' else ''} \
			${'--mito-chr-name ' + mito_chr_name} \
			${'--subsample ' + subsample} \
			--speak=0 \
			${'--nth ' + cpu}
	}
	output {
		File plot_pdf = glob('*.cc.plot.pdf')[0]
		File plot_png = glob('*.cc.plot.png')[0]
		File score = glob('*.cc.qc')[0]
		Int fraglen = read_int(glob('*.cc.fraglen.txt')[0])
	}
	runtime {
		cpu : cpu
		memory : '${mem_mb} MB'
		time : time_hr
		disks : disks
	}
}

task jsd {
	Array[File?] nodup_bams
	File blacklist
	Int mapq_thresh

	Int cpu
	Int mem_mb
	Int time_hr
	String disks

	command {
		python3 $(which encode_task_jsd.py) \
			${sep=' ' nodup_bams} \
			${'--mapq-thresh '+ mapq_thresh} \
			${'--blacklist '+ blacklist} \
			${'--nth ' + cpu}
	}
	output {
		File plot = glob('*.png')[0]
		Array[File] jsd_qcs = glob('*.jsd.qc')
	}
	runtime {
		cpu : cpu
		memory : '${mem_mb} MB'
		time : time_hr
		disks : disks
	}
}

task choose_ctl {
	Array[File?] tas
	Array[File?] ctl_tas
	File? ta_pooled
	File? ctl_ta_pooled
	Boolean always_use_pooled_ctl # always use pooled control for all exp rep.
	Float ctl_depth_ratio 		# if ratio between controls is higher than this
								# then always use pooled control for all exp rep.
	command {
		python3 $(which encode_task_choose_ctl.py) \
			--tas ${sep=' ' tas} \
			--ctl-tas ${sep=' ' ctl_tas} \
			${'--ta-pooled ' + ta_pooled} \
			${'--ctl-ta-pooled ' + ctl_ta_pooled} \
			${if always_use_pooled_ctl then '--always-use-pooled-ctl' else ''} \
			${'--ctl-depth-ratio ' + ctl_depth_ratio}
	}
	output {
		Array[File] chosen_ctl_tas = glob('ctl_for_rep*.tagAlign.gz')
	}
	runtime {
		cpu : 1
		memory : '8000 MB'
		time : 1
		disks : 'local-disk 50 HDD'
	}	
}

task count_signal_track {
	File ta 			# tag-align
	File chrsz			# 2-col chromosome sizes file

	command {
		python3 $(which encode_task_count_signal_track.py) \
			${ta} \
			${'--chrsz ' + chrsz}
	}
	output {
		File pos_bw = glob('*.positive.bigwig')[0]
		File neg_bw = glob('*.negative.bigwig')[0]
	}
	runtime {
		cpu : 1
		memory : '8000 MB'
		time : 4
		disks : 'local-disk 50 HDD'
	}
}

task call_peak {
	String peak_caller
	String peak_type
	File? custom_call_peak_py

	Array[File?] tas	# [ta, control_ta]. control_ta is optional
	String gensz		# Genome size (sum of entries in 2nd column of 
                        # chr. sizes file, or hs for human, ms for mouse)
	File chrsz			# 2-col chromosome sizes file
	Int cap_num_peak	# cap number of raw peaks called from MACS2
	Float pval_thresh  	# p.value threshold
	Int smooth_win 		# size of smoothing window
	File? blacklist 	# blacklist BED to filter raw peaks
	String? regex_bfilt_peak_chr_name

	Int cpu
	Int mem_mb
	Int time_hr
	String disks

	command {
		set -e

		if [ '${peak_caller}' == 'macs2' ]; then
			python2 $(which encode_task_macs2_cut_n_run.py) \
				${sep=' ' tas} \
				${'--gensz ' + gensz} \
				${'--chrsz ' + chrsz} \
				${'--cap-num-peak ' + cap_num_peak} \
				${'--pval-thresh '+ pval_thresh} \
				${'--smooth-win '+ smooth_win}
		else
			python ${custom_call_peak_py} \
				${sep=' ' tas} \
				${'--gensz ' + gensz} \
				${'--chrsz ' + chrsz} \
				${'--cap-num-peak ' + cap_num_peak} \
				${'--pval-thresh '+ pval_thresh} \
				${'--smooth-win '+ smooth_win}
		fi

		python3 $(which encode_task_post_call_peak_cut_n_run.py) \
			$(ls *Peak.gz) \
			${'--ta ' + tas[0]} \
			${'--regex-bfilt-peak-chr-name \'' + regex_bfilt_peak_chr_name + '\''} \
			${'--chrsz ' + chrsz} \
			${'--peak-type ' + peak_type} \
			${'--blacklist ' + blacklist}
	}
	output {
		# generated by custom_call_peak_py
		File peak = glob('*[!.][!b][!f][!i][!l][!t].'+peak_type+'.gz')[0]
		# generated by post_call_peak py
		File bfilt_peak = glob('*.bfilt.'+peak_type+'.gz')[0]
		File bfilt_peak_bb = glob('*.bfilt.'+peak_type+'.bb')[0]
		File bfilt_peak_hammock = glob('*.bfilt.'+peak_type+'.hammock.gz*')[0]
		File bfilt_peak_hammock_tbi = glob('*.bfilt.'+peak_type+'.hammock.gz*')[1]
		File frip_qc = glob('*.frip.qc')[0]
		File peak_region_size_qc = glob('*.peak_region_size.qc')[0]
		File peak_region_size_plot = glob('*.peak_region_size.png')[0]
		File num_peak_qc = glob('*.num_peak.qc')[0]
	}
	runtime {
		cpu : if peak_caller == 'macs2' then 1 else cpu
		memory : '${mem_mb} MB'
		time : time_hr
		disks : disks
	}
}

task macs2_signal_track {
	Array[File?] tas	# [ta, control_ta]. control_ta is optional
	String gensz		# Genome size (sum of entries in 2nd column of 
                        # chr. sizes file, or hs for human, ms for mouse)
	File chrsz			# 2-col chromosome sizes file
	Float pval_thresh  	# p.value threshold
	Int smooth_win 		# size of smoothing window
	
	Int mem_mb
	Int time_hr
	String disks

	command {
		python3 $(which encode_task_macs2_signal_track_cut_n_run.py) \
			${sep=' ' tas} \
			${'--gensz '+ gensz} \
			${'--chrsz ' + chrsz} \
			${'--pval-thresh '+ pval_thresh} \
			${'--smooth-win '+ smooth_win}
	}
	output {
		File pval_bw = glob('*.pval.signal.bigwig')[0]
		File fc_bw = glob('*.fc.signal.bigwig')[0]
	}
	runtime {
		cpu : 1
		memory : '${mem_mb} MB'
		time : time_hr
		disks : disks
	}
}

task idr {
	String prefix 		# prefix for IDR output file
	File peak1 			
	File peak2
	File peak_pooled
	Float idr_thresh
	File? blacklist 	# blacklist BED to filter raw peaks
	String regex_bfilt_peak_chr_name
	# parameters to compute FRiP
	File? ta			# to calculate FRiP
	File chrsz			# 2-col chromosome sizes file
	String peak_type
	String rank

	command {
		${if defined(ta) then '' else 'touch null.frip.qc'}
		touch null
		python3 $(which encode_task_idr.py) \
			${peak1} ${peak2} ${peak_pooled} \
			${'--prefix ' + prefix} \
			${'--idr-thresh ' + idr_thresh} \
			${'--peak-type ' + peak_type} \
			--idr-rank ${rank} \
			${'--chrsz ' + chrsz} \
			${'--blacklist '+ blacklist} \
			${'--regex-bfilt-peak-chr-name \'' + regex_bfilt_peak_chr_name + '\''} \
			${'--ta ' + ta}
	}
	output {
		File idr_peak = glob('*[!.][!b][!f][!i][!l][!t].'+peak_type+'.gz')[0]
		File bfilt_idr_peak = glob('*.bfilt.'+peak_type+'.gz')[0]
		File bfilt_idr_peak_bb = glob('*.bfilt.'+peak_type+'.bb')[0]
		File bfilt_idr_peak_hammock = glob('*.bfilt.'+peak_type+'.hammock.gz*')[0]
		File bfilt_idr_peak_hammock_tbi = glob('*.bfilt.'+peak_type+'.hammock.gz*')[1]
		File idr_plot = glob('*.txt.png')[0]
		File idr_unthresholded_peak = glob('*.txt.gz')[0]
		File idr_log = glob('*.idr*.log')[0]
		File frip_qc = if defined(ta) then glob('*.frip.qc')[0] else glob('null')[0]
	}
	runtime {
		cpu : 1
		memory : '8000 MB'
		time : 1
		disks : 'local-disk 50 HDD'
	}
}

task overlap {
	String prefix 		# prefix for IDR output file
	File peak1
	File peak2
	File peak_pooled
	File? blacklist 	# blacklist BED to filter raw peaks
	String regex_bfilt_peak_chr_name
	File? ta		# to calculate FRiP
	File chrsz			# 2-col chromosome sizes file
	String peak_type

	command {
		${if defined(ta) then '' else 'touch null.frip.qc'}
		touch null 
		python3 $(which encode_task_overlap.py) \
			${peak1} ${peak2} ${peak_pooled} \
			${'--prefix ' + prefix} \
			${'--peak-type ' + peak_type} \
			${'--chrsz ' + chrsz} \
			${'--blacklist '+ blacklist} \
			--nonamecheck \
			${'--regex-bfilt-peak-chr-name \'' + regex_bfilt_peak_chr_name + '\''} \
			${'--ta ' + ta}
	}
	output {
		File overlap_peak = glob('*[!.][!b][!f][!i][!l][!t].'+peak_type+'.gz')[0]
		File bfilt_overlap_peak = glob('*.bfilt.'+peak_type+'.gz')[0]
		File bfilt_overlap_peak_bb = glob('*.bfilt.'+peak_type+'.bb')[0]
		File bfilt_overlap_peak_hammock = glob('*.bfilt.'+peak_type+'.hammock.gz*')[0]
		File bfilt_overlap_peak_hammock_tbi = glob('*.bfilt.'+peak_type+'.hammock.gz*')[1]
		File frip_qc = if defined(ta) then glob('*.frip.qc')[0] else glob('null')[0]
	}
	runtime {
		cpu : 1
		memory : '4000 MB'
		time : 1
		disks : 'local-disk 50 HDD'
	}
}

task reproducibility {
	String prefix
	Array[File]? peaks # peak files from pair of true replicates
						# in a sorted order. for example of 4 replicates,
						# 1,2 1,3 1,4 2,3 2,4 3,4.
                        # x,y means peak file from rep-x vs rep-y
	Array[File?] peaks_pr	# peak files from pseudo replicates
	File? peak_ppr			# Peak file from pooled pseudo replicate.
	String peak_type
	File chrsz			# 2-col chromosome sizes file

	command {
		python3 $(which encode_task_reproducibility.py) \
			${sep=' ' peaks} \
			--peaks-pr ${sep=' ' peaks_pr} \
			${'--peak-ppr '+ peak_ppr} \
			--prefix ${prefix} \
			${'--peak-type ' + peak_type} \
			${'--chrsz ' + chrsz}
	}
	output {
		File optimal_peak = glob('*optimal_peak.*.gz')[0]
		File optimal_peak_bb = glob('*optimal_peak.*.bb')[0]
		File optimal_peak_hammock = glob('*optimal_peak.*.hammock.gz*')[0]
		File optimal_peak_hammock_tbi = glob('*optimal_peak.*.hammock.gz*')[1]
		File conservative_peak = glob('*conservative_peak.*.gz')[0]
		File conservative_peak_bb = glob('*conservative_peak.*.bb')[0]
		File conservative_peak_hammock = glob('*conservative_peak.*.hammock.gz*')[0]
		File conservative_peak_hammock_tbi = glob('*conservative_peak.*.hammock.gz*')[1]
		File reproducibility_qc = glob('*reproducibility.qc')[0]
		# QC metrics for optimal peak
		File peak_region_size_qc = glob('*.peak_region_size.qc')[0]
		File peak_region_size_plot = glob('*.peak_region_size.png')[0]
		File num_peak_qc = glob('*.num_peak.qc')[0]
	}
	runtime {
		cpu : 1
		memory : '4000 MB'
		time : 1
		disks : 'local-disk 50 HDD'
	}
}

task preseq {
	File bam
	Boolean paired_end

	Int mem_mb
	String picard_java_heap	

	File? null_f
	command {
		python3 $(which encode_task_preseq.py) \
			${if paired_end then '--paired-end' else ''} \
			${'--bam ' + bam} \
			${'--picard-java-heap ' + picard_java_heap}
	}
	output {
		File? picard_est_lib_size_qc = if paired_end then 
			glob('*.picard_est_lib_size.qc')[0] else null_f
		File preseq_plot = glob('*.preseq.png')[0]
		File preseq_log = glob('*.preseq.log')[0]
	}
	runtime {
		cpu : 1
		memory : '${mem_mb} MB'
		time : 1
		disks : 'local-disk 100 HDD'
	}
}

task annot_enrich {
	# Fraction of Reads In Annotated Regions
	File ta
	File? blacklist
	File? dnase
	File? prom
	File? enh

	command {
		python3 $(which encode_task_annot_enrich.py) \
			${'--ta ' + ta} \
			${'--blacklist ' + blacklist} \
			${'--dnase ' + dnase} \
			${'--prom ' + prom} \
			${'--enh ' + enh}
	}
	output {
		File annot_enrich_qc = glob('*.annot_enrich.qc')[0]
	}
	runtime {
		cpu : 1
		memory : '8000 MB'
		time : 1
		disks : 'local-disk 100 HDD'
	}
}

task tss_enrich {
	Int? read_len
	File nodup_bam
	File tss
	File chrsz

	command {
		python2 $(which encode_task_tss_enrich.py) \
			${'--read-len ' + read_len} \
			${'--nodup-bam ' + nodup_bam} \
			${'--chrsz ' + chrsz} \
			${'--tss ' + tss}
	}
	output {
		File tss_plot = glob('*.tss_enrich.png')[0]
		File tss_large_plot = glob('*.large_tss_enrich.png')[0]
		File tss_enrich_qc = glob('*.tss_enrich.qc')[0]
		Float tss_enrich = read_float(tss_enrich_qc)
	}
	runtime {
		cpu : 1
		memory : '8000 MB'
		time : 1
		disks : 'local-disk 100 HDD'
	}
}

task fraglen_stat_pe {
	# for PE only
	File nodup_bam

	String picard_java_heap

	command {
		python3 $(which encode_task_fraglen_stat_pe.py) \
			${'--nodup-bam ' + nodup_bam} \
			${'--picard-java-heap ' + picard_java_heap}
	}
	output {
		File nucleosomal_qc = glob('*nucleosomal.qc')[0]
		File fraglen_dist_plot = glob('*fraglen_dist.png')[0]
	}
	runtime {
		cpu : 1
		memory : '8000 MB'
		time : 1
		disks : 'local-disk 100 HDD'
	}
}

task gc_bias {
	File nodup_bam
	File ref_fa

	String picard_java_heap

	command {
		python3 $(which encode_task_gc_bias.py) \
			${'--nodup-bam ' + nodup_bam} \
			${'--ref-fa ' + ref_fa} \
			${'--picard-java-heap ' + picard_java_heap}
	}
	output {
		File gc_plot = glob('*.gc_plot.png')[0]
		File gc_log = glob('*.gc.txt')[0]
	}
	runtime {
		cpu : 1
		memory : '8000 MB'
		time : 1
		disks : 'local-disk 100 HDD'
	}
}

# gather all outputs and generate 
# - qc.html		: organized final HTML report
# - qc.json		: all QCs
task qc_report {
	String pipeline_ver
 	String title
	String description
	String? genome	
	# workflow params
	Int multimapping
	Array[Boolean?] paired_ends
	Array[Boolean?] ctl_paired_ends
	String pipeline_type
	String aligner
	String peak_caller
	Int cap_num_peak
	Float idr_thresh
	Float pval_thresh
	Int xcor_subsample_reads
	# QCs
	Array[File?] frac_mito_qcs
	Array[File?] samstat_qcs
	Array[File?] nodup_samstat_qcs
	Array[File?] dup_qcs
	Array[File?] lib_complexity_qcs
	Array[File?] xcor_plots
	Array[File?] xcor_scores
	File? jsd_plot
	Array[File]? jsd_qcs	
	Array[File]? idr_plots
	Array[File]? idr_plots_pr
	File? idr_plot_ppr
	Array[File?] frip_qcs
	Array[File?] frip_qcs_pr1
	Array[File?] frip_qcs_pr2
	File? frip_qc_pooled
	File? frip_qc_ppr1 
	File? frip_qc_ppr2 
	Array[File]? frip_idr_qcs
	Array[File]? frip_idr_qcs_pr
	File? frip_idr_qc_ppr 
	Array[File]? frip_overlap_qcs
	Array[File]? frip_overlap_qcs_pr
	File? frip_overlap_qc_ppr
	File? idr_reproducibility_qc
	File? overlap_reproducibility_qc

	Array[File?] annot_enrich_qcs
	Array[File?] tss_enrich_qcs
	Array[File?] tss_large_plots
	Array[File?] fraglen_dist_plots
	Array[File?] fraglen_nucleosomal_qcs
	Array[File?] gc_plots
	Array[File?] preseq_plots
	Array[File?] picard_est_lib_size_qcs

	Array[File?] peak_region_size_qcs
	Array[File?] peak_region_size_plots
	Array[File?] num_peak_qcs

	File? idr_opt_peak_region_size_qc
	File? idr_opt_peak_region_size_plot
	File? idr_opt_num_peak_qc

	File? overlap_opt_peak_region_size_qc
	File? overlap_opt_peak_region_size_plot
	File? overlap_opt_num_peak_qc

	File? qc_json_ref

	command {
		python3 $(which encode_task_qc_report.py) \
			${'--pipeline-ver ' + pipeline_ver} \
			${"--title '" + sub(title,"'","_") + "'"} \
			${"--desc '" + sub(description,"'","_") + "'"} \
			${'--genome ' + genome} \
			${'--multimapping ' + multimapping} \
			--paired-ends ${sep=' ' paired_ends} \
			--ctl-paired-ends ${sep=' ' ctl_paired_ends} \			
			--pipeline-type ${pipeline_type} \
			--aligner ${aligner} \
			--peak-caller ${peak_caller} \
			${'--cap-num-peak ' + cap_num_peak} \
			--idr-thresh ${idr_thresh} \
			--pval-thresh ${pval_thresh} \
			--xcor-subsample-reads ${xcor_subsample_reads} \
			--frac-mito-qcs ${sep='_:_' frac_mito_qcs} \
			--samstat-qcs ${sep='_:_' samstat_qcs} \
			--nodup-samstat-qcs ${sep='_:_' nodup_samstat_qcs} \
			--dup-qcs ${sep='_:_' dup_qcs} \
			--lib-complexity-qcs ${sep='_:_' lib_complexity_qcs} \
			--xcor-plots ${sep='_:_' xcor_plots} \
			--xcor-scores ${sep='_:_' xcor_scores} \
			--idr-plots ${sep='_:_' idr_plots} \
			--idr-plots-pr ${sep='_:_' idr_plots_pr} \
			${'--jsd-plot ' + jsd_plot} \
			--jsd-qcs ${sep='_:_' jsd_qcs} \
			${'--idr-plot-ppr ' + idr_plot_ppr} \
			--frip-qcs ${sep='_:_' frip_qcs} \
			--frip-qcs-pr1 ${sep='_:_' frip_qcs_pr1} \
			--frip-qcs-pr2 ${sep='_:_' frip_qcs_pr2} \
			${'--frip-qc-pooled ' + frip_qc_pooled} \
			${'--frip-qc-ppr1 ' + frip_qc_ppr1} \
			${'--frip-qc-ppr2 ' + frip_qc_ppr2} \
			--frip-idr-qcs ${sep='_:_' frip_idr_qcs} \
			--frip-idr-qcs-pr ${sep='_:_' frip_idr_qcs_pr} \
			${'--frip-idr-qc-ppr ' + frip_idr_qc_ppr} \
			--frip-overlap-qcs ${sep='_:_' frip_overlap_qcs} \
			--frip-overlap-qcs-pr ${sep='_:_' frip_overlap_qcs_pr} \
			${'--frip-overlap-qc-ppr ' + frip_overlap_qc_ppr} \
			${'--idr-reproducibility-qc ' + idr_reproducibility_qc} \
			${'--overlap-reproducibility-qc ' + overlap_reproducibility_qc} \
			--annot-enrich-qcs ${sep='_:_' annot_enrich_qcs} \
			--tss-enrich-qcs ${sep='_:_' tss_enrich_qcs} \
			--tss-large-plots ${sep='_:_' tss_large_plots} \
			--fraglen-dist-plots ${sep='_:_' fraglen_dist_plots} \
			--fraglen-nucleosomal-qcs ${sep='_:_' fraglen_nucleosomal_qcs} \
			--gc-plots ${sep='_:_' gc_plots} \
			--preseq-plots ${sep='_:_' preseq_plots} \
			--picard-est-lib-size-qcs ${sep='_:_' picard_est_lib_size_qcs} \
			--peak-region-size-qcs ${sep='_:_' peak_region_size_qcs} \
			--peak-region-size-plots ${sep='_:_' peak_region_size_plots} \
			--num-peak-qcs ${sep='_:_' num_peak_qcs} \
			${'--idr-opt-peak-region-size-qc ' + idr_opt_peak_region_size_qc} \
			${'--idr-opt-peak-region-size-plot ' + idr_opt_peak_region_size_plot} \
			${'--idr-opt-num-peak-qc ' + idr_opt_num_peak_qc} \
			${'--overlap-opt-peak-region-size-qc ' + overlap_opt_peak_region_size_qc} \
			${'--overlap-opt-peak-region-size-plot ' + overlap_opt_peak_region_size_plot} \
			${'--overlap-opt-num-peak-qc ' + overlap_opt_num_peak_qc} \
			--out-qc-html qc.html \
			--out-qc-json qc.json \
			${'--qc-json-ref ' + qc_json_ref}
	}
	output {
		File report = glob('*qc.html')[0]
		File qc_json = glob('*qc.json')[0]
		Boolean qc_json_ref_match = read_string('qc_json_ref_match.txt')=='True'
	}
	runtime {
		cpu : 1
		memory : '4000 MB'
		time : 1
		disks : 'local-disk 50 HDD'		
	}
}

task read_genome_tsv {
	File genome_tsv

	String? null_s
	command <<<
		# create empty files for all entries
		touch genome_name
		touch ref_fa bowtie2_idx_tar bwa_idx_tar chrsz gensz blacklist blacklist2
		touch custom_aligner_idx_tar
		touch ref_mito_fa
		touch bowtie2_mito_idx_tar bwa_mito_idx_tar custom_aligner_mito_idx_tar
		touch tss tss_enrich # for backward compatibility
		touch dnase prom enh reg2map reg2map_bed roadmap_meta
		touch mito_chr_name
		touch regex_bfilt_peak_chr_name

		python <<CODE
		import os
		with open('${genome_tsv}','r') as fp:
			for line in fp:
				arr = line.strip('\n').split('\t')
				if arr:
					key, val = arr
					with open(key,'w') as fp2:
						fp2.write(val)
		CODE
	>>>
	output {
		String? genome_name = if size('genome_name')==0 then basename(genome_tsv) else read_string('genome_name')
		String? ref_fa = if size('ref_fa')==0 then null_s else read_string('ref_fa')
		String? ref_mito_fa = if size('ref_mito_fa')==0 then null_s else read_string('ref_mito_fa')
		String? bwa_idx_tar = if size('bwa_idx_tar')==0 then null_s else read_string('bwa_idx_tar')
		String? bwa_mito_idx_tar = if size('bwa_mito_idx_tar')==0 then null_s else read_string('bwa_mito_idx_tar')
		String? bowtie2_idx_tar = if size('bowtie2_idx_tar')==0 then null_s else read_string('bowtie2_idx_tar')
		String? bowtie2_mito_idx_tar = if size('bowtie2_mito_idx_tar')==0 then null_s else read_string('bowtie2_mito_idx_tar')
		String? custom_aligner_idx_tar = if size('custom_aligner_idx_tar')==0 then null_s else read_string('custom_aligner_idx_tar')
		String? custom_aligner_mito_idx_tar = if size('custom_aligner_mito_idx_tar')==0 then null_s else read_string('custom_aligner_mito_idx_tar')
		String? chrsz = if size('chrsz')==0 then null_s else read_string('chrsz')
		String? gensz = if size('gensz')==0 then null_s else read_string('gensz')
		String? blacklist = if size('blacklist')==0 then null_s else read_string('blacklist')
		String? blacklist2 = if size('blacklist2')==0 then null_s else read_string('blacklist2')
		String? mito_chr_name = if size('mito_chr_name')==0 then null_s else read_string('mito_chr_name')
		String? regex_bfilt_peak_chr_name = if size('regex_bfilt_peak_chr_name')==0 then 'chr[\\dXY]+'
			else read_string('regex_bfilt_peak_chr_name')
		# optional data
		String? tss = if size('tss')!=0 then read_string('tss')
			else if size('tss_enrich')!=0 then read_string('tss_enrich') else null_s
		String? dnase = if size('dnase')==0 then null_s else read_string('dnase')
		String? prom = if size('prom')==0 then null_s else read_string('prom')
		String? enh = if size('enh')==0 then null_s else read_string('enh')
		String? reg2map = if size('reg2map')==0 then null_s else read_string('reg2map')
		String? reg2map_bed = if size('reg2map_bed')==0 then null_s else read_string('reg2map_bed')
		String? roadmap_meta = if size('roadmap_meta')==0 then null_s else read_string('roadmap_meta')
	}
	runtime {
		maxRetries : 0
		cpu : 1
		memory : '4000 MB'
		time : 1
		disks : 'local-disk 50 HDD'		
	}
}

task raise_exception {
	String msg
	command {
		echo -e "\n* Error: ${msg}\n" >&2
		exit 2
	}
	output {
		String error_msg = '${msg}'
	}
	runtime {
		maxRetries : 0
	}
}
