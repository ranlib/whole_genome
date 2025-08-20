version 1.0

task task_collect_wgs_metrics {
  input {
    File bam
    File reference
    File? bed
    String outputFile = "collect_wgs_metrics.txt"
    String sensitivityFile = "collect_wgs_sensitivity_metrics.txt"
    Int minMappingQuality = 20
    Int minBaseQuality = 20
    Int read_length = 150
    Int coverage_cap = 250
    Int sample_size = 10000
    Boolean use_fast_algorithm = true
    String docker = "broadinstitute/gatk:4.6.2.0"
    String memory = "8GB"
  }

  #--ALLELE_FRACTION [0.001, 0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.3, 0.5]
  
  command {
    set -ex

    if ~{defined(bed)} ; then
    gatk CreateSequenceDictionary \
    --REFERENCE ~{reference} \
    --OUTPUT "reference.dict"
    
    gatk BedToIntervalList \
    --INPUT ~{bed} \
    --OUTPUT "bed.intervals" \
    --SEQUENCE_DICTIONARY "reference.dict"
    
    gatk CollectWgsMetrics \
    --INPUT ~{bam} \
    --REFERENCE_SEQUENCE ~{reference} \
    --INTERVALS "bed.intervals" \
    --OUTPUT ~{outputFile} \
    --READ_LENGTH ~{read_length} \
    --COVERAGE_CAP ~{coverage_cap} \
    --USE_FAST_ALGORITHM ~{use_fast_algorithm} \
    --SAMPLE_SIZE ~{sample_size} \
    --MINIMUM_MAPPING_QUALITY ~{minMappingQuality} \
    --MINIMUM_BASE_QUALITY ~{minBaseQuality} \
    --THEORETICAL_SENSITIVITY_OUTPUT ~{sensitivityFile}

    else
    #--USE_FAST_ALGORITHM ~{use_fast_algorithm} \ # that crashes gatk
    gatk CollectWgsMetrics \
    --INPUT ~{bam} \
    --REFERENCE_SEQUENCE ~{reference} \
    --OUTPUT ~{outputFile} \
    --READ_LENGTH ~{read_length} \
    --COVERAGE_CAP ~{coverage_cap} \
    --SAMPLE_SIZE ~{sample_size} \
    --MINIMUM_MAPPING_QUALITY ~{minMappingQuality} \
    --MINIMUM_BASE_QUALITY ~{minBaseQuality} \
    --THEORETICAL_SENSITIVITY_OUTPUT ~{sensitivityFile}
    fi
    
  }

  output {
    File collectMetricsOutput = "${outputFile}"
    File collectMetricsSensitivity = "${sensitivityFile}"
  }
  
  runtime {
    docker: docker
    memory: memory
  }
}

