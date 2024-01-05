# ![wf-ani](docs/images/wf-ani_logo_light.png#gh-light-mode-only) ![wf-ani](docs/images/wf-ani_logo_dark.png#gh-dark-mode-only)

![GitHub release (latest by date)](https://img.shields.io/github/v/release/bacterial-genomics/wf-ani)
[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.04.3-23aa62.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

![workflow](docs/images/wf-ani_workflow.png)

_General schematic of the steps in the workflow_

## Contents

- [Quick Start](#quick-start-test)
- [Introduction](#introduction)
- [Installation](#installation)
- [Usage](#usage)
- [Parameters](#parameters)
  - [Required parameters](#required-parameters)
  - [Additonal parameters](#additional-parameters)
- [Resource Managers](#resource-managers)
- [Output](#output)
- [Troubleshooting](#troubleshooting)
- [Contributions and Support](#contributions-and-support)
- [Citations](#citations)

## Quick Start: Test

Run the built-in test set to confirm all parts are working as-expected. It will also download all dependencies to make subsequent runs much faster.

### Pull workflow from GitHub

```
nextflow pull bacterial-genomics/wf-ani
```

### Run test workflow

```
nextflow run \
  bacterial-genomics/wf-ani \
  -r main \
  -profile <docker|singularity>,test
```

## Quick Start: Run

Example command on FastAs in "new-fasta-dir" data using **BLAST** (ANIb) with singularity:

### Pull workflow from GitHub

```
nextflow pull bacterial-genomics/wf-ani
```

### Run workflow

```
nextflow run \
  bacterial-genomics/wf-ani \
  -r main \
  -profile singularity \
  --input new-fasta-dir \
  --outdir my-results \
  --ani blast
```

## Introduction

This workflow performs average nucleotide identity on assembled and/or annotated files (FastA/Genbank).

## Installation

- [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html#installation) `>=22.04.03`
- [Docker](https://docs.docker.com/engine/installation/) or [Singularity](https://www.sylabs.io/guides/3.0/user-guide/) `>=3.8.0`
- [Conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html) is currently unsupported

## Usage

```
nextflow run main.nf -profile <docker|singularity> --input <input directory> --outdir <directory for results> --ani <blast|fastani|skani>
```

Please see the [usage documentation](docs/usage.md) for further information on using this workflow.

## Parameters

Note the "`--`" long name arguments (e.g., `--help`, `--input`, `--outdir`) are generally specific to this workflow's options, whereas "`-`" long name options (e.g., `-help`, `-latest`, `-profile`) are general nextflow options.

These are the most pertinent options for this workflow:

#### Required parameters

```
  ============================================
        Input/Output
  ============================================
  --input                 Path to input data directory containing FastA/Genbank assemblies or samplesheet. Recognized extensions are:  {fa,fas,fsa,fna,fasta,gb,gbk,gbf,gbff} with optional gzip compression.

  --query                 Path to input data FastA/Genbank file or samplesheet. Recognized extensions are:  {fa,fas,fsa,fna,fasta,gb,gbk,gbf,gbff} with optional gzip compression.

  --refdir                Path to reference panel data directory containing FastA/Genbank assemblies or samplesheet. Recognized extensions are:  {fa,fas,fsa,fna,fasta,gb,gbk,gbf,gbff} with optional gzip compression.

  --outdir                The output directory where the results will be saved.


  ============================================
        Container platforms
  ============================================
  -profile singularity    Use Singularity images to run the workflow. Will pull and convert Docker images from Dockerhub if not locally available.

  -profile docker         Use Docker images to run the workflow. Will pull images from Dockerhub if not locally available.


  ============================================
        Optional ANI tools
  ============================================
  --ani               Specify what algorithm should be used to compare input files. Recognized arguments are: blast, fastani, skani. [Default: blast]
```

#### Additional parameters

View help menu of all workflow options:

```
nextflow run \
  bacterial-genomics/wf-ani \
  -r main \
  --help \
  --show_hidden_params
```

## Resource Managers

The most well-tested and supported is a Univa Grid Engine (UGE) job scheduler with Singularity for dependency handling.

1. UGE/SGE
   - Additional tips for UGE processing are [here](docs/HPC-UGE-scheduler.md).
2. No Scheduler
   - It has also been confirmed to work on desktop and laptop environments without a job scheduler using Docker with more tips [here](docs/local-device.md).

## Output

Please see the [output documentation](docs/output.md) for a table of all outputs created by this workflow.

## Troubleshooting

Q: It failed, how do I find out what went wrong?

A: View file contents in the `<outdir>/log` directory.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.
