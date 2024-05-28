# Functional annotation pipeline

The functional annotation workflow takes a draft assembly (parameter: `genome`) and
predicted gene coordinates (e.g., from Maker; parameter: `gff_annotation`), and assigns functional
annotation based on similarity to existing protein databases (parameter: `blast_db_fasta`).

## Quick start

Run workflow using the singularity profile:

`params.yml`:

```yml
subworkflow: 'functional_annotation'
genome: '/path/to/genome/assembly.fasta'
gff_annotation: '/path/to/annotation.gff3'
blast_db_fasta: '/path/to/protein/database.fasta'
outdir: '/path/to/save/results'
db_cache: '/path/to/save/interproscan_db/'
```

> [!IMPORTANT]  
> The Interproscan database is huge. If you supply `db_cache` then it will be downloaded
> once and saved in that directory. Setting your `db_cache` to this path for every run
> will then reuse this folder to supply the Interproscan database without re-extracting it again.
>
> Alternatively, set `interproscan_database` to point to the local path of the interproscan database.

Command line:

```bash
nextflow run NBISweden/pipelines-nextflow \
    -profile singularity \
    -params-file params.yml
```

## Parameters

- General:
  - `gff_annotation`:  Path to GFF genome annotation.
  - `genome`: Path to the genome assembly.
  - `outdir`: Path to the results folder.
  - `records_per_file`: Number of fasta records per file to distribute to blast and interproscan (default: 1000).
  - `codon_table`: (default: 1).
  - `blast_db_fasta` : Path to blast protein database fasta.
  - `merge_annotation_identifier`: The identifier to use for labeling genes (default: NBIS).
  - `use_pcds`: If true, enables the pcds flag when merging annotation.
  - `interproscan_database`: Path to interproscan database, if this is a `tar.gz`, the file will be extracted under
    `db_cache` and saved for future use.
  - `db_cahce`: The path to save the untarred Interproscan database archive.

### Tool specific parameters

In these workflows, the Nextflow process directive `ext.args` is used to inject command line tool parameters directly to the shell script.
These command line tool parameters can be changed by overriding the `ext.args` variable for the respective process in a configuration file.

`nextflow.config`:

```nextflow
process {
    withName: 'INTERPROSCAN' {
        ext.args = '--iprlookup --goterms -pa -t p'
    }
}
```

See [Functional annotation modules config](../../config/functional_annotation_modules.config) for the default tool configuration.

## Workflow Stages

1. Extract protein sequences based on GFF coordinates.
2. Blast protein sequences against protein database.
3. Query protein sequences against interproscan databases.
4. Merge functional annotations.
