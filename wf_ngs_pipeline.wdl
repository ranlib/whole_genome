version 1.0

import "task_fastqc.wdl" as fastqc
import "task_fastp.wdl" as fastp
import "task_samtools.wdl" as samtools
import "task_seqkit.wdl" as seqkit
import "wf_centrifuge.wdl" as centrifuge
import "wf_minimap2.wdl" as minimap2
import "wf_bam_metrics.wdl" as bam_metrics
import "task_collect_wgs_metrics.wdl" as wgsQC
import "wf_mosdepth.wdl" as mosdepth
import "task_multiqc.wdl" as multiqc

workflow wf_ngs_pipeline {
  input {
    Array[File]+ reads1
    Array[File]+ reads2
    Array[String]+ samplenames
    Array[File]+ references
    Map[String, String] dockerImages
    # seqkit
    Boolean all_stats = true
    Boolean use_basename = true
    String fq_encoding = "sanger"
    String gap_letters = "'- .'"
    Boolean skip_err = false
    Boolean skip_file_check = false
    Boolean tabular = true
    String out_file = "stats.tsv"
    # fastp
    File adapters
    # minimap2
    Int threads
    String memory
    # centrifuge
    Array[File]+ indexFiles
    Int disk_multiplier
    Int disk_size
    # bam metrics
    String outputDir = "."
    Boolean collectAlignmentSummaryMetrics = true
    Boolean meanQualityByCycle = true
    Array[File]+? targetIntervals
    File? ampliconIntervals
  }

  scatter ( indx in range(length(reads1)) ) {

    call seqkit.task_seqkit_stats {
      input:
      input_file = [ reads1[indx], reads2[indx] ],
      out_file = out_file,
      all_stats = all_stats,
      use_basename = use_basename,
      fq_encoding = fq_encoding,
      gap_letters = gap_letters,
      skip_err = skip_err,
      skip_file_check = skip_file_check,
      tabular = tabular,
      memory = memory,
      threads = threads,
      docker = dockerImages["seqkit"]
    }

    call fastqc.task_fastqc {
      input:
      forwardReads = reads1[indx],
      reverseReads = reads2[indx],
      docker = dockerImages["fastqc"],
      threads = threads,
      memory = memory
    }
    
    call fastp.task_fastp {
      input:
      read1 = reads1[indx],
      read2 = reads2[indx],
      sample_id = samplenames[indx],
      adapters = adapters,
      docker_image = dockerImages["fastp"],
      threads = threads,
      memory = memory
    }

    call seqkit.task_seqkit_stats as seqkit_after_cleanup {
      input:
      input_file = [ task_fastp.clean_read1, task_fastp.clean_read2 ],
      out_file = out_file,
      all_stats = all_stats,
      use_basename = use_basename,
      fq_encoding = fq_encoding,
      gap_letters = gap_letters,
      skip_err = skip_err,
      skip_file_check = skip_file_check,
      tabular = tabular,
      memory = memory,
      threads = threads,
      docker = dockerImages["seqkit"]
    }

    call fastqc.task_fastqc as fastqc_after_cleanup {
      input:
      forwardReads = task_fastp.clean_read1,
      reverseReads = task_fastp.clean_read2,
      docker = dockerImages["fastqc"],
      threads = threads,
      memory = memory
    }

    call centrifuge.wf_centrifuge {
      input:
      read1 = task_fastp.clean_read1,
      read2 = task_fastp.clean_read2,
      samplename = samplenames[indx],
      indexFiles = indexFiles,
      docker = dockerImages["centrifuge"],
      threads = threads,
      memory = memory,
      disk_size = disk_size,
      disk_multiplier = disk_multiplier
    } 
      
    call minimap2.wf_minimap2 {
      input:
      read1 = task_fastp.clean_read1,
      read2 = task_fastp.clean_read2,
      reference = references[indx],
      samplename = samplenames[indx],
      threads = threads,
      memory = memory,
      dockerImages = {"samtools": dockerImages["samtools"], "minimap": dockerImages["minimap"]},
      outputPrefix = samplenames[indx]
    }
    
    call samtools.DictAndFaidx {
      input:
      inputFile = references[indx],
      memory = memory,
      docker = dockerImages["samtools"]
    }

    call bam_metrics.wf_bam_metrics {
      input:
      bam = wf_minimap2.bam,
      bamIndex = wf_minimap2.bai,
      outputDir = outputDir,
      referenceFasta = references[indx],
      referenceFastaFai = DictAndFaidx.outputFastaFai,
      referenceFastaDict = DictAndFaidx.outputFastaDict,
      collectAlignmentSummaryMetrics = collectAlignmentSummaryMetrics,
      meanQualityByCycle = meanQualityByCycle,
      targetIntervals = targetIntervals,
      ampliconIntervals = ampliconIntervals,
      dockerImages = { "samtools": dockerImages["samtools"], "picard": dockerImages["picard"] }
    }
    
    call wgsQC.task_collect_wgs_metrics {
      input:
      bam = wf_minimap2.bam,
      reference = references[indx],
      docker = dockerImages["gatk"],
      memory = memory
    }

    call mosdepth.task_mosdepth {
      input:
      input_bam = wf_minimap2.bam,
      input_bai = wf_minimap2.bai,
      threads = threads,
      mapq = 20,
      prefix = samplenames[indx],
      memory = memory,
      disk = "10GB",
      docker = dockerImages["mosdepth"]
    }

  }
  
  Array[File] reports_fastq = flatten([ task_fastqc.forwardData, task_fastqc.reverseData, fastqc_after_cleanup.forwardData, fastqc_after_cleanup.reverseData, task_fastp.report_json])
  Array[File] reports_centrifuge = flatten([wf_centrifuge.krakenStyleTSV])
  Array[File] reports_picard = flatten(wf_bam_metrics.picardMetricsFiles)
  Array[File] reports_bam   = flatten([ task_collect_wgs_metrics.collectMetricsOutput])
  Array[File?] reports_mosdepth = flatten([task_mosdepth.global_dist, task_mosdepth.regions_depth])
  Array[File] allReports = select_all(flatten([ reports_mosdepth, reports_bam, reports_picard, reports_centrifuge, reports_fastq]))
  call multiqc.task_multiqc {
    input:
    inputFiles = allReports,
    outputPrefix = "multiqc",
    docker = dockerImages["multiqc"],
    memory = memory,
    disk_size = disk_size
  }
  
  output {
    # seqkit
    Array[File] seqkit_stats_result = task_seqkit_stats.stats_output
    Array[File] seqkit_stats_after_cleanup_result = seqkit_after_cleanup.stats_output
    
    # fastqc
    Array[File] forwardHtml = task_fastqc.forwardHtml
    Array[File] reverseHtml = task_fastqc.reverseHtml
    Array[File] forwardHtml_after_cleanup = fastqc_after_cleanup.forwardHtml
    Array[File] reverseHtmt_after_cleanup = fastqc_after_cleanup.reverseHtml

    # fastp
    Array[File] fastp_clean_reads1 = task_fastp.clean_read1
    Array[File] fastp_clean_reads2 = task_fastp.clean_read2
    Array[File] reports_json = task_fastp.report_json
    Array[File] reports_html = task_fastp.report_html

    # centrifuge
    Array[File] centrifuge_classification = wf_centrifuge.classificationTSV
    Array[File] centrifuge_kraken_style = wf_centrifuge.krakenStyleTSV
    Array[File] centrifuge_summary = wf_centrifuge.summaryReportTSV

    # minimap
    Array[File] bam = wf_minimap2.bam
    Array[File] bai = wf_minimap2.bai
    
    # bam metrics
    Array[File] flagstats = wf_bam_metrics.flagstats
    Array[Array[File]] picardMetricsFiles = wf_bam_metrics.picardMetricsFiles
    Array[Array[File]] targetedPcrMetrics = wf_bam_metrics.targetedPcrMetrics 
    Array[Array[File]] reports_bam_metrics = wf_bam_metrics.reports

    # picard
    Array[File] collect_wgs_output_metrics = task_collect_wgs_metrics.collectMetricsOutput
    
    # mosdepth
    Array[File] coverage_per_base = task_mosdepth.per_base_depth
    Array[File] coverage_summary = task_mosdepth.summary_output
    Array[File] coverage_global_dist = task_mosdepth.global_dist
    Array[File?] coverage_regions_depth = task_mosdepth.regions_depth

    # multiqc
    File report = task_multiqc.report
    #File report_pdf = task_multiqc.report_pdf
  }

  meta {
    author: "Dieter Best"
    email: "Dieter.Best@cdph.ca.gov"
    description: "## pipeline to analyze NGS samples"
  }

  parameter_meta {
    ## inputs
    reads1: {description: "Input fastq file with forward reads", category: "required"}
    reads2: {description: "Input fastq file with reverse reads", category: "required"}
    samplename: {description: "Sample name", category: "required"}
    reference: {description: "Reference sequence for pathogen to be anlyzed", category: "required"}
    pathogen: {description: "Name of pathogen to be anlyzed", category: "required"}
    ## output
    classificationTSV: {description: "Output tsv file with read classification"}
    summaryReportTSV: {description: "Output tsv file with summary of classification"}
    krakenStyleTSV: {description: "Output tsv file with read classification kraken style"}
  }
}
