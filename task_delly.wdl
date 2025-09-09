version 1.0

task task_delly {
  input {
    File bamFile
    File bamIndex
    File reference
    String svType = "DEL"
    String docker = "dbest/delly:v1.0.0"
    String memory = "32GB"
  }

  String outFile = sub(basename(bamFile),".bam",".delly.bcf")
  String outVCF = sub(basename(bamFile),".bam",".delly.vcf.gz")

  command {
    set -x
    delly call -t ~{svType} -o ~{outFile} -g ~{reference} ~{bamFile}
    if [ $? -eq 0 ] ; then
    bcftools view ~{outFile} | gzip > ~{outVCF}
    fi
  }

  output {
    File? vcfFile = outVCF
  }

  runtime {
    docker: docker
    memory: memory
  }

  parameter_meta {
    # inputs
    bamFile: {description: "The bam file to process.", category: "required"}
    bamIndex: {description: "The index bam file.", category: "required"}
    reference: {description: "The reference fasta file also used for mapping.", category: "required"}
    svType: {description: "Type of structural variant to look for.", category: "common"}
    memory: {description: "The memory required to run the programs.", category: "advanced"}
    docker: {description: "The docker image used for this task.", category: "advanced"}
    # outputs
    vcfFile: {description: "File containing structural variants."}
  }
}
