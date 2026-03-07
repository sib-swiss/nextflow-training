# General guidelines

## Course goal

<p style='text-align: justify;'>This is course is designed in three practical stages. In the first stage, you will identify key components of the Nextflow dataflow paradigm using a basic pipeline whose purpose is to demonstrate how processes are connected. For the second stage, once you are able to establish how data is flowing, you will apply what you have learned in order to execute an RNA-seq pipeline. Finally, you'll <i>collect()</i> the knowledge of the two previous stages to develop a metagenomics pipeline. Optionally, you can wrap your own analysis workflows; otherwise, there will be a genomics pipeline for you to expand your skills.</p>

<p style='text-align: justify;'>By the end of the course, you will have constructed/understood potentially 3 Nextflow and functional workflows implemented in <b>Nextflow DSL2</b>, using common features such as processes, channels, modules and configuration profiles. You will also have gained experience running the workflow in a controlled environment, and you will be equipped with the necessary information to execute the pipelines on a High Performance Computing (HPC) environment.</p>

## Software

All the software needed in this workflow is either:

* Already installed in a GitHub Codespaces environment.
* Already available in Docker containers.
* Will be installed via containers during today's exercises.

### GitHub Codespaces

<p style='text-align: justify;'>GitHub Codespaces is almost one of its kind nowadays services as there are really only a few alternative options to replace in case of any problem. It provides a complete self-contained execution environment and connected to an IDE for free! However, the resources are limited on the free tier we will be using for this course. Good news is that it should be sufficient for the purpose of the course, and in normal conditions no one would (hopefully) run out the resources allocated by Codespaces on the free tier.</p>

Without further ado, you can start here:

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/nextflow-io/training?quickstart=1&ref=master)

If by any chance, you exceed the Codespace resources. We have prepared a solution using [CodeSandbox](https://codesandbox.io/). These are the steps to follow:

1. Go to the website: [CodeSandbox](https://codesandbox.io/).
2. Sign in using your GitHub or your Google Account (top right corner).
3. Once signed-in, click on `+ Create` (top right corner).
4. Select `Docker CodeSanbox`.
5. On the `Configure window` leave everything as default and click on Create Devbox.
6. Wait until the microVM is created.
7. Now it looks like VS code. Create a new terminal then.
8. Run the following commands on the terminal:

```bash
curl -s https://get.sdkman.io | bash
source "/root/.sdkman/bin/sdkman-init.sh"
sdk install java 17.0.10-tem
curl -s https://get.nextflow.io | bash
chmod +x nextflow
export PATH=${PATH}:/project/workspace
git clone https://github.com/jeffe107/nextflow-training
cd nextflow-training
```

9. Now you should be into the repository folder, just like on GitHub Codespaces.

All information of this course is based on the [official Nextflow documentation](https://docs.seqera.io/nextflow/) and uses **Nextflow DSL2** syntax.

## Website colour code explanation

We tried to use a colour code throughout the website to make the different pieces of information easily distinguishable. Here's a quick summary about the colour blocks you will encounter:

!!! info "This is a supplementary piece of information"

!!! tip "This is a tip to help you solve an exercise"

!!! success "This is the answer to an exercise"

!!! warning "This is a warning about a potential problem"

!!! bug "This is an explanation about a common bug/error"

## Exercises

Each question provides a background explanation, a description of the task at hand and additional details when required.

!!! tip "Hints for challenging questions"
    For the most challenging questions, hints will be provided. However, you should first try to solve the problem without them!

## Answers

Do not hesitate to modify and overwrite your code from previous answers as difficulty is incremental. The questions are designed to incite you to build your answers upon the previous ones.

!!! tip "Restarting from a clean workflow"
    * If you feel that you drifted too far apart from the solution, you can always review the files provided in the solutions folder:
    ```bash
    cd /workspaces/nextflow-training/solutions/
    ```

If something is not clear at any point, please raise your hand and we will do our best to answer your questions! You can also check the [official Nextflow documentation](https://www.nextflow.io/docs/latest/index.html) for more information.

## Computing environment

!!! tip "Focus only on the execirse folder"
    The repository many other files and directories that may distract you, so just run this command on the terminal to open only the folder where the exercises are:
    ```bash
    code .
    ```