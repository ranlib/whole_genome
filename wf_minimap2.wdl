version 1.0

import "./task_minimap2.wdl" as minimap2
import "./task_samtools.wdl" as samtools

workflow wf_minimap2 {
  input {
    File reference
    File read1
    File read2
    String outputPrefix
    String samplename
    Map[String,String] dockerImages = { "minimap": "staphb/minimap2:2.29", "samtools": "dbest/samtools:v1.22.1" }
    String memory = "32G"
    Int threads = 1
  }

  call minimap2.Indexing {
    input:
    referenceFile = reference,
    outputPrefix = outputPrefix,
    cores = threads,
    memory = memory,
    docker = dockerImages["minimap"]
  }

  #referenceFile = reference,
  call minimap2.Mapping {
    input:
    referenceFile = Indexing.indexFile,
    queryFile1 = read1,
    queryFile2 = read2,
    outputPrefix = samplename,
    presetOption = "sr",
    addMDTagToSam = true,
    outputSam = true,
    cores = threads,
    memory = memory,
    docker = dockerImages["minimap"]
  }

  call samtools.Sort {
    input:
    inputBam = Mapping.alignmentFile,
    outputPath = basename(Mapping.alignmentFile, ".sam") + ".sorted.bam",
    threads = threads,
    docker = dockerImages["samtools"]
  }
  
  output {
    File bam = Sort.outputBam
    File bai = Sort.outputBamIndex
  }
}
