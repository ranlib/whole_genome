#!/bin/bash
#
# start with fresh snpEff.config and add organisms
#

#
# get fresh snpEff.config
#
cp $HOME/Software/snpEff/snpEff.config .
DB=$PWD/data

#
# add organisms
#

# tb
ORG=NC_000962.3
FAS=../references/tb/GCF_000195955.2_ASM19595v2_genomic.fna
GBK=../references/tb/GCF_000195955.2_ASM19595v2_genomic.gbff
GFF=../references/tb/GCF_000195955.2_ASM19595v2_genomic.gff
CDS=../references/tb/GCF_000195955.2_ASM19595v2_cds_from_genomic.fna
#CDS=../references/tb/GCF_000195955.2_ASM19595v2_translated_cds.faa
FAA=../references/tb/GCF_000195955.2_ASM19595v2_protein.faa
mkdir -p $DB/$ORG
cp $GBK $DB/$ORG/genes.gbk
cp $FAS $DB/$ORG/sequences.fa
#cp $GFF $DB/$ORG/genes.gff
#cp $FAA $DB/$ORG/protein.fa
#cp $CDS $DB/$ORG/cds.fa
echo "${ORG}.genome: ${ORG}" >> snpEff.config
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -gff3 $ORG
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -genbank $ORG

# acineto
ORG=NZ_CP045110.1
GBK=../references/acineto/GCF_009035845.1_ASM903584v1_genomic.gbff
GFF=../references/acineto/GCF_009035845.1_ASM903584v1_genomic.gff
FAS=../references/acineto/GCF_009035845.1_ASM903584v1_genomic.fna
CDS=../references/acineto/GCF_009035845.1_ASM903584v1_cds_from_genomic.fna
FAA=../references/acineto/GCF_009035845.1_ASM903584v1_protein.faa
#CDS=../references/acineto/GCF_009035845.1_ASM903584v1_translated_cds.faa
mkdir -p $DB/$ORG
cp $GBK $DB/$ORG/genes.gbk
cp $FAS $DB/$ORG/sequences.fa
#cp $GFF $DB/$ORG/genes.gff
#cp $FAA $DB/$ORG/protein.fa
#cp $CDS $DB/$ORG/cds.fa
echo "${ORG}.genome: ${ORG}" >> snpEff.config
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -gff3 $ORG
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -genbank $ORG

# pseudomonas
ORG=NC_021505.1
GBF=../references/pseudomonas/GCF_000412675.1_ASM41267v1_genomic.gbff
GFF=../references/pseudomonas/GCF_000412675.1_ASM41267v1_genomic.gff
FAS=../references/pseudomonas/GCF_000412675.1_ASM41267v1_genomic.fna
#CDS=../references/pseudomonas/GCF_000412675.1_ASM41267v1_translated_cds.faa
CDS=../references/pseudomonas/GCF_000412675.1_ASM41267v1_cds_from_genomic.fna
FAA=../references/pseudomonas/GCF_000412675.1_ASM41267v1_protein.faa
mkdir -p $DB/$ORG
cp $GBK $DB/$ORG/genes.gbk
cp $FAS $DB/$ORG/sequences.fa
#cp $GFF $DB/$ORG/genes.gff
#cp $FAA $DB/$ORG/protein.fa
#cp $CDS $DB/$ORG/cds.fa
echo "${ORG}.genome: ${ORG}" >> snpEff.config
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -gff3 $ORG
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -genbank $ORG

# shigella
ORG=NC_016822.1
#CDS=../references/shigella/GCF_000283715.1_ASM28371v1_translated_cds.faa
CDS=../references/shigella/GCF_000283715.1_ASM28371v1_cds_from_genomic.fna
FAA=../references/shigella/GCF_000283715.1_ASM28371v1_protein.faa
GBK=../references/shigella/GCF_000283715.1_ASM28371v1_genomic.gbff
GFF=../references/shigella/GCF_000283715.1_ASM28371v1_genomic.gff
FAS=../references/shigella/GCF_000283715.1_ASM28371v1_genomic.fna
mkdir -p $DB/$ORG
cp $FAS $DB/$ORG/sequences.fa
cp $GBK $DB/$ORG/genes.gbk
#cp $GFF $DB/$ORG/genes.gff
#cp $FAA $DB/$ORG/protein.fa
#cp $CDS $DB/$ORG/cds.fa
echo "${ORG}.genome: ${ORG}" >> snpEff.config
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -gff3 $ORG
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -genbank $ORG

# salmonella
ORG=NC_003197.2
FAS=../references/salmonella/GCF_000006945.2_ASM694v2_genomic.fna
GFF=../references/salmonella/GCF_000006945.2_ASM694v2_genomic.gff
GBK=../references/salmonella/GCF_000006945.2_ASM694v2_genomic.gbff
CDS=../references/salmonella/GCF_000006945.2_ASM694v2_cds_from_genomic.fna
#CDS=../references/salmonella/GCF_000006945.2_ASM694v2_translated_cds.faa
FAA=../references/salmonella/GCF_000006945.2_ASM694v2_protein.faa
mkdir -p $DB/$ORG
cp $FAS $DB/$ORG/sequences.fa
cp $GBK $DB/$ORG/genes.gbk
#cp $GFF $DB/$ORG/genes.gff
#cp $FAA $DB/$ORG/protein.fa
#cp $CDS $DB/$ORG/cds.fa
echo "${ORG}.genome: ${ORG}" >> snpEff.config
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -gff3 $ORG
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -genbank $ORG

# legionella
##ORG=NZ_CP071527.1
##GFF=../references/legionella/GCF_023921225.1_ASM2392122v1_genomic.gff
##FAS=../references/legionella/GCF_023921225.1_ASM2392122v1_genomic.fna

ORG=NZ_CP013742.1
CDS=../references/legionella/GCF_001941585.1_ASM194158v1_cds_from_genomic.fna
#CDS=../references/legionella/GCF_001941585.1_ASM194158v1_translated_cds.faa
FAS=../references/legionella/GCF_001941585.1_ASM194158v1_genomic.fna
GBK=../references/legionella/GCF_001941585.1_ASM194158v1_genomic.gbff
GFF=../references/legionella/GCF_001941585.1_ASM194158v1_genomic.gff
FAA=../references/legionella/GCF_001941585.1_ASM194158v1_protein.faa
mkdir -p $DB/$ORG
cp $FAS $DB/$ORG/sequences.fa
cp $GBK $DB/$ORG/genes.gbk
#cp $GFF $DB/$ORG/genes.gff
#cp $FAA $DB/$ORG/protein.fa
#cp $CDS $DB/$ORG/cds.fa
echo "${ORG}.genome: ${ORG}" >> snpEff.config
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -gff3 $ORG
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -genbank $ORG

# listeria
ORG=NZ_CP117229.1
GFF=../references/listeria/GCF_028596125.1_ASM2859612v1_genomic.gff
GBK=../references/listeria/GCF_028596125.1_ASM2859612v1_genomic.gbff
FAS=../references/listeria/GCF_028596125.1_ASM2859612v1_genomic.fna
FAA=../references/listeria/GCF_028596125.1_ASM2859612v1_protein.faa
CDS=../references/listeria/GCF_028596125.1_ASM2859612v1_cds_from_genomic.fna
#CDS=../references/listeria/GCF_028596125.1_ASM2859612v1_translated_cds.faa
mkdir -p $DB/$ORG
cp $FAS $DB/$ORG/sequences.fa
cp $GBK $DB/$ORG/genes.gbk
#cp $GFF $DB/$ORG/genes.gff
#cp $FAA $DB/$ORG/protein.fa
#cp $CDS $DB/$ORG/cds.fa
echo "${ORG}.genome: ${ORG}" >> snpEff.config
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -gff3 $ORG
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -genbank $ORG

# ecoli
ORG=NC_000913.3
GBK=../references/ecoli/GCF_000005845.2_ASM584v2_genomic.gbff
GFF=../references/ecoli/GCF_000005845.2_ASM584v2_genomic.gff
FAS=../references/ecoli/GCF_000005845.2_ASM584v2_genomic.fna
FAA=../references/ecoli/GCF_000005845.2_ASM584v2_protein.faa
CDS=../references/ecoli/GCF_000005845.2_ASM584v2_cds_from_genomic.fna
mkdir -p $DB/$ORG
cp $FAS $DB/$ORG/sequences.fa
cp $GBK $DB/$ORG/genes.gbk
#cp $GFF $DB/$ORG/genes.gff
#cp $FAA $DB/$ORG/protein.fa
#cp $CDS $DB/$ORG/cds.fa
echo "${ORG}.genome: ${ORG}" >> snpEff.config
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -gff3 $ORG
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -genbank $ORG

# klebsiella
ORG=NC_016845.1
FAA=../references/klebsiella/GCF_000240185.1_ASM24018v2_protein.faa
GFF=../references/klebsiella/GCF_000240185.1_ASM24018v2_genomic.gff
GBK=../references/klebsiella/GCF_000240185.1_ASM24018v2_genomic.gbff
CDS=../references/klebsiella/GCF_000240185.1_ASM24018v2_cds_from_genomic.fna
FAS=../references/klebsiella/GCF_000240185.1_ASM24018v2_genomic.fna
mkdir -p $DB/$ORG
cp $FAS $DB/$ORG/sequences.fa
cp $GBK $DB/$ORG/genes.gbk
#cp $GFF $DB/$ORG/genes.gff
#cp $FAA $DB/$ORG/protein.fa
#cp $CDS $DB/$ORG/cds.fa
echo "${ORG}.genome: ${ORG}" >> snpEff.config
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -gff3 $ORG
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -genbank $ORG

# enterobacter
ORG=NZ_AP022228.1
CDS=../references/enterobacter/GCF_014169635.1_ASM1416963v1_cds_from_genomic.fna
FAS=../references/enterobacter/GCF_014169635.1_ASM1416963v1_genomic.fna
GFF=../references/enterobacter/GCF_014169635.1_ASM1416963v1_genomic.gff
GBK=../references/enterobacter/GCF_014169635.1_ASM1416963v1_genomic.gbff
FAA=../references/enterobacter/GCF_014169635.1_ASM1416963v1_protein.faa
mkdir -p $DB/$ORG
cp $FAS $DB/$ORG/sequences.fa
cp $GFF $DB/$ORG/genes.gff
#cp $GBK $DB/$ORG/genes.gbk
#cp $FAA $DB/$ORG/protein.fa
#cp $CDS $DB/$ORG/cds.fa
echo "${ORG}.genome: ${ORG}" >> snpEff.config
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -gff3 $ORG
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -genbank $ORG

# proteus
ORG=NC_010554.1
FAA=../references/proteus/GCF_000069965.1_ASM6996v1_protein.faa
GFF=../references/proteus/GCF_000069965.1_ASM6996v1_genomic.gff
GBK=../references/proteus/GCF_000069965.1_ASM6996v1_genomic.gbff
FAS=../references/proteus/GCF_000069965.1_ASM6996v1_genomic.fna
CDS=../references/proteus/GCF_000069965.1_ASM6996v1_cds_from_genomic.fna
mkdir -p $DB/$ORG
cp $FAS $DB/$ORG/sequences.fa
cp $GBK $DB/$ORG/genes.gbk
#cp $GFF $DB/$ORG/genes.gff
#cp $FAA $DB/$ORG/protein.fa
#cp $CDS $DB/$ORG/cds.fa
echo "${ORG}.genome: ${ORG}" >> snpEff.config
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -gff3 $ORG
#docker run --rm -v .:/mnt -w /mnt dbest/snpeff:v5.4a snpEff build -noLog -c snpEff.config -genbank $ORG

#
# zip snpEff database
#
zip -r snpEff.zip data -i "*.bin"

exit 0
