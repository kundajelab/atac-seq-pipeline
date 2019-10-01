# Cut-n-run pipeline

## Introduction

### Features

* **Portability**: The pipeline run can be performed across different cloud platforms such as Google, AWS and DNAnexus, as well as on cluster engines such as SLURM, SGE and PBS.
* **User-friendly HTML report**: In addition to the standard outputs, the pipeline generates an HTML report that consists of a tabular representation of quality metrics including alignment/peak statistics and FRiP along with many useful plots (IDR/TSS enrichment). An example of the [HTML report](https://storage.googleapis.com/encode-pipeline-test-samples/encode-cut-n-run-pipeline/ENCSR889WQX/example_output/qc.html). The [json file](docs/example_output/v1.1.5/qc.json) used in generating this report.
* **Supported genomes**: Pipeline needs genome specific data such as aligner indices, chromosome sizes file and blacklist. We provide a genome database downloader/builder for hg38, hg19, mm10, mm9. You can also use this [builder](docs/build_genome_database.md) to build genome database from FASTA for your custom genome.

## Installation

1) [Install Caper](https://github.com/ENCODE-DCC/caper#installation). Caper is a python wrapper for [Cromwell](https://github.com/broadinstitute/cromwell).

	> **IMPORTANT**: Make sure that you have python3(> 3.4.1) installed on your system.

	```bash
	$ pip install caper  # use pip3 if it doesn't work
	```

2) Follow [Caper's README](https://github.com/ENCODE-DCC/caper) carefully. Find an instruction for your platform.
	> **IMPORTANT**: Configure your Caper configuration file `~/.caper/default.conf` correctly for your platform.

3) Git clone this pipeline.
	> **IMPORTANT*: use `~/cut-n-run-pipeline/cut_n_run.wdl` as `[WDL]` in Caper's documentation.

	```bash
	$ cd
	$ git clone https://github.com/kundajelab/cut-n-run-pipeline
	```

4) Install pipeline's [Conda environment](docs/install_conda.md) if you want to use Conda instead of Docker/Singularity. Conda is recommneded on local computer and HPCs (e.g. Stanford Sherlock/SCG). Use 
	> **IMPORTANT*: use `encode-cut-n-run-pipeline` as `[PIPELINE_CONDA_ENV]` in Caper's documentation.

## Test input JSON file

Use `https://storage.googleapis.com/encode-pipeline-test-samples/encode-cut-n-run-pipeline/ENCSR356KRQ_subsampled_caper.json` as `[INPUT_JSON]` in Caper's documentation.

## Input JSON file

An input JSON file specifies all the input parameters and files that are necessary for successfully running this pipeline. This includes a specification of the path to the genome reference files and the raw data fastq file. Please make sure to specify absolute paths rather than relative paths in your input JSON files.

[Input JSON file specification](docs/input.md)

## Running a pipeline without Caper

> **WARNING**: This method has been deprecated. There are many unfixed known bugs. We no longer support it.

Caper uses the cromwell workflow execution engine to run the workflow on the platform you specify. While we recommend you use caper, if you want to run cromwell directly without caper you can learn about that [here](docs/deprecated/OLD_METHOD.md).

## Running a pipeline on DNAnexus

You can also run this pipeline on DNAnexus without using Caper or Cromwell. There are two ways to build a workflow on DNAnexus based on our WDL.

1) [dxWDL CLI](docs/tutorial_dx_cli.md)
2) [DNAnexus Web UI](docs/tutorial_dx_web.md)

## How to organize outputs

Install [Croo](https://github.com/ENCODE-DCC/croo#installation). Make sure that you have python3(> 3.4.1) installed on your system. Find a `metadata.json` on Caper's output directory.

```bash
$ pip install croo
$ croo [METADATA_JSON_FILE]
```

There is another [useful tool](utils/qc_jsons_to_tsv/README.md) to make a spreadsheet of QC metrics from multiple workflows. This tool recursively finds and parses all `qc.json` (pipeline's [final output](docs/example_output/v1.1.5/qc.json)) found from a specified root directory. It generates a TSV file that has all quality metrics tabulated in rows for each experiment and replicate. This tool also estimates overall quality of a sample by [a criteria definition JSON file](utils/qc_jsons_to_tsv/criteria.default.json) which can be a good guideline for QC'ing experiments.
