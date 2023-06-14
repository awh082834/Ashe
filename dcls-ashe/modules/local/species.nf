process SPECIES {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(top_hits)

    output:
    tuple val(meta), stdout, emit: species_id

    script:
    """
    #!/usr/bin/env python3
    import re
    import glob
    
    with open('$top_hits', 'r') as infile:
        for line in infile:
            top_hit = line

            top_hit = re.sub(r'.*-\\.-', '', top_hit)
            top_hit=top_hit.split()
            top_hit=top_hit[0]
            top_hit=re.match(r'^[^_]*_[^_]*', top_hit).group(0)
            top_hit=re.sub(r'.fna', '', top_hit)

            if "_sp." not in top_hit:
                top_hit = top_hit.split('_')
                top_hit = top_hit[0] + "_" + top_hit[1]
                break
                
        infile.close()
        print(top_hit)
    """
}