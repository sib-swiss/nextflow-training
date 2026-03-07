# Session 1

## Learning outcomes

**After having completed this chapter you will be able to:**

* Create processes with multiple inputs and outputs
* Make the code shorter and more general by using channels and sample metadata
* Visualise a workflow DAG
* (Check a workflow's behaviour)

## Material

[:fontawesome-solid-file-pdf: Download the presentation](../assets/pdf/site_under_construction.pdf){: .md-button }

## Advice and reminders

In each process, you should try (as much as possible) to:

* Choose meaningful process names
* Use **channels** to feed data into processes—each process runs once per item (e.g. per sample) emitted by its input channel
* Use **tuples** when you need to pass multiple values together (e.g. `tuple val(sample_id), path(reads1), path(reads2)`)
* Use multiple (named) inputs/outputs when needed
* Connect process outputs to downstream process inputs via the workflow block

## Testing your workflow's logic

* Use a **dry-run** to see what Nextflow would execute without running it: `nextflow run main.nf -dry-run` (or `-with-dag dag.png` to generate a DAG image)
* To see the exact commands executed by each process, check the `.nextflow.log` file or run with `-with-timeline` / `-with-report` for a detailed execution report
* Use `nextflow run main.nf -resume` to continue a failed run without re-executing completed tasks

## Data origin

The data you will use during the exercises was produced [in this work](https://pubmed.ncbi.nlm.nih.gov/31654410/). Briefly, the team studied the transcriptional response of a strain of baker's yeast, [_Saccharomyces cerevisiae_](https://en.wikipedia.org/wiki/Saccharomyces_cerevisiae), facing environments with different concentrations of CO<sub>2</sub>. To this end, they performed **150 bp paired-end** sequencing of mRNA-enriched samples. Detailed information on all the samples are available [here](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA550078), but just know that for the purpose of the course, we selected **6 samples** (**3 replicates per condition**, **low** and **high CO<sub>2</sub>**) and **down-sampled** them to **1 million read pairs each** to reduce computation time.

## Exercises

One of the aims of today's course is to develop a simple, yet efficient, workflow to analyse bulk RNAseq data. This workflow takes reads coming from RNA sequencing as inputs and produces a list of genes that are differentially expressed between two conditions. The files containing reads are in [FASTQ format](https://en.wikipedia.org/wiki/FASTQ_format) and the final output will be a tab-separated file containing a list of genes with expression changes, results of statistical tests...

In this series of exercises, you will create the workflow 'backbone', _i.e._ processes that are the most computationally expensive, namely:

* A process to trim poor-quality reads
* A process to map trimmed reads on a reference genome
* A process to convert and sort files from SAM format to BAM format
* A process to count reads mapping on each gene

??? tip "Designing and debugging a workflow"
    If you have problems designing your Nextflow workflow or debugging it, you can find some help [here](7_debugging_snakemake.md#designing-a-workflow).

At the end of this series of exercises, your workflow should look like this:
<figure markdown align="center">
  ![backbone_rulegraph](../assets/images/backbone_rulegraph.png)
  <figcaption>Workflow DAG at <br>the end of the session</figcaption>
</figure>

### Downloading data and setting up folder structure

In this part, you will download the data and start building the directory structure of your workflow according to [Nextflow best practices](https://www.nextflow.io/docs/latest/getstarted.html#project-structure). You already started doing so in the previous series of exercises and at the end of the course, it should resemble this:
```
│── .gitignore
│── README.md
│── LICENSE.md
│── benchmarks
│   │── sample1.txt
│   └── sample2.txt
│── config
│   │── config.yaml
│   └── some-sheet.tsv
│── data
│   │── sample1_1.fastq
│   │── sample1_2.fastq
│   └── ...
│── images
│   │── dag.png
│   └── ...
│── logs
│── results
│   │── sample1
│   │   └── ...
│   └── sample2
│── resources
│   │── Scerevisiae.fasta
│   │── Scerevisiae.gtf
│   └── genome_indices
│       └── Scerevisiae_index.*.ht2
└── workflow
    │── main.nf
    │── nextflow.config
    │── modules
    │   │── read_mapping.nf
    │   └── analyses.nf
    │── envs
    │   └── ...
    └── scripts
        │── script1.py
        └── script2.R
```

For now, the main thing to remember is that **code** should go into the **`workflow` subfolder** and the **rest** is mostly **input/output files**. The **`config` subfolder** will be [explained later](4_optimising_snakemake.md#config-files). All **output files** generated in the workflow should be stored under **`results/`** (using `publishDir`).

Let's download the data, uncompress them and build the first part of the directory structure. Make sure you are connected to server, then run this in your VScode terminal:
```sh linenums="1"
wget https://containers-snakemake-training.s3.eu-central-1.amazonaws.com/snakemake_rnaseq.tar.gz  # Download data
tar -xvf snakemake_rnaseq.tar.gz  # Uncompress archive
rm snakemake_rnaseq.tar.gz  # Delete archive
cd snakemake_rnaseq/  # Start developing in new folder
```

In `snakemake_rnaseq/`, you should see two subfolders:

* `data/`, which contains data to analyse (paired-end FASTQ files named `*_1.fastq` and `*_2.fastq`)
* `resources/`, which contains the assembly, genome indices and annotation file of _S. cerevisiae_

We also need to create the other missing subfolders and the main workflow file:
```sh linenums="1"
mkdir -p config/ images/ workflow/modules workflow/envs workflow/scripts
touch workflow/main.nf
```

??? info "What does `-p` do?"
    The `-p` parameter of `mkdir` makes parent directories as needed and does not return an error if the directory already exists.

**main.nf** is the workflow **entry point**. Nextflow will use it when you run `nextflow run main.nf` from the project root.

??? warning "Relative paths in Nextflow"
    Paths in a Nextflow script are relative to the **launch directory** (where you run `nextflow run`). Use `params` or `projectDir` for paths that should stay fixed relative to the project root. For example, `file("${params.input_dir}/sample.fastq")` or `file("${projectDir}/resources/genome.fa")`.

If you followed the [advice](#advice-and-reminders) at the top of this page, you can now create the processes mentioned [earlier](#exercises). If needed, check [here](7_debugging_snakemake.md#designing-a-workflow) for workflow design tips.

??? info "'bottom-up' or 'top-down' development?"
    Even if it is often easier to start from final outputs and work backwards to first inputs, the next exercises are presented in the opposite direction (first inputs to last outputs) to make the session easier to understand.

#### Important: do not process all the samples!

**Do not try to process all the samples yet. For now, choose only one sample (two .fastq files because reads are paired-end). You will see an efficient way to process multiple samples in the next series of exercises.**

### Creating a process to trim reads

Usually, when dealing with sequencing data, the first step is to improve read quality by removing low quality bases, stretches of As and Ns and reads that are too short.

??? info "Trimming sequencing adapters"
    In theory, trimming should also remove sequencing adapters, but you will not do it here to keep computation time low and avoid parsing other files to extract adapter sequences.

You will use [atropos](https://peerj.com/articles/3720/) to trim reads. The first part of the trimming command is:
```sh
atropos trim -q 20,20 --minimum-length 25 --trim-n --preserve-order --max-n 10 --no-cache-adapters -a "A{20}" -A "A{20}"
```

??? info "Explanation of atropos parameters"
    * `-q 20,20`: trim low-quality bases from 5' and 3' ends of each read before adapter removal
    * `--minimum-length 25`: discard trimmed reads that are shorter than 25 bp
    * `--trim-n`: trim Ns at the ends of reads
    * `--preserve-order`: preserve order of reads in input files
    * `--max-n 10`: discard reads with more than 10 Ns
    * `--no-cache-adapters`: do not cache adapters list as '.adapters' in the working directory
    * `-a "A{20}" -A "A{20}"`: remove series of 20 As in adapter sequences (`-a` for first read of the pair, `-A` for the second one)

To run tools in a reproducible way, Nextflow supports **containers** (Docker, Singularity, Apptainer). Use the `container` directive to specify the image. Configure the container engine in `nextflow.config` (e.g. `docker { enabled = true }` or `singularity { enabled = true }`).

**Exercise:**

* Complete the atropos command with parameters to specify inputs (`-pe1`, `-pe2`) and outputs (`-o`, `-p`)
* Implement a process that trims reads. You will need:
    * An **input channel** that emits `(sample_id, [reads1, reads2])` for one sample
    * The `input`, `output`, `container` and `script` directives
    * The container image: `https://depot.galaxyproject.org/singularity/atropos%3A1.1.32--py312hf67a6ed_2`

??? tip "atropos inputs and outputs"
    * Paths of files to trim are specified with `-pe1` (first read) and `-pe2` (second read)
    * Paths of trimmed files are specified with `-o` (first read) and `-p` (second read)

??? success "Answer"
    This is one way of writing this process:
    ```groovy linenums="1"
    process fastq_trim {
        // Trims paired-end reads: removes low-quality bases, A stretches, N stretches
        container 'https://depot.galaxyproject.org/singularity/atropos%3A1.1.32--py312hf67a6ed_2'

        input:
            tuple val(sample_id), path(reads)
        output:
            tuple val(sample_id), path("${sample_id}_atropos_trimmed_1.fastq"), path("${sample_id}_atropos_trimmed_2.fastq")

        script:
            def (r1, r2) = reads
            """
            atropos trim -q 20,20 --minimum-length 25 --trim-n --preserve-order --max-n 10 \\
                --no-cache-adapters -a "A{20}" -A "A{20}" \\
                -pe1 ${r1} -pe2 ${r2} -o ${sample_id}_atropos_trimmed_1.fastq -p ${sample_id}_atropos_trimmed_2.fastq
            """
    }

    workflow {
        reads = Channel.fromFilePairs("data/highCO2_sample1_{1,2}.fastq", checkIfExists: true)
        fastq_trim(reads)
    }
    ```

    Notes:
    * `Channel.fromFilePairs` creates a channel emitting `(sample_id, [file1, file2])` for each pair
    * For one sample, we use a concrete pattern; later you will use `params.reads` to generalise
    * Outputs are written in the process work dir; use `publishDir` to copy them to `results/` (see next session)

**Exercise:** Run the workflow with `nextflow run main.nf`. Use `-with-singularity` or `-with-apptainer` if your config does not enable containers by default. What happens?

??? success "Answer"
    ```sh
    nextflow run main.nf -with-singularity
    ```
    Nextflow pulls the container (first run may be slow), runs `fastq_trim` for the sample, and writes outputs under `work/`. Add `publishDir 'results', pattern: '*.fastq'` to the process to copy outputs to `results/`.

### Creating a process to map trimmed reads onto a reference genome

Once the reads are trimmed, the next step is to map those reads onto the species genome (_S. cerevisiae_ strain S288C). The reference assembly is [RefSeq GCF_000146045.2](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000146045.2/). You will use [HISAT2](https://www.nature.com/articles/s41587-019-0201-4) to map reads.

??? info "HISAT2 genome index"
    HISAT2 uses a graph-based index. The index was pre-built and is in `resources/genome_indices/`. The basename is `Scerevisiae_index` (used with `-x`).

The mapping command structure:
```sh
hisat2 --dta --fr --no-mixed --no-discordant --time --new-summary --no-unal -x <index_basename> -1 <r1> -2 <r2> -S <out.sam> --summary-file <report.txt>
```

**Exercise:** Implement a process `read_mapping` that receives the output of `fastq_trim` and runs HISAT2. Use the container `https://depot.galaxyproject.org/singularity/hisat2%3A2.2.1--hdbdd923_6`.

??? tip "HISAT2 inputs and outputs"
    * `-1` / `-2`: trimmed FASTQ files
    * `-x`: basename of genome indices (e.g. `resources/genome_indices/Scerevisiae_index`)
    * `-S`: output SAM file
    * `--summary-file`: mapping report

??? success "Answer"
    ```groovy linenums="1"
    process read_mapping {
        container 'https://depot.galaxyproject.org/singularity/hisat2%3A2.2.1--hdbdd923_6'

        input:
            tuple val(sample_id), path(trim1), path(trim2)
        output:
            tuple val(sample_id), path("${sample_id}_mapped_reads.sam"), path("${sample_id}_mapping_report.txt")

        script:
            """
            hisat2 --dta --fr --no-mixed --no-discordant --time --new-summary --no-unal \\
                -x ${projectDir}/resources/genome_indices/Scerevisiae_index \\
                -1 ${trim1} -2 ${trim2} -S ${sample_id}_mapped_reads.sam --summary-file ${sample_id}_mapping_report.txt
            """
    }

    workflow {
        reads = Channel.fromFilePairs("data/highCO2_sample1_{1,2}.fastq", checkIfExists: true)
        trimmed = fastq_trim(reads)
        read_mapping(trimmed)
    }
    ```

    The `-x` path is hard-coded here; you will move it to `params` in the [next session](4_optimising_snakemake.md#non-file-parameters).

We recommend **not running it yet**—mapping takes ~6 min. You can continue with the next processes and run everything at once.

### Creating a process to convert and sort SAM to BAM

HISAT2 outputs [SAM format](https://en.wikipedia.org/wiki/SAM_(file_format)). Downstream tools use [BAM format](https://en.wikipedia.org/wiki/Binary_Alignment_Map). Use [Samtools](https://doi.org/10.1093/gigascience/giab008) to convert, sort, and index:

```groovy linenums="1"
process sam_to_bam {
    container 'https://depot.galaxyproject.org/singularity/samtools%3A1.21--h50ea8bc_0'

    input:
        tuple val(sample_id), path(sam), path(report)
    output:
        tuple val(sample_id), path("${sample_id}_mapped_reads_sorted.bam"), path("${sample_id}_mapped_reads_sorted.bam.bai")

    script:
        """
        samtools view ${sam} -b -o ${sample_id}_mapped_reads.bam
        samtools sort ${sample_id}_mapped_reads.bam -O bam -o ${sample_id}_mapped_reads_sorted.bam
        samtools index -b ${sample_id}_mapped_reads_sorted.bam -o ${sample_id}_mapped_reads_sorted.bam.bai
        """
}
```

??? info "Samtools parameters"
    * `samtools view -b`: convert SAM to BAM
    * `samtools sort`: sort by genomic coordinates
    * `samtools index -b`: create BAI index

**Exercise:** Add this process to your workflow and connect it to `read_mapping`. Note that `read_mapping` emits `(sample_id, sam, report)` and `sam_to_bam` needs the SAM file. You can use `.map { it -> tuple(it[0], it[1], it[2]) }` or simply pass the channel—Nextflow will match inputs by position.

??? success "Answer"
    In the workflow block:
    ```groovy
    mapped = read_mapping(trimmed)
    sam_to_bam(mapped)
    ```

### Creating a process to count mapped reads

To perform Differential Expression Analysis, you need read counts per gene. Use [featureCounts](https://academic.oup.com/bioinformatics/article/30/7/923/232889) with the annotation file `resources/Scerevisiae.gtf`:

```groovy linenums="1"
process reads_quantification_genes {
    container 'https://depot.galaxyproject.org/singularity/subread%3A2.0.6--he4a0461_2'

    input:
        tuple val(sample_id), path(bam_sorted), path(bam_index)
    output:
        tuple val(sample_id), path("${sample_id}_genes_read_quantification.tsv"), path("${sample_id}_genes_read_quantification.summary")

    script:
        """
        featureCounts -t exon -g gene_id -s 2 -p --countReadPairs \\
            -B -C --largestOverlap --verbose -F GTF \\
            -a ${projectDir}/resources/Scerevisiae.gtf -o ${sample_id}_genes_read_quantification.tsv ${bam_sorted}
        mv ${sample_id}_genes_read_quantification.tsv.summary ${sample_id}_genes_read_quantification.summary
        """
}
```

??? info "featureCounts"
    * `-a`: annotation file (GTF)
    * `-o`: output count table
    * The `.summary` file is renamed because featureCounts does not let you choose its name.

**Exercise:** Add this process and connect it to `sam_to_bam`. Then run the full workflow. How many read pairs were assigned to a feature?

??? success "Answer"
    ```groovy
    quantified = sam_to_bam(mapped)
    reads_quantification_genes(quantified)
    ```
    Run with:
    ```sh
    nextflow run main.nf -with-singularity
    ```
    Check the `.summary` file or the process log for the assignment statistics (e.g. ~83.8% for `highCO2_sample1`).

**(Optional) Exercise:** Add `publishDir 'results/${sample_id}', mode: 'copy'` to each process to publish outputs to `results/<sample_id>/`.

### Visualising the workflow DAG

Nextflow can generate a DAG of the workflow:

```sh
nextflow run main.nf -with-dag images/dag.png
```

??? tip "The `dot` command"
    Nextflow uses [Graphviz](https://graphviz.org/) to render the DAG. Install it if needed (`dot -Tpng`). Create the `images/` folder first.

You can also generate a timeline and report:

```sh
nextflow run main.nf -with-timeline -with-report
```

<figure markdown align="center">
  ![backbone_rulegraph](../assets/images/backbone_rulegraph.png)
  <figcaption>Workflow DAG at the end of the session</figcaption>
</figure>
