include { UNTAR                                                          } from "$projectDir/modules/nf-core/untar/main"
include { BLAST_MAKEBLASTDB                                              } from "$projectDir/modules/nf-core/blast/makeblastdb/main"
include { AGAT_EXTRACTSEQUENCES as GFF2PROTEIN                           } from "$projectDir/modules/local/agat/extractsequences"
include { BLAST_BLASTP                                                   } from "$projectDir/modules/local/blast/blastp"
include { INTERPROSCAN                                                   } from "$projectDir/modules/local/interproscan"
// include { INTERPROSCAN                                                   } from "$projectDir/modules/nf-core/interproscan"
include { AGAT_MANAGEFUNCTIONALANNOTATION as MERGE_FUNCTIONAL_ANNOTATION } from "$projectDir/modules/local/agat/managefunctionalannotation"

workflow FUNCTIONAL_ANNOTATION {

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
    Channel.fromPath( params.blast_db_fasta, checkIfExists: true )
        .tap { blast_fa }
        .branch { fasta -> 
            def db_files = [ fasta ] 
            try {
                db_files = [ fasta ] + file( fasta + ".p*", checkIfExists: true )
            } catch ( Exception e ){
                // No database files found matching the glob pattern
            }
            make_db : db_files.size() == 1
                return [ [ id: fasta.baseName ] , db_files ]
            with_db : db_files.size() > 1
                return [ [ id: fasta.baseName ] , db_files ]
        }.set { ch_blast_fa }

    if ( params.interproscan_database?.endsWith('.tar.gz') ){
        UNTAR( 
            Channel.fromPath(params.interproscan_database, checkIfExists: true)
                .map { db -> [ [id: db.baseName(2) ], db ] }
        )
        .untar.set { ch_interpro_db }
    } else if ( params.interproscan_database ) {
        Channel.fromPath(params.interproscan_database, checkIfExists: true)
            .set { ch_interpro_db }
    } else {
        Channel.empty().set { ch_interpro_db }
    }
    BLAST_MAKEBLASTDB(
        ch_blast_fa.make_db
    )
    blastdb_ch = BLAST_MAKEBLASTDB.out.db.mix( ch_blast_fa.with_db )
    GFF2PROTEIN( 
        gff_file, 
        genome.collect()
    )
    BLAST_BLASTP(
        GFF2PROTEIN.out.proteins.splitFasta( by: params.records_per_file, file: true ),
        blastdb_ch.map{ meta, db -> db }.collect()
    )
    INTERPROSCAN( 
        GFF2PROTEIN.out.proteins.splitFasta( by: params.records_per_file, file: true ),
        ch_interpro_db.toList()
    )
    MERGE_FUNCTIONAL_ANNOTATION(
        gff_file,
        BLAST_BLASTP.out.txt.map{ meta, txt -> txt }.collectFile( name: 'blast_merged.tsv' ),
        INTERPROSCAN.out.tsv.map{ meta, tsv -> tsv }.collectFile( name: 'interproscan_merged.tsv' ),
        blast_fa.collect()
    )
}
