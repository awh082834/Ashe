process FLYE {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::flye=2.9"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/flye:2.9--py39h6935b12_1' :
        'quay.io/biocontainers/flye:2.9--py39h6935b12_1' }"

    input:
    tuple val(meta), path(reads)
    val mode

    output:
    tuple val(meta), path(reads), path("${meta.id}/*.fasta.gz"), emit: assem
    tuple val(meta), path("${meta.id}/*.gfa.gz")  , emit: gfa
    tuple val(meta), path("${meta.id}/*.gv.gz")   , emit: gv
    tuple val(meta), path("${meta.id}/*.txt")     , emit: txt
    tuple val(meta), path("${meta.id}/*.log")     , emit: log
    tuple val(meta), path("${meta.id}/*.json")    , emit: json
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def valid_mode = ["--pacbio-raw", "--pacbio-corr", "--pacbio-hifi", "--nano-raw", "--nano-corr", "--nano-hq"]
    if ( !valid_mode.contains(mode) )  { error "Unrecognised mode to run Flye. Options: ${valid_mode.join(', ')}" }
    """
    flye \\
        $mode \\
        $reads \\
        -i 2 \\
        --out-dir . \\
        --threads \\
        $task.cpus \\
        $args

    mkdir ${prefix}

    gzip -c assembly.fasta > ${prefix}.assembly.fasta.gz
    mv ${prefix}.assembly.fasta.gz ${prefix}
    gzip -c assembly_graph.gfa > ${prefix}.assembly_graph.gfa.gz
    mv ${prefix}.assembly_graph.gfa.gz ${prefix}
    gzip -c assembly_graph.gv > ${prefix}.assembly_graph.gv.gz
    mv ${prefix}.assembly_graph.gv.gz ${prefix}
    mv assembly_info.txt ${prefix}/${prefix}.assembly_info.txt
    mv flye.log ${prefix}/${prefix}.flye.log
    mv params.json ${prefix}/${prefix}.params.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        flye: \$( flye --version )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo stub > assembly.fasta | gzip -c assembly.fasta > ${prefix}.assembly.fasta.gz
    echo stub > assembly_graph.gfa | gzip -c assembly_graph.gfa > ${prefix}.assembly_graph.gfa.gz
    echo stub > assembly_graph.gv | gzip -c assembly_graph.gv > ${prefix}.assembly_graph.gv.gz
    echo contig_1 > ${prefix}.assembly_info.txt
    echo stub > ${prefix}.flye.log
    echo stub > ${prefix}.params.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        flye: \$( flye --version )
    END_VERSIONS
    """
}
