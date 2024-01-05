//
// Check inputs and generate file pairs for ALL vs ALL analysis
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULES: Local modules
//
include { INFILE_HANDLING_UNIX     } from "../../modules/local/infile_handling_unix/main"
include { GENBANK2FASTA_BIOPYTHON  } from "../../modules/local/genbank2fasta_biopython/main"
include { GENERATE_PAIRS_BIOPYTHON } from "../../modules/local/generate_pairs_biopython/main"

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK              } from "./input_check"

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Convert params.ani to lowercase
def toLower(it) {
    it.toString().toLowerCase()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN ALL_VS_ALL WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ALL_VS_ALL {

    take:
    input
    ch_ani_name

    main:
    // SETUP: Define empty channels to concatenate certain outputs
    ch_versions = Channel.empty()

    // Check input for samplesheet or pull inputs from directory
    INPUT_CHECK (
        input
    )
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    // Convert Genbank to FastA for fastANI
    if (toLower(params.ani) == "fastani" || toLower(params.ani) == "skani") {
        GENBANK2FASTA_BIOPYTHON (
            INPUT_CHECK.out.input_files
        )
        ch_versions = ch_versions.mix(GENBANK2FASTA_BIOPYTHON.out.versions)

        // Collect Converted FastA files
        ch_fasta_files = GENBANK2FASTA_BIOPYTHON.out.fasta_files

    } else {
        ch_fasta_files = INPUT_CHECK.out.input_files
    }

    // Check input files meet size criteria
    INFILE_HANDLING_UNIX (
        ch_fasta_files
    )
    ch_versions = ch_versions.mix(INFILE_HANDLING_UNIX.out.versions)

    // Collect genomes.fofn files and concatenate into one
    ch_genomes_fofn = INFILE_HANDLING_UNIX.out.genomes
                        .collectFile(
                            name: "genomes.fofn",
                            skip: 1
                        )
                        .map {
                            file ->
                                def meta = [:]
                                meta['ani'] = "${ch_ani_name}"
                                [ meta, file ]
                        }

    ch_genomes_list = INFILE_HANDLING_UNIX.out.genomes
                        .collectFile(
                            name:       "genomes.tsv",
                            keepHeader: true,
                            storeDir:   "${params.outdir}/ANI/${ch_ani_name}"
                        )

    // PROCESS: Create pairings and append to pairs.fofn
    GENERATE_PAIRS_BIOPYTHON (
        ch_genomes_fofn,
        []
    )
    ch_versions = ch_versions.mix(GENERATE_PAIRS_BIOPYTHON.out.versions)

    // Collect pairs.fofn and assemblies directory
    ch_ani_pairs = GENERATE_PAIRS_BIOPYTHON.out.ani_pairs
                    .splitCsv(header: true, sep: '\t')
                    .map{ row -> tuple("${row.Filepair1}", "${row.Filepair2}") }

    emit:
    versions     = ch_versions
    ani_pairs    = ch_ani_pairs
    asm_files    = INFILE_HANDLING_UNIX.out.asm_files.collect()
    qc_filecheck = INFILE_HANDLING_UNIX.out.qc_filecheck.collect()
}
