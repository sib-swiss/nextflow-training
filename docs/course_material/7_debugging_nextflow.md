# Session 5

## Learning outcomes

**After having completed this chapter you will be able to:**

* Understand the inner workings and order of operations in Nextflow
* Efficiently design and debug a Nextflow workflow
* Use `publishDir` and selective outputs to manage intermediate files
* Handle directory outputs (e.g. for tools like FastQC)

## Material

[:fontawesome-solid-file-pdf: Download the presentation](../assets/pdf/site_under_construction.pdf){: .md-button }

## Designing a workflow

There are many ways to design a new workflow. These tips will help in most cases:

* **Sketch the DAG first**: Decide how many processes you need and how they connect. Draw the flow from inputs to final outputs.
    * Identify which processes aggregate inputs (e.g. `count_table` with `.collect()`) or split them (e.g. one process per sample)
* **Get inputs and outputs right first**: Before writing complex scripts, ensure channel connections and process I/O are correct. Use `-dry-run` to validate the graph without running tasks
* **List parameters early**: Note any paths, sample lists, or settings that might change; put them in `params`
* **Use clear names**: Choose meaningful names for processes, channels, and variables. Readability matters

## Debugging a workflow

You will likely encounter bugs when building a new workflow. That’s normal. Use the execution phases to narrow down where things fail.

### Order of operations in Nextflow

When you run `nextflow run main.nf`, Nextflow goes through several phases:

1. **Parse and load**:
    * Load `main.nf`, included modules, and config
    * Resolve `params`, `include` statements, and process definitions
1. **Build the execution graph**:
    * Evaluate the `workflow` block
    * Resolve channels and their connections
    * Determine which processes run and in what order
1. **Execute**:
    * Submit tasks to the executor (local, SLURM, etc.)
    * Stage inputs, run the script, collect outputs
    * On failure, report the error and stop (use `-resume` to continue from cached tasks)

### Debugging advice

Identify which phase failed and check the usual causes:

1. **Parse/load failures**:
    * Syntax errors: missing braces, commas, or quotes
    * Invalid Groovy/Nextflow syntax
    * Wrong paths in `include` or `script`
    * Use an editor with Groovy/Nextflow support for highlighting
1. **Graph-building failures**:
    * Channel type mismatches (e.g. passing a single value where a channel is expected)
    * Missing or incorrect `collect()`, `flatten()`, or other operators
    * Circular dependencies between processes
    * Invalid `params` or file patterns
1. **Execution failures**:
    * Non-zero exit code from the script
    * Missing output files (Nextflow expects all declared outputs to exist)
    * Wrong variable names in the script (e.g. `${input}` vs `${input_file}`)
    * When a task fails, Nextflow stops; fix the error and use `-resume` to reuse successful tasks

??? tip "Useful debugging options"
    * `-dry-run`: validate the workflow without running
    * `-resume`: continue from cached results after a failure
    * `-with-dag dag.png`: visualise the execution graph
    * `-with-report report.html`: inspect resource usage and task status
    * Check `.nextflow.log` for detailed error messages

## Managing intermediate and final outputs

_This section covers how to control what gets kept and where. Do it after finishing the main course._

### Selective publishing and cleanup

By default, Nextflow keeps all outputs under `work/`. Use **`publishDir`** to copy only the outputs you care about to a final location (e.g. `results/`). You can:

* Publish only specific outputs with `pattern`
* Use `mode: 'copy'` or `mode: 'link'` to control how files are placed
* Omit `publishDir` for intermediate processes if you don’t need those files long-term

**Exercise:** Which outputs in your workflow are truly intermediate (e.g. SAM, unsorted BAM) and which are final (e.g. sorted BAM, count tables, DEG list)?

??? success "Answer"
    Intermediate: SAM files, unsorted BAM. Final: sorted BAM, count tables, DEG list, plots. Use `publishDir` only for final outputs if you want to save space. Intermediate files in `work/` can be removed after a successful run (e.g. with `nextflow clean`).

### Directory outputs: the FastQC example

[FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) produces an HTML report and a ZIP file per input. It writes to a directory you specify with `-o`, but does not let you choose individual file names. You can either:

1. Treat the **directory** as the process output
2. Run FastQC, then **rename/move** files in the script to match explicit output paths

**Exercise:** Implement a process that runs FastQC on original and trimmed FASTQ files and publishes the reports. Use either a directory output or explicit outputs with `mv` in the script.

??? success "Answer (directory output)"
    ```groovy
    process fastqc {
        container 'https://depot.galaxyproject.org/singularity/fastqc%3A0.12.1--hdfd78af_0'

        input:
            tuple val(sample_id), path(reads)
        output:
            path "fastqc_${sample_id}", emit: reports

        script:
            def (r1, r2) = reads
            """
            mkdir -p fastqc_${sample_id}
            fastqc --format fastq --threads 2 --outdir fastqc_${sample_id} \\
                --dir fastqc_${sample_id} ${r1} ${r2}
            """
    }
    ```

    The output is a directory. Use `path` with a directory name; Nextflow will treat it as a directory output.

??? success "Answer (explicit outputs with mv)"
    Run FastQC to a temp directory, then `mv` the generated files to the exact paths declared in `output`. This gives full control over output names and makes downstream chaining easier.

??? info "FastQC and parallel runs"
    Each task runs in its own `work/` directory, so there is no conflict between parallel FastQC jobs. Avoid writing to a shared path.

### Controlling execution order

To ensure one process runs before another, connect them via channels. For example, to run FastQC before read mapping, you could pass the FastQC output as an extra (possibly unused) input to `read_mapping`, so that mapping only starts after FastQC completes. In general, data flow through channels defines execution order.

If a process has multiple inputs, the channel order and structure must match the input declaration.
