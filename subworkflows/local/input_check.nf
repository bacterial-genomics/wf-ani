//
// Check input samplesheet and get read channels
// Adapted from https://github.com/nf-core/mag
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULES: Local modules
//
include { CONVERT_SAMPLESHEET_PYTHON } from "../../modules/local/convert_samplesheet_python/main"

def hasExtension(it, extension) {
    it.toString().toLowerCase().endsWith(extension.toLowerCase())
}

def removeExtensions(it) {
    // List of file extensions to replace
    def extensions = [
                      ".fasta",
                      ".fas",
                      ".fa",
                      ".fsa",
                      ".fna",
                      ".gbff",
                      ".gbf",
                      ".gbk",
                      ".gb",
                      ".gz"
                      ]

    // Remove file path
    it = it.getName()

    // For each item in extensions, replace it
    extensions.eachWithIndex { item, idx ->
        it = it.toString().replaceAll(item, '')
    }

    // Replace periods and spaces; return cleaned meta
    return it.replaceAll('\\.', '\\_').replaceAll(' ', '_')
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN INPUT_CHECK WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow INPUT_CHECK {

    take:
    ch_input

    main:
    ch_versions = Channel.empty()

    if (hasExtension(ch_input, "csv")) {
        // Extracts read files from samplesheet CSV and distribute into channels
        ch_input_rows = Channel
            .from(ch_input)
            .splitCsv(header: true)
            .map { row ->
                    if (row.size() == 2) {
                        def id = row.sample
                        def file_path = row.file ? file(row.file, checkIfExists: true) : false
                        // Check if given combination is valid
                        if (!id) exit 1, "Invalid input samplesheet: sample column can not be empty."
                        if (!file_path) exit 1, "Invalid input samplesheet: file column can not be empty."
                        return [ id, file_path ]
                    } else {
                        exit 1, "Input samplesheet contains row with ${row.size()} column(s). Expects 2."
                    }
                }
        // Separate reads
        ch_input_files = ch_input_rows
            .map { id, file_path ->
                        def meta = [:]
                        meta.id  = id
                        return [ meta, [ file_path ] ]
                }
    } else if (hasExtension(ch_input, "tsv")) {
        // Extracts read files from samplesheet TSV and distribute into channels
        ch_input_rows = Channel
            .from(ch_input)
            .splitCsv(header: true, sep:'\t')
            .map { row ->
                    if (row.size() == 2) {
                        def id = row.sample
                        def file_path = row.file ? file(row.file, checkIfExists: true) : false
                        // Check if given combination is valid
                        if (!id) exit 1, "Invalid input samplesheet: sample column can not be empty."
                        if (!file_path) exit 1, "Invalid input samplesheet: file column can not be empty."
                        return [ id, file_path ]
                    } else {
                        exit 1, "Input samplesheet contains row with ${row.size()} column(s). Expects 2."
                    }
                }
        // Separate reads
        ch_input_files = ch_input_rows
            .map { id, file_path ->
                        def meta = [:]
                        meta.id  = id
                        return [ meta, [ file_path ] ]
                }
    } else if (hasExtension(ch_input, "xlsx") || hasExtension(ch_input, "xls") || hasExtension(ch_input, "ods")) {
        // Convert samplesehet to TSV format
        CONVERT_SAMPLESHEET_PYTHON(
            ch_input.map{
                file ->
                    def meta = [:]
                    meta['id'] = file.getSimpleName()
                    [ meta, file ]
            }
        )

        // Extracts read files from TSV samplesheet created
        // in above process and distribute into channels
        ch_input_rows = CONVERT_SAMPLESHEET_PYTHON.out.converted_samplesheet
            .splitCsv(header: true, sep:'\t')
            .map { row ->
                    if (row.size() == 2) {
                        def id = row.sample
                        def file_path = row.file ? file(row.file, checkIfExists: true) : false
                        // Check if given combination is valid
                        if (!id) exit 1, "Invalid input samplesheet: sample column can not be empty."
                        if (!file_path) exit 1, "Invalid input samplesheet: file column can not be empty."
                        return [ id, file_path ]
                    } else {
                        exit 1, "Input samplesheet contains row with ${row.size()} column(s). Expects 2."
                    }
                }
        // Separate reads
        ch_input_files = ch_input_rows
            .map { id, file_path ->
                        def meta = [:]
                        meta.id  = id
                        return [ meta, [ file_path ] ]
                }

        // Collect version info
        ch_versions = ch_versions
            .mix(CONVERT_SAMPLESHEET_PYTHON.out.versions)
    } else {
        // Read from FilePath if no samplesheet is given
        // Check if file ends in file extension for query
        if (ch_input.toString().toLowerCase().matches(/.*.(fasta|fas|fa|fsa|fna|gbff|gbf|gbk|gb)(.gz)?$/)) {
            ch_input_files = Channel
                .fromPath(ch_input, checkIfExists: true)
                .ifEmpty { exit 1, "Cannot find any files matching: ${ch_input}\nNB: Path needs to be enclosed in quotes!" }
                .map { row ->
                            def meta = [:]
                            meta.id = removeExtensions(row)
                            return [ meta, [ row ] ]
                    }
            ch_input_rows = Channel.empty()
        } else {
            // Find files in input path directory
            ch_input_files = Channel
                .fromPath(ch_input+'/**.{fasta,fas,fa,fsa,fna,gbff,gbf,gbk,gb}{,.gz}', checkIfExists: true)
                .ifEmpty { exit 1, "Cannot find any files matching: ${ch_input}\nNB: Path needs to be enclosed in quotes!" }
                .map { row ->
                            def meta = [:]
                            meta.id = removeExtensions(row)
                            return [ meta, [ row ] ]
                    }
            ch_input_rows = Channel.empty()
        }
    }

    // Ensure sample IDs are unique
    ch_input_rows
        .map { id, file_path -> id }
        .toList()
        .map { ids -> if( ids.size() != ids.unique().size() ) {exit 1, "ERROR: input samplesheet contains duplicated sample IDs!" } }

    emit:
    input_files = ch_input_files
    versions    = ch_versions
}
