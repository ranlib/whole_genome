version 1.0

task task_bbduk {
  input {
    File read1
    File read2
    File adapters
    File phiX
    File polyA
    String samplename
    String docker = "staphb/bbtools:39.26"
    String memory = "8GB"
    Boolean keep = true
    Int threads = 1
    Int disk_size = 100
    Int number_of_retries = 1
  }

  String java_mem = "-Xmx" + sub(memory,"GB","g")
  
  command <<<
    set -euxo pipefail

    # adapters
    bbduk.sh ~{java_mem} threads=~{threads} \
    in1=~{read1} \
    in2=~{read2} \
    out1=~{samplename}_no_adapter_1.fastq.gz \
    out2=~{samplename}_no_adapter_2.fastq.gz \
    ref=~{adapters} \
    stats=~{samplename}_adapter.stats.txt \
    ktrim=r \
    k=23 \
    mink=11 \
    hdist=1 \
    tpe \
    tbo &> ~{samplename}_adapter.log

    # phix
    bbduk.sh ~{java_mem} threads=~{threads} \
    in1=~{samplename}_no_adapter_1.fastq.gz \
    in2=~{samplename}_no_adapter_2.fastq.gz \
    out1=~{samplename}_no_phix_1.fastq.gz \
    out2=~{samplename}_no_phix_2.fastq.gz \
    outm=~{samplename}_matched_phix.fq.gz \
    ref=~{phiX} \
    stats=~{samplename}_phix.stats.txt \
    k=31 \
    hdist=1 &> ~{samplename}_phix.log

    # polyA
    bbduk.sh ~{java_mem} threads=~{threads} \
    in1=~{samplename}_no_phix_1.fastq.gz \
    in2=~{samplename}_no_phix_2.fastq.gz \
    out1=~{samplename}_no_polyA_1.fastq.gz \
    out2=~{samplename}_no_polyA_2.fastq.gz \
    outm=~{samplename}_matched_polyA.fq.gz \
    ref=~{polyA} \
    stats=~{samplename}_polyA.stats.txt \
    k=31 \
    hdist=1 &> ~{samplename}_polyA.log

    cp ~{samplename}_no_polyA_1.fastq.gz ~{samplename}_clean_1.fastq.gz
    cp ~{samplename}_no_polyA_2.fastq.gz ~{samplename}_clean_2.fastq.gz 

    # cleanup
    if ! ~{keep}
    then
        rm -fv ./*no_adapter*.fastq.gz
        rm -fv ./*no_phix*.fastq.gz
        rm -fv ./*no_polyA*.fastq.gz
    fi
  >>>

  output {
    File clean_read1 = "${samplename}_clean_1.fastq.gz"
    File clean_read2 = "${samplename}_clean_2.fastq.gz"
    File adapter_stats = "${samplename}_adapter.stats.txt"
    File phiX_stats = "${samplename}_phix.stats.txt"
    File polyA_stats = "${samplename}_polyA.stats.txt"
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
