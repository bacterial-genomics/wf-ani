process INFILE_HANDLING_UNIX {

    publishDir "${params.process_log_dir}",
        mode: "${params.publish_dir_mode}",
        pattern: ".command.*",
        saveAs: { filename -> "${prefix}.${task.process}${filename}" }

    container "ubuntu:jammy"

    input:
    tuple val(meta), path(input)

    output:
    path ".command.out"
    path ".command.err"
    path "genomes.fofn"           , emit: genomes
    path "versions.yml"           , emit: versions
    path "assemblies/*"           , emit: asm_files
    path "Initial_Input_Files.tsv", emit: qc_input_filecheck

    shell:
    // Remove spaces from meta.id and get file extension
    prefix="${meta.id}".replaceAll(' ', '_');
    extension="${input}".split('\\.')[1..-1].join('.');
    '''
    source bash_functions.sh

    # Rename input files to prefix and move to assemblies dir
    mkdir assemblies
    cp !{input} assemblies/"!{prefix}"

    # gunzip all files that end in .{gz,Gz,GZ,gZ}
    find -L assemblies/ -type f -name '*.[gG][zZ]' -exec gunzip -f {} +

    # Filter out small genomes
    msg "Checking input file sizes.."
    for file in assemblies/*; do
      if [[ $(find -L "${file}" -type f -size +"!{params.min_input_filesize}" 2>/dev/null) ]]; then
        echo -e "$(basename ${file})\tInitial_Input File\tPASS" \
        >> Initial_Input_Files.tsv

        # Generate list of genomes
        echo -e "$(basename ${file})" >> genomes.fofn
      else
        echo -e "$(basename ${file})\tInitial_Input File\tFAIL" \
        >> Initial_Input_Files.tsv
        echo -e "" >> genomes.fofn

        msg "INFO: $(basename ${file}) not >!{params.min_input_filesize} so it was not included in the analysis"
        rm ${file}
      fi
    done

    cat <<-END_VERSIONS > versions.yml
    "!{task.process}":
      ubuntu: $(awk -F ' ' '{print $2,$3}' /etc/issue | tr -d '\\n')
    END_VERSIONS
    '''
}
