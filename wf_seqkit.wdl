version 1.0

import "task_seqkit.wdl" as seqkit

workflow wf_seqkit {
  input {
    Array[File]+ input_file
    Boolean? all_stats
    Boolean? use_basename
    Boolean? skip_err
    Boolean? skip_file_check
    Boolean? tabular
    String? fq_encoding
    String? gap_letters
    String out_file
    String memory
    String docker
    Int threads
  }

  call seqkit.task_seqkit_stats {
    input:
    input_file = input_file,
    out_file = out_file,
    all_stats = all_stats,
    use_basename = use_basename,
    fq_encoding = fq_encoding,
    gap_letters = gap_letters,
    skip_err = skip_err,
    skip_file_check = skip_file_check,
    tabular = tabular,
    memory = memory,
    docker = docker,
    threads = threads
  }

  output {
    File seqkit_stats_result = task_seqkit_stats.stats_output
  }
}
