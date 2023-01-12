process GENERATE_PAIRS {

    publishDir "${params.outpath}",
        mode: "${params.publish_dir_mode}",
        pattern: "*.fofn"
    publishDir "${params.process_log_dir}",
        mode: "${params.publish_dir_mode}",
        pattern: ".command.*",
        saveAs: { filename -> "${task.process}${filename}" }

    container "gregorysprenger/biopython@sha256:77a50d5d901709923936af92a0b141d22867e3556ef4a99c7009a5e7e0101cc1"

    input:
        path asm
        path query

    output:
        path "genomes.fofn"
        path "pairs.fofn", emit: pairs
        path ".command.out"
        path ".command.err"
        path "versions.yml", emit: versions
        
    shell:
        '''
        source bash_functions.sh

        # Place assembly files into new variable
        ASM=()
        for file in !{asm}/*; do
            ASM+=( $(basename ${file}) )
        done

        # Generate list of pairwise comparisons
        genomes="genomes.fofn"
        printf "%s\n" "${ASM[@]}" > "${genomes}"

        # Generate pairs
        if [[ -f !{query} ]]; then
            # If query is a file and not null,
            # Append query to genomes.fofn
            echo -e "assemblies/!{query}" >> ${genomes}

            # Create pairs.fofn
            for file in "${ASM[@]}"; do
                echo -e "!{query}\t${file}" >> pairs.fofn
            done

            # Make sure there are file pairs to analyze
            if [ $(wc -l pairs.fofn) -eq 0 ]; then
                msg 'ERROR: no file pairs to submit for analysis' >&2
                exit 1
            fi

            # Move query to assemblies folder for ANI process
            mv !{query} assemblies

        else
            # If query is not a file
            tasks_per_job=20000

            # Create environment variables
            export genomes tasks_per_job
            
            # Use python3 to find all possible combinations of files
            # Script placed into bash_functions.sh due to line indention errors
            find_combinations

            if [ ${#COMBO_FILES[@]} -eq 0 ]; then
                msg 'ERROR: no file pairs to submit for analysis' >&2
                exit 1
            fi
        fi

        pairs_file_length=$(awk 'END {print NR}' pairs.fofn)
        msg "INFO: Pairs file, 'pairs.fofn', created with ${pairs_file_length} pairs"

        # Add version info to versions.yml
        echo "!{task.process}" >> versions.yml
        echo "    python: $(python --version 2>&1 | awk '{print $2}')" >> versions.yml
        '''
}
