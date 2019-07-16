#!/bin/bash

# Script written by Jenna Lynn Collier

# This script takes in input arguments and performs STAR index generation using genome fasta and gene annotation files (.gtf)
# STAR index is necessary for STAR alignment and assignment or validation of RNAseq data

#SBATCH -p short 		# partition name
#SBATCH -t 0-1:00 		# hours:minutes runlimit
#SBATCH -c 6 		# number of cores requested
#SBATCH --mem 30G   # memory requested
#SBATCH --job-name STAR_index 		# Job name
#SBATCH -o %j.out			# File to which standard out will be written
#SBATCH -e %j.err 		# File to which standard err will be written

# Generate file containing job ID for later debugging
# Use <cat star_index_jobid.txt | sed -z "s/\n/.out\n/" | less> on the command line to look at standard output
# Use <cat star_index_jobid.txt | sed -z "s/\n/.err\n/" | less> on the command line to look at standard error
echo $SLURM_JOB_ID > star_index_jobid.txt

# Use getopts to parse arguments
while getopts ":ho:f:g:" opt; do
    case ${opt} in
        h )
            # Help description of input arguments
            echo "Usage for STAR genome index generation:"
            echo "    -h	Display this help message."
            echo "    -o 	Directory location for output results from STAR."
            echo "    -f 	Directory location for fasta file for genome."
            echo "    -g 	Name of .gtf annotation file for genome."
            exit 0
            ;;
        o )
            # Determine output directory 
            outDir=$OPTARG
            mkdir -p ${outDir} || echo $(date) "Unable to make output directory: $OPTARG" 1>&2; exit 1
            ;;
        f )
            fastaDir=$OPTARG
            [ "$(ls -A ${fastaDir})" ] && echo $(date) "Using directory: $OPTARG for genome fasta files" || $(date) "Could not identify $OPTARG directory containing genome fasta files"; exit 1 
            ;;
        g )
            gtfFile=$OPTARG
            [ -f ${fastaDir} ] && echo $(date) "Using $OPTARG for gene annotation (.gtf) file" || $(date) "Could not identify $OPTARG file"; exit 1
            ;;            
        \? )
            echo $(date) "Invalid option: $OPTARG" 1>&2; exit 1
            ;;
        : )
            echo $(date) "Invalid option: $OPTARG requires an argument" 1>&2; exit 1
            ;;
    esac
done
# Purge opt arguments
shift $((OPTIND -1))

# Load required modules
module load gcc/6.2.0 star/2.5.4a

# Run STAR with input arguments
STAR --runThreadN 8 \ # Number of threads to use
--runMode genomeGenerate \ # Run mode to generate genome index
--genomeDir ${outDir} \ # Define out directory
--genomeFastaFiles ${fastaDir} \ # Define directory for fasta files
--sjdbGTFfile ${gtfFile} \ # Name .gtf genome annotation file
--sjdbOverhang 99 # Overhang is optimally ((Length of average read) - 1)

