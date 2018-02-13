########################################################################################################################
## createAnnotationPackage.rn5.R
## created: 2014-02-13
## creator: Yassen Assenov
## ---------------------------------------------------------------------------------------------------------------------
## Annotation package creation for Rn5.
########################################################################################################################

## F U N C T I O N S ###################################################################################################

#' createAnnotationPackage.rn5
#'
#' Helper function to create RnBeads annotation package for genome assembly rn5.
#'
#' @return None (invisible \code{NULL}).
#' @author Yassen Assenov
#' @noRd
createAnnotationPackage.rn6 <- function() { #AMS# CHANGED INTO rn6

	suppressPackageStartupMessages(require(BSgenome.Rnorvegicus.UCSC.rn6)) #AMS# CHANGED INTO rn6

	## Genomic sequence and supported chromosomes
	GENOME <- "BSgenome.Rnorvegicus.UCSC.rn6" #AMS# CHANGED INTO rn6
	assign('GENOME', GENOME, .globals)
	CHROMOSOMES <- c(1:20, "X", "Y") #AMS# ADDED "Y". IF SOMETHING FUCKES UP WE MAY ADD HERE "as.character"
	names(CHROMOSOMES) <- paste0("chr", CHROMOSOMES)
	assign('CHROMOSOMES', CHROMOSOMES, .globals)
	rm(GENOME)

	## Download SNP annotation
	logger.start("SNP Annotation")
	vcf.files <- gsub("^chr(.+)$", "vcf_chr_\\1.vcf.gz", names(CHROMOSOMES))
	vcf.files <- paste0(DBSNP.FTP.BASE, "rat_10116/VCF/", vcf.files) #AMS# NOTHING TO CHANGE HERE, REFERENCE2ASSEMBLY VARIABLE IN GLOBALS ALSO LOOKS OK
	update.annot("snps", "polymorphism information", rnb.update.dbsnp, ftp.files = vcf.files)
	logger.info(paste("Using:", attr(.globals[['snps']], "version")))
	rm(vcf.files)
	logger.completed()

	## Define genomic regions
	biomart.parameters <- list(
		database.name = "ENSEMBL_MART_ENSEMBL",
		dataset.name = "rnorvegicus_gene_ensembl",
		required.columns = c(
			"id" = "ensembl_gene_id",
			"chromosome" = "chromosome_name",
			"start" = "start_position",
			"end" = "end_position",
			"strand" = "strand",
			"symbol" = "rgd_symbol",
			"entrezID" = "entrezgene"),
		host = "dec2017.archive.ensembl.org") #AMS# HERE I CHANGED TO "dec2017" WHICH IS ENSEMBL 91, WHICH INCLUDES rn6
	logger.start("Region Annotation")
	update.annot("regions", "region annotation", rnb.update.region.annotation,
		biomart.parameters = biomart.parameters)
	rm(biomart.parameters)
	logger.completed()
#AMS# WE SHOULD NOT NEED TO EXPLICITLY STATE cgi.url, BECAUSE THE NAME OF RAT ASSEMBLY IN UCSC IS rn6, WHICH IS CORRECT
#AMS# FOR PROOF CHECK .globals[['assembly']] IN regions.R
	
	## Define genomic sites
	logger.start("Genomic Sites")
	update.annot("sites", "CpG annotation", rnb.update.sites)
	logger.completed()

	## Create all possible mappings from regions to sites
	logger.start("Mappings")
	update.annot("mappings", "mappings", rnb.create.mappings)
	logger.completed()

	## Export the annotation tables
	rnb.export.annotations.to.data.files()
}
