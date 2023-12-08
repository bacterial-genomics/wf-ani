process ANI_BLAST_BIOPYTHON {

    publishDir "${params.outdir}/comparisons",
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
    tuple val(filename1), val(filename2)
    path asm            , stageAs: 'assemblies/*'

    output:
    path "ANI--*"
    path ".command.out"
    path ".command.err"
    path "versions.yml"        , emit: versions
    path "ANI--*/ani*stats.tab", emit: ani_stats

    shell:
    // Get basename of input
    base1 = filename1.split('\\.')[0].split('_genomic')[0];
    base2 = filename2.split('\\.')[0].split('_genomic')[0];

    // Optional params
    small_frags = params.keep_final_fragment ? "" : "--keep-small-frags"
    '''
    source bash_functions.sh

    # Skip comparison if precomputed value exists
    ANI=""
    if [ -s "!{params.outdir}/ANI--!{base1},!{base2}/ani.!{base1},!{base2}.stats.tab" ]; then
      msg "INFO: Found precomputed !{params.outdir}/ANI--!{base1},!{base2}/ani.!{base1},!{base2}.stats.tab" >&2
      ANI=$(grep ',' "!{params.outdir}/ANI--!{base1},!{base2}/ani.!{base1},!{base2}.stats.tab" | cut -f 3 | sed 's/%//1')
    elif [ -s "!{params.outdir}/ANI--!{base2},!{base1}/ani.!{base2},!{base1}.stats.tab" ]; then
      msg "INFO: Found precomputed !{params.outdir}/ANI--!{base2},!{base1}/ani.!{base2},!{base1}.stats.tab" >&2
      ANI=$(grep ',' "!{params.outdir}/ANI--!{base2},!{base1}/ani.!{base2},!{base1}.stats.tab" | cut -f 3 | sed 's/%//1')
    fi
    if [[ ! -z ${ANI} ]]; then
      if [[ "${ANI%.*}" -ge 0 && "${ANI%.*}" -le 100 ]]; then
        msg "INFO: Found ANI ${ANI} for !{base1},!{base2}; skipping the comparison" >&2
        exit 0
      fi
    fi

    msg "INFO: Performing ANI on !{base1} and !{base2}."

    ANIb+.py \
      -1 assemblies/!{filename1} \
      -2 assemblies/!{filename2} \
      --name1 !{base1} \
      --name2 !{base2} \
      !{small_frags} \
      -c !{task.cpus} \
      -s !{params.step_size} \
      -o "ANI--!{base1},!{base2}" \
      -w !{params.nucleotide_fragment_size} \
      --min-ACGT !{params.min_ACGT_fraction} \
      -i !{params.min_fragment_percent_identity} \
      -l !{params.min_fragment_alignment_length} \
      -f !{params.min_fraction_alignment_percentage} \
      --min-aln-len !{params.min_two_way_alignment_length} \
      --min-aln-frac !{params.min_two_way_alignment_fraction}

    cat <<-END_VERSIONS > versions.yml
    "!{task.process}":
      python: $(python --version 2>&1 | awk '{print $2}')
      blast: $(blastn -version | head -n 1 | awk '{print $2}')
      biopython: $(python -c 'import Bio; print(Bio.__version__)' 2>&1)
    END_VERSIONS
    '''
}
