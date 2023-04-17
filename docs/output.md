# Output File Structure
| Output Directory | Filename | Explanation |
| ---------------- | ---------------- | ---------------- |
| **Main output directory** | | **Main output directory**
| | ANI.Summary.tab | Bidirectional summary of all samples |
| | genomes.fofn | List of all input genomes |
| | pairs.fofn | List of all pairings of genomes in genomes.fofn |
| | nextflow_log.<job_ID>.txt | Log output from Nextflow |
| **ANI--\<Pair1\>,\<Pair2\>** | | **ANI Output of \<Pair1\> and \<Pair2\>** |
| | ani.\<Pair1\>,\<Pair2\>.stats.tab | ANI of each pair and their combined bidirectional ANI |
| | blast.\<Pair1\>,\<Pair2\>.tab | BLAST output of each fragment of \<Pair2\> vs reference \<Pair2\> |
| | blast.\<Pair1\>,\<Pair2\>.filt.tab | Filtered BLAST output |
| | blast.\<Pair1\>,\<Pair2\>.filt.two-way.tab | Filtered bidirectional BLAST output |
| **log** | | **Log files** |
| | ASM_\<Number of Samples\>.o\<Submission Number\> | HPC output report |
| | ASM_\<Number of Samples\>.e\<Submission Number\> | HPC error report |
| | pipeline_dag.\<YYYY-MM-DD_HH-MM-SS\>.html | Direct acrylic graph of workflow |
| | report.\<YYYY-MM-DD_HH-MM-SS\>.html | Nextflow summary report of workflow |
| | timeline.\<YYYY-MM-DD_HH-MM-SS\>.html | Nextflow execution timeline of each process in workflow |
| | trace.\<YYYY-MM-DD_HH-MM-SS\>.txt | Nextflow execution tracing of workflow, which includes percent of CPU and memory usage |
| | software_versions.yml | Versions of software used in each process |
| | errors.tsv | Errors file if errors exist and summarizes the errors |
| **log/process_logs** | | **Process log files** |
| | \<SampleName\>.\<ProcessName\>.command.out | Standard output for \<SampleName\> during process \<ProcessName\> |
| | \<SampleName\>.\<ProcessName\>.command.err | Standard error for \<SampleName\> during process \<ProcessName\> |