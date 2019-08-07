## Setup
### Bioconductor and CRAN libraries used
library(DESeq2)
library(tidyverse)
library(RColorBrewer)
library(pheatmap)
library(DEGreport)
library(tximport)
library(ggplot2)
library(ggrepel)

setwd('/Users/jcollier/Downloads/salmon')
targets <- c('ENSMUSG00000031299','ENSMUSG00000006494')
out_counts <- 'tximport_counts.csv'
meta_file <- 'manifest.csv'
files_to_remove <- c('PD1KO1','AC9394','AC9392','AC9391','AC9393','AD1496','AD1494','PD1KO2','AC3868dLN','AC5393','AC3944dLN','AC3947dLN','AC7199dLN','AC7204dLN','AD3330-52','AD3331','AD3333','AD3351')

samples <- list.files(path = ".", full.names=T, pattern="\\.sf") # List all directories containing data
# this loop sets the names of the samples as the basename of the files  
for (i in 1:length(samples)){
    names(samples)[i] <- gsub('/','',unlist(strsplit(samples[i],'\\.'))[2])
}
samples <- samples[!(names(samples) %in% files_to_remove)]
tx2gene <- read.delim("../musmusculus_tx2gene.txt") # Load the annotation table for GrCh38

# Run tximport
txi <- tximport(samples, type="salmon", tx2gene=tx2gene[,c('ensembl_transcript_id_version', 'ensembl_gene_id')], countsFromAbundance="lengthScaledTPM")

# Write the counts to file; row names are the genes
data <- txi$counts %>% round() %>% data.frame()
write.csv(data,out_counts)

# Read in the sample table/metadata
meta_data <- data.frame(read.csv(meta_file, header=TRUE, sep=","))
meta <- filter(data.frame(meta_data), challenge=='primary') %>% filter(!sample %in% files_to_remove)
meta <- meta[match(colnames(txi$counts),meta[,'sample']),]
rownames(meta) <- meta[,'sample']
meta <- select(meta, 'cre')

# ggplot(data) +
#   geom_histogram(aes(x = Mov10_oe_1), stat = "bin", bins = 200) +
#   xlab("Raw expression counts") +
#   ylab("Number of genes")

# ggplot(data) +
#    geom_histogram(aes(x = Mov10_oe_1), stat = "bin", bins = 200) + 
#    xlim(-5, 500)  +
#    xlab("Raw expression counts") +
#    ylab("Number of genes")

# mean_counts <- apply(data[,6:8], 1, mean)
# variance_counts <- apply(data[,6:8], 1, var)
# df <- data.frame(mean_counts, variance_counts)

# ggplot(df) +
#         geom_point(aes(x=mean_counts, y=variance_counts)) + 
#         geom_line(aes(x=mean_counts, y=mean_counts, color="red")) +
#         scale_y_log10() +
#         scale_x_log10()


### DESEQ2
# Check that sample names match in both files
all(colnames(txi$counts) %in% rownames(meta))
all(colnames(txi$counts) == rownames(meta))

## Create DESeq2Dataset object
dds <- DESeqDataSetFromTximport(txi, colData = meta, design = ~ cre)
dds <- estimateSizeFactors(dds)
sizeFactors(dds)
normalized_counts <- counts(dds, normalized=TRUE)
write.table(normalized_counts, file="normalized_counts.txt", sep="\t", quote=F, col.names=NA)
pheatmap(normalized_counts[targets,rownames(meta[order(meta$cre), , drop = FALSE])], 
         annotation = meta[order(meta$cre), , drop = FALSE], 
         cluster_cols=FALSE, cluster_rows = FALSE, scale='row')
write.table(normalized_counts[targets,rownames(meta[order(meta$cre), , drop = FALSE])], 
            file="PDH_norm_counts.txt", sep="\t", quote=F, col.names=NA)


