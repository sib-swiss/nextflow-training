# Session 2

## Learning outcomes

**After having completed this chapter you will be able to:**

* Use `params` and config files in Nextflow
* Modularise a workflow using DSL2 modules
* Make a workflow process multiple samples via channels
* Define the main workflow entry point
* (Optimise CPU usage with the `cpus` directive)

## Material

[:fontawesome-solid-file-pdf: Download the presentation](../assets/pdf/site_under_construction.pdf){: .md-button }

## Workflow from previous session

If you didn't finish the previous part, you can restart from a complete workflow. Download the files from the [solutions folder](https://github.com/sib-swiss/containers-snakemake-training/tree/main/docs/solutions/session2) or create a minimal `main.nf` with the four processes from the previous chapter.

## Exercises

This series of exercises focuses on how to improve the workflow you developed in the previous session. You will add parameters, split the workflow into modules, and process all samples.

??? tip "Development and back-up"
    During this session you will modify your workflow quite heavily. Make back-ups from time to time (with `cp` or version control).

### Using params and config files

#### Non-file parameters

Workflow execution often depends on **non-file parameters** such as paths to indices or annotation files. Hard-coding these in the script makes the workflow inflexible. In Nextflow, use the **`params`** object to define such values. They can be set in the script or, better, in `nextflow.config` or a separate params file.

??? info "params in Nextflow"
    * `params` is a global object; define defaults with `params.name = value`
    * Access in processes with `${params.name}` in the script block
    * Override at runtime: `nextflow run main.nf --index 'path/to/index'`

**Exercise:** Replace the hard-coded paths in `read_mapping` and `reads_quantification_genes` with `params.index` and `params.annotations`. Define them at the top of `main.nf` or in `nextflow.config`.

??? success "Answer"
    In `nextflow.config` or at the top of `main.nf`:
    ```groovy
    params.index = "${projectDir}/resources/genome_indices/Scerevisiae_index"
    params.annotations = "${projectDir}/resources/Scerevisiae.gtf"
    ```

    In the processes, use `${params.index}` and `${params.annotations}` in the script instead of the hard-coded paths.

#### Config files

For a cleaner setup, move parameters to a **YAML config file** and load it in `nextflow.config`:

```yaml
# config/config.yaml
index: 'resources/genome_indices/Scerevisiae_index'
annotations: 'resources/Scerevisiae.gtf'
samples:
  - highCO2_sample1
  - highCO2_sample2
  - highCO2_sample3
  - lowCO2_sample1
  - lowCO2_sample2
  - lowCO2_sample3
```

In `nextflow.config`:
```groovy
params {
    config = file("${projectDir}/config/config.yaml")
}
// Load YAML and set params (simplified; you can use a custom loader or keep params in nextflow.config)
```

For simplicity, many workflows keep `params` directly in `nextflow.config`:

```groovy
// nextflow.config
params {
    index = "${projectDir}/resources/genome_indices/Scerevisiae_index"
    annotations = "${projectDir}/resources/Scerevisiae.gtf"
    reads = "data/*_{1,2}.fastq"
}
```

**Exercise:** Create `config/config.yaml` with `index`, `annotations` and `samples`, and wire these into your workflow (e.g. via a custom config loader or by copying values into `params` in `nextflow.config`).

### Modularising a workflow with DSL2 modules

As workflows grow, splitting them into **modules** improves maintainability and reusability. Nextflow DSL2 supports this with `include` and process definitions in separate files.

**Exercise:** Create a module file `workflow/modules/read_mapping.nf` containing the four processes (`fastq_trim`, `read_mapping`, `sam_to_bam`, `reads_quantification_genes`). Then include it in `main.nf` and call the processes from the workflow block.

??? success "Answer"
    In `workflow/modules/read_mapping.nf`:
    ```groovy
    process fastq_trim {
        // ... (process definition)
    }
    process read_mapping {
        // ... (process definition)
    }
    process sam_to_bam {
        // ... (process definition)
    }
    process reads_quantification_genes {
        // ... (process definition)
    }
    ```

    In `main.nf`:
    ```groovy
    include { fastq_trim, read_mapping, sam_to_bam, reads_quantification_genes } from './modules/read_mapping'

    workflow {
        reads = Channel.fromFilePairs(params.reads, checkIfExists: true)
        trimmed = fastq_trim(reads)
        mapped = read_mapping(trimmed)
        bams = sam_to_bam(mapped)
        reads_quantification_genes(bams)
    }
    ```

??? info "Module paths"
    The path in `include` is relative to the file that contains it. If `main.nf` is in `workflow/`, use `'./modules/read_mapping'` (omit the `.nf` extension).

??? info "Organising modules"
    Group related processes in the same module (e.g. `read_mapping.nf` for alignment steps, `analyses.nf` for count tables and DEG). This keeps the workflow readable and reusable.

### Processing all samples

So far you have processed a single sample. To process **all samples**, use a channel that emits one item per sample. `Channel.fromFilePairs` with a pattern does this automatically:

```groovy
params.reads = "data/*_{1,2}.fastq"
reads = Channel.fromFilePairs(params.reads, checkIfExists: true)
```

This creates a channel emitting `(sample_id, [file1, file2])` for each pair. Each downstream process runs once per sample.

**Exercise:** Update your workflow to use `params.reads` (or a sample list) so that all six samples are processed. Run a dry-run to confirm.

??? success "Answer"
    In `nextflow.config`:
    ```groovy
    params.reads = "data/*_{1,2}.fastq"
    ```

    In the workflow:
    ```groovy
    reads = Channel.fromFilePairs(params.reads, checkIfExists: true)
    trimmed = fastq_trim(reads)
    // ... rest of pipeline
    ```

    Dry-run:
    ```sh
    nextflow run main.nf -dry-run
    ```

    You should see six tasks per process (one per sample).

**Exercise:** Alternatively, define a sample list in `params` and build the channel from it:

```groovy
params.samples = ['highCO2_sample1', 'highCO2_sample2', 'highCO2_sample3', 'lowCO2_sample1', 'lowCO2_sample2', 'lowCO2_sample3']
reads = Channel.fromList(params.samples)
    .map { id -> tuple(id, file("data/${id}_1.fastq"), file("data/${id}_2.fastq")) }
```

**Exercise:** Run the full workflow on all samples and generate the DAG. With multithreading (see below), execution should take under ~10 min.

??? success "Answer"
    ```sh
    nextflow run main.nf -with-singularity
    nextflow run main.nf -with-dag images/all_samples_dag.png
    ```

### Optimising CPU usage with the `cpus` directive

To speed up computation, allocate more CPUs to processes that support multithreading. Use the **`cpus`** directive and pass the value to the tool (e.g. `--threads` or `-T`).

**Exercise:** What do you need to add to a process to enable multithreading?

??? success "Answer"
    1. The `cpus` directive to tell Nextflow how many CPUs to request
    2. The tool-specific option in the script (e.g. `--threads ${task.cpus}` or `-T ${task.cpus}`)

Recommended values for this workflow:

* `hisat2`: 4 cpus
* `atropos`, `samtools`, `featureCounts`: 2 cpus

**Exercise:** Add the `cpus` directive to the processes and pass `${task.cpus}` to the tools that support it.

??? success "Answer"
    Example for `read_mapping`:
    ```groovy
    process read_mapping {
        cpus 4
        container '...'
        input: ...
        output: ...
        script:
            """
            hisat2 ... --threads ${task.cpus} ...
            """
    }
    ```

    Run with enough parallelism, e.g.:
    ```sh
    nextflow run main.nf -with-singularity
    ```
    Nextflow will run multiple tasks in parallel according to available resources.

??? warning "Parallel execution"
    * Parallel tasks can mix log output; use log files for important messages
    * More parallel tasks use more RAM; monitor system resources
    * Using too many CPUs on small datasets can reduce efficiency
