process ANI_BLAST_BIOPYTHON {

    publishDir "${params.outpath}",
        mode: "${params.publish_dir_mode}",
        pattern: "ANI--*"
    publishDir "${params.process_log_dir}",
        mode: "${params.publish_dir_mode}",
        pattern: ".command.*",
        saveAs: { filename -> "${base1}_${base2}.${task.process}${filename}" }

    label "process_high"
    tag( "${base1}_${base2}" )

    container "gregorysprenger/blast-plus-biopython@sha256:dc6a4cd2d3675b6782dbe88a0852663a7f9406670b4178867b8b230eb3be0d0d"

    input:
        tuple val(filename1), val(filename2), path(filepair1), path(filepair2)

    output:
        path "ANI--*"
        path "ANI--*/ani*stats.tab", emit: ani_stats
        path ".command.out"
        path ".command.err"
        path "versions.yml", emit: versions
        
    shell:
        // Get basename of pair1 and pair2 to add to .command.out/err log files
        base1=filename1.split('\\.')[0].split('_genomic')[0]; 
        base2=filename2.split('\\.')[0].split('_genomic')[0];

        // Set blastn_ani_script parameters
        ani_blast_params = "-f ${params.min_fraction_alignment_percentage}"
        if (params.min_fragment_percent_identity != '30.0') {
            ani_blast_params += " -i ${params.min_fragment_percent_identity}"
        }
        if (params.min_fragment_alignment_length != '0') {
            ani_blast_params += " -l ${params.min_fragment_alignment_length}"
        }
        if (params.step_size != '200') {
            ani_blast_params += " -s ${params.step_size}"
        }
        if (params.nucleotide_fragment_size != '1000') {
            ani_blast_params += " -w ${params.nucleotide_fragment_size}"
        }
        if (params.keep_final_fragment != 'False') {
            ani_blast_params += " --keep-small-frags"
        }
        if (params.min_ACGT_fraction != '0.97') {
            ani_blast_params += " --min-ACGT ${params.min_ACGT_fraction}"
        }
        if (params.min_two_way_alignment_fraction != '0') {
            ani_blast_params += " --min-aln-frac ${params.min_two_way_alignment_fraction}"
        }
        if (params.min_two_way_alignment_length != '0') {
            ani_blast_params += " --min-aln-len ${params.min_two_way_alignment_length}"
        }
        '''
        source bash_functions.sh

        # Get ANIb+.py and check if it exists
        blastn_ani_script="${DIR}/ANIb+.py"
        if ! check_if_file_exists_allow_seconds ${blastn_ani_script} '60'; then
          exit 1
        fi
       
        # Verify input files exist and not empty
        verify_minimum_file_size "!{filepair1}" 'Input sequence' "!{params.min_filesize_filepair1}"
        verify_minimum_file_size "!{filepair2}" 'Input sequence' "!{params.min_filesize_filepair2}"

        # When sample basename variable not given, grab from filename
        B1=$(echo !{filename1} | sed 's/\\.[^.]*$//1' | sed 's/_genomic//1')
        B2=$(echo !{filename2} | sed 's/\\.[^.]*$//1' | sed 's/_genomic//1')
        
        # Skip comparison if precomputed value exists
        ANI=""
        if [ -s "!{params.outpath}/ANI--${B1},${B2}/ani.${B1},${B2}.stats.tab" ]; then
          msg "INFO: Found precomputed !{params.outpath}/ANI--${B1},${B2}/ani.${B1},${B2}.stats.tab" >&2
          ANI=$(grep ',' "!{params.outpath}/ANI--${B1},${B2}/ani.${B1},${B2}.stats.tab" | cut -f 3 | sed 's/%//1')
        elif [ -s "!{params.outpath}/ANI--${B2},${B1}/ani.${B2},${B1}.stats.tab" ]; then
          msg "INFO: Found precomputed !{params.outpath}/ANI--${B2},${B1}/ani.${B2},${B1}.stats.tab" >&2
          ANI=$(grep ',' "!{params.outpath}/ANI--${B2},${B1}/ani.${B2},${B1}.stats.tab" | cut -f 3 | sed 's/%//1')
        fi
        if [[ ! -z ${ANI} ]]; then
          if [[ "${ANI%.*}" -ge 0 && "${ANI%.*}" -le 100 ]]; then
            msg "INFO: Found ANI ${ANI} for ${B1},${B2}; skipping the comparison" >&2
            exit 0
          fi
        fi

        msg "INFO: Performing ANI on ${B1} and ${B2}."

        python ${blastn_ani_script} \
          -1 !{filepair1} \
          -2 !{filepair2} \
          --name1 ${B1} \
          --name2 ${B2} \
          -c !{task.cpus} \
          -o "ANI--${B1},${B2}" \
          !{ani_blast_params}

        cat <<-END_VERSIONS > versions.yml
        "!{task.process} (${B1}_${B2})":
          python: $(python --version 2>&1 | awk '{print $2}')
          biopython: $(python -c 'import Bio; print(Bio.__version__)' 2>&1)
          blast: $(blastn -version | head -n 1 | awk '{print $2}')
        END_VERSIONS
        '''
}
