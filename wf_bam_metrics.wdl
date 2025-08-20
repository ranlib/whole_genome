version 1.0

import "task_picard.wdl" as picard
import "task_samtools.wdl" as samtools

workflow wf_bam_metrics {
    input {
        File bam
        File bamIndex
        String outputDir = "."
        File referenceFasta
        File referenceFastaFai
        File referenceFastaDict
        Boolean collectAlignmentSummaryMetrics = true
        Boolean meanQualityByCycle = true

        Array[File]+? targetIntervals
        File? ampliconIntervals

        Map[String, String] dockerImages
    }

    String prefix = outputDir + "/" + basename(bam, ".bam")

    call samtools.Flagstat as Flagstat {
        input:
            inputBam = bam,
            outputPath = prefix + ".flagstats",
            docker = dockerImages["samtools"]
    }

    call picard.CollectMultipleMetrics as picardMetrics {
        input:
            inputBam = bam,
            inputBamIndex = bamIndex,
            prefix = prefix,
            referenceFasta = referenceFasta,
            referenceFastaDict = referenceFastaDict,
            referenceFastaFai = referenceFastaFai,
            collectAlignmentSummaryMetrics = collectAlignmentSummaryMetrics,
            meanQualityByCycle = meanQualityByCycle,
            dockerImage = dockerImages["picard"]
    }

    if (defined(targetIntervals)) {
        Array[File] targetBeds = select_first([targetIntervals])
        scatter (targetBed in targetBeds) {
            call picard.BedToIntervalList as targetIntervalsLists {
                input:
                    bedFile = targetBed,
                    outputPath = prefix + "_intervalLists/" + basename(targetBed) + ".interval_list",
                    dict = referenceFastaDict,
                    dockerImage = dockerImages["picard"]
            }
        }

        call picard.BedToIntervalList as ampliconIntervalsLists {
             input:
                 bedFile = select_first([ampliconIntervals]),
                 outputPath = prefix + "_intervalLists/" + basename(select_first([ampliconIntervals])) + ".interval_list",
                 dict = referenceFastaDict,
                 dockerImage = dockerImages["picard"]
            }

        call picard.CollectTargetedPcrMetrics as targetMetrics {
            input:
                inputBam = bam,
                inputBamIndex = bamIndex,
                referenceFasta = referenceFasta,
                referenceFastaDict = referenceFastaDict,
                referenceFastaFai = referenceFastaFai,
                prefix = prefix,
                targetIntervals = targetIntervalsLists.intervalList,
                ampliconIntervals = ampliconIntervalsLists.intervalList,
                dockerImage = dockerImages["picard"]
        }
    }

    output {
        File flagstats = Flagstat.flagstat
        Array[File] picardMetricsFiles = picardMetrics.allStats
        Array[File] targetedPcrMetrics = select_all([targetMetrics.perTargetCoverage, targetMetrics.perBaseCoverage, targetMetrics.metrics])
        Array[File] reports = flatten([picardMetricsFiles, targetedPcrMetrics, [flagstats]])
    }

    parameter_meta {
        # inputs
        bam: {description: "The BAM file for which metrics will be collected.", category: "required"}
        bamIndex: {description: "The index for the bam file.", category: "required"}
        outputDir: {description: "The directory to which the outputs will be written.", category: "common"}
        referenceFasta: {description: "The reference fasta file.", category: "required"}
        referenceFastaDict: {description: "The sequence dictionary associated with the reference fasta file.", category: "required"}
        referenceFastaFai: {description: "The index for the reference fasta file.", category: "required"}
        strandedness: {description: "The strandedness of the RNA sequencing library preparation. One of \"None\" (unstranded), \"FR\" (forward-reverse: first read equal transcript) or \"RF\" (reverse-forward: second read equals transcript).", category: "common"}
        collectAlignmentSummaryMetrics: {description: "Equivalent to the `PROGRAM=CollectAlignmentSummaryMetrics` argument in Picard.", category: "advanced"}
        meanQualityByCycle: {description: "Equivalent to the `PROGRAM=MeanQualityByCycle` argument in Picard.", category: "advanced"}
        targetIntervals: {description: "An interval list describing the coordinates of the targets sequenced. This should only be used for targeted sequencing or WES. If defined targeted PCR metrics will be collected. Requires `ampliconIntervals` to also be defined.", category: "common"}
        ampliconIntervals: {description: "An interval list describinig the coordinates of the amplicons sequenced. This should only be used for targeted sequencing or WES. Required if `ampliconIntervals` is defined.", category: "common"}
        dockerImages: {description: "The docker images used. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}

        # outputs
        flagstats: {description: "Statistics output from flagstat."}
        picardMetricsFiles: {description: "All statistics from the CollectMultipleMetrics tool."}
        targetedPcrMetrics: {description: "Statistics from the targeted PCR metrics tool."}
        reports: {description: "All reports from this pipeline gathered into one array."}
    }
}
