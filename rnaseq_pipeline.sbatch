#!/bin/bash

#SBATCH -p short 		# partition name
#SBATCH -t 0-0:05 		# hours:minutes runlimit
#SBATCH --mem 200MB   # memory requested
#SBATCH --job-name bulk_RNA 		# Job name
#SBATCH -o %j.out			# File to which standard out will be written
#SBATCH -e %j.err 		# File to which standard err will be written

# Script based off of script by HBCtraining, edited by Jenna Lynn Collier 
# This script takes a fastq file of RNA-seq data, runs FastQC, STAR, Qualimap and Salmon.
# USAGE: sh rnaseq_analysis_on_input_file.sh <name of fastq file>

# Generate file containing job ID for later debugging
# Use <cat bulk_rnaseq_pipeline.txt | sed -z "s/\n/.out\n/" | less> on the command line to look at standard output
# Use <cat bulk_rnaseq_pipeline.txt | sed -z "s/\n/.err\n/" | less> on the command line to look at standard error
echo $SLURM_JOB_ID > bulk_rnaseq_pipeline.txt


# Use getopts to parse arguments
while getopts ":b:f:s:x" opt; do
    case "${opt}" in
        b)
            # Determine output directory 
            baseDir=$OPTARG
            [[ ${baseDir} != */ ]] && baseDir=${baseDir}/ # Assert that the base directory has a '/' at the end; otherwise, add it
            mkdir -p "${baseDir}" && echo $(date) "Created base project directory: ${baseDir} || echo $(date) "Unable to make base project directory: ${baseDir}"
            cd "${baseDir}" && echo "Changed to location: "${baseDir}"" # Change to the base directory
            ;;
        f)
            fastaFile=$OPTARG
            echo $(date) "Using fasta file: ${fastaFile}" 
            ;;
        s)
            suffix=$OPTARG
            echo $(date) "Using ${suffix} for suffix of fasta file"
            ;;
        x)
            species=$OPTARG
            if [ ${species}=='mouse' ] || [ ${species}=='Mouse' ]; then
                # directory with the genome and transcriptome index files + name of the gene annotation file
                genome=/n/groups/shared_databases/igenome/Mus_musculus/NCBI/GRCm38/Sequence/starIndex
                transcriptome=/n/groups/hbctraining/ngs-data-analysis-longcourse/rnaseq/salmon.ensembl38.idx
                gtf=/n/groups/shared_databases/igenome/Mus_musculus/NCBI/GRCm38/Annotation/Genes/genes.gtf
            elif [ ${species}=='human' ] || [ ${species}=='Human' ]; then
                echo $(date) "Not currently configured for analyzing ${species} fasta file" 1>&2; exit 1
            fi
            echo $(date) "Analyzing ${species} fasta file using parameters at following locations required for STAR alignment:"
            echo $(date) "Genome: ${genome}"
            echo $(date) "Transcriptome: ${transcriptome}"
            echo $(date) "Gtf annotation: ${gtf}"
            ;;            
    esac
done
# Purge opt arguments
shift $((OPTIND -1))

# grab base of filename for naming outputs
baseFile=`basename ${fastaFile} ${suffix}`
echo $(date) "Using: ${baseFile} for naming of output files"

# set up output filenames and locations
align_out=${baseDir}results/star/${baseFile}_aligned
align_out_bam=${baseDir}results/star/${baseFile}_aligned.sortedByCoord.out.bam
qualimap_out=${baseDir}results/qualimap/${baseFile}.qualimap
salmon_out=${baseDir}results/salmon/${baseFile}.salmon
salmon_mappings=${baseDir}results/salmon/${baseFile}_salmon.out

# make all of the output directories
# The -p option means mkdir will create the whole path if it 
# does not exist and refrain from complaining if it does exist
mkdir -p ${baseDir}results/star/ && echo $(date) "Created directory: ${baseDir}results/star/" || echo $(date) "Unable to make directory: ${baseDir}results/star/" 1>&2; exit 1
mkdir -p ${baseDir}results/qualimap/ && echo $(date) "Created directory: ${baseDir}results/qualimap/" || echo $(date) "Unable to make directory: ${baseDir}results/qualimap/" 1>&2; exit 1
mkdir -p ${baseDir}results/salmon/ && echo $(date) "Created directory: ${baseDir}results/salmon/" || echo $(date) "Unable to make directory: ${baseDir}results/salmon/" 1>&2; exit 1
echo $(date) "Generated all project directories sucessfully"

# set up the software environment
module load fastqc/0.11.3 && echo $(date) "Loaded fastqc/0.11.3 sucessfully"
module load gcc/6.2.0 && echo $(date) "Loaded gcc/6.2.0 sucessfully"
module load star/2.7.0a && echo $(date) "Loaded star/2.7.0a sucessfully"
module load samtools/1.3.1 && echo $(date) "Loaded samtools/1.3.1 sucessfully"
unset DISPLAY # Necessary for qualimap
export PATH=/n/app/bcbio/dev/anaconda/bin:$PATH # Necessary for salmon command
echo $(date) "Loaded all modules sucessfully"

echo $(date) "Processing file ${fastaFile}"
echo $(date) "Starting QC for ${baseFile}"

# Run FastQC and move output to the appropriate folder
/n/data2/mbib/sharpe/jcollier/scripts/fastqc.sh -b ${baseDir} -f ${fastaFile}
