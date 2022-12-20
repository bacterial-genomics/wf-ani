# Average Nucleotide Identity (ANI) Workflow

## Workflow Overview
1. Identify all FastA or Genbank files in a given input path
    - Recognized file extesions are: fa, fas, fsa, fna, fasta, gb, gbk, gbf, gbff,   fa.gz, fas.gz, fsa.gz, fna.gz, fasta.gz, gb.gz, gbk.gz, gbf.gz, gbff.gz
2. Create assemblies temp dir, move files and decompression
3. Create a list of genomes and pairs and append to files genomes.fofn and pairs.fofn, respectively
4. Perform ANI using [ANIb+.py](https://github.com/chrisgulvik/genomics_scripts/blob/master/ANIb%2B.py) on each pair
5. Grab ani.stats.tab file generated from performing ANI on each pair and append to a Summary.ANI.tab file

<br>

## Requirements
- Nextflow
- Docker or Singularity

<br>

## Install
```
# Download github repository. This creates a directory called 'wf-ani' that contains the workflow.
git clone https://github.com/chrisgulvik/wf-ani.git

# Enter the directory of the workflow
cd wf-ani
```

<br>

## Run Workflow
Run workflow on test data to verify workflow is working properly and to download all dependencies (~5 mins on HPC). Test data, [GCF000343165](https://www.ncbi.nlm.nih.gov/data-hub/genome/GCF_000343165.1/) and [GCF000342365](https://www.ncbi.nlm.nih.gov/data-hub/genome/GCF_000342365.1/), are located in subdirectory assets/test_data.

```
nextflow run main.nf -profile singularity,test
```
<br>

To run the workflow replace INPUT_FILE, INPUT_DIR with the corresponding input files. Replace OUTPUT_DIR with the path to desired output. 
Note: If no output directory is specified, output files will be placed in current directory.
Note: If output directory is not empty, output files will be added/overwritten.

```
# Run with Singularity -- replace with Docker if using Docker

# Run ANI on all files in a directory
nextflow run main.nf \
-profile singularity \
--inpath INPUT_DIR \
--outpath OUTPUT_DIR

# Run ANI on a QUERY vs REFERENCE panel
nextflow run main.nf \
-profile singularity \
--query INPUT_FILE \
--refdir INPUT_DIR \
--outpath OUTPUT_DIR
```
<br>

```
# Help menu with all options
nextflow run main.nf --help
```

<br>

## Workflow Output
```
# View output summary file
cat OUTPUT_DIR/ANI.Summary.tab
```
| Sample | Sample | Fragments_Used_for_Bidirectional_Calc[#] | Bidirectional_ANI[%] | Bidirectional_StDev[%] | Fragments_Used_for_Unidirectional_Calc[#] | Unidirectional_ANI[%] | Unidirectional_StDev[%] | Fragments_Used_for_Unidirectional_Calc[#]  | Unidirectional_ANI[%] | Unidirectional_StDev[%]
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | 
| GCF000343165 | GCF000342365 | 9509 | 98.798 | 1.496 | 20366 | 98.690 | 1.829 | 20346 | 98.652 | 2.083 |

<br>

## Quick Start for UGE Users
Set LAB_HOME environment variable:
```
echo "export LAB_HOME=/PATH/TO/LAB/HOME/" >> ~/.bashrc
```

Add Singularity environment variables to .bashrc
```
SINGULARITY_BASE=/scicomp/scratch/$USER
export SINGULARITY_TMPDIR=$SINGULARITY_BASE/singularity.tmp
export SINGULARITY_CACHEDIR=$SINGULARITY_BASE/singularity.cache
export NXF_SINGULARITY_CACHEDIR=$SINGULARITY_BASE/singularity.cache
mkdir -pv $SINGULARITY_TMPDIR $SINGULARITY_CACHEDIR
```

Reload bashrc file
```
source ~/.bashrc
```

Run wrapper scripts to simplify workflow:
```
# Run ANI on ALL vs ALL
run_ani_ALL.uge-nextflow INPUT_DIR OUTPUT_DIR

# Run ANI on QUERY vs REFERENCE panel
run_ani_QUERY_vs_REF.uge-nextflow INPUT_QUERY_FILE INPUT_REF_DIR OUTPUT_DIR
```