include { EMBL_APIVALIDATOR } from "$projectDir/modules/local/embl/apivalidator"

workflow FORMAT_VALIDATION {

    main:
    log.info """
        Functional annotation workflow
        ===================================================
    """
    Channel.fromPath( params.gff_annotation, checkIfExists: true )
        .map { gff -> [ [ id: gff.baseName ], gff ] }
        .set { gff_file }
    Channel.fromPath( params.genome, checkIfExists: true )
        .set { genome }

    EMBL_APIVALIDATOR ( gff_file.map { meta, gff -> [ meta, gff, gff.getExtension() ] } )
}