# wf-ani: Output

## Introduction

This document describes the output produced by the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes FastA/Genbank files. Output differs between ANI comparison methods:

- [ANI summary](#ani-summary) - ANI Summary file and pairing files
- [ANI Calculation Output](#ani-output) - Output of each file pairing
- [Log files](#log) - Nextflow and HPC logs, software information, and error list if applicable
- [Process logs](#process-logs) - Output and error logs for each process
- [QC file checks](#qc-file-checks) - Process output quality checks to determine if input files can be used in ANI comparisons

| Output Directory                                            | Filename                                          | Explanation                                                                            |
| ----------------------------------------------------------- | ------------------------------------------------- | -------------------------------------------------------------------------------------- |
| <a id="ani-summary">Main output directory</a>               |                                                   | **Main output directory**                                                              |
|                                                             | ANI.Summary.tsv                                   | ANI summary of all samples                                                             |
|                                                             | nextflow_log.<job_ID>.txt                         | Log output from Nextflow                                                               |
| <a id="ani-comparisons">comparisons</a>                     |                                                   | **ANI comparisons directory**                                                          |
|                                                             | genomes.fofn                                      | List of all input genomes when comparing all files vs each other                       |
|                                                             | query.fofn                                        | List of query genome(s) when comparing a query vs a reference panel                    |
|                                                             | refdir.fofn                                       | List of all reference genomes when comparing a query vs a reference panel              |
|                                                             | pairs.fofn                                        | List of all pairings of genomes in genomes.fofn                                        |
| <a id="ani-output">comparisons/ANI--\<Pair1\>,\<Pair2\></a> |                                                   | **ANI Output of \<Pair1\> and \<Pair2\>**                                              |
|                                                             | skani.out                                         | ANI output of \<Pair1\> vs \<Pair2\> when performing skani                             |
|                                                             | fastani.out                                       | ANI output of \<Pair1\> vs \<Pair2\> when performing fastANI                           |
|                                                             | ani.\<Pair1\>,\<Pair2\>.stats.tab                 | ANI of each pair and their combined bidirectional ANI when performing ANIb             |
|                                                             | blast.\<Pair1\>,\<Pair2\>.tab                     | BLAST output of each fragment of \<Pair2\> vs reference \<Pair2\> when performing ANIb |
|                                                             | blast.\<Pair1\>,\<Pair2\>.filt.tab                | Filtered BLAST output when performing ANIb                                             |
|                                                             | blast.\<Pair1\>,\<Pair2\>.filt.two-way.tab        | Filtered bidirectional BLAST output when performing ANIb                               |
| <a id="log">log</a>                                         |                                                   | **Log files**                                                                          |
|                                                             | ANI\_\<Number of Samples\>.o\<Submission Number\> | HPC output report                                                                      |
|                                                             | ANI\_\<Number of Samples\>.e\<Submission Number\> | HPC error report                                                                       |
|                                                             | pipeline_dag.\<YYYY-MM-DD_HH-MM-SS\>.html         | Direct acrylic graph of workflow                                                       |
|                                                             | report.\<YYYY-MM-DD_HH-MM-SS\>.html               | Nextflow summary report of workflow                                                    |
|                                                             | timeline.\<YYYY-MM-DD_HH-MM-SS\>.html             | Nextflow execution timeline of each process in workflow                                |
|                                                             | trace.\<YYYY-MM-DD_HH-MM-SS\>.txt                 | Nextflow execution tracing of workflow, which includes percent of CPU and memory usage |
|                                                             | software_versions.yml                             | Versions of software used in each process                                              |
|                                                             | errors.tsv                                        | Errors file if errors exist and summarizes the errors                                  |
| <a id="process-logs">log/process_logs</a>                   |                                                   | **Process log files**                                                                  |
|                                                             | \<SampleName\>.\<ProcessName\>.command.out        | Standard output for \<SampleName\> during process \<ProcessName\>                      |
|                                                             | \<SampleName\>.\<ProcessName\>.command.err        | Standard error for \<SampleName\> during process \<ProcessName\>                       |
| <a id="qc-file-checks">log/qc_file_checks</a>               |                                                   | **QC file check log files**                                                            |
|                                                             | Initial_Input_Files.tsv                           | Initial Fasta/Genbank File Check                                                       |
