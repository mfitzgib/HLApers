library(hlaseqlib)
suppressPackageStartupMessages(library(tidyverse))

opts <- commandArgs(TRUE)
transcripts <- opts[1]
outPrefix   <- opts[2]

abundance_file <- file.path(outPrefix, "abundance.tsv")
outgenos <- file.path(outPrefix, "genotypes.tsv")
outindex <- file.path(outPrefix, "index.fa")

index <- Biostrings::readDNAStringSet(transcripts)

genos <- abundance_file %>% 
    read_tsv() %>% 
    filter(grepl("^IMGT_", target_id)) %>%
    mutate(locus = sub("^IMGT_([^\\*]+).+$", "\\1", target_id)) %>%
    select(locus, allele = target_id, counts = est_counts, tpm) %>%
    hla_genotype(th = 0.15) %>%
    filter(!is.na(allele))

alleles <- genos %>%
    pull(allele) %>%
    str_split("-") %>%
    unlist() %>%
    unique()

write_tsv(genos, outgenos)
Biostrings::writeXStringSet(index[alleles], outindex)