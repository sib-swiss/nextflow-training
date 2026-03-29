# Nextflow in Action: Build Smarter, Faster, Reproducible Pipelines

![Static Badge](https://img.shields.io/badge/release%20date-march%202025-%230DC09D)

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.19311980.svg)](https://doi.org/10.5281/zenodo.19311980)

[![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC_BY--SA_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)

* Website is hosted at [https://sib-swiss.github.io/nextflow-training/](https://sib-swiss.github.io/nextflow-training/)

* Please refer to [issues](https://github.com/sib-swiss/nextflow-training/issues) for improvements/bugs for course material or the website

* Any contribution to this course material is highly appreciated :+1:. Please have a look at the [CONTRIBUTING.md](CONTRIBUTING.md) file to learn more on how to contribute

## Author

* [Jeferyd Yepes-García](https://jeferydyepes.com/)

## How to host the website locally?

Once you have cloned the repo, you can host it on your local browser. The website is generated with [MkDocs](https://www.mkdocs.org/), with the [Material](https://squidfunk.github.io/mkdocs-material/) theme.

* Clone the repository:
	```bash
	git clone https://github.com/sib-swiss/nextflow-training
	```

* Install MkDocs:
	```bash
	pip install mkdocs
	```

* And Material:
	```bash
	pip install mkdocs-material
	```

* Make sure you are in the repository directory and type:
	```bash
	mkdocs serve
	```

The website will be hosted on your local browser at [http://localhost:8000/](http://localhost:8000/).

## How to generate a github page?

For an automatically generated github page, you can run:

```sh
mkdocs gh-deploy
```
