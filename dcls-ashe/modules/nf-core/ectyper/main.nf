process ECTYPER {
    tag "$meta.id"
    label 'process_low'

    conda "bioconda::ectyper=1.0.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ectyper:1.0.0--pyhdfd78af_1' :
        'quay.io/biocontainers/ectyper:1.0.0--pyhdfd78af_1' }"

    input:
    tuple val(meta), path(reads), path(fasta), val (species)

    output:
    tuple val(meta), path("${meta.id}/*.log"), emit: log,optional: true
    path("${meta.id}/*.tsv")                 , emit: tsv,optional: true
    tuple val(meta), path("${meta.id}/*.txt"), emit: txt,optional: true
    path "versions.yml"           , emit: versions, optional: true

    when:
    task.ext.when == null || task.ext.when
    
    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def is_compressed = fasta.getName().endsWith(".gz") ? true : false
    def fasta_name = fasta.getName().replace(".gz", "")
    def species_name = species.replace("\n","")
    """

    if [ "$species_name" == "Escherichia_coli" ]; then
        if [ "$is_compressed" == "true" ]; then
            gzip -c -d $fasta > $fasta_name
        fi

        ectyper \\
            $args \\
            --refseq $projectDir/bin/refseq.genomes.k21s1000.msh \\
            --cores $task.cpus \\
            --output ${prefix} \\
            --verify \\
            --input $fasta_name
        mv $prefix/output.tsv $prefix/${prefix}_ectype.tsv
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ectyper: \$(echo \$(ectyper --version 2>&1)  | sed 's/.*ectyper //; s/ .*\$//')
    END_VERSIONS
    
    """
}
