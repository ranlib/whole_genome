version 1.0

import "./task_gatk.wdl" as gatk

workflow wf_gatk {
  input {
    Array[File]+ inputBams
    Array[File]+ inputBamsIndex
    File referenceFasta
    File referenceFastaDict
    File referenceFastaFai
    Array[File]+? intervals
    String outputVcf
    String outputAlignedVcf
    String outputFilteredVcf
    Int min_reads_per_strand
    Int min_median_read_position
    Float min_allele_fraction
    String javaXmx = "8G"
    String memory = "9G"
    String docker = "broadinstitute/gatk:4.6.1.0"
  }

  call gatk.Mutect2 {
    input:
    inputBams = inputBams,
    inputBamsIndex = inputBamsIndex,
    referenceFasta = referenceFasta,
    referenceFastaDict = referenceFastaDict,
    referenceFastaFai = referenceFastaFai,
    outputVcf = outputVcf,
    intervals = intervals,
    javaXmx = javaXmx,
    memory = memory,
    docker = docker
  }

  call gatk.LeftAlignAndTrimVariants {
    input:
    referenceFasta = referenceFasta,
    referenceFastaDict = referenceFastaDict,
    referenceFastaFai = referenceFastaFai,
    unfilteredVcf = Mutect2.vcfFile,
    alignedVcf = outputAlignedVcf,
    javaXmx = javaXmx,
    memory = memory,
    docker = docker
  }

  call gatk.FilterMutectCalls {
    input:
    referenceFasta = referenceFasta,
    referenceFastaDict = referenceFastaDict,
    referenceFastaFai = referenceFastaFai,
    unfilteredVcf = LeftAlignAndTrimVariants.outputAlignedVcf,
    filteredVcf = outputFilteredVcf,
    mutect2stats = Mutect2.vcfFileStats,
    min_reads_per_strand = min_reads_per_strand,
    min_median_read_position = min_median_read_position,
    min_allele_fraction = min_allele_fraction,
    javaXmx = javaXmx,
    memory = memory,
    docker = docker
  }

  output {
    File vcfFile = Mutect2.vcfFile
    File vcfFileIndex = Mutect2.vcfFileIndex
    File vcfFileStats = Mutect2.vcfFileStats
    File vcfAlignedFile = LeftAlignAndTrimVariants.outputAlignedVcf
    File vcfAlignedFileIndex = LeftAlignAndTrimVariants.outputAlignedVcfIndex
    File vcfFilteredFile = FilterMutectCalls.outputFilteredVcf
    File vcfFilteredFileIndex = FilterMutectCalls.outputFilteredVcfIndex
    File vcfFilteredFileStats = FilterMutectCalls.outputFilteredStats
  }
}
