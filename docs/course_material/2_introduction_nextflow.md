# Introduction to Nextflow

## Learning outcomes

**After having completed this chapter you will be able to:**

* Understand the structure of a Nextflow DSL2 workflow.
* Write processes and workflow definitions to produce the desired outputs.
* Chain processes together using channels.
* Run a Nextflow workflow.

## Material

[:fontawesome-solid-file-pdf: Download the presentation](../assets/pdf/site_under_construction.pdf){: .md-button }

## Structuring a workflow

We will have a folder for each exercise to maintain the file structure neat and clean. Throughout the exercises we will use always `results` as the output folder within each exercise directory.

## Exercise

Let's go then to the to first exercise:

```bash
cd exercises/intro_nextflow
code .
```

This folder is empty as in this exercise we will build everything from the ground up. For the following exercises, we will provide the materials and/or templates.

This exercise will bear no biological meaning, it is designed to explain the fundamentals of Nextflow.

### Creating a basic process

A **process** is the smallest block of code with which you can build a **workflow**. It is a **set of instructions** to create one or more **output(s)** from zero or more **input(s)**. When a process runs with specific input/output data, it is called a **task**. The definition of a process always starts with the **keyword** `process`. Processes have **directives** (such as `input`, `output`, `script`) that define their **properties**.

To create the simplest process possible, you need at least two _directives_:

* `output`: declaration of the output file(s)
* `script`: shell commands that will create the output when they are executed

Other directives will be explained throughout the course.

**Exercise:** The following example shows the minimal syntax to implement a process. What do you think it does? Does it create a file? If so, how is it called?

```groovy title="hellow_nextflow.nf" linenums="1"
process hello_world {
    output:
        path 'hello.txt'
    script:
        '''
        echo "Hello world!" > hello.txt
        '''
}
```

??? success "Answer"
    This process uses the `echo` shell command to print `Hello world!` in an **output file** called `hello.txt`.

You also need a **workflow** block that invokes your processes—otherwise Nextflow will not run anything.

```groovy title="hellow_nextflow.nf" linenums="1"
workflow {
    hello_world()
}
```

### Executing a workflow

It is now time to execute your first workflow! Nextflow runs the workflow defined in the `workflow` block. By default, it executes all processes that are called from that block.

**Exercise:** Create a `hello_world.nf` file with the `hello_world` process and the `workflow` block below. Then, execute the workflow with `nextflow run hello_world.nf`. Where can you locate the output file? Explore the directory.

??? full-code "Full code file"
    ```groovy title="hello_world.nf" linenums="1"
    #!/usr/bin/env nextflow

    /*
    * Use echo to print 'Hello World!' to a file
    */

    process hello_world {
        output:
            path 'hello.txt'
        script:
            '''
            echo "Hello world!" > hello.txt
            '''
    }

    workflow {
        hello_world()
    }
    ```

??? success "Answer"
    When you run Nextflow for the first time in a given directory, it creates a directory called work where it will write all files (and any symlinks) generated in the course of execution.

    Within the work directory, Nextflow organizes outputs and logs per process call. For each process call, Nextflow creates a nested subdirectory, named with a hash in order to make it unique, where it will stage all necessary inputs (using symlinks by default), write helper files, and write out logs and any outputs of the process.

    The path to that subdirectory is shown in truncated form in square brackets in the console output. Looking at what we got for the run shown above, the console log line for the hello_world process starts with _`[00/00000]`_. That corresponds to the following directory path: _`work/00/0000000000...`_

**Exercise:** Now, let's modify the workflow to specify where we want our output. Can you infer where the output will be stored?:

=== "After"
    ```groovy title="hello_world.nf" linenums="16"
    workflow {
        hello_world()

    publish:
        hello_folder = hello_world.out
    }

    output {
        hello_folder {
            path 'hello_folder'
        }
    }
    ```

=== "Before"
    ```groovy title="hello_world.nf" linenums="16"
    workflow {
        hello_world()
    }
    ```

??? success "Answer"
    * The output is written to `results/hello_folder/hello.txt`. You can check with `ls -alh results/` and `cat results/hello_folder/hello.txt`.
    * Nextflow creates the `results/` directory if it does not exist.

??? warning "Code structure in Nextflow"
    Nextflow uses Groovy-like syntax. Proper **indentation** and **braces** matter. A few rules:

    * Use consistent indentation (typically 4 spaces).
    * Do not mix space and tab indents.
    * Every `process` and `workflow` block must be properly closed with `}`.

**Exercise:** Re-run the exact same command. What happens?

??? success "Answer"
    Nextflow runs again, but it may **reuse cached results** from a previous run. If the process has already produced the same output (Nextflow hashes inputs to detect this), you might see a message indicating that the task was cached. To force a fresh run, you can use `nextflow run hello_nextflow.nf -resume` after a failure, or delete the `work/` directory to clear the cache.

??? info "Nextflow execution and caching"
    By default, Nextflow:

    * Runs each process in an isolated directory under `work/`.
    * Caches task results based on input hashes—if you run again with the same inputs, it may reuse cached outputs.
    * Uses `-resume` to continue a failed run without re-executing completed tasks.
    * To force re-execution of everything, remove the `work/` directory before running.

### Understanding the input directive

Another directive used by most processes is `input`. It declares the file(s) or data required by the process to create the output. In the following example, a process uses `hello.txt` as input and copies its content to `copied_file.txt`:

```groovy title="hellow_nextflow.nf" linenums="1"
process copy_file {
    input:
        path hello
    output:
        path 'copied_file.txt'
    script:
        """
        cp ${hello} copied_file.txt
        """
}
```

Here, `hello` is a **Channel** that will emit the file path. The `path` qualifier tells Nextflow to stage the file into the process work directory.

??? info "Nextflow channels"
    Channels are the core of the Nextflow's engine. There are multiple ways to create channels:

    * Check the [documentation](https://docs.seqera.io/nextflow/reference/channel) to know more about the Channel factories.
    * We will discuss more about this in the lecture.

### Creating a workflow with several processes

The `input` and `output` directives, combined with **channels**, create links (dependencies) between processes. The output of `hello_world` becomes the input of `copy_file` when we connect them in the workflow block. That is how we build a **pipeline**!

#### Chaining processes with channels

In Nextflow, data flows through **channels**. The output of one process is a channel; we pass it as input to the next process. The `workflow` block defines this flow:

```groovy title="hellow_nextflow.nf" linenums="1"
workflow {
    hello_ch = hello_world()
    copy_file(hello_ch.out)
}
```

`hello_world()` returns a channel emitting the output file(s). We pass that channel to `copy_file`, which will run once per item emitted (here, one file).

??? bug "`Missing input` or `No such file`"
    If you see errors about missing inputs, check that:

    * The workflow block correctly passes the output of one process as input to the next.
    * Output names match what the downstream process expects.
    * File paths in your `script` use the correct variable names (e.g. `${hello}`).

**Exercise:** Add the `copy_file` process to your `hello_nextflow.nf`, and update the `workflow` block to call both processes. Run the workflow with `nextflow run hello_nextflow.nf`. What do you see?

??? tip "Where are you going to store the output of `copy_file`?"
    Following what we did in the previous exercise, try to figure out where to store the output of this process.

??? full-code "This is the final script"
    ```groovy title="hellow_nextflow.nf" linenums="1"
    #!/usr/bin/env nextflow

    /*
    * Use echo to print 'Hello World!' to a file
    */

    process hello_world {
        output:
            path 'hello.txt'
        script:
            '''
            echo "Hello world!" > hello.txt
            '''
    }

    process copy_file {
        input:
            path hello
        output:
            path 'copied_file.txt'
        script:
            """
            cp ${hello} copied_file.txt
            """
    }

    workflow {
        hello_world()
        copy_file(hello_world.out)
        
        publish:
        hello_folder = hello_world.out
        copy_folder = copy_file.out
    }

    output {
        hello_folder {
            path 'hello_folder'
        }
        copy_folder {
            path 'copy_folder'
        }
    }
    ```

??? success "Answer"
    * Nextflow runs `hello_world` first, then `copy_file` with the output of `hello_world`.
    * Both `hello.txt` and `copied_file.txt` are produced, being stored individually within `hello_folder` and `copy_folder`, respectively.
    * To force a full re-run (e.g. after changing the script), you can delete the `work` directory and run again.

#### Referencing process outputs

When you have many processes, repeating file paths can be error-prone. In Nextflow, you reference process outputs by the **channel** they produce. The workflow block is the single place where you define how data flows:

* Outputs of one process are passed directly as inputs to the next
* You do not hard-code file paths between processes—the channel carries the data
* This makes the pipeline easier to read and maintain

The example above already uses this pattern: `hello_ch = hello_world()` and `copy_file(hello_ch)`.

??? warning "Each process output should have a single producer"
    A given output file should be produced by only one process. If two processes could produce the same output, the workflow would be ambiguous. Design your pipeline so each output has a clear, single producer.

We are ready to continue with a more complex pipeline!
