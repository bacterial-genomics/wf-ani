process ANI_FASTANI {

    label "process_high"
    tag( "${base1}_${base2}" )
    container "gregorysprenger/fastani@sha256:047dbb5bd779bd12c98258c2b5570c4d30c33582203c94786b0901149e233eaa"

    input:
    tuple val(filename1), val(filename2)
    path(asm)           , stageAs: 'assemblies/*'

    output:
    path("ANI--*")
    path("ANI--*/fastani.out"), emit: ani_stats
    path(".command.{out,err}")
    path("versions.yml")      , emit: versions

    shell:
    // Get basename of input
    base1 = filename1.split('\\.')[0].split('_genomic')[0];
    base2 = filename2.split('\\.')[0].split('_genomic')[0];

    // Optional params
    matrix = params.fastani_matrix ? "--matrix" : ""
    '''
    source bash_functions.sh

    # Create ANI dir
    mkdir "ANI--!{base1},!{base2}"

    # Run fastANI
    fastANI \
      --ref "assemblies/!{filename1}" \
      --query "assemblies/!{filename2}" \
      --output "ANI--!{base1},!{base2}/fastani.out" \
      !{matrix} \
      --visualize \
      --threads !{task.cpus} \
      --kmer !{params.fastani_kmer_size} \
      --fragLen !{params.fastani_fragment_length} \
      --minFraction !{params.fastani_minimum_fraction}

    # Clean up fastani.out file
    sed -i \
      "s/assemblies\\/!{filename1}/!{base1}/g" \
      "ANI--!{base1},!{base2}/fastani.out"
    sed -i \
      "s/assemblies\\/!{filename2}/!{base2}/g" \
      "ANI--!{base1},!{base2}/fastani.out"

    # Add column headings
    sed -i \
      '1i Reference\tQuery\tANI (%)\tAligned Matches\tTotal Sequence Fragments' \
      "ANI--!{base1},!{base2}/fastani.out"

    cat <<-END_VERSIONS > versions.yml
    "!{task.process}":
      fastANI: $(fastANI --version 2>&1 | awk '{print $2}')
    END_VERSIONS
    '''
}
