version 1.0

task task_bbduk_illumina_primers {
  input {
    File read1
    File read2
    File primers
    String samplename
    String docker = "staphb/bbtools:39.26"
    String memory = "8GB"
    Int threads = 1
    Int disk_size = 100
    Int number_of_retries = 1
  }

  String java_mem = "-Xmx" + sub(memory,"GB","g")
  String clipped_1 = samplename + "_no_primers_1.fastq.gz"
  String clipped_2 = samplename + "_no_primers_2.fastq.gz"
  String stats = samplename + "_primers.stats.txt"
  String log = samplename + "_bbduk.log"
  
  command <<<
    set -euxo pipefail
    bbduk.sh ~{java_mem} threads=~{threads} \
    in1=~{read1} \
    in2=~{read2} \
    out1=~{clipped_1} \
    out2=~{clipped_2} \
    ref=~{primers} \
    stats=~{stats} \
    ktrim=r \
    k=23 \
    mink=11 \
    hdist=1 \
    tpe \
    tbo &> ~{log}
  >>>

  output {
    File read1_no_primers = clipped_1
    File read2_no_primers = clipped_2
    File primer_stats = stats
  }

  runtime {
    docker: docker
    memory: memory
    cpu: threads
    disks: "local-disk " + disk_size + " SSD"
    maxRetries: number_of_retries
    preemptible: 0
  }
}
