- Configure and run the same workflow using either containers or Conda environments.

- **Execution in containers or Conda**, depending on your environment.
- **How we execute tools** (Conda vs Docker).

- **Named profiles** for different environments (laptop vs HPC).

### Global engines: Conda vs Docker

At the top of `nextflow.config` you will find:

- **`docker.enabled = false`**: Docker is off by default.
- **`conda.enabled = true`**: Conda environments are enabled by default.

This means:

- Processes with a `conda` directive will use Conda **unless** a profile overrides this.
- Docker is disabled unless explicitly turned on via a profile.

??? info "Why configure this centrally?"
    By toggling `docker.enabled` and `conda.enabled` in `nextflow.config`, you can move the same workflow between environments (e.g. laptop vs HPC cluster) **without changing any process code**.

### Profiles: adapting to different environments

The `profiles` block defines three example profiles:

- **`my_laptop`**:
  - `process.executor = 'local'`
  - `docker.enabled = true` (enables Docker for container execution)
- **`univ_hpc`**:
  - `process.executor = 'slurm'`
  - `conda.enabled = true`
  - `process.resourceLimits` set to large values (memory, CPUs, time)
- **`test`**:
  - Overrides `params.input`, `params.batch` and `params.character` for a quick test run.

You select a profile with `-profile`:

```bash
nextflow run hello-pipeline.nf -profile my_laptop
nextflow run hello-pipeline.nf -profile univ_hpc
nextflow run hello-pipeline.nf -profile test
```

??? success "Exercise: create your own profile"
    - Copy the `my_laptop` profile and create a new one, e.g. `training_cluster`.
    - Change its executor and enable either Docker or Conda according to your environment.
    - Run `nextflow run hello-pipeline.nf -profile training_cluster` and confirm that the workflow still runs without changing **any** `.nf` file.


## Containers and Conda: running tools reproducibly

The `cowpy` process demonstrates how to support **both containers and Conda** for the same tool:

- `container 'community.wave.seqera.io/library/cowpy:1.1.5--3db457ae1977a273'`
- `conda 'conda-forge::cowpy==1.1.5'`

How this interacts with `nextflow.config`:

- When `docker.enabled = true` (e.g. in `my_laptop` profile), Nextflow runs `cowpy` in the specified **container image**.
- When `conda.enabled = true` and Docker is disabled (e.g. `univ_hpc` profile), Nextflow creates/uses a **Conda environment** with `cowpy==1.1.5` from `conda-forge`.

This gives you:

- The same process code, portable across environments.
- A clear link between the process and the exact tool version it needs.

??? info "Choosing between container and Conda"
    - **Containers** are great when Docker/Singularity is available and you want fully isolated environments.
    - **Conda** is useful on HPC systems where containers are harder to use or prohibited.
    - By declaring both, you allow the **profile** (and cluster policies) to decide which engine to use.

### Running the `hello-pipeline` with containers

On a laptop with Docker:

```bash
nextflow run hello-pipeline.nf -profile my_laptop
```

- Docker is enabled via the profile.
- Processes with `container` directives run inside containers.

On an HPC with Singularity/Apptainer (if you adapt the config accordingly):

- Configure a profile that sets `singularity.enabled = true`.
- Use container URIs supported by Singularity or Apptainer.

### Running the `hello-pipeline` with Conda

On a Conda-enabled environment (no containers):

```bash
nextflow run hello-pipeline.nf -profile univ_hpc
```

- `conda.enabled = true` in the profile.
- Processes with a `conda` directive create/use the appropriate Conda environment.

??? success "Exercise: switch execution modes"
    - Run the workflow with a Docker-enabled profile and check that containers are pulled and run.
    - Run the workflow with a Conda-enabled profile and check that environments are created under `.conda`/`.nextflow`.
    - Confirm that outputs are identical (same greetings and ASCII art), even though the execution environment is different.

- Using both **containers** and **Conda** in process directives, controlled by profiles, makes the `hello-pipeline` portable across laptops and HPC clusters.

??? success "Exercise: extend dynamic naming"
    - Modify one of the modules so that the output filename also includes the current date or time (e.g. `COLLECTED-${batch_name}-${now}.txt`).
    - Re-run the workflow and observe how filenames change.
    - Think about pros and cons: more traceability vs. less caching and reproducibility.