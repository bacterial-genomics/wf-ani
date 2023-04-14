process INFILE_HANDLING_UNIX {

    publishDir "${params.process_log_dir}",
        mode: "${params.publish_dir_mode}",
        pattern: ".command.*",
        saveAs: { filename -> "${task.process}${filename}" }

    container "ubuntu:jammy"

    input:
        path input_dir
        path query_input

    output:
        path "assemblies"
        path "assemblies/*", emit: asm_files
        path ".command.out"
        path ".command.err"
        path "versions.yml", emit: versions
        
    shell:
        '''
        source bash_functions.sh
                
        # Get input data
        shopt -s nullglob
        compressed_asm=( "!{input_dir}"/*.{fa,fas,fsa,fna,fasta,gb,gbk,gbf,gbff}.gz )
        plaintext_asm=( "!{input_dir}"/*.{fa,fas,fsa,fna,fasta,gb,gbk,gbf,gbff} )
        shopt -u nullglob
        
        msg "INFO: ${#compressed_asm[@]} compressed assemblies found"
        msg "INFO: ${#plaintext_asm[@]} plain text assemblies found"

        # Modify total_inputs if !{query_input} is present
        if [[ -f !{query_input} ]]; then
          verify_minimum_file_size "!{query_input}" 'Query input file' "!{params.min_filesize_query_input}"
          total_inputs=$(( ${#compressed_asm[@]} + ${#plaintext_asm[@]} + 1 ))
        else
          total_inputs=$(( ${#compressed_asm[@]} + ${#plaintext_asm[@]} ))
        fi

        # Check if total inputs are > 2
        if [[ ${total_inputs} -lt 2 ]]; then
          msg 'ERROR: At least 2 genomes are required for batch analysis' >&2
          exit 1
        fi

        # Make assemblies directory and move files to assemblies dir
        mkdir assemblies
        for file in "${compressed_asm[@]}" "${plaintext_asm[@]}"; do
          cp ${file} assemblies
        done

        # Decompress files
        if [[ ${#compressed_asm[@]} -ge 1 ]]; then
          gunzip ./assemblies/*.gz
        fi

        # Get all assembly files after gunzip
        shopt -s nullglob
        ASM=( ./assemblies/*.{fa,fas,fsa,fna,fasta,gb,gbk,gbf,gbff} )
        shopt -u nullglob

        msg "INFO: Total number of genomes: ${#ASM[@]}"

        # Filter out and report unusually small genomes
        FNA=()
        for A in "${ASM[@]}"; do
        # TO-DO: file content corruption and format validation tests
          if [[ $(find -L "$A" -type f -size +"!{params.min_filesize_assembly_input_dir}" 2>/dev/null) ]]; then
            FNA+=("$A")
          else
            msg "INFO: $(basename ${A}) not >!{params.min_filesize_assembly_input_dir}B so it was not included in the analysis" >&2
          fi
        done

        # Check if total inputs are > 2
        if [ ${#FNA[@]} -lt 2 ]; then
          msg 'ERROR: Found <2 genome files >!{params.min_filesize_assembly_input_dir}B' >&2
          exit 1
        fi

        cat <<-END_VERSIONS > versions.yml
        "!{task.process}":
          ubuntu: $(awk -F ' ' '{print $2,$3}' /etc/issue | tr -d '\\n')
        END_VERSIONS
        '''
}
