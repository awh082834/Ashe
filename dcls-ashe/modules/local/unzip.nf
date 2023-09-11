process UNZIP{
    tag "$meta.id"
    label "process_low"

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    tuple val(meta), path(longReads),path(zippedASSEM), path(info)
    tuple val(meta), path(gfa)

    output:
    tuple val(meta), path ('*.fastq'), path ('*.fasta'), path('*_assem_info.txt') , emit: unzip_assem
    tuple val(meta), path ('*.gfa') , emit:unzippedGFA
    script:
    """
    gzip -d $zippedASSEM
    gzip -d $longReads
    gzip -d $gfa
    mv $info ${meta.id}_assem_info.txt
    """
}