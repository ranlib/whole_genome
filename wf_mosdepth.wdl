version 1.0

task task_mosdepth {
    input {
        File input_bam
        File input_bai
        File? bed_file
        Int threads = 1
        Int mapq = 20
        String prefix
        String memory = "4GB"
        String disk = "10GB"
        String docker = "brentp/mosdepth:v0.3.3"
    }

    command <<<
        set -euxo pipefail
        mosdepth \
            ~{true="--by " false="" defined(bed_file)} ~{bed_file} \
            --mapq ~{mapq} \
            --threads ~{threads} \
             ~{prefix} \
            ~{input_bam}
           
    >>>

    output {
        File per_base_depth = "${prefix}.per-base.bed.gz"
        File global_dist = "${prefix}.mosdepth.global.dist.txt"
        File summary_output = "${prefix}.mosdepth.summary.txt"
        File? regions_depth = "${prefix}.regions.bed.gz"
    }

    runtime {
        docker: docker
        memory: memory
        cpu: threads
        disk: disk
    }
}

workflow wf_mosdepth {
    input {
        File sample_bam
        File sample_bai
        File? target_regions_bed
        String output_prefix
    }

    call task_mosdepth as MosdepthCoverage {
        input:
            input_bam = sample_bam,
            input_bai = sample_bai,
            bed_file = target_regions_bed,
            prefix = output_prefix
    }

    output {
        File coverage_per_base = MosdepthCoverage.per_base_depth
        File coverage_summary = MosdepthCoverage.summary_output
        File coverage_global_dist = MosdepthCoverage.global_dist
        File? coverage_regions_depth = MosdepthCoverage.regions_depth
    }
}
