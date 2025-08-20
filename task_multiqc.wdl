version 1.0

task task_multiqc {
  input {
    Array[File] inputFiles
    String outputPrefix
    String docker = "multiqc/multiqc:v1.30"
    String memory = "8GB"
    Int disk_size = 100
  }
  
  command <<<
    set -euxo
    for file in ~{sep=' ' inputFiles}; do
    if [ -e $file ] ; then
    cp -r $file .
    else
    echo "<W> multiqc: $file does not exist!"
    fi
    done
    multiqc --force --no-data-dir --filename ~{outputPrefix} .
  >>>

  output {
    File report = "${outputPrefix}.html"
    #File report_pdf = "${outputPrefix}.pdf"
  }

  runtime {
    docker: docker
    memory: memory
    disks: "local-disk " + disk_size + " SSD"
  }
}

