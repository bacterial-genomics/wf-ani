/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowANI.initialise(params, log)

// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.query, params.refdir ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input && !params.query && !params.refdir) {
    ch_input  = file(params.input)
} else if (params.query && params.refdir && !params.input) {
    ch_query  = file(params.query)
    ch_refdir = file(params.refdir)
} else if (params.input && params.query && params.refdir) {
    error("Invalid input combinations! Cannot specify query or refdir with input!")
} else {
    error("Input not specified")
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// CONFIGS: Import configs for this workflow
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULES: Local modules
//
include { ANI_BLAST_BIOPYTHON   } from "../modules/local/ani_blast_biopython/main"
include { ANI_FASTANI           } from "../modules/local/ani_fastani/main"
include { ANI_SKANI             } from "../modules/local/ani_skani/main"
include { BLAST_SUMMARY_UNIX    } from "../modules/local/blast_summary_unix/main"

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { ALL_VS_ALL            } from "../subworkflows/local/all_vs_all_file_pairings"
include { QUERY_VS_REFDIR       } from "../subworkflows/local/query_vs_refdir_file_pairings"

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CREATE CHANNELS FOR INPUT PARAMETERS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOW FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Convert params.ani to lowercase
def toLower(it) {
    it.toString().toLowerCase()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ANI {

    // SETUP: Define empty channels to concatenate certain outputs
    ch_versions     = Channel.empty()
    ch_qc_filecheck = Channel.empty()

    /*
    ================================================================================
                            Preprocessing input data
    ================================================================================
    */
    if (params.query && params.refdir && !params.input) {
        //
        // Process query file and refdir directory
        //
        QUERY_VS_REFDIR (
            ch_query,
            ch_refdir
        )
        ch_versions = ch_versions.mix(QUERY_VS_REFDIR.out.versions)
        ch_qc_filecheck = QUERY_VS_REFDIR.out.qc_filecheck

        // Collect ANI data
        ch_asm_files = QUERY_VS_REFDIR.out.asm_files
        ch_ani_pairs = QUERY_VS_REFDIR.out.ani_pairs

    } else if (params.input && !params.query && !params.refdir) {
        //
        // Process input directory
        //
        ALL_VS_ALL (
            ch_input
        )
        ch_versions = ch_versions.mix(ALL_VS_ALL.out.versions)
        ch_qc_filecheck = ALL_VS_ALL.out.qc_filecheck

        // Collect ANI data
        ch_asm_files = ALL_VS_ALL.out.asm_files
        ch_ani_pairs = ALL_VS_ALL.out.ani_pairs

    } else {
        // Throw error if query, refdir, and input are combined
        error("Invalid input combinations! Cannot specify query or refdir with input!")
    }

    /*
    ================================================================================
                            Performing ANI on input data
    ================================================================================
    */
    if ( toLower(params.ani) == "fastani" ) {
        // PROCESS: Perform fastANI on each pair
        ANI_FASTANI (
            ch_ani_pairs,
            ch_asm_files
        )
        ch_versions = ch_versions.mix(ANI_FASTANI.out.versions)

        // Collect all fastani.out files and concatenate into one file
        ch_summary = ANI_FASTANI.out.ani_stats
                        .collect()
                        .collectFile(
                            name: 'ANI.Summary.tsv',
                            storeDir: params.outdir,
                            keepHeader: true
                        )

    } else if ( toLower(params.ani) == "skani" ) {
        // PROCESS: Perform SKANI on each pair
        ANI_SKANI (
            ch_ani_pairs,
            ch_asm_files
        )
        ch_versions = ch_versions.mix(ANI_SKANI.out.versions)

        // Collect all fastani.out files and concatenate into one file
        ch_summary = ANI_SKANI.out.ani_stats
                        .collect()
                        .collectFile(
                            name: 'ANI.Summary.tsv',
                            storeDir: params.outdir,
                            keepHeader: true
                        )

    } else {
        // PROCESS: Perform BLAST ANI on each pair
        ANI_BLAST_BIOPYTHON (
            ch_ani_pairs,
            ch_asm_files
        )
        ch_versions = ch_versions.mix(ANI_BLAST_BIOPYTHON.out.versions)

        // PROCESS: Summarize ANI stats into one file
        BLAST_SUMMARY_UNIX (
            ANI_BLAST_BIOPYTHON.out.ani_stats.collect()
        )
        ch_versions = ch_versions.mix(BLAST_SUMMARY_UNIX.out.versions)
    }

    // Collect QC file checks and concatenate into one file
    ch_qc_filecheck = Channel.empty()
    ch_qc_filecheck = ch_qc_filecheck
                        .collectFile(
                            name:       "Summary.QC_File_Checks.tab",
                            keepHeader: true,
                            storeDir:   "${params.outdir}/Summaries",
                            sort:       'index'
                        )

    // PATTERN: Collate method for version information
    ch_versions
        .unique()
        .collectFile(
            name: 'software_versions.yml',
            storeDir: params.logpath
        )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
