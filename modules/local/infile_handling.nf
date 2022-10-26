process INFILE_HANDLING {

    publishDir "${params.process_log_dir}",
        mode: "${params.publish_dir_mode}",
        pattern: ".command.*",
        saveAs: { filename -> "${basename}.${task.process}${filename}" }

    input:
        tuple val(basename), path(input)

    output:
        path input, emit: input
        val basename, emit: base
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

        total_inputs=$(( ${#compressed_asm[@]} + ${#plaintext[@]} ))

        if [ ${#total_inputs[@]} -lt 2 ]; then
            echo 'ERROR: at least 2 genomes are required for batch analysis' >&2
        exit 1
        fi

        if [[ ${#compressed_asm[@]} -ge 1 ]]; then
            gunzip !{input}/*.gz
        fi
        '''
}
