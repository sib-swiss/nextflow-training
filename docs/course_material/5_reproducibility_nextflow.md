# Session 3

## Learning outcomes

**After having completed this chapter you will be able to:**

* Use `collect()` to gather outputs from multiple samples into a single process
* Run scripts from other languages (Python and R) with the `script` directive
* Deploy a process-specific conda environment
* Deploy a process-specific Docker/Apptainer container

## Material

[:fontawesome-solid-file-pdf: Download the presentation](../assets/pdf/site_under_construction.pdf){: .md-button }

## Workflow from previous session

If you didn't finish the previous part, you can restart from the workflow with modules and multithreading. Download from the [solutions folder](https://github.com/sib-swiss/containers-snakemake-training/tree/main/docs/solutions/session3) or adapt the session 4 material.

## Exercises

In this series of exercises, you will create the last two processes of the workflow. Each will run a script (Python and R; the scripts are provided) and use dedicated environments (conda or container).

??? tip "Development and back-up"
    Make back-ups or use version control before making large changes.

### Creating a process to gather read counts

To perform Differential Expression Analysis (DEA), you need a single file with read counts from all samples. The next process will merge the per-sample count tables using a Python script.

#### Gathering inputs from multiple samples

In Nextflow, a process runs once per item emitted by its input channel. To run **once** with **all** count tables, you must **collect** the outputs of `reads_quantification_genes` into a single channel emission. Use the `.collect()` operator:

```groovy
// In the workflow block:
quantified = reads_quantification_genes(bams)
count_table(quantified.collect())
```

`quantified` emits one tuple per sample. `.collect()` gathers all emissions and emits a single list, so `count_table` runs once with the full list.

**Exercise:** Create a process `count_table` that receives the collected output of `reads_quantification_genes` and produces `results/total_count_table.tsv`. The process will run a Python script.

??? success "Answer"
    ```groovy
    process count_table {
        input:
            path(count_files)
        output:
            path 'total_count_table.tsv'

        script:
            def file_list = count_files.sort().join(' ')
            """
            python ${projectDir}/workflow/scripts/count_table.py ${file_list} total_count_table.tsv
            """
        // Or use the script directive (see below)
    }
    ```

    The Python script must be adapted to accept file paths as arguments if it does not use the Nextflow `params` object. Alternatively, use the `script` directive so Nextflow injects `input` and `output` automatically.

#### Using the `script` directive for Python

Nextflow can run external scripts with the **`script`** directive. The script receives `params` with `input`, `output`, etc. For a script that expects Snakemake-style `snakemake.input`, you can either adapt it to read from `params` or wrap it.

**Exercise:** Download `count_table.py` from the [solutions](https://raw.githubusercontent.com/sib-swiss/containers-snakemake-training/main/docs/solutions/session4/workflow/scripts/count_table.py) and place it in `workflow/scripts/`. Adapt it for Nextflow: it can read `params.input` (a list of paths) and `params.output` (output path), or use command-line arguments.

??? tip "Nextflow script params"
    When using `script: 'path/to/script.py'`, Nextflow generates a wrapper that sets `params.input` and `params.output` from the process `input`/`output`. In the script, access them via the `params` object (or the generated argv).

??? success "Answer"
    A minimal process using the script directive:
    ```groovy
    process count_table {
        container 'quay.io/biocontainers/python:3.12'
        // Or use conda (see below)

        input:
            path(count_files)
        output:
            path 'total_count_table.tsv'

        script:
            def inputs = count_files.sort()
            """
            python ${projectDir}/workflow/scripts/count_table_nextflow.py ${inputs.join(' ')} total_count_table.tsv
            """
    }
    ```

    If the original script uses `snakemake.input`, create a small adapter that reads from `params` or argv and calls the original logic.

#### Providing a process-specific conda environment

For a Python script that needs `pandas`, use a **conda** environment. In Nextflow, add the `conda` directive with a YAML file:

```groovy
process count_table {
    conda "${projectDir}/workflow/envs/py.yaml"
    // ...
}
```

Create `workflow/envs/py.yaml`:
```yaml
name: py3.12
channels:
  - conda-forge
  - bioconda
dependencies:
  - python >= 3.12
  - pandas == 2.2.3
```

**Exercise:** Add the conda environment to `count_table`. Run with `-with-conda` or set `conda.enabled = true` in `nextflow.config`.

??? success "Answer"
    Enable conda in `nextflow.config`:
    ```groovy
    conda {
        enabled = true
    }
    ```

    Run:
    ```sh
    nextflow run main.nf -with-conda
    ```

    The first run will take longer while conda creates the environment.

#### Connecting to the workflow

**Exercise:** Update the workflow block to call `count_table` with the collected output of `reads_quantification_genes`. Ensure the main workflow output includes the count table.

??? success "Answer"
    ```groovy
    workflow {
        reads = Channel.fromFilePairs(params.reads, checkIfExists: true)
        trimmed = fastq_trim(reads)
        mapped = read_mapping(trimmed)
        bams = sam_to_bam(mapped)
        quantified = reads_quantification_genes(bams)
        count_table(quantified.collect())
    }
    ```

### Creating a process to detect Differentially Expressed Genes (DEG)

The final process runs an R script (DESeq2) on the count table and produces a DEG list and plots.

#### Process structure

**Exercise:** Create a process `differential_expression` that:
* Takes the output of `count_table` as input
* Produces `results/deg_list.tsv` and `results/deg_plots.pdf`
* Runs the R script `workflow/scripts/DESeq2.R`

??? success "Answer"
    ```groovy
    process differential_expression {
        container 'docker://athiebaut/deseq2:v3'

        input:
            path(count_table)
        output:
            path 'deg_list.tsv'
            path 'deg_plots.pdf'

        script:
            """
            Rscript ${projectDir}/workflow/scripts/DESeq2.R ${count_table} deg_list.tsv deg_plots.pdf
            """
        // Or use script: 'workflow/scripts/DESeq2.R' if the script reads from Nextflow params
    }
    ```

    The R script must be adapted to accept paths as arguments, or use the Nextflow `params` object if it was written for Snakemake.

#### Using a container for R

R scripts often depend on many packages. Using a **container** (e.g. `docker://athiebaut/deseq2:v3`) ensures a reproducible environment.

**Exercise:** Add the `container` directive to `differential_expression` and run the workflow with `-with-singularity` or `-with-docker`.

??? success "Answer"
    Run:
    ```sh
    nextflow run main.nf -with-singularity
    ```

    Check `results/deg_list.tsv` for the number of DEGs (e.g. 10: 4 up, 6 down).

### Running the complete workflow

**Exercise:** Run the full workflow. How many DEGs are detected?

??? success "Answer"
    ```sh
    nextflow run main.nf -with-conda -with-singularity
    ```

    Ensure both conda (for `count_table`) and containers (for other processes and `differential_expression`) are enabled.

**Exercise:** Visualise the DAG of the entire workflow.

??? success "Answer"
    ```sh
    nextflow run main.nf -with-dag images/total_dag.png
    ```

<figure align="center">
  <img src="../../../assets/images/total_dag.png" width="100%"/>
</figure>
