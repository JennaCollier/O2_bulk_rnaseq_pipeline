#!/bin/bash
#SBATCH -t 0-00:05                         # Runtime in D-HH:MM format
#SBATCH -p short                           # Partition to run in
#SBATCH --mem=500M                         # Memory total in MB (for all cores)-reports in kilobytes
#SBATCH -o %j.out                 # File to which STDOUT will be written
#SBATCH -e %j.err

# Script written by Jenna Lynn Collier 
# This script takes in a base directory (-b) and fastq file (-f) to target for FastQC analysis that has an output directory
# within the base directory: {base directory}/results/fastqc

# Generate file containing job ID for later debugging
# Use <cat fastQC_jobid.txt | sed -z "s/\n/.out\n/" | less> on the command line to look at standard output
# Use <cat fastQC_jobid.txt | sed -z "s/\n/.err\n/" | less> on the command line to look at standard error
echo $SLURM_JOB_ID > fastQC_jobid.txt

# Use getopts to parse arguments
while getopts ":ho:f:g:" opt; do
    case ${opt} in
        h )
            # Help description of input arguments
            echo "Usage for STAR genome index generation:"
            echo "    -h	Display this help message."
            echo "    -o 	Output file directory."
            echo "    -f 	Name of fastq file for analysis"
            exit 0
            ;;
        o )
            # Produce output directory using the given base directory
            outDir=$OPTARG && echo $(date) "Results from fastQC will be placed in ${outDir}" || $(date) "Could not identify output directory for fastQC: ${outDir}"; exit 1 
            ;;
        f )
            fqFile=$OPTARG && echo $(date) "Targeting ${fqFile} for fastQC analysis" || $(date) "Could not identify ${fqFile} fastq file for fastQC"; exit 1
            ;;        
        \? )
            echo $(date) "Invalid option for fastQC: $OPTARG" 1>&2; exit 1
            ;;
        : )
            echo $(date) "Invalid option for fastQC: $OPTARG requires an argument" 1>&2; exit 1
            ;;
    esac
done
# Purge opt arguments
shift $((OPTIND -1))

# Load required modules
module load java/jdk-1.8u112
module load fastqc/0.11.5

# Call fastqc command using output directory targeting fastq file
fastqc -o ${outDir} ${fqFile}
