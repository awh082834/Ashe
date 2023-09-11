process DB_COPY {
    tag "copying DBs"
    label 'process_single'

    script:
    def args = task.ext.args ?: ''
    """
    cp $params.polish_db $projectDir/bin/
    cp $params.ectyper_db $projectDir/bin/
    cp $params.mash_db $projectDir/bin/
    """
}
