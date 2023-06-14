process SEQSERO2 {
    tag "$meta.id"
    label 'process_low'

    conda "bioconda::seqsero2=1.2.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqsero2:1.2.1--py_0' :
        'quay.io/biocontainers/seqsero2:1.2.1--py_0' }"

    input:
    tuple val(meta), path(reads), path(seqs), val (species)

    output:
    tuple val(meta), path("${meta.id}/*_log.txt")   , emit: log, optional: true
    path("${meta.id}/*_result.tsv")                 , emit: tsv, optional: true
    tuple val(meta), path("${meta.id}/*_result.txt"), emit: txt, optional: true
    path "versions.yml"                          , emit: versions, optional: true

    when:
    task.ext.when == null || task.ext.when
    

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def species_name = species.replace("\n","")
    """
    if [ "$species_name" == "Salmonella_enterica" ]; then
        SeqSero2_package.py \\
            $args \\
            -d $prefix/ \\
            -n $prefix \\
            -p $task.cpus \\
            -m k \\
            -t 4 \\
            -i $seqs
    fi
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqsero2: \$( echo \$( SeqSero2_package.py --version 2>&1) | sed 's/^.*SeqSero2_package.py //' )
    END_VERSIONS

    """
}
