version 1.0

import "./task_bbduk.wdl" as bbduk
import "./task_bbduk_illumina_primers.wdl" as bbduk_primers

workflow wf_bbduk {
  input {
    File read1
    File read2
    File adapters
    File phiX
    File polyA
    File primers
    String samplename
    String memory = "6GB"
    Int disk_size = 100
    Int threads = 1
    String docker = "staphb/bbtools:39.26"
  }

  call bbduk.task_bbduk {
    input:
    read1 = read1,
    read2 = read2,
    adapters = adapters,
    phiX = phiX,
    polyA = polyA,
    samplename = samplename,
    disk_size = disk_size,	
    threads = threads,
    memory = memory,
    docker = docker
  }

  call bbduk_primers.task_bbduk_illumina_primers {
    input:
    read1 = task_bbduk.clean_read1,
    read2 = task_bbduk.clean_read2,
    primers = primers,
    samplename = samplename,
    disk_size = disk_size,	
    threads = threads,
    memory = memory,
    docker = docker
  }

  output {
    File clean_read1 = task_bbduk_illumina_primers.read1_no_primers
    File clean_read2 = task_bbduk_illumina_primers.read2_no_primers
    File adapter_stats = task_bbduk.adapter_stats
    File phiX_stats = task_bbduk.phiX_stats
    File polyA_stats = task_bbduk.polyA_stats
    File primer_stats = task_bbduk_illumina_primers.primer_stats
  }

  meta {
    author: "Dieter Best"
    email: "Dieter.Best@cdph.ca.gov"
    description: "## Decontamination with bbduk"
  }

  parameter_meta {
    ## inputs
    forwardReads: {description: "fastq file with forward reads.", category: "required"}
    reverseReads: {description: "fastq file with reverse reads.", category: "required"}
    contamination: {description: "Input gzipped tar file with fasta files of reference genomes for species considered contaminants.", category: "optional"}

    ## outputs
    read1_clean: {description: "Cleaned output fastq file for forward reads."}
    read2_clean: {description: "Cleaned output fastq file for reverse reads."}
  }
}
