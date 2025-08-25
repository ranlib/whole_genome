version 1.0

task seqkit_stats_task {
  input {
    Array[File]+ input_file
    String out_file
    Boolean? all_stats
    Boolean? use_basename
    Boolean? skip_err
    Boolean? skip_file_check
    Boolean? tabular
    String? fq_encoding
    String? gap_letters
    String memory
    String docker = "dbest/seqkit:2.10.0"
    Int threads
  }

  command <<<
    set -euxo pipefail
    #${sep=' -N ' '-N' : n_values} \
    seqkit stats \
    --out-file ~{out_file} \
    ~{true='--all' false='' all_stats} \
    ~{true='--basename' false='' use_basename} \
    ~{true='--skip-err' false='' skip_err} \
    ~{true='--skip-file-check' false='' skip_file_check} \
    ~{true='--threads' false='' defined(threads)} ~{threads} \
    ~{true='--fq-encoding' false='' defined(fq_encoding) } ~{fq_encoding} \
    ~{true='--gap-letters' false='' defined(gap_letters) } ~{gap_letters} \
    ~{true='--tabular' false='' tabular} \
    ~{sep=" " input_file}
  >>>

  output {
    File stats_output = out_file
  }

  runtime {
    docker: docker
    memory: memory
    cpu: threads
  }
}

