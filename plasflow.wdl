version 1.0

task spades_assembly {
    input {
        File read1_fastq
        File read2_fastq
        String sample_id
        String extra_args = ""
        String docker = "staphb/spades:4.2.0"
        Boolean careful = true
        Int threads = 8
        Int memory_gb = 32
    }

    command <<<
        set -euxo pipefail

        mkdir -p spades_out

        spades.py \
          -1 ~{read1_fastq} \
          -2 ~{read2_fastq} \
          -o spades_out \
          -t ~{threads} \
          -m ~{memory_gb} \
          ~{if careful then "--careful" else ""} \
          ~{extra_args}

        cp spades_out/contigs.fasta ~{sample_id}_spades_contigs.fasta
    >>>

    output {
        File contigs_fasta = "~{sample_id}_spades_contigs.fasta"
        File spades_log = "spades_out/spades.log"
    }

    runtime {
        docker: docker
        cpu: threads
        memory: "~{memory_gb}G"
    }
}

task filter_contigs_minlen {
    input {
        File contigs_fasta
        Int min_len = 1000
        String sample_id
        String docker = "dbest/seqkit:v2.10.1"
        String memory = "2G"
    }

    command <<<
        set -euxo pipefail
        seqkit seq -m ~{min_len} ~{contigs_fasta} > ~{sample_id}_contigs_min~{min_len}.fasta
    >>>

    output {
        File filtered_contigs = "~{sample_id}_contigs_min~{min_len}.fasta"
    }

    runtime {
        docker: docker
        cpu: 1
        memory: memory
    }
}


task plasflow_contigs {
    input {
        File contigs_fasta
        Float threshold = 0.7
        String sample_id
        String docker = "dbest/plasflow:v1.1"
        String memory = "8G"
        Int threads = 4
    }

    command <<<
        set -euxo pipefail
        PlasFlow.py \
            --input ~{contigs_fasta} \
            --output ~{sample_id} \
            --threshold ~{threshold}

        mv ~{sample_id} ~{sample_id}_plasflow.tsv
    >>>

    output {
        File plasflow_tsv = "~{sample_id}_plasflow.tsv"
        File plasflow_plasmids = "~{sample_id}_plasmids.fasta"
        File plasflow_chromosomes = "~{sample_id}_chromosomes.fasta"
        File plasflow_unclassified = "~{sample_id}_unclassified.fasta"
    }

    runtime {
        docker: docker
        cpu: threads
        memory: memory
    }
}

task plasflow_summary {
    input {
        File plasflow_tsv
        String sample_id
    }

    command <<<
        set -euxo pipefail

        awk -F'\t' '
        BEGIN { plasmid=0; total=0 }
        NR>1 {
            total++
            if ($2 == "Plasmid") plasmid++
        }
        END {
            print "sample\tplasmid_contigs\ttotal_contigs\tplasmid_fraction";
            printf "%s\t%d\t%d\t%.6f\n", "~{sample_id}", plasmid, total, plasmid/total
        }' ~{plasflow_tsv} > ~{sample_id}_plasflow_summary.tsv
    >>>

    output {
        File summary_tsv = "~{sample_id}_plasflow_summary.tsv"
    }

    runtime {
        docker: "ubuntu:25.04"
        cpu: 1
        memory: "512M"
    }
}

workflow plasflow {
    input {
        File read1_fastq
        File read2_fastq
        String sample_id
        Int threads = 8
        Int memory_gb = 32
        Int minlen = 1000
        Map[String,String] dockerImages
    }

    call spades_assembly {
        input:
        read1_fastq = read1_fastq,
        read2_fastq = read2_fastq,
        sample_id   = sample_id,
        threads     = threads,
        memory_gb   = memory_gb,
        careful     = true,
        extra_args  = "--cov-cutoff auto",
        docker = dockerImages["spades"]
    }

    call filter_contigs_minlen {
        input:
        contigs_fasta = spades_assembly.contigs_fasta,
        sample_id     = sample_id,
        min_len       = minlen,
        docker = dockerImages["seqkit"]
    }

    call plasflow_contigs {
        input:
        contigs_fasta = filter_contigs_minlen.filtered_contigs,
        sample_id     = sample_id,
        threads       = threads,
        docker = dockerImages["plasflow"]
    }

    call plasflow_summary {
        input:
        plasflow_tsv = plasflow_contigs.plasflow_tsv,
        sample_id   = sample_id
    }

    output {
        File assembly_contigs        = spades_assembly.contigs_fasta
        File plasflow_tsv            = plasflow_contigs.plasflow_tsv
        File plasflow_summary_tsv    = plasflow_summary.summary_tsv
    }
}
