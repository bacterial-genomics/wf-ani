process ANI {

    publishDir "${params.outpath}",
        mode: "${params.publish_dir_mode}",
        pattern: "ANI--*"
    publishDir "${params.process_log_dir}",
        mode: "${params.publish_dir_mode}",
        pattern: ".command.*",
        saveAs: { filename -> "${basename}.${task.process}${filename}" }

    label "process_high"

    container "gregorysprenger/blast-plus-biopython@sha256:3ac93e8a8ad2f2f80393fd8ca9102d1a466fcbeeb18da16e22ad6327e9b197c9"

    input:
        tuple val(pair1), val(pair2), path(asm)

    output:
        path "ANI--*"
        path "ANI--*/ani*stats.tab", emit: stats
        path ".command.out"
        path ".command.err"
        path "versions.yml", emit: versions
        
    shell:
        '''
        source bash_functions.sh

        # Get ANIb+.py and check if it exists
        run_ANI="${DIR}/ANIb+.py"
        check_if_file_exists_allow_seconds ${run_ANI} '60'
        
        # Verify input files exist and not empty
        verify_file_minimum_size "!{pair1}" 'input sequence file' '1k'
        verify_file_minimum_size "!{pair2}" 'input sequence file' '1k'

        # When sample (base)name variable not given, grab from filename
        B1=$(echo !{pair1} | cut -d '/' -f 2 | sed 's/\\.[^.]*$//1' | sed 's/_genomic//1')
        B2=$(echo !{pair2} | cut -d '/' -f 2 | sed 's/\\.[^.]*$//1' | sed 's/_genomic//1')
        
        # Skip comparison if precomputed value exists
        if [ -s "!{params.outpath}/ANI--${B1},${B2}/ani.${B1},${B2}.stats.tab" ]; then
            echo "INFO: found precomputed !{params.outpath}/ANI--${B1},${B2}/ani.${B1},${B2}.stats.tab" >&2
            ANI=$(grep ',' "!{params.outpath}/ANI--${B1},${B2}/ani.${B1},${B2}.stats.tab" | cut -f 3 | sed 's/%//1')
        elif [ -s "!{params.outpath}/ANI--${B2},${B1}/ani.${B2},${B1}.stats.tab" ]; then
            echo "INFO: found precomputed !{params.outpath}/ANI--${B2},${B1}/ani.${B2},${B1}.stats.tab" >&2
            ANI=$(grep ',' "!{params.outpath}/ANI--${B2},${B1}/ani.${B2},${B1}.stats.tab" | cut -f 3 | sed 's/%//1')
        fi

        python ${run_ANI} -1 !{pair1} -2 !{pair2} --name1 ${B1} --name2 ${B2} -c !{task.cpus} \
        -o "ANI--${B1},${B2}"

        cat <<-END_VERSIONS > versions.yml
        "!{task.process}":
            python: $(python --version 2>&1 | awk '{print $2}')
            biopython: $(python -c 'import Bio; print(Bio.__version__)' 2>&1)
            blast: $(blastn -version | head -n 1 | awk '{print $2}')
        END_VERSIONS
        '''
}
