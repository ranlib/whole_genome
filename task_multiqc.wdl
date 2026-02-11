version 1.0

task task_multiqc {
  input {
    Array[File] inputFiles
    File? config_file 
    String outputPrefix
    String docker = "multiqc/multiqc:v1.33"
    String memory = "8GB"
    Int disk_size = 100
    Boolean? pdf
  }
  
  command <<<
    set -euxo
    for file in ~{sep=' ' inputFiles}; do
       if [ -e $file ] ; then
          cp $file .
       else
          echo "<W> multiqc: $file does not exist!"
       fi
    done
    multiqc --force --no-data-dir \
    ~{if defined(pdf) then "--pdf --template 'simple' " else "" } \
    ~{if defined(config_file) then "--config " else "" } ~{config_file} \
    --filename ~{outputPrefix} .
  >>>

  output {
    File report = "${outputPrefix}.html"
    File? report_pdf = "${outputPrefix}.pdf"
  }

  runtime {
    docker: docker
    memory: memory
    disks: "local-disk " + disk_size + " SSD"
  }
}

task task_multiqc_global {
    input {
        Array[File] reports_fastq_raw
        Array[File] reports_fastp_tight
        Array[File] reports_fastp_loose
        Array[File] reports_centrifuge
        Array[File] reports_host_contamination
        Array[File] reports_picard     
        Array[File] reports_bam        
        Array[File?] reports_mosdepth  
        Array[File] reports_snpEff     
        Array[File] reports_seqkit_raw 
        Array[File] reports_seqkit_after_cleanup
        Array[File] reports_fastq_after_cleanup
        File config_file 
        String outputPrefix
        String docker = "multiqc/multiqc:v1.33"
        String memory = "8GB"
        Int disk_size = 100
    }
    
    command <<<
        set -euxo
        mkdir -p multiqc_input/{fastq_raw,fastq_raw_R1,fastq_raw_R2,fastp_tight,fastp_loose,centrifuge,picard,bam,mosdepth,snpEff,seqkit_raw,fastq_after_cleanup,fastq_after_cleanup_R1,fastq_after_cleanup_R2,seqkit_after_cleanup,host_contamination}
        
        # FastQC_raw
        for f in ~{sep=' ' reports_fastq_raw}; do
            ln -s "$f" multiqc_input/fastq_raw/
        done

        # Fastp_tight
        for f in ~{sep=' ' reports_fastp_tight}; do
            ln -s "$f" multiqc_input/fastp_tight/
        done

        # Fastp_loose
        for f in ~{sep=' ' reports_fastp_loose}; do
            ln -s "$f" multiqc_input/fastp_loose/
        done

        # Centrifuge
        for f in ~{sep=' ' reports_centrifuge}; do
            ln -s "$f" multiqc_input/centrifuge/
        done

        # host contamination
        for f in ~{sep=' ' reports_host_contamination}; do
            ln -s "$f" multiqc_input/host_contamination/
        done

        # Picard
        for f in ~{sep=' ' reports_picard}; do
            ln -s "$f" multiqc_input/picard/
        done

        # Bam
        for f in ~{sep=' ' reports_bam}; do
            ln -s "$f" multiqc_input/bam/
        done

        # mosdepth
        for f in ~{sep=' ' reports_mosdepth}; do
            ln -s "$f" multiqc_input/mosdepth/
        done

        # snpEff
        for f in ~{sep=' ' reports_snpEff}; do
            ln -s "$f" multiqc_input/snpEff/
        done

        # seqkit_raw
        for f in ~{sep=' ' reports_seqkit_raw}; do
            ln -s "$f" multiqc_input/seqkit_raw/
        done

        # seqkit_after_cleanup
        for f in ~{sep=' ' reports_seqkit_after_cleanup}; do
            ln -s "$f" multiqc_input/seqkit_after_cleanup/
        done

        # FastQC_after_cleanup
        for f in ~{sep=' ' reports_fastq_after_cleanup}; do
            ln -s "$f" multiqc_input/fastq_after_cleanup/
        done

        multiqc --config ~{config_file} --filename ~{outputPrefix} multiqc_input
    >>>
    
    output {
        File report = "${outputPrefix}.html"
    }
    
    runtime {
        docker: docker
        memory: memory
        disks: "local-disk " + disk_size + " SSD"
    }
}

