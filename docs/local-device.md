# ![wf-ani](images/wf-ani_logo_light.png#gh-light-mode-only) ![wf-ani](images/wf-ani_logo_dark.png#gh-dark-mode-only)

![workflow](images/wf-ani_workflow.png)

_A schematic of the steps in the workflow._

## Requirements

- [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=22.04.3`)
- [`Docker`](https://docs.docker.com/engine/installation/) or [`Singularity >=3.8.0`](https://www.sylabs.io/guides/3.0/user-guide/)

## Install Worflow Locally

```
git clone https://github.com/gregorysprenger/wf-ani.git
```

# Run Workflow

Before running workflow on new data, the workflow should be ran on the built-in test data to make sure everything is working properly. It will also download all dependencies to make subsequent runs much faster.

```
cd wf-ani/

nextflow run main.nf \
  -profile singularity,test
```

Example analysis using Nextflow command:

```
nextflow run main.nf \
  -profile singularity \
  --input INPUT_DIRECTORY \
  --outdir OUTPUT_DIRECTORY
```

When running locally, `--max_cpus` and `--max_memory` may need to be specified. Below, max cpus is set to 4 and max memory is set to 16 (for 16GB).

```
nextflow run main.nf \
  -profile singularity \
  --input INPUT_DIRECTORY \
  --outdir OUTPUT_DIRECTORY \
  --max_cpus 4 \
  --max_memory 16
```

Help menu of all options:

```
nextflow run main.nf --help
```
