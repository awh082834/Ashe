process HOMOPOLISH {
    container 'staphb/homopolish:latest'
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(reads), path(assem)

    output:
    tuple val(meta), path(reads), path("homopolish/${meta.id}_homopolished.fasta"), emit: polished_assem
    path "versions.yml"                                                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    cp $params.polish_db $projectDir/bin/
    gzip -d $projectDir/bin/bacteria.msh.gz

    gzip -d --force $assem
    homopolish polish -m R9.4.pkl \\
        -a ${prefix}.fa \\
        -s $projectDir/bin/bacteria.msh \\
        -t $task.cpus \\
        -o homopolish
    rm ${prefix}.fa

    rm -rf $projectDir/bin/bacteria.msh

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        homopolish: staphb/homopolish:latest
    END_VERSIONS
    """
}