version 1.0

task task_fastp {
  input {
    File read1
    File read2
    String sample_id
    String outprefix = sample_id
    String adapter_sequence = "AGATCGGAAGAGCACACGTC"
    String adapter_sequence_r2 = "AGATCGGAAGAGCGTCGTGTAGGAAAGAGTG"
    Int threads = 2
    Int trim_front1 = 0
    Int trim_tail1 = 0
    Int trim_front2 = 0
    Int trim_tail2 = 0
    Boolean cutadapt_compatible = false
    Boolean umi = false
    String umi_loc = "read1"
    Int umi_len = 0
    Boolean disable_quality_filtering = false
    Int minimum_base_quality = 20
    Int unqualified_percent_limit = 40
    Int n_base_limit = 5
    Int low_complexity_filter = 0
    Int complexity_threshold = 40
    Int minimum_read_length = 15
    Boolean filter_by_index = false
    Boolean correction = false
    Boolean proper_pairs_only = false
    Boolean merge_pe = false
    Boolean output_read1 = true
    Boolean output_read2 = true
    String extra_options = ""
    String docker_image = "dbest/fastp:v1.0.1"
    String memory = "32GB"
  }

  command <<<
    set -euxo pipefail
    fastp \
    -i ~{read1} \
    ~{true=' -I ' false="" defined(read2)} ~{read2} \
    -o ~{outprefix}.clean.1.fastq.gz \
    ~{if defined(read2) && output_read2 then '-O ' + outprefix + '.clean.2.fastq.gz' else ''} \
    -j ~{outprefix}.json \
    -h ~{outprefix}.html \
    -a ~{adapter_sequence} \
    ~{if defined(read2) then '-A ' + adapter_sequence_r2 else ''} \
    --thread ~{threads} \
    --trim_front1 ~{trim_front1} \
    --trim_tail1 ~{trim_tail1} \
    --length_required ~{minimum_read_length} \
    ~{if defined(read2) then '-F ' + trim_front2 else ''} \
    ~{if defined(read2) then '-T ' + trim_tail2 else ''} \
    ~{if cutadapt_compatible then '--cutadapt_compatible' else ''} \
    ~{if umi then '--umi' else ''} \
    ~{if umi then '--umi_loc ' + umi_loc else ''} \
    ~{if umi then '--umi_len ' + umi_len else ''} \
    ~{if disable_quality_filtering then '--disable_quality_filtering' else ''} \
    --qualified_quality_phred ~{minimum_base_quality} \
    --unqualified_percent_limit ~{unqualified_percent_limit} \
    --n_base_limit ~{n_base_limit} \
    ~{if low_complexity_filter > 0 then '--low_complexity_filter' else ''} \
    ~{if low_complexity_filter > 0 then '-z ' + complexity_threshold else ''} \
    ~{if filter_by_index then '--filter_by_index' else ''} \
    ~{if correction then '--correction' else ''} \
    ~{if proper_pairs_only then '--proper_pairs_only' else ''} \
    ~{if merge_pe then '--merge_pe' else ''} \
    ~{if !output_read1 then '--dont_output_read1' else ''} \
    ~{if defined(read2) && !output_read2 then '--dont_output_read2' else ''} \
    --detect_adapter_for_pe \
    ~{extra_options}
  >>>

  output {
    File clean_read1 = "${outprefix}.clean.1.fastq.gz"
    File clean_read2 = "${outprefix}.clean.2.fastq.gz"
    File report_json = "${outprefix}.json"
    File report_html = "${outprefix}.html"
  }

  runtime {
    docker: docker_image
    memory: memory
    cpu: threads
  }
}
