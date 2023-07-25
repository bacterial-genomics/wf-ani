/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowBlast.initialise(params, log)

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
    exit 1, 'Cannot use input parameters --input AND --query AND --refdir!'
} else {
    exit 1, 'Input not specified!'
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
include { ANI_SKANI             } from "../modules/local/ani_skani/main"

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { ALL_VS_ALL            } from "../subworkflows/local/all_vs_all_file_pairings"
include { QUERY_VS_REFDIR       } from "../subworkflows/local/query_vs_refdir_file_pairings"

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow SKANI {

    // SETUP: Define empty channels to concatenate certain outputs
    ch_summary   = Channel.empty()
    ch_versions  = Channel.empty()
    ch_asm_files = Channel.empty()
    ch_ani_pairs = Channel.empty()

    // Check input to see which subworkflow to run
    if (params.query && params.refdir) {
        // Run Query vs Refdir workflow
        QUERY_VS_REFDIR (
            ch_query,
            ch_refdir
        )

        // Collect version info
        ch_versions = ch_versions
            .mix(QUERY_VS_REFDIR.out.versions)

        // Collect assembly files
        ch_asm_files = QUERY_VS_REFDIR.out.asm_files

        // Collect ANI pairs
        ch_ani_pairs = QUERY_VS_REFDIR.out.ani_pairs

    } else if (params.input) {
        // Run All vs All workflow
        ALL_VS_ALL (
            ch_input
        )

        // Collect version info
        ch_versions = ch_versions
            .mix(ALL_VS_ALL.out.versions)

        // Collect ASM directory with files
        ch_asm_files = ALL_VS_ALL.out.asm_files

        // Collect ANI pairs
        ch_ani_pairs = ALL_VS_ALL.out.ani_pairs

    } else {
        // Exit if query, refdir, and input are combined
        exit 1, 'Cannot use input parameters --input AND --query AND --refdir!'
    }

    // PROCESS: Perform BLAST ANI on each pair
    ANI_SKANI (
        ch_ani_pairs,
        ch_asm_files
    )

    // Collect all fastani.out files and concatenate into one file
    ch_summary = ch_summary
        .mix(ANI_SKANI.out.ani_stats)
        .collectFile(name: 'ANI.Summary.tsv', storeDir: params.outdir, keepHeader: true)

    // Collect version info
    ch_versions = ch_versions
        .mix(ANI_SKANI.out.versions)

    // PATTERN: Collate method for version information
    ch_versions
        .unique()
        .collectFile(name: 'software_versions.yml', storeDir: params.logpath)
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
