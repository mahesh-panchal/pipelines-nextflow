process EMBL_APIVALIDATOR {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::embl-api-validator:1.1.180"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/embl-api-validator:1.1.180--py36_0':
        'biocontainers/embl-api-validator:1.1.180--py36_0' }"

    input:
    tuple val(meta), path(file), val(extension)

    output:
    tuple val(meta), env(status)                  , emit: status
    tuple val(meta), path("*.gff3")               , emit: gff3         , optional: true
    tuple val(meta), path("diagnose", type: 'dir'), emit: diagnosis    , optional: true
    tuple val(meta), path("*_good.txt")           , emit: filtered_good, optional: true
    tuple val(meta), path("*_bad.txt")            , emit: filtered_bad , optional: true
    path "versions.yml"                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    status=embl-api-validator \\
        -f $extension \\
        $args \\
        -p ${prefix} \\
        $file \\
        || echo "\$?"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        embl-api-validator: \$(embl-api-validator -version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def mkdir_diagnose = args.contains('-fix_diagnose')? 'mkdir diagnose' : ''
    """
    touch ${prefix}.gff3
    $mkdir_diagnose


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        embl-api-validator: \$(embl-api-validator -version)
    END_VERSIONS
    """
}
