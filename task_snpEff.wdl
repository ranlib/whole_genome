version 1.0

task task_snpEff {
    input {
      File vcf
      File config
      File dataDir
      String genome
      String outputPath = "./snpeff.vcf"
      Boolean hgvs = true
      Boolean lof = true
      Boolean noDownstream = false
      Boolean noIntergenic = false
      Boolean noShiftHgvs = false
      Int? upDownStreamLen
      String stats = "snpEff_summary.html"
      String csvStats = "snpEff_summary.csv"
      String memory = "9G"
      String docker = "dbest/snpeff:v5.2f"
    }
    
    command {
      set -ex
      mkdir -p "$(dirname ~{outputPath})"
      unzip ~{dataDir}
      snpEff ann \
      -verbose \
      -noDownload \
      -noLog \
      -stats ~{stats} \
      -csvStats ~{csvStats} \
      -config ~{config} \
      -dataDir "$PWD"/data \
      ~{true="-hgvs" false="-noHgvs" hgvs} \
      ~{true="-lof" false="-noLof" lof} \
      ~{true="-no-downstream" false="" noDownstream} \
      ~{true="-no-intergenic" false="" noIntergenic} \
      ~{true="-noShiftHgvs" false="" noShiftHgvs} \
      ~{"-upDownStreamLen " + upDownStreamLen} \
      ~{genome} \
      ~{vcf} \
      > ~{outputPath}
      rm -r "$PWD"/data
    }
    
    output {
      File outputVcf = outputPath
      File snpEff_summary_csv = csvStats
      File snpEff_summary_html = stats
    }

    runtime {
      docker: docker
      memory: memory
    }
}
