version 1.0

task trim_galore_task {
  input {
    File fastq_file
    File fastq_file_2
    String? adapter
    String? adapter2
    Int? quality
    Int? length
    Int? stringency
    Int? error_rate
    Boolean? paired
    String? outdir
    String? filename
    Boolean? dont_gzip
    Boolean? suppress_warnings
    Boolean? no_report_file
    Int? hardtrim5
    Int? hardtrim3
    Boolean? nextseq
    Boolean? trim1
    Int? clip_r1
    Int? clip_r2
    Int? three_prime_clip_r1
    Int? three_prime_clip_r2
    Boolean? poly_a
    Boolean? poly_g
    Boolean? retain_unpaired
    Boolean? rrna
    String? fastqc_args
    Int? cores
    Int? max_memory_gb
    Int? disk_size_gb
  }

  #  --filename ~{filename} \
  command <<<
    set -euxo pipefail
    trim_galore \
    ~{true="--adapter" false="" defined(adapter)}  ~{adapter} \
    ~{true="--adapter2" false="" defined(adapter2)} ~{adapter2} \
    --quality ~{quality} \
    --length ~{length} \
    --cores ~{cores} \
    --output_dir ~{outdir} \
    ~{true="--paired" false="" paired} \
    ~{true="--stringency" false="" defined(stringency)} ~{stringency} \
    ~{true="--error_rate" false="" defined(error_rate)} ~{error_rate} \
    ~{true="--dont_gzip" false="" dont_gzip} \
    ~{true="--hardtrim5" false="" defined(hardtrim5)} ~{hardtrim5} \
    ~{true="--hardtrim3" false="" defined(hardtrim3)} ~{hardtrim3} \
    ~{true="--suppress_warnings" false="" suppress_warnings} \
    ~{true="--no_report_file" false="" no_report_file} \
    ~{true="--nextseq" false="" nextseq} \
    ~{true="--trim1" false="" trim1} \
    ~{true="--clip_R1" false="" defined(clip_r1)} ~{clip_r1} \
    ~{true="--clip_R2" false="" defined(clip_r2)} ~{clip_r2} \
    ~{true="--three_prime_clip_R1" false="" defined(three_prime_clip_r1)} ~{three_prime_clip_r1} \
    ~{true="--three_prime_clip_R2" false="" defined(three_prime_clip_r2)} ~{three_prime_clip_r2} \
    ~{true="--polyA" false="" poly_a} \
    ~{true="--polyG" false="" poly_g} \
    ~{true="--retain_unpaired" false="" retain_unpaired} \
    ~{true="--rrna" false="" rrna} \
    --fastqc_args ~{fastqc_args} \
    ~{fastq_file} \
    ~{fastq_file_2}
  >>>

  output {
    Array[File] trimmed_fastq = glob("${outdir}/*.fq.gz")
    Array[File] fastqc_report = glob("${outdir}/*fastqc.html")
  }

  runtime {
    docker: "genomicpariscentre/trimgalore:0.6.10"
    cpu: select_first([cores, 1])
    memory: "${max_memory_gb} GB"
    disks: "default:${disk_size_gb} GB"
  }
}

workflow trim_galore_workflow {
  input {
    File input_fastq
    File input_fastq_2
    String? adapter_sequence
    String? adapter_sequence_2
    Int min_quality = 20
    Int min_length = 20
    Boolean find_adapters_with_sliding_window = false
    Int max_adapter_mismatch_rate = 3
    Boolean is_paired_end = false
    String output_directory = "trimmed_fastq_output"
    String output_filename_prefix = basename(input_fastq, ".fastq.gz")
    Boolean keep_gzip_output = false
    Boolean be_quiet = false
    Boolean no_warnings = false
    Int? hard_trim_5prime
    Int? hard_trim_3prime
    Boolean nextseq_compatibility = false
    Boolean trim_first_base = false
    Int? clip_r1_end
    Int? clip_r1_three_prime
    Int? clip_r2_end
    Int? clip_r2_three_prime
    Boolean remove_poly_a = false
    Boolean remove_poly_g = false
    Boolean also_keep_unpaired_reads = false
    Boolean remove_rrna_sequences = false
    String fastqc_additional_options = ""
    Int num_threads = 1
    Int memory_limit_gb = 2
    Int disk_space_gb = 10
  }

  call trim_galore_task {
    input:
      fastq_file = input_fastq,
      fastq_file_2 = input_fastq_2,
      adapter = adapter_sequence,
      adapter2 = adapter_sequence_2,
      quality = min_quality,
      length = min_length,
      stringency = max_adapter_mismatch_rate,
      paired = is_paired_end,
      outdir = output_directory,
      filename = output_filename_prefix,
      dont_gzip = keep_gzip_output,
      suppress_warnings = be_quiet,
      no_report_file = no_warnings,
      hardtrim5 = hard_trim_5prime,
      hardtrim3 = hard_trim_3prime,
      nextseq = nextseq_compatibility,
      trim1 = trim_first_base,
      clip_r1 = clip_r1_end,
      three_prime_clip_r1 = clip_r1_three_prime,
      clip_r2 = clip_r2_end,
      three_prime_clip_r2 = clip_r2_three_prime,
      poly_a = remove_poly_a,
      poly_g = remove_poly_g,
      retain_unpaired = also_keep_unpaired_reads,
      rrna = remove_rrna_sequences,
      fastqc_args = fastqc_additional_options,
      cores = num_threads,
      max_memory_gb = memory_limit_gb,
      disk_size_gb = disk_space_gb
  }

  output {
    Array[File] trimmed_reads = trim_galore_task.trimmed_fastq
    Array[File] fastqc_reports = trim_galore_task.fastqc_report
  }
}
