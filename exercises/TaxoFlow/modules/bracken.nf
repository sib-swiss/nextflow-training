process BRACKEN {
    tag "${sample_id}"
    container "community.wave.seqera.io/library/bracken:3.1--22a4e66ce04c5e01"

    input:
    tuple val(sample_id), path(k2report), path(kraken2)
    path kraken2_db

    output:
    tuple val("${sample_id}"), path("${sample_id}.breport"), path("${sample_id}.bracken")

    script:
    """
    bracken -d $kraken2_db \
    -i ${k2report} -r 250 -l S -t 2 \
    -o ${sample_id}.bracken \
    -w ${sample_id}.breport
    """

}
