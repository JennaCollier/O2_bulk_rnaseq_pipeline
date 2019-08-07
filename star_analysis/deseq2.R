suppressPackageStartupMessages(library('DESeq2'))
suppressPackageStartupMessages(library('reshape2'))
suppressPackageStartupMessages(library('dplyr'))

in_counts = 'htseq_counts.csv'
in_info = 'sample_info.csv'
out_file='deseq2_results.csv'

cts = as.matrix(read.csv(in_counts,row.names=1,header=TRUE,check.names=FALSE)) #check.names prevents converting '-' in colnames to '.'
coldata = read.csv(in_info, row.names=1)

all(rownames(coldata) %in% colnames(cts)) #must be true; also in same order (?)
coldata['Phenotype']=coldata[colnames(cts), ]
rownames(coldata)=colnames(cts)

#perform DESeq2 analysis
dds = DESeqDataSetFromMatrix(countData=cts,colData=coldata,design=~Phenotype)
dds = DESeq(dds)
resultsNames(dds)

#get results from DESeq2 data
res=results(dds, name='Phenotype_CREp_vs_CREn')
res=res[order(res[,'log2FoldChange'],decreasing=TRUE),] #sort results by decreasing log2foldchange
head(res)
#write data with padj<0.05 and |log2FoldChange| > 0
write.csv(res[which((res[,'padj']<0.05)&(abs(res[,'log2FoldChange'])>0)),],file=out_file)
