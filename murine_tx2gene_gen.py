# Script to prepare a tx2gene file from Ensembl with genese for DEseq2 analysis
# from Salmon analyzed data
# Written by: Jenna Lynn Collier

outfile='musmusculus_tx2gene.txt'

import numpy as np
import pandas as pd
import pybiomart as pbm

# Grab dataset from mouse ensembl genes using pybiomart
dataset=pbm.Dataset(name='mmusculus_gene_ensembl', host='http://www.ensembl.org')
geneset=dataset.query(attributes=['ensembl_transcript_id_version','ensembl_gene_id', 'external_gene_name'])
geneset.columns=['ensembl_transcript_id_version','ensembl_gene_id','external_gene_name']
geneset['external_gene_name']=geneset['external_gene_name'].str.upper() # make gene names all capitals
geneset.to_csv(outfile,sep='\t') # save file as tab delimited