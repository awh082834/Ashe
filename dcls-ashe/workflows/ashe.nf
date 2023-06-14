/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowEualr.initialise(params, log)

// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config, params.fasta ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { UNZIP       } from '../modules/local/unzip'
include { HOMOPOLISH  } from '../modules/local/homopolish'
include { SPECIES     } from '../modules/local/species'
include { REPORT      } from '../modules/local/report'

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK     } from '../subworkflows/local/input_check'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { FASTQC                      } from '../modules/nf-core/fastqc'
include { MULTIQC                     } from '../modules/nf-core/multiqc'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions'
include { NANOPLOT                    } from '../modules/nf-core/nanoplot'
include { FILTLONG                    } from '../modules/nf-core/filtlong'
include { FLYE                        } from '../modules/nf-core/flye'
include { BANDAGE                     } from '../modules/nf-core/bandage/image'
include { MEDAKA                      } from '../modules/nf-core/medaka'
include { QUAST                       } from '../modules/nf-core/quast'
include { AMRFINDERPLUS_UPDATE        } from '../modules/nf-core/amrfinderplus/update'
include { AMRFINDERPLUS_RUN           } from '../modules/nf-core/amrfinderplus/run'
include { MOBSUITE_RECON              } from '../modules/nf-core/mobsuite/recon'
include { MASH_SKETCH                 } from '../modules/nf-core/mash/sketch'
include { MASH_DIST                   } from '../modules/nf-core/mash/dist'
include { SEQSERO2                    } from '../modules/nf-core/seqsero2'
include { EMMTYPER                    } from '../modules/nf-core/emmtyper'
include { ECTYPER                     } from '../modules/nf-core/ectyper'
include { CHOPPER                     } from '../modules/nf-core/chopper/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow ASHE {
    
    ch_versions = Channel.empty()
    quastReports = Channel.empty()
    nanoReports = Channel.empty()
    flyeReports = Channel.empty()
    speciesReports = Channel.empty()
    ectyperReports = Channel.empty()
    emmtyperReports = Channel.empty()
    seqseroReports = Channel.empty()
    plasReports = Channel.empty()
    report_ch = Channel.empty().ifEmpty("no go")

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    //
    // MODULE: Update AMRFinderPlus Data
    //
    AMRFINDERPLUS_UPDATE()
    ch_versions = ch_versions.mix(AMRFINDERPLUS_UPDATE.out.versions.first())
    
    //
    // MODULE: Run FastQC
    //
    FASTQC (
        INPUT_CHECK.out.reads
    )
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    CHOPPER(
        INPUT_CHECK.out.reads
    )

    //
    // MODULE: Run NanoPlot
    //
    NANOPLOT (
        CHOPPER.out.fastq
    )
    ch_versions = ch_versions.mix(NANOPLOT.out.versions.first())
    nanoReports = NANOPLOT.out.txt.collect()

    //
    // MODULE: Run Flye
    //
    FLYE(
        CHOPPER.out.fastq,"--nano-hq"
    )
    ch_versions = ch_versions.mix(FLYE.out.versions.first())
    flyeReports = FLYE.out.txt.collect()

    //
    // MODULE: Unzip files that need to be unzipped
    //
    UNZIP(
        FLYE.out.assem, FLYE.out.gfa
    )

    //
    // MODULE: Run Bandage
    //
    BANDAGE(
        UNZIP.out.unzippedGFA
    )
    ch_versions = ch_versions.mix(BANDAGE.out.versions.first())
    pdf_ch = BANDAGE.out.png
    //
    // MODULES: Run Medaka
    //
    MEDAKA(
        UNZIP.out.med_ch
    )
    ch_versions = ch_versions.mix(MEDAKA.out.versions.first())

    //
    // MODULES: Run Homopolish 
    //
    HOMOPOLISH(
        MEDAKA.out.assembly
    )

    //
    // MODULE: Run Mash Sketch
    //
    MASH_SKETCH (
        HOMOPOLISH.out.polished_assem
    )
    ch_versions = ch_versions.mix(MASH_SKETCH.out.versions.first())

    //
    // MODULE: Run Mash Dist
    //
    MASH_DIST (
        MASH_SKETCH.out.mash
    )
    ch_versions = ch_versions.mix(MASH_DIST.out.versions.first())
    speciesReports = MASH_DIST.out.report_dist.collect()

    //
    // MODULE: Run Species Module
    //
    SPECIES(
        MASH_DIST.out.top_dist
    )  

    ch_versions = ch_versions.mix(HOMOPOLISH.out.versions.first())
    ch_forTyping = HOMOPOLISH.out.polished_assem.join(SPECIES.out.species_id)

    //
    // MODULE: Run SeqSero2
    //
    SEQSERO2(
        ch_forTyping
    )
    ch_versions = ch_versions.mix(SEQSERO2.out.versions.first())
    seqseroReports = SEQSERO2.out.tsv.collect()

    //
    // MODULE: Run EmmTyper
    //
    EMMTYPER(
        ch_forTyping
    )
    ch_versions = ch_versions.mix(EMMTYPER.out.versions.first())
    emmtyperReports = EMMTYPER.out.tsv.collect()

    //
    // MODULE: Run EcTyper
    //
    ECTYPER(
        ch_forTyping
    )
    ch_versions = ch_versions.mix(ECTYPER.out.versions.first())
    ectyperReports = ECTYPER.out.tsv.collect()

    //
    // MODULE: Mob Suite Recon
    //
    MOBSUITE_RECON(
        HOMOPOLISH.out.polished_assem
    )
    ch_versions = ch_versions.mix(MOBSUITE_RECON.out.versions.first())
    plasReports = MOBSUITE_RECON.out.mobtyper_results.collect()
    pdf_ch = pdf_ch.join(MOBSUITE_RECON.out.mobtyper_results).view()
    //
    // MODULE: Run AMRFinderPlus on Medaka Output
    //
    AMRFINDERPLUS_RUN(
        HOMOPOLISH.out.polished_assem, AMRFINDERPLUS_UPDATE.out.db
    )
    ch_versions = ch_versions.mix(AMRFINDERPLUS_RUN.out.versions.first())
    pdf_ch = pdf_ch.join(AMRFINDERPLUS_RUN.out.report)
    
    //
    // MODULE: Run QUAST
    //
    QUAST(
        HOMOPOLISH.out.polished_assem
    )
    ch_versions = ch_versions.mix(QUAST.out.versions.first())
    quastReports = QUAST.out.reportTSV.collect()
    
    //Channel of collected Report channels to be passed to report generation module as a single list
    reportGen = quastReports.concat(nanoReports,seqseroReports,ectyperReports,emmtyperReports,plasReports,speciesReports,flyeReports).toList()
    
    //
    // MODULE: Generate final report summary
    //
    report_ch.view()
    REPORT(reportGen)
    //report_ch = REPORT.out.finalReport
    //report_ch.view()
    //PDF_REPORT(pdf_ch,REPORT.out.finalReport)

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowEualr.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowEualr.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )
    multiqc_report = MULTIQC.out.report.toList()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
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
