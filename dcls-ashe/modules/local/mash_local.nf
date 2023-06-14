process MASH_DIST {
    container 'staphb/mash:latest'
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(query)

    output:
    tuple val(meta), path("${meta.id}/*_top_hits.tab"), emit: top_dist
    path ("${meta.id}/*_top_hits.tab"), emit: report_dist
    path "versions.yml"                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir ${prefix}
    gzip -d $projectDir/bin/RefSeqSketchesDefaults.msh.gz $projectDir/bin/RefSeqSketchesDefaults.msh
    mash dist -p $task.cpus $args $projectDir/bin/RefSeqSketchesDefaults.msh $query > ${prefix}_distance.tab
    sort -gk3 ${prefix}_distance.tab > ${prefix}_sorted_distance.tab
    head ${prefix}_sorted_distance.tab > ${prefix}/${prefix}_top_hits.tab

    gzip $projectDir/bin/RefSeqSketchesDefaults.msh 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mash: \$(mash --version 2>&1)
    END_VERSIONS
    """
}