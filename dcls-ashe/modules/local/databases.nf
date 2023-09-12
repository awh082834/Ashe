process DB_COPY {
    tag "copying DBs"
    label 'process_single'

    script:
    def args = task.ext.args ?: ''
    """
    FILE1=$projectDir/bin/bacteria.msh
    FILE2=$projectDir/bin/refseq.genomes.k21s1000.msh
    FILE3=$projectDir/bin/RefSeqSketchesDefaults.msh
    
    if ! [ -f "\$FILE1" ]; then
        cp $params.polish_db $projectDir/bin/
    fi

    if ! [ -f "\$FILE2" ]; then  
        cp $params.ectyper_db $projectDir/bin/
    fi

    if ! [ -f "\$FILE3" ]; then
        cp $params.mash_db $projectDir/bin/
    fi
    
    """
}
