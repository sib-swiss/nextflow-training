# Session 4

## Learning outcomes

**After having completed this chapter you will be able to:**

* Understand resource usage with Nextflow reports and trace
* Optimise resource usage with the `memory` and `time` directives
* Run a Nextflow workflow in an SLURM-based HPC environment
* Set up configuration profiles for different execution environments

## Material

[:fontawesome-solid-file-pdf: Download the presentation](../assets/pdf/site_under_construction.pdf){: .md-button }

## Workflow from previous session

If you didn't finish the previous part, you can restart from the workflow with modules, `count_table`, and `differential_expression`. Download from the [solutions folder](https://github.com/sib-swiss/containers-snakemake-training/tree/main/docs/solutions/session4).

## Exercises

In this last series of exercises, you will learn how to monitor resource usage, set process-level resources, and run your workflow on an SLURM-based HPC cluster using Nextflow profiles.

### Monitoring resource usage

Knowing how many resources each task uses helps you tune the workflow for local and HPC execution. Nextflow can record execution metrics with:

* **`-with-report`**: generates an HTML report with resource usage per process
* **`-with-timeline`**: generates a timeline of task execution
* **`-with-trace`**: writes a trace file with detailed metrics (time, memory, etc.)

**Exercise:** Run your workflow with `-with-report` and `-with-timeline`. Open the generated HTML files and inspect resource usage per process.

??? success "Answer"
    ```sh
    nextflow run main.nf -with-singularity -with-report -with-timeline
    ```

    This produces `report.html` and `timeline.html`. Use them to infer sensible `memory` and `time` values for each process.

### Controlling memory and runtime

Use the **`memory`** and **`time`** directives in each process to tell Nextflow (and the scheduler) how much memory and wall time to request. This avoids out-of-memory failures and helps the scheduler prioritise jobs.

??? info "Resource usage and schedulers"
    On HPC clusters, jobs with lower resource requests often start sooner. Setting realistic `memory` and `time` improves throughput.

Suggested values for this workflow:

* `fastq_trim`: 500 MB
* `read_mapping`: 2 GB
* `sam_to_bam`: 250 MB
* `reads_quantification_genes`: 500 MB

**Exercise:** Add the `memory` and `time` directives to your processes.

??? success "Answer"
    Example for `read_mapping`:
    ```groovy
    process read_mapping {
        cpus 4
        memory '2 GB'
        time '2 h'
        container '...'
        // ...
    }
    ```

    Use `memory '500 MB'`, `time '30 min'`, etc. for the other processes. Nextflow accepts units like `MB`, `GB`, `min`, `h`.

### Running on SLURM with a profile

Nextflow supports several **executors**, including `slurm`, `sge`, `pbs`, etc. Configure the executor and cluster options in `nextflow.config` or via a **profile**.

**Exercise:** Create a profile named `slurm` in `nextflow.config` that:

1. Sets the executor to `slurm`
2. Configures `queue`, `clusterOptions`, or `sbatch`-style options
3. Limits the number of concurrent jobs (e.g. `maxParallelForks`)

??? success "Answer"
    In `nextflow.config`:
    ```groovy
    profiles {
        slurm {
            process {
                executor = 'slurm'
                queue = 'normal'
                clusterOptions = '-A my_account'
            }
            executor {
                queueSize = 100
                submitRateLimit = '10 sec'
            }
        }
    }
    ```

    Process-level resources (`memory`, `time`, `cpus`) are automatically passed to SLURM via `--mem`, `--time`, and `--cpus-per-task`.

??? info "SLURM-specific options"
    Nextflow maps `memory` → `--mem`, `time` → `--time`, `cpus` → `--cpus-per-task`. For custom options, use `clusterOptions` or a custom `cluster` config. See the [Nextflow executor docs](https://www.nextflow.io/docs/latest/executor.html).

**Exercise:** Add SLURM options so that:

* Job names include the process name and task index
* Logs are written to `slurm_logs/`

??? success "Answer"
    ```groovy
    process {
        clusterOptions = '-A my_account --job-name=${task.process}-${task.id} --output=slurm_logs/%j.out'
    }
    ```

    Create `slurm_logs/` before running, or add `mkdir -p slurm_logs` to a `beforeScript` or a setup step.

### Passing process-specific resources to SLURM

The `memory`, `time`, and `cpus` directives are passed to the scheduler automatically. Ensure each process has appropriate values:

```groovy
process fastq_trim {
    memory '500 MB'
    time '30 min'
    cpus 2
    // ...
}
```

**Exercise:** Add `memory` and `time` to all processes. Use the values suggested earlier. Run with the `slurm` profile and verify that SLURM receives the correct resource requests.

??? success "Answer"
    Run:
    ```sh
    nextflow run main.nf -profile slurm -with-singularity
    ```

    Check submitted jobs with `squeue -u $USER` or `watch -n 10 squeue -u $USER`.

### Adapting to available resources

Before running on a cluster, check the available resources (e.g. via the HPC user guide or `sinfo`). Adjust `memory`, `time`, and `maxParallelForks` so that the workflow fits within cluster limits.

**Exercise:** If your cluster has 48 CPUs and 96 GB RAM, is the default configuration suitable?

??? success "Answer"
    Yes. The suggested per-process resources (e.g. 2 GB for `read_mapping`, 500 MB for others) and a moderate `queueSize` (e.g. 10–20) should work well.

??? bug "Always check cluster limits"
    If jobs request more resources than the cluster allows, they may stay pending indefinitely. Check partition limits with `sinfo` and adjust your process directives accordingly.

### Final exercise

**Exercise:** Run the full workflow on the HPC with the SLURM profile:

```sh
nextflow run main.nf -profile slurm -with-singularity
```

Monitor jobs with:
```sh
watch -n 10 squeue -u $USER
```

|  **JOBID**  | **PARTITION** | **NAME** | **USER** | **ST** | **TIME** | **NODES** | **NODELIST(REASON)** |
|:-------:|:---------:|:-----------:|:-----------:|:-----------:|:-----------:|:---------:|:----------:|
| 91 |  local  |  read_mapping  |  user1  |  PD  |  0:00  |  1  |  (Resources)  |
| 90 |  local  |  read_mapping  |  user1  |  R   |  0:30  |  1  |  node01  |

Congratulations! You can now build a Nextflow workflow, make it reproducible with Conda and containers, and run it on an HPC cluster.

For more, see [additional concepts](7_debugging_snakemake.md#using-non-conventional-outputs) and [Nextflow best practices](https://www.nextflow.io/docs/latest/getstarted.html#best-practices).
