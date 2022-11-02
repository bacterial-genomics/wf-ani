process GENERATE_PAIRS {

    publishDir "${params.outpath}",
        mode: "${params.publish_dir_mode}",
        pattern: "*.fofn"
    publishDir "${params.process_log_dir}",
        mode: "${params.publish_dir_mode}",
        pattern: ".command.*",
        saveAs: { filename -> "${basename}.${task.process}${filename}" }

        container "snads/biopython@sha256:bb041f55fd45d0fb577656e2d1f1a9f477d3ba80878b3b42218adff3322ae06e"

    input:
        path asm

    output:
        path "genomes.fofn"
        path "pairs*.fofn", emit: pairs
        path ".command.out"
        path ".command.err"
        path "versions.yml", emit: versions
        
    shell:
        '''
        source bash_functions.sh

        # Place assembly files into new variable
        ASM=( !{asm}/* )

        # Generate list of pairwise comparisons
        genomes="genomes.fofn"
        printf "%s\n" "${ASM[@]}" > "${genomes}"
        tasks_per_job=20000

        # Create environment variables
        export OUT genomes tasks_per_job
        
        # Use python3 to find all possible combinations of files
        # Script placed into bash_functions.sh due to line indention errors
        find_combinations

        if [ ${#COMBO_FILES[@]} -eq 0 ]; then
            msg 'ERROR: no file pairs to submit for analysis' >&2
            exit 1
        fi

        pairs_file=$(find . -name *pairs* | rev | cut -d '/' -f 1 | rev)
        pairs_file_length=$(awk '{print NR}' ${pairs_file})
        msg "INFO: Pairs file, '${pairs_file}', created with ${pairs_file_length} pairs"

        cat <<-END_VERSIONS > versions.yml
        "!{task.process}":
            ubuntu: $(cat /etc/issue)
        END_VERSIONS
        '''
}
