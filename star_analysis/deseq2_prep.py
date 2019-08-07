#script to prepare combined sample data from htseq for DEseq2 analysis

import numpy as np
import pandas as pd
import pybiomart as pbm

filename = 'combined.txt' #name of combined dataset file from STAR?
filename = 'salmon/AC1449.salmon.quant.sf' #name of one file

dataset=pbm.Dataset(name='mmusculus_gene_ensembl', host='http://www.ensembl.org')
geneset=dataset.query(attributes=['ensembl_gene_id_version', 'external_gene_name'])
geneset.columns=['ensembl_gene_id_version','gene']

#df=pd.read_csv(filename, header=0, sep='\t', quotechar="''")
#df.drop(df.tail(5).index,inplace=True) # drop last 5 rows describing stats
df=pd.read_csv(filename, header=0, sep='\t')
df.rename(columns={'Name':'ensembl_transcript_id_version'}, inplace=True)

#get the gene names according to the ensembl gene id version
dataset=pbm.Dataset(name='mmusculus_gene_ensembl', host='http://www.ensembl.org')
geneset=dataset.query(attributes=['ensembl_transcript_id_version','ensembl_gene_id_version', 'external_gene_name'])
geneset.columns=['ensembl_transcript_id_version','ensembl_gene_id_version','gene']

#generate the dataframe of genes
df=df.merge(geneset,how='inner',on='ensembl_transcripte_id_version')
df.drop_duplicates(subset='gene',inplace=True) #drop duplicates
df.reset_index(drop=True,inplace=True)

#read in sample info
remove=['Unk','PD1ko'] #values to remove
info=pd.read_csv('sample_info.txt', header=0, sep=',', quotechar='"')[['Mouse','Phenotype']]

#find samples to remove because they are not CREn or CREp
remove=['Unk','PD1ko']
remove=info['Mouse'].loc[info['Phenotype'].isin(remove)].tolist()
remove.append('ensembl_gene_id_version') #also remove ensembl
df.drop(remove,axis=1,inplace=True) #drop those columns of data
#drop draining lymph nodes
remove=remove[0:3]+df.filter(like='dLN').columns.tolist()
df.drop(df.filter(like='dLN').columns.tolist(),axis=1,inplace=True)
#remove all these samples from the info sheet
info=info.loc[~info['Mouse'].isin(remove)]

#save data and set genes as first column
df=df.iloc[:, [24]+[i for i in range(24)]]
df.to_csv(index=False,path_or_buf='htseq_counts.csv')
info.to_csv(index=False,path_or_buf='sample_info.csv')
