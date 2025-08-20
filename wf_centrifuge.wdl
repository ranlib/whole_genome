version 1.0

import "./task_centrifuge.wdl" as centrifuge
import "./task_kreport.wdl" as kreport

workflow wf_centrifuge {
  input {
    File read1
    File read2
    String samplename
    Int threads = 32
    Array[File]+ indexFiles
    String memory = "64GB"
    Int disk_size = 100
    Int disk_multiplier = 20
    String docker = "dbest/centrifuge:v1.0.4.2"
  }
  
  Int dynamic_disk_size = disk_multiplier*ceil(size(read1, "GiB"))
  Int disk_size_gb = select_first([disk_size, dynamic_disk_size])

  call centrifuge.task_centrifuge {
    input:
    read1 = read1,
    read2 = read2,
    samplename = samplename,
    threads = threads,
    memory = memory,
    disk_size = disk_size_gb,
    indexFiles = indexFiles,
    docker = docker
  }
  
  call kreport.task_kreport {
    input:
    classificationTSV = task_centrifuge.classificationTSV,
    samplename = samplename,
    memory = memory,
    disk_size = disk_size_gb,
    indexFiles = indexFiles,
    docker = docker
  }
  
  output {
    File classificationTSV = task_centrifuge.classificationTSV
    File summaryReportTSV = task_centrifuge.summaryReportTSV
    File krakenStyleTSV = task_kreport.krakenStyleTSV
  }

  meta {
    author: "Dieter Best"
    email: "Dieter.Best@cdph.ca.gov"
    description: "## Taxonomic classification of reads using centrifuge"
  }

  parameter_meta {
    ## inputs
    read1: {description: "Input fastq file with forward reads", category: "required"}
    read2: {description: "Input fastq file with reverse reads", category: "required"}
    samplename: {description: "Sample name", category: "required"}
    ## output
    classificationTSV: {description: "Output tsv file with read classification"}
    summaryReportTSV: {description: "Output tsv file with summary of classification"}
    krakenStyleTSV: {description: "Output tsv file with read classification kraken style"}
  }

}
