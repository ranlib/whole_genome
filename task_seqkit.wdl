version 1.0

task task_seqkit_stats {
  input {
    Array[File]+ input_file
    String out_file
    Boolean? all_stats
    Boolean? use_basename
    Boolean? skip_err
    Boolean? skip_file_check
    Boolean? tabular
    String? fq_encoding
    String? gap_letters
    String memory
    String docker = "dbest/seqkit:2.10.0"
    Int threads
  }

  command <<<
    set -euxo pipefail
    #${sep=' -N ' '-N' : n_values} \
    seqkit stats \
    --out-file ~{out_file} \
    ~{true='--all' false='' all_stats} \
    ~{true='--basename' false='' use_basename} \
    ~{true='--skip-err' false='' skip_err} \
    ~{true='--skip-file-check' false='' skip_file_check} \
    ~{true='--threads' false='' defined(threads)} ~{threads} \
    ~{true='--fq-encoding' false='' defined(fq_encoding) } ~{fq_encoding} \
    ~{true='--gap-letters' false='' defined(gap_letters) } ~{gap_letters} \
    ~{true='--tabular' false='' tabular} \
    ~{sep=" " input_file}
  >>>

  output {
    File stats_output = out_file
  }

  runtime {
    docker: docker
    memory: memory
    cpu: threads
  }
}

task task_seqkit_seq {
    input {
        File inputFile
        Boolean? colorizeSequences
        Boolean? complementSequence
        Boolean? dnaToRna
        String? gapLetters
        Boolean? lowerCase
        Int? maxLength
        Float? maxQuality
        Int? minLength
        Float? minQuality
        Boolean? onlyNames
        Boolean? onlyId
        Boolean? onlyQualities
        Int? qualityAsciiBase
        Boolean? removeGaps
        Boolean? reverseSequence
        Boolean? rnaToDna
        Boolean? onlySequences
        Boolean? upperCase
        Boolean? validateSequence
        Int? validateSequenceLength

        # Global Flags
        Int? alphabetGuessSeqLength
        Int? compressLevel
        Boolean? idNcbi
        String? idRegexp
        File? infileList
        Int? lineWidth
        String outFilePath 
        Boolean? quiet
        String? sequenceType
      Int threads = 1
      String  memory
      String docker = "stjude/seqkit:2.1.0"
    }

    command <<<
      set -euxo pipefail
        seqkit seq \
        ~{true="--color" false="" colorizeSequences} \
        ~{true="--complement" false="" complementSequence} \
        ~{true="--dna2rna" false="" dnaToRna} \
        ~{if defined(gapLetters) then "--gap-letters '" + gapLetters + "'" else ""} \
        ~{true="--lower-case" false="" lowerCase} \
        ~{if defined(maxLength) then "--max-len " + maxLength else ""} \
        ~{if defined(maxQuality) then "--max-qual " + maxQuality else ""} \
        ~{if defined(minLength) then "--min-len " + minLength else ""} \
        ~{if defined(minQuality) then "--min-qual " + minQuality else ""} \
        ~{true="--name" false="" onlyNames} \
        ~{true="--only-id" false="" onlyId} \
        ~{true="--qual" false="" onlyQualities} \
        ~{if defined(qualityAsciiBase) then "--qual-ascii-base " + qualityAsciiBase else ""} \
        ~{true="--remove-gaps" false="" removeGaps} \
        ~{true="--reverse" false="" reverseSequence} \
        ~{true="--rna2dna" false="" rnaToDna} \
        ~{true="--seq" false="" onlySequences} \
        ~{true="--upper-case" false="" upperCase} \
        ~{true="--validate-seq" false="" validateSequence} \
        ~{if defined(validateSequenceLength) then "--validate-seq-length " + validateSequenceLength else ""} \
        ~{if defined(alphabetGuessSeqLength) then "--alphabet-guess-seq-length " + alphabetGuessSeqLength else ""} \
        ~{if defined(compressLevel) then "--compress-level " + compressLevel else ""} \
        ~{true="--id-ncbi" false="" idNcbi} \
        ~{if defined(idRegexp) then "--id-regexp '" + idRegexp + "'" else ""} \
        ~{if defined(infileList) then "--infile-list " + infileList else ""} \
        ~{if defined(lineWidth) then "--line-width " + lineWidth else ""} \
        ~{true="--quiet" false="" quiet} \
        ~{if defined(sequenceType) then "--seq-type '" + sequenceType + "'" else ""} \
        ~{if defined(threads) then "--threads " + threads else ""} \
        -o ~{outFilePath} \
        ~{inputFile}
    >>>

    output {
        File outputFasta = outFilePath
    }

    runtime {
        docker: docker
        cpu: threads
        memory: memory
        disks: "local-disk 100 SSD"
    }
}

