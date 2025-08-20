version 1.0

task task_centrifuge {
  input {
    File read1
    File read2
    Array[File]+ indexFiles
    String samplename
    Int threads = 1
    String docker = "dbest/centrifuge:v1.0.4.2"
    String memory = "20GB"
    Int disk_size = 100
  }

  command <<<
    set -x
    indexBasename="$(basename ~{sub(indexFiles[0], '\.[0-9]\.cf', '')})"
    for file in ~{sep=" " indexFiles}
    do
       ln -s ${file} ${PWD}/"$(basename ${file})"
    done
    centrifuge -x ${PWD}/${indexBasename} --threads ~{threads} -1 ~{read1} -2 ~{read2} --report-file ~{samplename}.centrifuge.summary.report.tsv -S ~{samplename}.centrifuge.classification.tsv
    (head -n1 ~{samplename}.centrifuge.summary.report.tsv ; tail -n+2 ~{samplename}.centrifuge.summary.report.tsv | sort -t $'\t' -r -g -k7 ) > ~{samplename}.centrifuge.summary.report.sorted.tsv
  >>>

  output {
    File classificationTSV = "${samplename}.centrifuge.classification.tsv"
    File summaryReportTSV = "${samplename}.centrifuge.summary.report.sorted.tsv"
  }

  runtime {
    docker: docker
    cpu: threads
    memory: memory
    disks: "local-disk " + disk_size + " SSD"
  }

  parameter_meta {
    # inputs
    read1: {description: "Fastq file with forward reads.", category: "required"}
    read2: {description: "Fastq file with reverse reads.", category: "required"}
    samplename: {description: "Name of sample.", category: "required"}
    indexFiles: {description: "The files of the index for the reference genomes.", category: "required"}
    disk_size: {description: "Disk size in GB needed for this job", category: "advanced"}
    threads: {description: "The number of threads to be used.", category: "advanced"}
    memory: {description: "The amount of memory available to the job.", category: "advanced"}
    docker: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}
    
    # outputs
    classificationTSV: {description: "File with the classification results."}
    summaryReportTSV: {description: "File with a classification summary."}
  }
}
