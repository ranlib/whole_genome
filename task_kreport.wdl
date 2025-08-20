version 1.0

task task_kreport {
  input {
    File classificationTSV
    Array[File]+ indexFiles
    String samplename
    String docker = "dbest/centrifuge:v1.0.4.2"
    String memory = "20GB"
    Int disk_size = 100
  }

  command <<<
    set -x
    indexBasename="$(basename ~{sub(indexFiles[0], "\.[0-9]\.cf", "")})"
    for file in ~{sep=" " indexFiles}
    do
       ln -s ${file} $PWD/"$(basename ${file})"
    done
    centrifuge-kreport -x $PWD/${indexBasename} ~{classificationTSV} 2> ~{samplename}.centrifuge.classification.kraken_style.err 1> ~{samplename}.centrifuge.classification.kraken_style.tsv
  >>>

  output {
    File krakenStyleTSV = "${samplename}.centrifuge.classification.kraken_style.tsv"
  }

  runtime {
    docker: docker
    memory: memory
    disks: "local-disk " + disk_size + " SSD"
  }
}

