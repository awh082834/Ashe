process NANOPLOT {
    tag "$meta.id"
    label 'process_low'

    conda "bioconda::nanoplot=1.41.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nanoplot:1.41.0--pyhdfd78af_0' :
        'quay.io/biocontainers/nanoplot:1.41.0--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(ontfile)

    output:
    tuple val(meta), path("${meta.id}/*.html")                , emit: html
    tuple val(meta), path("${meta.id}/*.png") , optional: true, emit: png
    path("${meta.id}/*.txt")                                  , emit: txt
    tuple val(meta), path("${meta.id}/*.log")                 , emit: log
    path  "versions.yml"                                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input_file = ("$ontfile".endsWith(".fastq.gz")) ? "--fastq ${ontfile}" :
        ("$ontfile".endsWith(".txt")) ? "--summary ${ontfile}" : ''
    """
    mkdir ${prefix}
    NanoPlot \\
        -o ${prefix} \\
        --tsv_stats \\
        $args \\
        -t $task.cpus \\
        $input_file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanoplot: \$(echo \$(NanoPlot --version 2>&1) | sed 's/^.*NanoPlot //; s/ .*\$//')
    END_VERSIONS
    """
}
