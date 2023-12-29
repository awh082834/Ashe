process ROTATE {

    errorStrategy 'ignore'
    tag "$meta.id: $prefix"
    label 'process_med'

    conda "conda-forge::python=3.8.3"
    container "quay.io/biocontainers/dnaapler:0.3.0--pyhdfd78af_0"

    input:
    tuple val(meta), path(dummy1), path(fasta), path(info)

    output:
    tuple val(meta), path("*.fastq"), path("$outdir/*_reoriented.fasta") , emit: rotated

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix   = task.ext.prefix ?: "${fasta}"
    prefix = prefix.take(prefix.lastIndexOf('.'))
    outdir = "${meta.id}_${prefix}"
    readName = "${meta.id}_"

    """
    mv $dummy1 ${readName}.fastq
    TEMP="temp.txt"

    awk '\$4=="N"{print \$1}' $info >> \$TEMP
    if [ \$(wc -l < \$TEMP) -eq 0 ]; then
        dnaapler all --input $fasta -o $outdir -p $prefix -t $task.cpus
    else
        dnaapler all --input $fasta -o $outdir -p $prefix -t $task.cpus --ignore \$TEMP
    fi
    """ 
}