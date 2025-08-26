version 1.0

import "task_seqkit.wdl" as seqkit

workflow wf_seqkit_seq {
    input {
      File input_fastq
      String output_fastq
      String memory
      String docker
      Int minimum_read_length
      Int threads
    }
    
    call seqkit.task_seqkit_seq {
      input:
      inputFile = input_fastq,
      minLength = minimum_read_length,
      outFilePath = output_fastq,
      removeGaps = true,
      memory = memory,
      threads = threads,
      docker = docker
    }

    output {
      File processedFasta = task_seqkit_seq.outputFasta
    }
}
