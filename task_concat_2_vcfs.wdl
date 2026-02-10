version 1.0

task task_concat_2_vcfs {
  input {
    File vcf1
    File vcf2
    String output_vcf_name
    String docker = "staphb/bcftools:1.17"
  }
  
  command <<<
      set -euxo
      bcftools sort -o ~{vcf1}.sorted ~{vcf1}
      bcftools sort -o ~{vcf2}.sorted ~{vcf2}
      bgzip ~{vcf1}.sorted
      bgzip ~{vcf2}.sorted
      tabix -p vcf ~{vcf1}.sorted.gz
      tabix -p vcf ~{vcf2}.sorted.gz
      bcftools concat --allow-overlaps -o ~{output_vcf_name} ~{vcf1}.sorted.gz ~{vcf2}.sorted.gz
  >>>
  
  output {
    File concatenated_vcf = output_vcf_name
  }
  
  runtime {
    docker: docker
  }
}

