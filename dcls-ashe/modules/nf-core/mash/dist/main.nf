process MASH_DIST {
    tag "$meta.id"
    label 'process_low'

    conda "bioconda::mash=2.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mash:2.3--he348c14_1' :
        'quay.io/biocontainers/mash:2.3--he348c14_1' }"

    input:
    tuple val(meta), path(query)

    output:
    tuple val(meta), path("${meta.id}/*_sorted.txt"), emit: top_dist
    path ("${meta.id}/*_sorted.txt"), emit: report_dist
    path "versions.yml"                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir ${prefix}
    mkdir $projectDir/bin/mash_$prefix
    cp $params.mash_db $projectDir/bin/mash_$prefix
    gzip -d $projectDir/bin/mash_$prefix/RefSeqSketchesDefaults.msh.gz

    mash \\
        dist \\
        -p $task.cpus \\
        $args \\
        $projectDir/bin/mash_$prefix/RefSeqSketchesDefaults.msh \\
        $query > ${prefix}.txt
    sort -gk3 ${prefix}.txt > ${prefix}/${prefix}_sorted.txt

    rm -rf $projectDir/bin/mash_$prefix

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mash: \$(mash --version 2>&1)
    END_VERSIONS
    """
}
