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
    RUN ALL_VS_ALL WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ALL_VS_ALL {

    take:
    input

    main:
    // SETUP: Define empty channels to concatenate certain outputs
    ch_versions           = Channel.empty()
    ch_ani_pairs          = Channel.empty()
    ch_asm_files          = Channel.empty()
    ch_fasta_files        = Channel.empty()
    ch_genomes_fofn       = Channel.empty()
    ch_input_qc_filecheck = Channel.empty()
    ch_query_genomes      = file("$baseDir/assets/dummy_file.txt", checkIfExists: true)

    // Check input for samplesheet or pull inputs from directory
    INPUT_CHECK (
        input
    )

    // Collect version info
    ch_versions = ch_versions
        .mix(INPUT_CHECK.out.versions)

    // Convert Genbank to FastA for fastANI
    if (params.ani == "fastani" || params.ani == "skani") {
        GENBANK2FASTA_BIOPYTHON (
            INPUT_CHECK.out.input_files
        )

        // Collect Converted FastA files
        ch_fasta_files = ch_fasta_files
            .mix(GENBANK2FASTA_BIOPYTHON.out.fasta_files)

        // Collect version info
        ch_versions = ch_versions
            .mix(GENBANK2FASTA_BIOPYTHON.out.versions)

    } else {
        ch_fasta_files = INPUT_CHECK.out.input_files
    }

    // Check input files meet size criteria
    INFILE_HANDLING_UNIX (
        ch_fasta_files
    )

    // Collect version info
    ch_versions = ch_versions
        .mix(INFILE_HANDLING_UNIX.out.versions)

    // Collect all Initial Input File checks and concatenate into one file
    ch_input_qc_filecheck = ch_input_qc_filecheck
        .mix(INFILE_HANDLING_UNIX.out.qc_input_filecheck)
        .collectFile(name: 'Initial_Input_Files.tsv', storeDir: params.qc_filecheck_log_dir)

    // Collect genomes.fofn files and concatenate into one
    ch_genomes_fofn = ch_genomes_fofn
        .mix(INFILE_HANDLING_UNIX.out.genomes)
        .collectFile(name: 'genomes.fofn', storeDir: "${params.outdir}/comparisons")

    // Collect assembly files
    ch_asm_files = ch_asm_files
        .mix(INFILE_HANDLING_UNIX.out.asm_files)
        .collect()

    // PROCESS: Create pairings and append to pairs.fofn
    GENERATE_PAIRS_BIOPYTHON (
        ch_genomes_fofn,
        ch_query_genomes
    )

    // Collect version info
    ch_versions = ch_versions
        .mix(GENERATE_PAIRS_BIOPYTHON.out.versions)

    // Collect pairs.fofn and assemblies directory.
    ch_ani_pairs = ch_ani_pairs
        .mix(GENERATE_PAIRS_BIOPYTHON.out.ani_pairs)
        .splitCsv(header:false, sep:'\t')
        .map{row-> tuple(row[0], row[1])}

    emit:
    versions     = ch_versions
    ani_pairs    = ch_ani_pairs
    asm_files    = ch_asm_files
    qc_filecheck = ch_input_qc_filecheck
    asm_genomes  = INFILE_HANDLING_UNIX.out.genomes
}
