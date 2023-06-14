//
//  Obtain Species ID from Mash
//


include { SEQSERO2    } from '../../modules/nf-core/seqsero2'
include { EMMTYPER    } from '../../modules/nf-core/emmtyper'
include { ECTYPER     } from '../../modules/nf-core/ectyper'

workflow SPECIES_ID {
    take:
    assembly
    species

    main:

    SEQSERO2(
        assembly, species
    )

    EMMTYPER(
        assembly, species
    )

    ECTYPER(
        assembly, species
    )

    emit:
    results
    
}