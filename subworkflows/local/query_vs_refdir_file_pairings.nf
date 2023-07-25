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
include { INFILE_HANDLING_UNIX as REFDIR_INFILE_HANDLING_UNIX       } from "../../modules/local/infile_handling_unix/main"
include { INFILE_HANDLING_UNIX as QUERY_INFILE_HANDLING_UNIX        } from "../../modules/local/infile_handling_unix/main"
include { GENBANK2FASTA_BIOPYTHON as REFDIR_GENBANK2FASTA_BIOPYTHON } from "../../modules/local/genbank2fasta_biopython/main"
include { GENBANK2FASTA_BIOPYTHON as QUERY_GENBANK2FASTA_BIOPYTHON  } from "../../modules/local/genbank2fasta_biopython/main"
include { GENERATE_PAIRS_BIOPYTHON                                  } from "../../modules/local/generate_pairs_biopython/main"

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK as REFDIR_INPUT_CHECK                         } from "./input_check"
include { INPUT_CHECK as QUERY_INPUT_CHECK                          } from "./input_check"

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN QUERY_VS_REFDIR WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow QUERY_VS_REFDIR {

    take:
    query
    refdir

    main:
    // SETUP: Define empty channels to concatenate certain outputs
    ch_versions            = Channel.empty()
    ch_ani_pairs           = Channel.empty()
    ch_asm_files           = Channel.empty()
    ch_query_fofn          = Channel.empty()
    ch_refdir_fofn         = Channel.empty()
    ch_query_files         = Channel.empty()
    ch_refdir_files        = Channel.empty()
    ch_input_qc_filecheck  = Channel.empty()

    // Check query for samplesheet or grab file
    QUERY_INPUT_CHECK (
        query
    )

    // Collect version info
    ch_versions = ch_versions
        .mix(QUERY_INPUT_CHECK.out.versions)

    // Check input for samplesheet or pull inputs from directory
    REFDIR_INPUT_CHECK (
        refdir
    )

    // Collect version info
    ch_versions = ch_versions
        .mix(REFDIR_INPUT_CHECK.out.versions)

    // Convert Genbank to FastA for fastANI
    if (params.ani == "fastani" || params.ani == "skani") {
        QUERY_GENBANK2FASTA_BIOPYTHON (
            QUERY_INPUT_CHECK.out.input_files
        )

        REFDIR_GENBANK2FASTA_BIOPYTHON (
            REFDIR_INPUT_CHECK.out.input_files
        )

        // Collect Converted FastA files
        ch_query_files = QUERY_GENBANK2FASTA_BIOPYTHON.out.fasta_files
        ch_refdir_files = REFDIR_GENBANK2FASTA_BIOPYTHON.out.fasta_files

        // Collect version info
        ch_versions = ch_versions
            .mix(QUERY_INPUT_CHECK.out.versions)
            .mix(REFDIR_GENBANK2FASTA_BIOPYTHON.out.versions)

    } else {
        ch_query_files = QUERY_INPUT_CHECK.out.input_files
        ch_refdir_files = REFDIR_INPUT_CHECK.out.input_files
    }

    // Check query file meets size criteria
    QUERY_INFILE_HANDLING_UNIX (
        ch_query_files
    )

    // Collect version info
    ch_versions = ch_versions
        .mix(QUERY_INFILE_HANDLING_UNIX.out.versions)

    // Check refdir input files meet size criteria
    REFDIR_INFILE_HANDLING_UNIX (
        ch_refdir_files
    )

    // Collect version info
    ch_versions = ch_versions
        .mix(REFDIR_INFILE_HANDLING_UNIX.out.versions)

    // Collect all Initial Input File checks and concatenate into one file
    ch_input_qc_filecheck = ch_input_qc_filecheck
        .mix(QUERY_INFILE_HANDLING_UNIX.out.qc_input_filecheck)
        .mix(REFDIR_INFILE_HANDLING_UNIX.out.qc_input_filecheck)
        .collectFile(name: 'Initial_Input_Files.tsv', storeDir: params.qc_filecheck_log_dir)

    // Collect genomes.fofn and rename to query and refdir
    ch_query_fofn = QUERY_INFILE_HANDLING_UNIX.out.genomes
        .collectFile(name: 'query.fofn', storeDir: "${params.outdir}/comparisons")
    ch_refdir_fofn = REFDIR_INFILE_HANDLING_UNIX.out.genomes
        .collectFile(name: 'refdir.fofn', storeDir: "${params.outdir}/comparisons")

    // Collect assembly files
    ch_asm_files = ch_asm_files
        .mix(QUERY_INFILE_HANDLING_UNIX.out.asm_files)
        .mix(REFDIR_INFILE_HANDLING_UNIX.out.asm_files)
        .collect()

    // PROCESS: Create pairings and append to pairs.fofn
    GENERATE_PAIRS_BIOPYTHON (
        REFDIR_INFILE_HANDLING_UNIX.out.asm_files.collect(),
        QUERY_INFILE_HANDLING_UNIX.out.asm_files.collect()
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
    versions  = ch_versions
    ani_pairs = ch_ani_pairs
    asm_files = ch_asm_files
}
