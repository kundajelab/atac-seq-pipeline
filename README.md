# Cut-n-run pipeline

## Introduction

### Features

* **Portability**: The pipeline run can be performed across different cloud platforms such as Google, AWS and DNAnexus, as well as on cluster engines such as SLURM, SGE and PBS.
* **User-friendly HTML report**: In addition to the standard outputs, the pipeline generates an HTML report that consists of a tabular representation of quality metrics including alignment/peak statistics and FRiP along with many useful plots (IDR/TSS enrichment).
* **Supported genomes**: Pipeline needs genome specific data such as aligner indices, chromosome sizes file and blacklist. We provide a genome database downloader/builder for hg38, hg19, mm10, mm9. You can also use this [builder](docs/build_genome_database.md) to build genome database from FASTA for your custom genome.

## Installation

1) Git clone this pipeline.
	> **IMPORTANT*: use `~/cut-n-run-pipeline/cut_n_run.wdl` as `[WDL]` in Caper's documentation.

	```bash
	$ cd
	$ git clone https://github.com/kundajelab/cut-n-run-pipeline
	```

2) Install pipeline's [Conda environment](docs/install_conda.md) if you want to use Conda instead of Docker/Singularity. Conda is recommneded on local computer and HPCs (e.g. Stanford Sherlock/SCG).
	> **IMPORTANT*: use `encode-cut-n-run-pipeline` as `[PIPELINE_CONDA_ENV]` in Caper's documentation.


3) **Skip this step if you have installed pipeline's Conda environment**. Caper is already included in the Conda environment. [Install Caper](https://github.com/ENCODE-DCC/caper#installation). Caper is a python wrapper for [Cromwell](https://github.com/broadinstitute/cromwell).
	> **IMPORTANT**: Make sure that you have python3(> 3.4.1) installed on your system.

	```bash
	$ pip install caper  # use pip3 if it doesn't work
	```

4) Follow [Caper's README](https://github.com/ENCODE-DCC/caper) carefully. Find an instruction for your platform.
	> **IMPORTANT**: Configure your Caper configuration file `~/.caper/default.conf` correctly for your platform.

## Test input JSON file


## Input JSON file

> **IMPORTANT**: DO NOT BLINDLY USE A TEMPLATE/EXAMPLE INPUT JSON. READ THROUGH THE FOLLOWING GUIDE TO MAKE A CORRECT INPUT JSON FILE.

An input JSON file specifies all the input parameters and files that are necessary for successfully running this pipeline. This includes a specification of the path to the genome reference files and the raw data fastq file. Please make sure to specify absolute paths rather than relative paths in your input JSON files.

1) [Input JSON file specification (short)](docs/input_short.md)
2) [Input JSON file specification (long)](docs/input.md)

## How to organize outputs

Install [Croo](https://github.com/ENCODE-DCC/croo#installation). **You can skip this installation if you have installed pipeline's Conda environment and activated it**. Make sure that you have python3(> 3.4.1) installed on your system. Find a `metadata.json` on Caper's output directory.

```bash
$ pip install croo
$ croo [METADATA_JSON_FILE]
```

There is another [useful tool](utils/qc_jsons_to_tsv/README.md) to make a spreadsheet of QC metrics from multiple workflows. This tool recursively finds and parses all `qc.json` (pipeline's [final output](docs/example_output/v1.1.5/qc.json)) found from a specified root directory. It generates a TSV file that has all quality metrics tabulated in rows for each experiment and replicate. This tool also estimates overall quality of a sample by [a criteria definition JSON file](utils/qc_jsons_to_tsv/criteria.default.json) which can be a good guideline for QC'ing experiments.
