version 1.0

# Copyright (c) 2017 Leiden University Medical Center
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

task BgzipAndIndex {
    input {
        File inputFile
        String outputDir
        String preset = "vcf"

        Int compressLevel = 1
        Int threads = 1
        String memory = "2GiB"
        String docker = "quay.io/biocontainers/htslib:1.21--h566b1c6_1"
    }

    String outputGz = outputDir + "/" + basename(inputFile) + ".gz"

    command {
        set -e
        mkdir -p "$(dirname ~{outputGz})"
        bgzip \
        --threads ~{threads} \
        --compress-level ~{compressLevel} \
        -c ~{inputFile} > ~{outputGz}
        
        tabix \
        --preset ~{preset} \
        --threads ~{threads - 1} \
        ~{outputGz} 
    }

    output {
        File compressed = outputGz
        File index = outputGz + ".tbi"
    }

    runtime {
        cpu: threads
        memory: memory
        
        docker: docker
    }

    parameter_meta {
        # inputs
        inputFile: {description: "The file to be compressed and indexed.", category: "required"}
        outputDir: {description: "The directory in which the output will be placed.", category: "required"}
        preset: {description: "The preset for the file (eg. vcf or bed) to be compressed and indexed.", category: "common"}
        memory: {description: "The amount of memory this job will use.", category: "advanced"}
        docker: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}
        compressLevel: {description: "Set compression level.", category: "advanced"}
        threads: {description: "The number of threads to use.", category: "advanced"}

        # outputs
        compressed: {description: "Compressed input file."}
        index: {description: "Index of the compressed input file."}
    }
}

task DictAndFaidx {
    input {
        File inputFile
        String memory = "3GiB"
        String docker = "dbest/samtools:v1.22.1"
    }

    String outputFile = basename(inputFile)
    # Capture .fa¸ .fna and .fasta
    String outputDict = sub(outputFile, "\.fn?as?t?a?$", "") + ".dict"
    # This executes both dict and faidx, so indexes are co-located in the same folder.
    command <<<
        set -e
        cp ~{inputFile} ~{outputFile}
        samtools dict -o ~{outputDict}  ~{outputFile}
        samtools faidx ~{outputFile} --fai-idx ~{outputFile}.fai
    >>>

    output {
        File outputFasta = outputFile
        File outputFastaDict = outputDict
        File outputFastaFai = outputFile + ".fai"
    }

    runtime {
        memory: memory
        docker: docker
        cpu: 1
    }

    parameter_meta {
        # inputs
        inputFile: {description: "The input fasta file.", category: "required"}
        memory: {description: "The amount of memory available to the job.", category: "advanced"}
        docker: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}
        # outputs
        outputFasta: {description: "Fasta file that is co-located with the indexes"}
        outputFastaFai: {description: "Fasta index file for the outputFasta file."}
        outputFastaDict: {description: "Sequence dictionary for the outputFasta file."}
    }
}

task Faidx {
    input {
        File inputFile
        String outputDir

        String memory = "2GiB"
        String docker = "dbest/samtools:v1.22.1"
    }

    command {
        set -e
        mkdir -p "~{outputDir}"
        ln -s ~{inputFile} "~{outputDir}/$(basename ~{inputFile})"
        samtools faidx \
        "~{outputDir}/$(basename ~{inputFile})"
    }

    output {
        File outputIndex = outputDir + "/" + basename(inputFile) + ".fai"
    }

    runtime {
        memory: memory
        docker: docker
    }

    parameter_meta {
        # inputs
        inputFile: {description: "The input fasta file.", category: "required"}
        outputDir: {description: "Output directory path.", category: "required"}
        memory: {description: "The amount of memory available to the job.", category: "advanced"}
        docker: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}

        # outputs
        outputIndex: {description: "Index of the input fasta file."}
    }
}

task Fastq {
    input {
        File inputBam
        String outputRead1
        String? outputRead2
        String? outputRead0
        Boolean appendReadNumber = false
        Boolean outputQuality = false

        Int? includeFilter
        Int? excludeFilter
        Int? excludeSpecificFilter
        Int compressionLevel = 1

        Int threads = 1
        String memory = "1GiB"
        String docker = "dbest/samtools:v1.22.1"
    }

    command {
        set -e
        mkdir -p "$(dirname ~{outputRead1})"
        samtools collate -u -O ~{inputBam} | \
        samtools fastq \
        ~{true="-1" false="-s" defined(outputRead2)} ~{outputRead1} \
        ~{"-2 " + outputRead2} \
        ~{"-0 " + outputRead0} \
        ~{"-f " + includeFilter} \
        ~{"-F " + excludeFilter} \
        ~{"-G " + excludeSpecificFilter} \
        ~{true="-N" false="-n" appendReadNumber} \
        ~{true="-O" false="" outputQuality} \
        -c ~{compressionLevel} \
        "--threads "  ~{threads - 1}
    }

    output {
        File read1 = outputRead1
        File? read2 = outputRead2
        File? read0 = outputRead0
    }

    runtime {
        cpu: threads
        memory: memory
        docker: docker
        
    }

    parameter_meta {
        # inputs
        inputBam: {description: "The bam file to process.", category: "required"}
        outputRead1: {description: "The location the reads (first reads for pairs, in case of paired-end sequencing) should be written to.", category: "required"}
        outputRead2: {description: "The location the second reads from pairs should be written to.", category: "common"}
        outputRead0: {description: "The location the unpaired reads should be written to (in case of paired-end sequenicng).", category: "advanced"}
        appendReadNumber: {description: "Append /1 and /2 to the read name, or don't. Corresponds to `-n/N`.", category: "advanced"}
        outputQuality: {description: "Equivalent to samtools fastq's `-O` flag.", category: "advanced"}
        includeFilter: {description: "Include reads with ALL of these flags. Corresponds to `-f`.", category: "advanced"}
        excludeFilter: {description: "Exclude reads with ONE OR MORE of these flags. Corresponds to `-F`.", category: "advanced"}
        excludeSpecificFilter: {description: "Exclude reads with ALL of these flags. Corresponds to `-G`.", category: "advanced"}
        compressionLevel: {description: "Set compression level when writing gz or bgzf fastq files.", category: "advanced"}
        threads: {description: "The number of threads to use.", category: "advanced"}
        memory: {description: "The amount of memory this job will use.", category: "advanced"}
        docker: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}

        # outputs
        read1: {description: "Reads with the READ1 FLAG set."}
        read2: {description: "Reads with the READ2 FLAG set."}
        read0: {description: "Reads with either READ1 FLAG or READ2 flag set."}
    }
}

task FilterShortReadsBam {
    input {
        File bamFile
        String outputPathBam

        String memory = "1GiB"
        String docker = "dbest/samtools:v1.22.1"
    }

    String outputPathBamIndex = sub(outputPathBam, ".bam", ".bai")

    command {
        set -e
        mkdir -p "$(dirname ~{outputPathBam})"
        samtools view -h ~{bamFile} | \
        awk 'length($10) > 30 || $1 ~/^@/' | \
        samtools view -bS -> ~{outputPathBam}
        samtools index ~{outputPathBam} ~{outputPathBamIndex}
    }

    output {
        File filteredBam = outputPathBam
        File filteredBamIndex = outputPathBamIndex
    }

    runtime {
        memory: memory
        docker: docker
    }

    parameter_meta {
        # inputs
        bamFile: {description: "The bam file to process.", category: "required"}
        outputPathBam: {description: "The filtered bam file.", category: "common"}
        memory: {description: "The amount of memory this job will use.", category: "advanced"}
        docker: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}

        # outputs
        filteredBam: {description: "BAM file filtered for short reads."}
        filteredBamIndex: {description: "Index of filtered BAM file."}
    }
}

task Flagstat {
    input {
        File inputBam
        String outputPath

        Int threads = 1

        String memory = "256MiB"  # Only 40.5 MiB used for 150G bam file.
        String docker = "dbest/samtools:v1.22.1"
    }

    command <<<
        set -euxo pipefail
        mkdir -p "$(dirname ~{outputPath})"

        samtools flagstat \
            --threads ~{threads - 1} \
            ~{inputBam} > ~{outputPath}
    >>>

    output {
        File flagstat = outputPath
    }

    runtime {
        cpu: threads
        memory: memory
        docker: docker
    }

    parameter_meta {
        # inputs
        inputBam: {description: "The BAM file for which statistics should be retrieved.", category: "required"}
        outputPath: {description: "The location the ouput should be written to.", category: "required"}
        memory: {description: "The amount of memory needed for the job.", category: "advanced"}
        docker: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}
        threads: {description: "The number of threads to use.", category: "advanced"}

        # outputs
        flagstat: {description: "The number of alignments for each FLAG type."}
    }
}

task Idxstats {
    input {
        File inputBam
        String outputPath
        String memory = "256MiB"  # Only 40.5 MiB used for 150G bam file.
        String docker = "dbest/samtools:v1.22.1"
    }

    command <<<
        set -euco pipefail
        mkdir -p "$(dirname ~{outputPath})"
        samtools idxstats ~{inputBam} > ~{outputPath}
    >>>

    output {
        File idxstats = outputPath
    }

    runtime {
      memory: memory
      docker: docker
    }

    parameter_meta {
        # inputs
        inputBam: {description: "The BAM file for which statistics should be retrieved.", category: "required"}
        outputPath: {description: "The location the ouput should be written to.", category: "required"}
        memory: {description: "The amount of memory needed for the job.", category: "advanced"}
        docker: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}
        # outputs
        idxstats: {description: "Bam index stats."}
    }
}

task Index {
    input {
        File bamFile

        String? outputBamPath

        Int threads = 1

        String memory = "2GiB"
        String docker = "dbest/samtools:v1.22.1"
    }

    # Select_first is needed, otherwise womtool validate fails.
    String outputPath = select_first([outputBamPath, basename(bamFile)])
    String bamIndexPath = sub(outputPath, ".bam", ".bai")

    command {
        bash -c '
        set -e
        # Make sure outputBamPath does not exist.
        if [ ! -f ~{outputPath} ]
        then
            mkdir -p "$(dirname ~{outputPath})"
            ln ~{bamFile} ~{outputPath} || cp ~{bamFile} ~{outputPath}
        fi
        samtools index \
        --threads ~{threads -1} \
        ~{outputPath} ~{bamIndexPath}
        '
    }

    output {
        File indexedBam = outputPath
        File index =  bamIndexPath
    }

    runtime {
        cpu: threads
        memory: memory
        
        docker: docker
    }

    parameter_meta {
        # inputs
        bamFile: {description: "The BAM file for which an index should be made.", category: "required"}
        outputBamPath: {description: "The location where the BAM file should be written to. The index will appear alongside this link to the BAM file.", category: "common"}
        memory: {description: "The amount of memory needed for the job.", category: "advanced"}
        docker: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}
        threads: {description: "The number of threads to use.", category: "advanced"}

        # outputs
        indexedBam: {description: "BAM file that was indexed."}
        index: {description: "Index of the input BAM file."}
    }
}

task Markdup {
    input {
        File inputBam
        String outputBamPath
        Int threads = 1

        String docker = "dbest/samtools:v1.22.1"
    }

    command {
        set -e
        mkdir -p "$(dirname ~{outputBamPath})"
        samtools markdup \
        --threads ~{threads - 1} \
        ~{inputBam} ~{outputBamPath}
    }

    output {
        File outputBam = outputBamPath
    }

    runtime {
        cpu: threads
        docker: docker
        
    }

    parameter_meta {
        # inputs
        inputBam: {description: "The BAM file to be processed.", category: "required"}
        outputBamPath: {description: "The location of the output BAM file.", category: "required"}
        docker: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}
        threads: {description: "The number of threads to use.", category: "advanced"}

        # outputs
        outputBam: {description: "BAM file with duplicate alignments marked."}
    }
}

task Merge {
    input {
        Array[File]+ bamFiles
        String outputBamPath = "merged.bam"
        Boolean force = true

        Boolean combineRGHeaders = false 
        Boolean combinePGHeaders = false

        Int compressionLevel = 1
        # Use one thread per input + one for the output + one for merging
        Int threads = length(bamFiles) + 2
        String memory = "4GiB"
        String docker = "dbest/samtools:v1.22.1"
    }

    String indexPath = sub(outputBamPath, ".bam",".bai")

    # Samtools uses additional threads for merge.
    command {
        set -e
        mkdir -p "$(dirname ~{outputBamPath})"
        samtools merge \
        --threads ~{threads - 1} \
        ~{true="-f" false="" force} \
        -l ~{compressionLevel} \
        ~{true="-c" false="" combineRGHeaders} \
        ~{true="-p" false="" combinePGHeaders} \
        ~{outputBamPath} ~{sep=' ' bamFiles}
        samtools index -@ ~{threads - 1} ~{outputBamPath} ~{indexPath}
    }

    output {
        File outputBam = outputBamPath
        File outputBamIndex = indexPath
    }

    runtime {
        cpu: threads
        memory: memory
        
        docker: docker
    }

    parameter_meta {
        # inputs
        bamFiles: {description: "The BAM files to merge.", category: "required"}
        outputBamPath: {description: "The location the merged BAM file should be written to.", category: "common"}
        force: {description: "Equivalent to samtools merge's `-f` flag.", category: "advanced"}

        combineRGHeaders: {description: "Combine @RG headers with colliding IDs", category: "advanced"}
        combinePGHeaders: {description: "Combine @PG headers with colliding IDs", category: "advanced"}

        compressionLevel: {description: "Compression level from 0 (uncompressed) to 9 (best).", category: "advanced"}
        
        threads: {description: "Number of threads to use.", category: "common"}
        memory: {description: "The amount of memory this job will use.", category: "advanced"}
        docker: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}

        # outputs
        outputBam: {description: "Multiple BAM files merged into one."}
        outputBamIndex: {description: "Index of the merged BAM file."}
    }
}

task Quickcheck {
    input {
        File inputBam

        String docker = "dbest/samtools:v1.22.1"
    }

    command {
        set -e
        samtools quickcheck ~{inputBam}
    }

    output {
        File outputBam = inputBam
    }

    runtime {
        cpu: 1
        memory: "1GiB"
        docker: docker
    }

    parameter_meta {
        # inputs
        inputBam: {description: "The input BAM/SAM/CRAM file.", category: "required"}

        docker: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}

        # outputs
        outputBam: {description: "The exact same input file, but use this so it is recognised as a dependent task."}
    }
}

task Sort {
    input {
        File inputBam
        String outputPath
        Boolean sortByName = false
        Int compressionLevel = 1

        Int memoryPerThreadGb = 4
        Int threads = 1
        Int memoryGb = 1 + threads * memoryPerThreadGb
        String docker = "dbest/samtools:v1.22.1"
    }

    String bamIndexPath = sub(outputPath, ".bam", ".bai")

    command <<<
        set -euxo pipefail
        mkdir -p "$(dirname ~{outputPath})"
        samtools sort \
        -l ~{compressionLevel} \
        ~{true="-n" false="" sortByName} \
        ~{"--threads " + threads} \
        -m ~{memoryPerThreadGb}G \
        -o ~{outputPath} \
        ~{inputBam}
        samtools index \
        --threads ~{threads - 1} \
        ~{outputPath} ~{bamIndexPath}
    >>>

    output {
        File outputBam = outputPath
        File outputBamIndex = bamIndexPath
    }

    runtime {
        cpu: threads
        memory: "~{memoryGb}GiB"
        docker: docker
    }

    parameter_meta {
        # inputs
        inputBam: {description: "The input SAM file.", category: "required"}
        outputPath: {description: "Output directory path + output file.", category: "required"}
        sortByName: {description: "Sort the inputBam by read name instead of position.", category: "advanced"}
        compressionLevel: {description: "Compression level from 0 (uncompressed) to 9 (best).", category: "advanced"}
        memoryPerThreadGb: {description: "The amount of memory used per sort thread in gigabytes.", category: "advanced"}
        threads: {description: "The number of threads that will be used for this task.", category: "advanced"}
        memoryGb: {description: "The amount of memory available to the job in gigabytes.", category: "advanced"}
        docker: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}

        # outputs
        outputBam: {description: "Sorted BAM file."}
        outputBamIndex: {description: "Sorted BAM file index."}
    }
}

task Split {
    input {
        File inputBam
        String outputPath
        String? unaccountedPath
        String filenameFormat = "%!.%."

        Int compressionLevel = 1

        Int threads = 1
        String memory = "1GiB"
        String docker = "dbest/samtools:v1.22.1"
    }

    command {
        set -e
        mkdir -p "~{outputPath}/rg/"
        samtools split \
            --output-fmt bam \
            --output-fmt-option level=~{compressionLevel} \
            -f "~{outputPath}/rg/~{filenameFormat}" \
            ~{"-u " + unaccountedPath} \
            --threads ~{threads - 1} \
            --write-index \
            ~{inputBam}
    }

    output {
        Array[File] splitBam = glob(outputPath + "/rg/*.bam")
        Array[File] splitBamIndex = glob(outputPath + "/rg/*.bam.csi")
        File? unaccounted = unaccountedPath
    }

    runtime {
        cpu: threads
        memory: memory
        docker: docker
        
    }

    parameter_meta {
        # inputs
        inputBam: {description: "The bam file to split.", category: "required"}
        outputPath: {description: "Directory to store output bams", category: "required"}

        # Optional parameters
        unaccountedPath: {description: "The location to write reads to which are not detected as being part of an existing read group.", category: "common"}
        filenameFormat: {description: "Format of the filename, the following tokens can be used: %% a literal % sign, %* basename,  %# @RG index, %! @RG ID, %. filename extension for output format", category: "common"}
        compressionLevel: {description: "Set compression level when writing gz or bgzf fastq files.", category: "advanced"}

        # outputs
        splitBam: {description: "BAM file split by read groups"}
        splitBamIndex: {description: "BAM indexes"}
        unaccounted: {description: "Reads with no RG tag or an unrecognised RG tag."}
    }
}

task Tabix {
    input {
        File inputFile
        String outputFilePath = basename(inputFile)
        String preset = "vcf"

        String docker = "quay.io/biocontainers/htslib:1.21--h566b1c6_1"
    }

    # FIXME: It is better to do the indexing on VCF creation.
    # Not in a separate task. With file localization this gets hairy fast.
    command {
        set -e
        mkdir -p "$(dirname ~{outputFilePath})"
        if [ ! -f ~{outputFilePath} ]
        then
            ln ~{inputFile} ~{outputFilePath} || cp ~{inputFile} ~{outputFilePath}
        fi
        tabix ~{outputFilePath} -p ~{preset}
    }

    output {
        File indexedFile = outputFilePath
        File index = outputFilePath + ".tbi"
    }

    runtime {
        memory: "2GiB"
        
        docker: docker
    }

    parameter_meta {
        # inputs
        inputFile: {description: "The file to be indexed.", category: "required"}
        outputFilePath: {description: "The location where the file should be written to. The index will appear alongside this link to the file.", category: "common"}
        preset: {description: "The preset for the file (eg. vcf or bed) to be indexed.", category: "common"}
        docker: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}

        # outputs
        indexedFile: {description: "Indexed input file."}
        index: {description: "Index of the input file."}
    }
}

task View {
    input {
        File inFile
        String outputFileName = "view.bam"
        Boolean uncompressedBamOutput = false

        File? referenceFasta
        Int? includeFilter
        Int? excludeFilter
        Int? excludeSpecificFilter
        Int? MAPQthreshold
        File? targetFile

        Boolean fast = true  # Sets compression level to 1.

        Int threads = 1
        String memory = "1GiB"
        String docker = "dbest/samtools:v1.22.1"
    }

    String outputIndexPath = basename(outputFileName) + ".bai"

    # Always output to bam and output header.
    # -u should be after --fast, and will override it in that case.
    command {
        set -e
        mkdir -p "$(dirname ~{outputFileName})"
        samtools view -b \
        ~{"-T " + referenceFasta} \
        ~{"-o " + outputFileName} \
        ~{true="--fast" false="" fast} \
        ~{true="-u " false="" uncompressedBamOutput} \
        ~{"-f " + includeFilter} \
        ~{"-F " + excludeFilter} \
        ~{"-G " + excludeSpecificFilter} \
        ~{"-q " + MAPQthreshold} \
        --threads ~{threads - 1} \
        ~{"--target-file " + targetFile} \
        ~{inFile}
        samtools index ~{outputFileName} ~{outputIndexPath}
    }

    output {
        File outputBam = outputFileName
        File outputBamIndex = outputIndexPath
    }

    runtime {
        cpu: threads
        memory: memory
        
        docker: docker
    }

    parameter_meta {
        # inputs
        inFile: {description: "A BAM, SAM or CRAM file.", category: "required"}
        outputFileName: {description: "The location the output BAM file should be written.", category: "common"}
        fast: {description: "Sets compression level to 1. Set to true by default.", category: "common"}
        uncompressedBamOutput: {description: "Equivalent to samtools view's `-u` flag.", category: "advanced"}
        referenceFasta: {description: "The reference fasta file also used for mapping.", category: "advanced"}
        includeFilter: {description: "Equivalent to samtools view's `-f` option.", category: "advanced"}
        excludeFilter: {description: "Equivalent to samtools view's `-F` option.", category: "advanced"}
        excludeSpecificFilter: {description: "Equivalent to samtools view's `-G` option.", category: "advanced"}
        MAPQthreshold: {description: "Equivalent to samtools view's `-q` option.", category: "advanced"}
        targetFile: {description: "A BED file with regions to include", caegory: "advanced"}
        threads: {description: "The number of threads to use.", category: "advanced"}
        memory: {description: "The amount of memory this job will use.", category: "advanced"}
        docker: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}

        # outputs
        outputBam: {description: "Processed input file."}
        outputBamIndex: {description: "Index of the processed input file."}
    }
}

task Stats {
  input {
    File input_bam
    File? input_bam_index
    String? region
    Array[Int]? coverage_min_max_step
    Boolean remove_dups = false
    Boolean customized_index_file = false
    String? required_flag
    String? filtering_flag
    Float? gc_depth
    Int? insert_size
    String? read_group_id
    Int? read_length
    Float? most_inserts
    String? split_prefix
    Int? trim_quality
    File? reference_sequence
    String? split_tag
    File? target_regions_file
    Boolean sparse_output = false
    Boolean remove_overlaps = false
    Int? coverage_threshold
    String? input_format_option
    Int threads = 1
    Int verbosity = 0
    
    Int cpu_cores = 1
    Int memory_gb = 4
    Int disk_gb = 20
    
    String outputPath
    String docker = "dbest/samtools:v1.22.1"
  }
  
  command <<<
    set -euxo pipefail
    samtools stats \
    ~{true="--coverage" false="" defined(coverage_min_max_step)} ~{sep=',' coverage_min_max_step} \
    ~{true="-d" false="" remove_dups} \
    ~{true="-X" false="" customized_index_file} \
    ~{true="-f" false="" defined(required_flag)} ~{required_flag} \
    ~{true="-F" false="" defined(filtering_flag)} ~{filtering_flag} \
    ~{true="--GC-depth" false="" defined(gc_depth)} ~{gc_depth} \
    ~{true="-i" false="" defined(insert_size)} ~{insert_size} \
    ~{true="-I" false="" defined(read_group_id)} ~{read_group_id} \
    ~{true="-l" false="" defined(read_length)} ~{read_length} \
    ~{true="-m" false="" defined(most_inserts)} ~{most_inserts} \
    ~{true="-P" false="" defined(split_prefix)} ~{split_prefix} \
    ~{true="-q" false="" defined(trim_quality)} ~{trim_quality} \
    ~{true="-r" false="" defined(reference_sequence)} ~{reference_sequence} \
    ~{true="-S" false="" defined(split_tag)} ~{split_tag} \
    ~{true="-t" false="" defined(target_regions_file)} ~{target_regions_file} \
    ~{true="-x" false="" sparse_output} \
    ~{true="-p" false="" remove_overlaps} \
    ~{true="-g" false="" defined(coverage_threshold)} ~{coverage_threshold} \
    ~{true="--input-fmt-option" false="" defined(input_format_option)} ~{input_format_option} \
    ~{true="-@" false="" defined(threads)} ~{threads} \
    ~{true="--verbosity" false="" defined(verbosity)} ~{verbosity} \
    ~{input_bam} \
    ~{region} \
    > ~{outputPath}
  >>>
  
  output {
    File stats = outputPath
  }
  
  runtime {
    docker: docker
    cpu: cpu_cores
    memory: "${memory_gb} GB"
    disk: "${disk_gb} GB"
  }
  
  parameter_meta {
    # inputs
    input_bam: {description: "Input bam file", category: "required"}
    threads: {description: "The number of threads to use.", category: "advanced"}
    memory_gb: {description: "The amount of memory this job will use.", category: "advanced"}
    docker: {description: "The docker image used for this task.", category: "advanced"}
    
    # outputs
    stats: {description: "Output bam statistics."}
  }
}

workflow Samtools {
  input {
    File bam_file
    File? bam_index_file
    String? target_region
    Array[Int]? cov_dist_params
    Boolean exclude_duplicates
    File? ref_fasta
    Int num_threads
  }
  
  call Stats {
    input:
    input_bam = bam_file,
    input_bam_index = bam_index_file,
    outputPath = basename(bam_file, ".bam") + ".stats",
    region = target_region,
    coverage_min_max_step = cov_dist_params,
    remove_dups = exclude_duplicates,
    reference_sequence = ref_fasta,
    threads = num_threads
  }
  
  output {
    File generated_stats_file = Stats.stats
  }
}
