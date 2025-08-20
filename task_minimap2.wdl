version 1.0

task Indexing {
  input {
    Boolean useHomopolymerCompressedKmer = false
    Int kmerSize = 15
    Int minimizerWindowSize = 10
    String outputPrefix
    File referenceFile
    
    Int? splitIndex
    
    Int cores = 1
    String memory = "4G"
    String docker = "staphb/minimap2:2.29"
  }
  
  command {
    set -euxo pipefail
    mkdir -p "$(dirname ~{outputPrefix})"
    minimap2 \
    ~{true="-H" false="" useHomopolymerCompressedKmer} \
    -k ~{kmerSize} \
    -w ~{minimizerWindowSize} \
    ~{"-d " + outputPrefix + ".mmi"} \
    -t ~{cores} \
    ~{"-I " + splitIndex} \
    ~{referenceFile}
  }
  
  output {
    File indexFile = outputPrefix + ".mmi"
  }
  
  runtime {
    cpu: cores
    memory: memory
    docker: docker
  }
  
  parameter_meta {
    # inputs
    useHomopolymerCompressedKmer: {description: "Use homopolymer-compressed k-mer (preferrable for pacbio).", category: "advanced"}
    kmerSize: {description: "K-mer size (no larger than 28).", category: "advanced"}
    minimizerWindowSize: {description: "Minimizer window size.", category: "advanced"}
    outputPrefix: {description: "Output directory path + output file prefix.", category: "required"}
    referenceFile: {description: "Reference fasta file.", category: "required"}
    splitIndex: {description: "Split index for every ~NUM input bases.", category: "advanced"}
    cores: {description: "The number of cores to be used.", category: "advanced"}
    memory: {description: "The amount of memory available to the job.", category: "advanced"}
    docker: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}
    
    # outputs
    indexFile: {description: "Indexed reference file."}
  }
}

task Mapping {
  input {
    String presetOption
    Int kmerSize = 15
    Boolean skipSelfAndDualMappings = false
    Boolean outputSam = true
    String outputPrefix
    Boolean addMDTagToSam = true
    Boolean secondaryAlignment = false
    Boolean softClippingForSupplementaryAlignments = true
    Boolean writeLongCigar = true
    File referenceFile
    File queryFile1
    File queryFile2
    
    Int? maxIntronLength
    Int? maxFragmentLength
    Int? retainMaxSecondaryAlignments
    Int? matchingScore
    Int? mismatchPenalty
    String? howToFindGTAG
    
    Int cores = 4
    String memory = "30G"
    String docker = "staphb/minimap2:2.29"
  }

  String output_file = outputPrefix + ".sam"
  
  command <<<
    set -euxo pipefail
    mkdir -p "$(dirname ~{outputPrefix})"
    read_group="@RG\\tID:~{outputPrefix}\\tSM:~{outputPrefix}"
    minimap2 \
    -x ~{presetOption} \
    -k ~{kmerSize} \
    --eqx \
    -R ${read_group} \
    -o ~{output_file} \
    -t ~{cores} \
    ~{true="-L" false="" writeLongCigar} \
    ~{true="-Y" false="" softClippingForSupplementaryAlignments} \
    ~{true="-X" false="" skipSelfAndDualMappings} \
    ~{true="-a" false="" outputSam} \
    ~{true="--MD" false="" addMDTagToSam} \
    --secondary=~{true="yes" false="no" secondaryAlignment} \
    ~{"-G " + maxIntronLength} \
    ~{"-F " + maxFragmentLength} \
    ~{"-N " + retainMaxSecondaryAlignments} \
    ~{"-A " + matchingScore} \
    ~{"-B " + mismatchPenalty} \
    ~{"-u " + howToFindGTAG} \
    ~{referenceFile} \
    ~{queryFile1} \
    ~{queryFile2} 
  >>>
  
  output {
    File alignmentFile = output_file
  }
  
  runtime {
    cpu: cores
    memory: memory
    docker: docker
  }

  parameter_meta {
    # inputs
    presetOption: {description: "This option applies multiple options at the same time.", category: "common"}
    kmerSize: {description: "K-mer size (no larger than 28).", category: "advanced"}
    skipSelfAndDualMappings: {description: "Skip self and dual mappings (for the all-vs-all mode).", category: "advanced"}
    outputSam: {description: "Output in the sam format.", category: "common"}
    outputPrefix: {description: "Output directory path + output file prefix.", category: "required"}
    addMDTagToSam: {description: "Adds a MD tag to the sam output file.", category: "common"}
    secondaryAlignment: {description: "Whether to output secondary alignments.", category: "advanced"}
    referenceFile: {description: "Reference fasta file.", category: "required"}
    queryFile1: {description: "Input fasta file.", category: "required"}
    maxIntronLength: {description: "Max intron length (effective with -xsplice; changing -r).", category: "advanced"}
    maxFragmentLength: {description: "Max fragment length (effective with -xsr or in the fragment mode).", category: "advanced"}
    retainMaxSecondaryAlignments: {description: "Retain at most N secondary alignments.", category: "advanced"}
    matchingScore: {description: "Matching score.", category: "advanced"}
    mismatchPenalty: {description: "Mismatch penalty.", category: "advanced"}
    howToFindGTAG: {description: "How to find GT-AG. f:transcript strand, b:both strands, n:don't match GT-AG.", category: "common"}
    cores: {description: "The number of cores to be used.", category: "advanced"}
    memory: {description: "The amount of memory available to the job.", category: "advanced"}
    docker: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}
    
    # outputs
    alignmentFile: {description: "Mapping and alignment between collections of dna sequences file."}
  }
}
