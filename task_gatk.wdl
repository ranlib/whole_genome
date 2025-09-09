version 1.0

task LeftAlignAndTrimVariants {
    input {
      File referenceFasta
      File referenceFastaFai
      File referenceFastaDict
      File unfilteredVcf
      String alignedVcf
      
      String javaXmx = "12G"
      String memory = "13G"
      String docker = "broadinstitute/gatk:4.6.1.0"
    }
    
    command {
      set -ex
      mkdir -p "$(dirname ~{alignedVcf})"
      gatk --java-options '-Xmx~{javaXmx} -XX:ParallelGCThreads=1' \
      LeftAlignAndTrimVariants \
      --reference ~{referenceFasta} \
      --variant ~{unfilteredVcf} \
      --output ~{alignedVcf} \
      --split-multi-allelics
    }

    output {
      File outputAlignedVcf = alignedVcf
      File outputAlignedVcfIndex = alignedVcf + ".idx"
    }

    runtime {
        memory: memory
        docker: docker
    }
}

task FilterMutectCalls {
    input {
      File referenceFasta
      File referenceFastaFai
      File referenceFastaDict
      File unfilteredVcf
      File mutect2stats
      String filteredVcf
      Int min_reads_per_strand
      Int min_median_read_position
      Float min_allele_fraction
      String javaXmx = "12G"
      String memory = "13G"
      String docker = "broadinstitute/gatk:4.6.1.0"
    }

    command {
      set -ex
      mkdir -p "$(dirname ~{filteredVcf})"
      gatk --java-options '-Xmx~{javaXmx} -XX:ParallelGCThreads=1' \
      FilterMutectCalls \
      --reference ~{referenceFasta} \
      --variant ~{unfilteredVcf} \
      --output ~{filteredVcf} \
      --min-reads-per-strand ~{min_reads_per_strand} \
      --min-median-read-position ~{min_median_read_position} \
      --min-allele-fraction ~{min_allele_fraction} \
      --stats ~{mutect2stats} \
      --microbial-mode true
    }

    output {
      File outputFilteredVcf = filteredVcf
      File outputFilteredVcfIndex = filteredVcf + ".idx"
      File outputFilteredStats = filteredVcf + ".filteringStats.tsv"
    }

    runtime {
        memory: memory
        docker: docker
    }
}

task Mutect2 {
    input {
        Array[File]+ inputBams
        Array[File]+ inputBamsIndex
        File referenceFasta
        File referenceFastaDict
        File referenceFastaFai
        String outputVcf
        Array[File]+? intervals
        String javaXmx = "4G"
        String memory = "5G"
        String docker =  "broadinstitute/gatk:4.6.1.0"
    }

    command {
        set -ex
        mkdir -p "$(dirname ~{outputVcf})"
        gatk --java-options '-Xmx~{javaXmx} -XX:ParallelGCThreads=1' \
        Mutect2 \
        --reference ~{referenceFasta} \
        --input ~{sep=" -I " inputBams} \
        ~{if defined(intervals) then "--intervals" else "" } ~{sep=" -L " intervals} \
        --output ~{outputVcf}
    }

    output {
      File vcfFile = outputVcf
      File vcfFileIndex = outputVcf + ".idx"
      File vcfFileStats = outputVcf + ".stats"
    }

    runtime {
        memory: memory
        docker: docker
    }

}

