#!/usr/bin/env nextflow

include {TaxoFlow} from './workflow.nf'

workflow {

    main:

    if(params.reads){
            reads_ch = channel.fromFilePairs(params.reads, checkIfExists:true)
        } else {
            reads_ch = channel.fromPath(params.sheet_csv)
                            .splitCsv(header:true)
                            .map {row -> tuple(row.sample_id, [file(row.fastq_1), file(row.fastq_2)])}
        }

    TaxoFlow(params.bowtie2_index, params.kraken2_db, reads_ch)

    // publish files
    publish:

    bowtie_unali = TaxoFlow.out.bowtie_unali
    kraken_class = TaxoFlow.out.kraken_class
    bracken_class = TaxoFlow.out.bracken_class
    k_report = TaxoFlow.out.k_report
    biom = TaxoFlow.out.biom

}

output {

    bowtie_unali {
        path 'bowtie2'
    }
    kraken_class {
        path 'kraken2'
    }
    bracken_class {
        path 'bracken'
    }
    k_report {
        path 'k_report'
    }
    biom {
        path 'biom'
    }
}
