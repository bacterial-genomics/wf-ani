//
// This file holds several functions specific to the workflow/blast.nf in the wf-ani pipeline
//

import groovy.text.SimpleTemplateEngine

class WorkflowANI {

    //
    // Check and validate parameters
    //
    public static void initialise(params, log) {
        if (params.query && params.input || params.refdir && params.input) {
            log.error "Cannot mix '--input' WITH '--query' OR '--refdir'"
            System.exit(1)
        } else if (!params.input && !params.query) {
            log.error "Please provide an input method: '--input' OR '--query' and '--refdir'"
            System.exit(1)
        } else if (params.query && !params.refdir || !params.query && params.refdir) {
            log.error "Please provide query and reference method: '--query' AND '--refdir'"
            System.exit(1)
        }
    }
}
