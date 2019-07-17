#!/bin/bash

#SBATCH -p short 		# partition name
#SBATCH -t 0-0:05 		# hours:minutes runlimit
#SBATCH --mem 30GB   # memory requested
#SBATCH -c 6  # cores
#SBATCH --job-name bulk_RNA 		# Job name
#SBATCH -o %j.out			# File to which standard out will be written
#SBATCH -e %j.err 		# File to which standard err will be written

# Script based off of script by HBCtraining, edited by Jenna Lynn Collier 
# This script takes a fastq file of RNA-seq data, runs FastQC, STAR, Qualimap and Salmon.
# USAGE: sh rnaseq_analysis_on_input_file.sh <name of fastq file>

cores=6 # Set number of cores for testing

# Generate file containing job ID for later debugging
# Use <cat bulk_rnaseq_pipeline.txt | sed -z "s/\n/.out\n/" | less> on the command line to look at standard output
# Use <cat bulk_rnaseq_pipeline.txt | sed -z "s/\n/.err\n/" | less> on the command line to look at standard error
echo $SLURM_JOB_ID > bulk_rnaseq_pipeline.txt
echo $(date) "Created bulk_rnaseq_pipeline.txrt file with SLURM job ID: $SLURM_JOB_ID"

echo $(date) "Parsing arguments using getopts..."
# Use getopts to parse arguments
while getopts "b:f:s:x:" opt; do
    case "${opt}" in
        b)
            # Determine output directory 
            baseDir="${OPTARG}"
            [[ ${baseDir} != */ ]] && baseDir=${baseDir}/ # Assert that the base directory has a '/' at the end; otherwise, add it
            mkdir -p "${baseDir}" && echo $(date) "Created base project directory: ${baseDir}" || echo $(date) "Unable to make base project directory: ${baseDir}"
            cd "${baseDir}" && echo "Changed to location: ${baseDir}"
            ;;
        f)
            fastaFile="${OPTARG}"
            echo $(date) "Using fasta file: ${fastaFile}" 
            ;;
        s)
            suffix="${OPTARG}"
            echo $(date) "Using ${suffix} for suffix of fasta file to be removed from subsequent output files"
            ;;
        x)
            species="${OPTARG}"
            if [ "${species}"=="mouse" ] || [ "${species}"=="Mouse" ]; then
                genome="/n/data2/hms/mbib/sharpe/genomes/mus_musculus/ensembl/GRCm38/sequence/star_index" # Directory
                transcriptome="/n/data2/hms/mbib/sharpe/genomes/mus_musculus/ensembl/GRCm38/sequence/salmon_index" # Directory
                gtf="/n/data2/hms/mbib/sharpe/genomes/mus_musculus/ensembl/GRCm38/annotation/genes.gtf" # gtf file
            elif [ "${species}"=="human" ] || [ "${species}"=="Human" ]; then
                echo $(date) "Not currently configured for analyzing "${species}" fasta file" 1>&2
            fi
            echo $(date) "Analyzing "${species}" fasta file using parameters at following locations required for STAR alignment:"
            echo $(date) "Using genome at directory location: ${genome}"
            echo $(date) "Using transcriptome at directory location: ${transcriptome}"
            echo $(date) "Using gtf annotation file: ${gtf}"
            ;;            
    esac
done
# Purge opt arguments
shift $((OPTIND -1))
echo $(date) "Parsed arguments!"
echo ""

# grab base of filename for naming outputs
baseFile=`basename ${fastaFile} ${suffix}`
echo $(date) "Using: ${baseFile} for naming of output files"

# set up output filenames and locations
align_out="${baseDir}"results/star/${baseFile}_aligned && echo $(date) "Using STAR alignment output file name: ${align_out}"
align_out_bam="${baseDir}"results/star/${baseFile}_aligned.sortedByCoord.out.bam && echo $(date) "Using STAR alignment output BAM file name: ${align_out_bam}"
qualimap_out="${baseDir}"results/qualimap/${baseFile}.qualimap && echo $(date) "Using Qualimap output file name: ${qualimap_out}"
salmon_out="${baseDir}"results/salmon/${baseFile}.salmon && echo $(date) "Using Salmon output file name: ${salmon_out}"
salmon_mappings="${baseDir}"results/salmon/${baseFile}_salmon.out && echo $(date) "Using Salmon mappings file name: ${salmon_mappings}"
fastqc_outDir="${baseDir}"results/fastqc/ && echo $(date) "Using FastQC directory for ouput: ${fastqc_outDir}"
trim_outDir="${baseDir}"results/trimmomatic/ && echo $(date) "Using Trimmomatic directory for ouput: ${trim_outDir}"

# make all of the output directories
# The -p option means mkdir will create the whole path if it 
# does not exist and refrain from complaining if it does exist
mkdir -p ${fastqc_outDir} && echo $(date) "Created directory: ${fastqc_outDir}" || echo $(date) "Unable to make directory: ${fastqc_outDir}" 1>&2;
mkdir -p "${baseDir}"results/star/ && echo $(date) "Created directory: ${baseDir}results/star/" || echo $(date) "Unable to make directory: ${baseDir}results/star/" 1>&2;
mkdir -p "${baseDir}"results/qualimap/ && echo $(date) "Created directory: ${baseDir}results/qualimap/" || echo $(date) "Unable to make directory: ${baseDir}results/qualimap/" 1>&2;
mkdir -p "${baseDir}"results/salmon/ && echo $(date) "Created directory: ${baseDir}results/salmon/" || echo $(date) "Unable to make directory: ${baseDir}results/salmon/" 1>&2;
mkdir -p ${trim_outDir} && echo $(date) "Created directory: ${trim_outDir}" || echo $(date) "Unable to make directory: ${trim_outDir}" 1>&2;
mkdir -p "${trim_outDir}"/logs/ && echo $(date) "Created directory: "${trim_outDir}"/logs/" || echo $(date) "Unable to make directory: "${trim_outDir}"/logs/" 1>&2;

echo $(date) "Generated all project directories sucessfully"
echo ""

# set up the software environment
module load fastqc/0.11.3 && echo $(date) "Loaded fastqc/0.11.3 sucessfully"
module load gcc/6.2.0 && echo $(date) "Loaded gcc/6.2.0 sucessfully"
module load star/2.7.0a && echo $(date) "Loaded star/2.7.0a sucessfully"
module load samtools/1.3.1 && echo $(date) "Loaded samtools/1.3.1 sucessfully"
unset DISPLAY && echo $(date) "Unset display as needed for qualimap" # Necessary for qualimap
export PATH=/n/app/bcbio/dev/anaconda/bin:$PATH && echo $(date) "Exported path for Salmon" # Necessary for salmon command
echo $(date) "Loaded all modules sucessfully"
echo ""

echo $(date) "Processing file ${fastaFile}"
echo ""
echo $(date) "Starting FastQC"
# Run FastQC and move output to the appropriate folder
fastqc -o ${fastqc_outDir} ${fastaFile}
echo $(date) "Completed FastQC"

# Trimmomatic may or may not work
java -jar /n/app/trimmomatic/0.36/bin/trimmomatic-0.36.jar SE \
-threads 6 \
-phred33 \
-trimlog "${trim_outDir}"/logs/${baseFile}.txt \
${fastaFile} \
${trim_outDir}/${baseFile}.fq.gz \
ILLUMINACLIP:/n/app/trimmomatic/0.36/bin/adapters/TruSeq3-SE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

echo $(date) "Starting STAR alignment for: ${baseFile} using $cores cores"

# Run STAR
STAR --runThreadN $cores \
--genomeDir ${genome} \
--readFilesIn ${fastaFile} \
--outFileNamePrefix ${align_out} \
--outSAMtype BAM SortedByCoordinate \
--outSAMunmapped Within \
--outSAMattributes Standard

echo $(date) "Completed STAR alignment for: ${baseFile}!"
echo $(date) "Starting Qualimap for: ${baseFile}..."

# Run Qualimap
qualimap rnaseq \
-outdir ${qualimap_out} \
-a proportional \
-bam ${align_out_bam} \
-gtf ${gtf} \
--java-mem-size=10G

echo $(date) "Completed Qualimap for: ${baseFile}!"
# Run salmon
echo $(date) "Starting Salmon run for: ${baseFile}..."

salmon quant -i ${transcriptome} \
-p $cores \
-l A \
-r ${fastaFile} \
-o ${salmon_out} \
--seqBias \
--useVBOpt

echo $(date) "Completed Salmon run for: ${baseFile}!"
echo $(date) "Analysis of ${baseFile} complete"