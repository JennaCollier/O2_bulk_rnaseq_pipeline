
#libraries
import seaborn as sns
import pandas as pd
from matplotlib import pyplot as plt

#file names
in_cts='htseq_counts.csv'
in_deseq='deseq2_results.csv'
in_info='sample_info.csv'

#select deseq values of interest
target_basemean=5
target_padj=0.01
target_foldchange=1
deseq=pd.read_csv(in_deseq,index_col=0)
deseq=deseq.loc[(abs(deseq['log2FoldChange'])>target_foldchange)&(deseq['padj']<target_padj)&(deseq['baseMean']>target_basemean)]

#read in counts file
cts=pd.read_csv(in_cts)
cts=cts.set_index('gene')
del cts.index.name

#get phenotype info for cluster labels
info=pd.read_csv(in_info)
info.sort_values(by=['Phenotype'],inplace=True)
info.set_index('Mouse',inplace=True,drop=True)
cts=cts[info.index.tolist()] #sort cts based on phenotype

#get column colors based on phenotype
info=info.pop('Phenotype')
pheno=dict(zip(info.unique(), ['indigo','darkgreen']))
col_colors = info.map(pheno)

#select deseq data of interest and use specific column order
col_order=['AC3947', 'AC9394', 'AD3353', 'AC9392', 'AD3330-52', 'AD3351',
       'AD1496', 'AC2228', 'AC4858', 'AC3942','AC3944', 'AC7204', 'AC9391',
       'AC9393', 'AD1494', 'AC3946', 'AC7199', 'AD3331', 'AD3333', 'AC4861',
       'AC4868', 'AC4862', 'AC1449','AD3354']
cts_de=cts.loc[deseq.index.tolist(),col_order]

#fig, ax = plt.subplots(1,1, figsize = (5,5))
#divider = make_axes_locatable(ax)
hmap=sns.clustermap(cts_de,z_score=0,robust=True,col_colors=col_colors,col_cluster=False,cmap='Blues',figsize=(10,5),linewidths=0.5)
hmap.ax_row_dendrogram.set_visible(False)
hmap.ax_row_dendrogram.set_xlim([0,0])
hmap.ax_heatmap.set(xticks=[])
plt.show(hmap)
