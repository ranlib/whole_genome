version 1.0

task task_concat_2_vcfs {
  input {
    File vcf1
    File vcf2
    String output_vcf_name
    String docker = "staphb/bcftools:1.17"
  }
  
  command {
    set -x
    bcftools sort -o ~{vcf1}.sorted ~{vcf1}
    bcftools sort -o ~{vcf2}.sorted ~{vcf2}
    bcftools concat ~{vcf1}.sorted ~{vcf2}.sorted -o ${output_vcf_name}
  }
  
  output {
    File concatenated_vcf = output_vcf_name
  }
  
  runtime {
    docker: docker
  }
}

