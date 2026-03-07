# Introduction to Nextflow

## Learning outcomes

**After having completed this chapter you will be able to:**

* Understand the structure of a Nextflow DSL2 workflow
* Write processes and workflow definitions to produce the desired outputs
* Chain processes together using channels
* Run a Nextflow workflow

## Material

[:fontawesome-solid-file-pdf: Download the presentation](../assets/pdf/site_under_construction.pdf){: .md-button }

## Structuring a workflow

It is advised to implement your code in a directory called `workflow` (you will learn more about workflow structure in the [next series of exercises](3_generalising_snakemake.md#downloading-data-and-setting-up-folder-structure)). Filenames and locations are up to you, but we recommend that you at least group all workflow outputs in a `results` folder.

## Exercises

This series of exercises will bear no biological meaning, on purpose: it is designed to explain the fundamentals of Nextflow.

### Creating a basic process

A **process** is the smallest block of code with which you can build a **workflow**. It is a **set of instructions** to create one or more **output(s)** from zero or more **input(s)**. When a process runs with specific input/output data, it is called a **task**. The definition of a process always starts with the **keyword** `process`. Processes have **directives** (such as `input`, `output`, `script`) that define their **properties**.

To create the simplest process possible, you need at least two _directives_:

* `output`: declaration of the output file(s)
* `script`: shell commands that will create the output when they are executed

Other directives will be explained throughout the course.

**Exercise:** The following example shows the minimal syntax to implement a process. What do you think it does? Does it create a file? If so, how is it called?

```groovy linenums="1"
process hello_world {
    output:
        path 'results/hello.txt'
    script:
        '''
        mkdir -p results
        echo "Hello world!" > results/hello.txt
        '''
}
```

??? success "Answer"
    This process uses the `echo` shell command to print `Hello world!` in an **output file** called `hello.txt`, located in the `results` folder.

Processes are defined in a file typically named `main.nf` (or `workflow.nf`). This file should be located at the workflow root directory (here, `workflow/main.nf`). You also need a **workflow** block that invokes your processes—otherwise Nextflow will not run anything.

```groovy linenums="1"
workflow {
    hello_world()
}
```

### Executing a workflow

It is now time to execute your first workflow! Nextflow runs the workflow defined in the `workflow` block. By default, it executes all processes that are called from that block.

**Exercise:** Create a `main.nf` file with the `hello_world` process and the `workflow` block above. Then, execute the workflow with `nextflow run main.nf`. Where can you locate the output file?

??? info "Where do outputs go?"
    Nextflow runs each process in an isolated directory under `workflow/`. Output files are first written there, then can be **published** to a final location (e.g. `results/`) using the `publishDir` directive. For this simple example, we write directly to `results/` in the script; in real workflows you will typically use `publishDir` (covered later).

??? warning "Code structure in Nextflow"
    Nextflow uses Groovy-like syntax. Proper **indentation** and **braces** matter. A few rules:

    * Use consistent indentation (typically 4 spaces)
    * Do not mix space and tab indents
    * Every `process` and `workflow` block must be properly closed with `}`

??? success "Answer"
    * The command to execute the workflow is:
    ```sh
    nextflow run main.nf
    ```
    * The output is written to `results/hello.txt` (as specified in the script). You can check with `ls -alh results/` and `cat results/hello.txt`
    * Nextflow creates the `results/` directory if it does not exist

**Exercise:** Re-run the exact same command. What happens?

??? success "Answer"
    Nextflow runs again, but it may **reuse cached results** from a previous run. If the process has already produced the same output (Nextflow hashes inputs to detect this), you might see a message indicating that the task was cached. To force a fresh run, you can use `nextflow run main.nf -resume` after a failure, or delete the `workflow/` directory to clear the cache.

??? info "Nextflow execution and caching"
    By default, Nextflow:

    * Runs each process in an isolated directory under `workflow/`
    * Caches task results based on input hashes—if you run again with the same inputs, it may reuse cached outputs
    * Uses `-resume` to continue a failed run without re-executing completed tasks
    * To force re-execution of everything, remove the `workflow/` directory before running

Long commands in the `script` block can be split across lines using triple quotes:

```groovy linenums="1"
process long_message {
    output:
        path 'results/long_message.txt'
    script:
        '''
        echo "I want to print a very very very very very \
        very very very long string in my output" > results/long_message.txt
        '''
}
```

### Understanding the input directive

Another directive used by most processes is `input`. It declares the file(s) or data required by the process to create the output. In the following example, a process uses `results/hello.txt` as input and copies its content to `results/copied_file.txt`:

```groovy linenums="1"
process copy_file {
    input:
        path hello
    output:
        path 'results/copied_file.txt'
    script:
        """
        mkdir -p results
        cp ${hello} results/copied_file.txt
        """
}
```

Here, `hello` is a **channel** that will emit the file path. The `path` qualifier tells Nextflow to stage the file into the process work directory.

### Creating a workflow with several processes

The `input` and `output` directives, combined with **channels**, create links (dependencies) between processes. The output of `hello_world` becomes the input of `copy_file` when we connect them in the workflow block. That is how we build a **pipeline**!

#### Chaining processes with channels

In Nextflow, data flows through **channels**. The output of one process is a channel; we pass it as input to the next process. The `workflow` block defines this flow:

```groovy linenums="1"
workflow {
    hello_ch = hello_world()
    copy_file(hello_ch)
}
```

`hello_world()` returns a channel emitting the output file(s). We pass that channel to `copy_file`, which will run once per item emitted (here, one file).

??? bug "`Missing input` or `No such file`"
    If you see errors about missing inputs, check that:
    * The workflow block correctly passes the output of one process as input to the next
    * Output names match what the downstream process expects
    * File paths in your `script` use the correct variable names (e.g. `${hello}`)

**Exercise:** Add the `copy_file` process to your `main.nf`, and update the `workflow` block to call both processes. Run the workflow with `nextflow run main.nf`. What do you see?

??? tip "Your main.nf should look like this"
    ```groovy linenums="1"
    process hello_world {
        output:
            path 'results/hello.txt'
        script:
            'echo "Hello world!" > results/hello.txt'
    }

    process copy_file {
        input:
            path hello
        output:
            path 'results/copied_file.txt'
        script:
            "cp ${hello} results/copied_file.txt"
    }

    workflow {
        hello_ch = hello_world()
        copy_file(hello_ch)
    }
    ```

??? success "Answer"
    * Nextflow runs `hello_world` first, then `copy_file` with the output of `hello_world`
    * Both `results/hello.txt` and `results/copied_file.txt` are produced
    * To force a full re-run (e.g. after changing the script), you can delete the `workflow/` directory and run again

**Exercise:** To trigger execution of both processes from scratch, remove the `results/` folder (or the `workflow/` cache), then run `nextflow run main.nf`. What happens?

??? success "Answer"
    Nextflow builds the execution graph, runs `hello_world`, then passes its output to `copy_file`, which runs and produces `results/copied_file.txt`. You only need to define the workflow connections—Nextflow figures out the execution order automatically.

#### Referencing process outputs

When you have many processes, repeating file paths can be error-prone. In Nextflow, you reference process outputs by the **channel** they produce. The workflow block is the single place where you define how data flows:

* Outputs of one process are passed directly as inputs to the next
* You do not hard-code file paths between processes—the channel carries the data
* This makes the pipeline easier to read and maintain

The example above already uses this pattern: `hello_ch = hello_world()` and `copy_file(hello_ch)`.

??? warning "Each process output should have a single producer"
    A given output file should be produced by only one process. If two processes could produce the same output, the workflow would be ambiguous. Design your pipeline so each output has a clear, single producer.

Try to structure your workflows this way in the next series of exercises!
