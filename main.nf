#!/usr/bin/env nextflow


/*
==============================================================================
                              wf-ani                              
==============================================================================
usage: nextflow run main.nf [--help]
----------------------------------------------------------------------------
*/

def helpMessage() {
    log.info"""
    =========================================
     wf-ani v${version}
    =========================================
    Usage:
    To run ALL vs ALL:
        nextflow run -profile <docker|singularity> main.nf --inpath <Input Directory> --outpath <Output Directory>
    
    To run QUERY vs REFERENCE:
        nextflow run -profile <docker|singularity> main.nf --query <Input Query File> --refdir <Reference Input Directory> --outpath <Output Directory>

    Run with test data:
    nextflow run main.nf -profile test,<docker|singularity>
    
    Input/output options:
        --outpath            The output directory where the results will be saved.

        For ALL vs ALL Analysis:
            --inpath             Path to input data directory containing FastA and/or Genbank files. Recognized extensions are: {fa,fas,fsa,fna,fasta,gb,gbk,gbf,gbff}{'',gz}.
        
        For QUERY vs REFERENCE Analysis:
            --query              Path to query input data file that is FastA or Genbank. Recognized extensions are: {fa,fas,fsa,fna,fasta,gb,gbk,gbf,gbff}{'',.gz}.
            --refdir             Path to input data directory containing FastA and/or Genbank files. Recognized extensions are: {fa,fas,fsa,fna,fasta,gb,gbk,gbf,gbff}{'',.gz}.
    
    Analysis options:
      --bigdata            Whether or not to use more compute resources. Options are true, false (default).
      --max_memory         Specify memory limit on your machine/infrastructure, e.g. '128.GB'. Useful to ensure workflow doesn't request too many resources.
      --max_time           Specify time limit for each process, e.g. '240.h'. Useful to ensure workflow doesn't request too many resources.
      --max_cpus           Specify CPU limit on your machine/infrastructure, e.g. 16. Useful to ensure workflow doesn't request too many resources.
    Profile options:
      -profile singularity Use Singularity images to run the workflow. Will pull and convert Docker images from Dockerhub if not locally available.
      -profile docker      Use Docker images to run the workflow. Will pull images from Dockerhub if not locally available.
      -profile conda       TODO: this is not implemented yet.
    Other options:
      -resume              Re-start a workflow using cached results. May not behave as expected with containerization profiles docker or singularity.
      -stub                Use example output files for any process with an uncommented stub block. For debugging/testing purposes.
      -name                Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic
    """.stripIndent()
}

version = "1.0.0"
nextflow.enable.dsl=2

if (params.help) {
    helpMessage()
    exit 0
}

if (params.version){
    println "VERSION: $version"
    exit 0
}

/*
========================================================================================
    VALIDATE INPUTS
========================================================================================
*/

// Make sure input parameters are not mixed
if (params.inpath && params.query && !params.refdir || 
    params.inpath && params.refdir && !params.query || 
    params.query && params.refdir && params.inpath || 
    !params.inpath && !params.query && !params.refdir) {
    System.err.println "ERROR: parameter inpath OR (query AND refdir) must be specified"
    exit 1
}

if (params.inpath) {
    File inpathFileObj = new File(params.inpath)
    if (!inpathFileObj.exists()){
        System.err.println "ERROR: $params.inpath doesn't exist"
        exit 1
    }
} else if (params.query) {
    File queryFileObj = new File(params.query)
    if (!queryFileObj.exists()){
    System.err.println "ERROR: $params.query doesn't exist"
    exit 1
    }
} else if (params.refdir) {
    File refdirFileObj = new File(params.refdir)
    if (!refdirFileObj.exists()){
    System.err.println "ERROR: $params.refdir doesn't exist"
    exit 1
    }
}

File outpathFileObj = new File(params.outpath)
if (outpathFileObj.exists()) {
    // Per the config file, outpath stores log & trace files so it is created before this point
    // Check that outpath only contains a trace file created this hour
    dayAndHour = new java.util.Date().format('yyyy-MM-dd_HH-mm-ss')
    outFiles = outpathFileObj.list()
    if (!(outFiles[0] ==~ /trace.($dayAndHour).txt/ && outFiles.size() == 1)) {
        // If it contains an older trace file or other files, warn the user
        System.out.println "WARNING: $params.outpath already exists. Output files will be overwritten."
    }
} else {
    outpathFileObj.mkdirs()
}

File logpathFileObj = new File(params.logpath)
if (logpathFileObj.exists()) {
    System.out.println "WARNING: $params.logpath already exists. Log files will be overwritten."
} else {
    logpathFileObj.mkdirs()
}

// Set optional input channels to null
params.query = "NO_QUERY_FILE"
params.refdir = "NO_REF_DIR"

// Check inputs and print relevant log info
if (params.query && params.refdir && !params.inpath) {
    // Print parameters used
    log.info """
        =====================================
        wf-ani $version
        =====================================
        query:              ${params.query}
        refdir:             ${params.refdir}
        outpath:            ${params.outpath}
        logpath:            ${params.logpath}
        workDir:            ${workflow.workDir}
        =====================================
        """
        .stripIndent()
} else {
    // Print parameters used
    log.info """
        =====================================
        wf-ani $version
        =====================================
        inpath:             ${params.inpath}
        outpath:            ${params.outpath}
        logpath:            ${params.logpath}
        workDir:            ${workflow.workDir}
        =====================================
        """
        .stripIndent()
}

/*
========================================================================================
                 Import local custom modules and subworkflows                 
========================================================================================
*/

include { INFILE_HANDLING } from "./modules/local/infile_handling.nf"
include { GENERATE_PAIRS } from "./modules/local/generate_pairs.nf"
include { ANI } from "./modules/local/ani.nf"
include { SUMMARY } from "./modules/local/summary.nf"

/*
========================================================================================
                   Import nf-core modules and subworkflows                    
========================================================================================
*/

// None

/*
========================================================================================
                            Run the main workflow                             
========================================================================================
*/

workflow {

    // SETUP: Define input channels
    if (params.query && params.refdir && !params.inpath) {
        input_ch = Channel.fromPath(params.refdir, checkIfExists: true)
    } else {
        input_ch = Channel.fromPath(params.inpath, checkIfExists: true)
    }

    // SETUP: Define optional input channels
    query_ch = file(params.query) // Set to null. Overwritten if parameter query is used.


    // SETUP: Define dependency channels
    ch_versions = Channel.empty()
    pairs_ch = Channel.empty()
    ani_stats_ch = Channel.empty()

    // PROCESS: Read files from input directory, validate and stage input files
    INFILE_HANDLING (
        input_ch,
        query_ch
    )

    // Collect version info
    ch_versions = ch_versions.mix(INFILE_HANDLING.out.versions)

    // PROCESS: Append files to genomes.fofn and then create pairing and append to pairs.fofn
    GENERATE_PAIRS (
        INFILE_HANDLING.out.asm,
        query_ch
    )

    // Collect version info
    ch_versions = ch_versions.mix(GENERATE_PAIRS.out.versions)

    // Collect pairs.fofn and assemblies directory. Combine each row of pairs.fofn with assemblies directory.
    pairs_ch = pairs_ch.mix(GENERATE_PAIRS.out.pairs).splitCsv(header:false, sep:'\t').map{row-> tuple(row[0], row[1])}.combine(INFILE_HANDLING.out.asm)

    // PROCESS: Perform ANI on each pair
    ANI (
        pairs_ch
    )

    // Collect version info
    ch_versions = ch_versions.mix(ANI.out.versions)

    // Collect all ANI stats.tab files and concatenate into one
    ani_stats_ch = ani_stats_ch.mix(ANI.out.stats).collect()

    // PROCESS: Summarize ANI stats into one file
    SUMMARY (
        ani_stats_ch
    )

    // Collect version info
    ch_versions = ch_versions.mix(SUMMARY.out.versions)
    
    // PATTERN: Collate version information
    ch_versions.collectFile(name: 'software_versions.yml', storeDir: params.logpath)
}

/*
========================================================================================
                        Completion e-mail and summary                         
========================================================================================
*/

workflow.onComplete {
    log.info """
                |=====================================
                |Pipeline Execution Summary
                |=====================================
                |Workflow Version : ${version}
                |Nextflow Version : ${nextflow.version}
                |Command Line     : ${workflow.commandLine}
                |Resumed          : ${workflow.resume}
                |Completed At     : ${workflow.complete}
                |Duration         : ${workflow.duration}
                |Success          : ${workflow.success}
                |Exit Code        : ${workflow.exitStatus}
                |Launch Dir       : ${workflow.launchDir}
                |=====================================
             """.stripMargin()
}

workflow.onError {
    def err_msg = """
                     |=====================================
                     |Error summary
                     |=====================================
                     |Completed at : ${workflow.complete}
                     |exit status  : ${workflow.exitStatus}
                     |workDir      : ${workflow.workDir}
                     |Error Report :
                     |${workflow.errorReport ?: '-'}
                     |=====================================
                  """.stripMargin()
    log.info err_msg
}


