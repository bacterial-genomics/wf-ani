process ANI_SKANI {

    label "process_high"
    tag( "${base1}-${base2}" )
    container "gregorysprenger/skani@sha256:f775f114281a7bd647467a13b90d243ec32ab3f7763c5dbeb06be5e35a842bb6"

    input:
    tuple val(filename1), val(filename2)
    path(asm)           , stageAs: 'assemblies/*'

    output:
    path("skani.out")         , emit: ani_stats
    path(".command.{out,err}")
    path("versions.yml")      , emit: versions

    shell:
    // Get basename of input
    base1 = filename1.split('\\.')[0].split('_genomic')[0];
    base2 = filename2.split('\\.')[0].split('_genomic')[0];

    // Optional params
    median               = params.skani_estimate_median          ? "--median"      : ""
    multi_line           = params.skani_multi_line_fasta         ? "--qi --ri"     : ""
    learned_ani          = params.skani_learned_ani              ? "--learned-ani" : ""
    confidence_intervals = params.skani_confidence_intervals     ? "--ci"          : ""
    estimate_mean        = params.skani_estimate_mean_after_trim ? "--robust"      : ""

    // Max results. 0 = unlimited, else use specified value
    if (params.skani_max_results == 0) {
      max_results = ""
    } else {
      max_results = "-n ${params.skani_max_results}"
    }

    // Speed of skani alters accuracy.
    if (params.skani_speed == "fast") {
      speed = "--fast"
    } else if (params.skani_speed == "medium") {
      speed = "--medium"
    } else if (params.skani_speed == "slow") {
      speed = "--slow"
    } else {
      speed = ""
    }
    '''
    source bash_functions.sh

    # Run skani
    skani dist \
      -q "assemblies/!{filename1}" \
      -r "assemblies/!{filename2}" \
      -o skani.out \
      -v \
      !{speed} \
      !{median} \
      --detailed \
      !{multi_line} \
      !{max_results} \
      !{learned_ani} \
      -t !{task.cpus} \
      !{estimate_mean} \
      !{confidence_intervals} \
      -c !{params.skani_compression_factor} \
      -s !{params.skani_output_ani_greater_than} \
      -m !{params.skani_marker_compression_factor} \
      --min-af !{params.skani_minimum_alignment_fraction}

    # Clean up skani.out file
    sed -i "s/assemblies\\/!{filename1}/!{base1}/g" skani.out
    sed -i "s/assemblies\\/!{filename2}/!{base2}/g" skani.out

    cat <<-END_VERSIONS > versions.yml
    "!{task.process}":
      fastANI: $(fastANI --version 2>&1 | awk '{print $2}')
    END_VERSIONS
    '''
}
