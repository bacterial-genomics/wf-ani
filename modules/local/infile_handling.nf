process INFILE_HANDLING {

    publishDir "${params.process_log_dir}",
        mode: "${params.publish_dir_mode}",
        pattern: ".command.*",
        saveAs: { filename -> "${basename}.${task.process}${filename}" }

        container "ubuntu:focal"

    input:
        path input

    output:
        path input, emit: input
        path assemblies, emit: asm
        path ".command.out"
        path ".command.err"
        
    shell:
        '''
        source bash_functions.sh
        
        # Get input data
        shopt -s nullglob
        compressed_asm=( "!{input}"/*.{fa,fas,fsa,fna,fasta,gb,gbk,gbf,gbff}.gz )
        plaintext_asm=( "!{input}"/*.{fa,fas,fsa,fna,fasta,gb,gbk,gbf,gbff} )
        shopt -u nullglob
        msg "INFO: ${#compressed_asm[@]} compressed assemblies found"
        msg "INFO: ${#plaintext_asm[@]} plain text assemblies found"

        # Check if total inputs are > 2
        total_inputs=$(( ${#compressed_asm[@]} + ${#plaintext_asm[@]} ))
        if [[ ${total_inputs} -lt 2 ]]; then
            msg 'ERROR: at least 2 genomes are required for batch analysis' >&2
        exit 1
        fi

        # Make tmp directory and move assemblies
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
        msg "INFO: ${#ASM[@]} assemblies found after gunzip (if needed)"

        # Filter out and report unusually small genomes
        FNA=()
        for A in "${ASM[@]}"; do
        # TO-DO: file content corruption and format validation tests
        if [[ $(find -L "$A" -type f -size +45k 2>/dev/null) ]]; then
            FNA+=("$A")
        else
            msg "INFO: $A not >45 kB so it was not included in the analysis" >&2
        fi
        done
        if [ ${#FNA[@]} -lt 2 ]; then
            msg 'ERROR: found <2 genome files >45 kB' >&2
        exit 1
        fi

        cat <<-END_VERSIONS > versions.yml
        "!{task.process}":
            ubuntu: $(cat /etc/issue)
        END_VERSIONS
        '''
}
