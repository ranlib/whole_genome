version 1.0

task task_fastqc {
  input {
    File forwardReads
    File reverseReads
    File? adapters
    File? contaminants
    File? limits
    Int threads = 1
    String docker = "staphb/fastqc:0.12.1"
    String memory = "8GB"
  }

  String forwardName = sub(sub(basename(forwardReads),".fastq.gz$",""),".fq.gz$","")
  String reverseName = sub(sub(basename(reverseReads),".fastq.gz$",""),".fq.gz$","")
  String tempForwardData = forwardName + "_fastqc/fastqc_data.txt"
  String tempReverseData = reverseName + "_fastqc/fastqc_data.txt"
  
  command <<<
    set -x
    CONT=""
    ADAP=""
    
    if ~{defined(adapters)} ; then
    zcat ~{adapters} | awk 'BEGIN{RS=">"; OFS="\t"}{print $1,$2}' > adapters.tsv
    ADAP="--adapters adapters.tsv"
    fi
    
    if ~{defined(contaminants)} ; then
    zcat ~{contaminants} | awk 'BEGIN{RS=">";OFS="\t"}{print $1,$2}' > contaminants.tsv 
    CONT="--contaminants contaminants.tsv"
    fi

    fastqc --outdir "." --extract --threads ~{threads} ${ADAP} ${CONT} \
    ~{"--limits " + limits} \
    ~{forwardReads} ~{reverseReads} 

    grep 'Total Sequences' "~{tempForwardData}" | cut -f 2 1> NUMBER_FORWARD_SEQUENCES
    grep 'Total Sequences' "~{tempReverseData}" | cut -f 2 1> NUMBER_REVERSE_SEQUENCES
  >>>

  output {
    File forwardHtml = forwardName + "_fastqc.html"
    File reverseHtml = reverseName + "_fastqc.html"
    File forwardZip = forwardName + "_fastqc.zip"
    File reverseZip = reverseName + "_fastqc.zip"
    File forwardData = forwardName + "_fastqc/fastqc_data.txt"
    File reverseData = reverseName + "_fastqc/fastqc_data.txt"
    File forwardSummary = forwardName + "_fastqc/summary.txt"
    File reverseSummary = reverseName + "_fastqc/summary.txt"
    Int numberForwardReads = read_int("NUMBER_FORWARD_SEQUENCES")
    Int numberReverseReads = read_int("NUMBER_REVERSE_SEQUENCES")
  }
  
  runtime {
    docker: docker
    memory: memory
    cpu: threads
  }
  
  parameter_meta {
    forwardReads: {description: "fastq file with forward reads.", category: "required"}
    reverseReads: {description: "fastq file with reverse reads.", category: "required"}
    threads: {description: "Number of cpus for this process.", category: "optional"}
    adapters: {description: "tsv file with adapter names in column 1 and sequences in column 2.", category: "optional"}
    contaminants: {description: "tsv file with adapter names in column 1 and sequences in column 2.", category: "optional"}
    limits: {description: "File with a set of warn/error limits for the various modules", category: "optional"}
    memory: {description: "The amount of memory this job will use.", category: "advanced"}
    docker: {description: "The docker image used for this task.", category: "advanced"}

    forwardHtml: {description: "Output html file for forward reads."}
    reverseHtml: {description: "Output html file for reverse reads."}
    forwardZip: {description: "Output zip file for forward reads."}
    reverseZip: {description: "Output zip file for reverse reads."}
    forwardData: {description: "Output data file for forward reads."}
    reverseData: {description: "Output data file for reverse reads."}
    forwardSummary: {description: "Output summary file for forward reads."}
    reverseSummary: {description: "Output summary file for reverse reads."}
    numberForwardReads: {description: "Number of forward reads."}
    numberReverseReads: {description: "Number of reverse reads."}
  }
}


