#!/bin/bash/

# Script written by Jenna Lynn Collier
# This script takes a fastq file of RNA-seq data, runs FastQC, STAR, Qualimap and Salmon.
# USAGE: sh rnaseq_analysis_on_input_file.sh <name of fastq file>

# initialize a variable with an intuitive name to store the name of the input fastq file
fq=$1

# change directories to /n/scratch2/ so that all the analysis is stored there.
cd /n/scratch2/sharpe

# grab base of filename for naming outputs
base=`basename $fq .subset.fq`
echo "Sample name is $base"   

# specify the number of cores to use
cores=6

# directory with the genome and transcriptome index files + name of the gene annotation file
genome=/n/groups/shared_databases/igenome/Mus_musculus/NCBI/GRCm38/Sequence/starIndex
transcriptome=/n/groups/hbctraining/ngs-data-analysis-longcourse/rnaseq/salmon.ensembl38.idx
gtf=/n/groups/shared_databases/igenome/Mus_musculus/NCBI/GRCm38/Annotation/Genes/genes.gtf

# make all of the output directories
# The -p option means mkdir will create the whole path if it 
# does not exist and refrain from complaining if it does exist
mkdir -p results/fastqc/
mkdir -p results/STAR/
mkdir -p results/qualimap/
mkdir -p results/salmon/

# set up output filenames and locations
fastqc_out=results/fastqc/
align_out=results/STAR/${base}_
align_out_bam=results/STAR/${base}_Aligned.sortedByCoord.out.bam
qualimap_out=results/qualimap/${base}.qualimap
salmon_out=results/salmon/${base}.salmon
salmon_mappings=results/salmon/${base}_salmon.out


# set up the software environment
module load fastqc/0.11.3
module load gcc/6.2.0  
module load star/2.7.0a
module load samtools/1.3.1
unset DISPLAY
export PATH=/n/app/bcbio/dev/anaconda/bin:$PATH

echo "Processing file $fq"
echo "Starting QC for $base"

# Run FastQC and move output to the appropriate folder
fastqc -o $fastqc_out $fq

# Run STAR
STAR --runThreadN $cores --genomeDir $genome --readFilesIn $fq --outFileNamePrefix $align_out --outSAMtype BAM SortedByCoordinate --outSAMunmapped Within --outSAMattributes Standard

# Run Qualimap
qualimap rnaseq \
-outdir $qualimap_out \
-a proportional \
-bam $align_out_bam \
-p strand-specific-reverse \
-gtf $gtf \
--java-mem-size=8G

# Run salmon
echo "Starting Salmon run for $base"

salmon quant -i $transcriptome \
-p $cores \
-l A \
-r $fq \
-o $salmon_out \
--seqBias \
--useVBOpt
