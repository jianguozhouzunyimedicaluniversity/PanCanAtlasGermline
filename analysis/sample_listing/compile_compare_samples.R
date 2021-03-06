##### compile_compare_samples.R #####
# Kuan-lin Huang @ WashU 2017 Oct.
# compile sample lists and compare PCA germline samples to MC3 sample set

setwd("/Users/khuang/Box Sync/PhD/germline/PanCanAtlasGermline/analysis/sample_listing")
source("../global_aes_out.R")
system("mkdir out")
library(UpSetR)

# read and preprocess files
ISB_fn = "/Users/khuang/Box Sync/PhD/germline/PanCanAtlasGermline/TCGA_data/ISB-manifest/CGHub_legacyGDC_DNA_bams.csv.gz"
ISB = read.table(header=T, sep = ',',file=ISB_fn)
ISB_normal = ISB[substr(ISB$sample_barcode,14,14)==1,]
ISB_normal$inferred_ctype = gsub(".*TCGA.([A-Z]+)/.*","\\1",toupper(ISB_normal$bam_gcs_url))

final_fn = "/Users/khuang/Box\ Sync/PhD/germline/PanCanAtlasGermline/TCGA_data/sampleQC/pca_table.20171019.tsv"
final_full = read.table(header=T, sep = '\t',file=final_fn )
final = final_full[,c(1:4)]
colnames(final) = c("uuid","bcr_sample_barcode","bcr_patient_barcode","cancer")

ISB_normal_WXS = ISB_normal[ISB_normal$experimental_strategy == "WXS",]
ISB_normal_WXS_uniq = ISB_normal_WXS[!duplicated(ISB_normal_WXS$case_barcode),]
ISB_normal_WXS_uniq$final = ISB_normal_WXS_uniq$case_barcode %in% final$bcr_patient_barcode
table(ISB_normal_WXS_uniq$analyte_type,ISB_normal_WXS_uniq$inferred_ctype,ISB_normal_WXS_uniq$final)

ISB_normal_WGS = ISB_normal[ISB_normal$experimental_strategy == "WGS",]
ISB_normal_WGS_uniq = ISB_normal_WGS[!duplicated(ISB_normal_WGS$case_barcode),]

WXS_data = data.frame(table(ISB_normal_WXS_uniq$inferred_ctype))
WGS_data = data.frame(table(ISB_normal_WGS_uniq$inferred_ctype))
WXS_data$Technology = "WXS"
WGS_data$Technology = "WGS"
ISB_data = rbind(WXS_data,WGS_data)#merge(WXS_data,WGS_data,by="Var1")
colnames(ISB_data)[1:2] = c("Cancer","Count")
ISB_data$Cancer = as.character(ISB_data$Cancer)
#ISB_data$yPos = ISB_data$Count

# p = ggplot(data=ISB_data)
# p = p + geom_bar(aes(x=Cancer, y=Count, fill=Technology),stat = "identity")
# p = p + geom_text(aes(x=Cancer,y=Count, label=ifelse(Technology=="WXS",Count,NA)),color="black", vjust = -0.5, size=2)
# p = p + theme_bw()
# p = p + theme(axis.text.x = element_text(colour="black", size=8,angle=90,vjust=0.5))#,
# p
# fn = "out/cancer_datatype_distribution.pdf"
# ggsave(file=fn, h=5,w=6,useDingbats=FALSE)

# clinical data quick look:
# 10957 /Users/khuang/Box Sync/PhD/germline/PanCanAtlasGermline/TCGA_data/clinical/clinical_PANCAN_patient_with_followup.tsv
# 11160 /Users/khuang/Box Sync/PhD/germline/PanCanAtlasGermline/TCGA_data/clinical/PanCan_ClinicalData_V4_20170428.txt
# 14505 /Users/khuang/Box Sync/PhD/germline/PanCanAtlasGermline/TCGA_data/clinical/all.clin.merged.picked.txt

firehose_clin_fn = "/Users/khuang/Box Sync/PhD/germline/PanCanAtlasGermline/TCGA_data/clinical//all.clin.merged.picked.txt"
firehose_clin = read.table(header=T, sep = '\t',file=firehose_clin_fn,fill=T )
firehose_clin = firehose_clin[,1:6]
PCA_clin_f_fn = "/Users/khuang/Box Sync/PhD/germline/PanCanAtlasGermline/TCGA_data/clinical/PanCan_ClinicalData_V4_20170428.txt"
PCA_clin_f = read.table(header=T, sep = '\t',file=PCA_clin_f_fn,fill=T )
PCA_clin = PCA_clin_f[,1:6]
MC3_clin_fn = "/Users/khuang/Box Sync/PhD/germline/PanCanAtlasGermline/TCGA_data/clinical/clinical_PANCAN_patient_with_followup.tsv"
MC3_clin = read.table(header=T, sep = '\t',file=MC3_clin_fn,quote="" )
MC3_clin = MC3_clin[,1:6]

# some samples simply don't have clinical data
# just include samples with clinical data
colnames(final_full)[1:4] = c("uuid","bcr_sample_barcode","bcr_patient_barcode","cancer")
final_wclin = final_full[final_full$bcr_patient_barcode %in% PCA_clin$bcr_patient_barcode,]
fn = "/Users/khuang/Box\ Sync/PhD/germline/PanCanAtlasGermline/TCGA_data/sampleQC/pca_table.20171019.wclin.tsv"
write.table(final_wclin, file=fn, quote=F, sep="\t", col.names=T, row.names=F)

##### include samples that pass QC #####
# sample QC: NVAR count
NVAR_fn = "/Users/khuang/Box\ Sync/PhD/germline/PanCanAtlasGermline/analysis/variant_QC/out/low_call_samples.txt"
NVARSamples = as.vector(t(read.table(sep="\t",header=T, quote="",stringsAsFactors = F, file=NVAR_fn)[,2]))
# Genotype concordance
LowConcordance_fn = "/Users/khuang/Box\ Sync/PhD/germline/PanCanAtlasGermline/analysis/variant_QC/out/low_concordance_samples.txt"
LowConcordanceSamples = as.vector(t(read.table(sep="\t",header=T, quote="",stringsAsFactors = F, file=LowConcordance_fn)))

final_wclin_filtered = final_wclin[!(final_wclin$uuid %in% LowConcordanceSamples) & !(final_wclin$bcr_sample_barcode %in% NVARSamples),]
fn = "/Users/khuang/Box\ Sync/PhD/germline/PanCanAtlasGermline/TCGA_data/sampleQC/pca_table.20171118.filtered.wclin.tsv"
write.table(final_wclin_filtered, file=fn, quote=F, sep="\t", col.names=T, row.names=F)


# merge clinical data with AIM group ethnicity
clin_aim_f = "/Users/khuang/Box\ Sync/PhD/germline/PanCanAtlasGermline/TCGA_data/clinical/gdan_aim_patient_ancestry_calls.061217.txt"
clin_aim = read.table(header=T, sep = '\t',file=clin_aim_f,fill=T )
clin_aim$bcr_patient_barcode = paste("TCGA-",clin_aim$patient,sep="")
clin_aim = clin_aim[,c("bcr_patient_barcode","self_identified_race","self_identified_ethnicity","consensus_call")]
PCA_clin_f_aim = merge(PCA_clin_f,clin_aim,by="bcr_patient_barcode",all.x=T)
fn = "/Users/khuang/Box\ Sync/PhD/germline/PanCanAtlasGermline/TCGA_data/clinical/PanCan_ClinicalData_V4_wAIM.txt"
write.table(PCA_clin_f_aim, file=fn, quote=F, sep="\t", col.names=T, row.names=F)

PCA_clin_f_aim_filtered = PCA_clin_f_aim[PCA_clin_f_aim$bcr_patient_barcode %in% final_wclin_filtered$bcr_patient_barcode,]
fn = "/Users/khuang/Box\ Sync/PhD/germline/PanCanAtlasGermline/TCGA_data/clinical/PanCan_ClinicalData_V4_wAIM_filtered10389.txt"
write.table(PCA_clin_f_aim_filtered, file=fn, quote=F, sep="\t", col.names=T, row.names=F)


##### compare our WGS samples to MC3 and PCA samples #####
all_cases_data = data.frame(unique(c(as.character(firehose_clin$sample),as.character(ISB_normal_WXS_uniq$case_barcode),as.character(PCA_clin$bcr_patient_barcode),as.character(MC3_clin$bcr_patient_barcode),as.character(final$bcr_patient_barcode))))
colnames(all_cases_data) = "bcr_patient_barcode"
all_cases_data$inISB = all_cases_data$bcr_patient_barcode %in% as.character(ISB_normal_WXS_uniq$case_barcode)
all_cases_data$inPCA = all_cases_data$bcr_patient_barcode %in% as.character(PCA_clin$bcr_patient_barcode)
all_cases_data$inMC3 = all_cases_data$bcr_patient_barcode %in% as.character(MC3_clin$bcr_patient_barcode)
all_cases_data$final = all_cases_data$bcr_patient_barcode %in% as.character(PCA_clin_f_aim_filtered$bcr_patient_barcode)
all_cases_data$firehose = all_cases_data$bcr_patient_barcode %in% as.character(firehose_clin$sample)
all_cases_data[!all_cases_data] = 0
all_cases_data[all_cases_data] = 1
fn = "out/20171116_final_sample_upset.pdf"
pdf(fn, useDingbats = F)
upset(all_cases_data, sets = c("inISB", "inPCA", "inMC3","final","firehose"),order.by = "freq")
dev.off()