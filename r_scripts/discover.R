
tryCatch({
	#stop("funkar")

require(jsonlite)
require(base64enc)
require(tictoc)
require(data.table)
require(MASS) # Linear discriminant function analysis
# tic("--------------------")
	
in.development <- 0

# --------------------------------------------------------------------------------------------- Load packages ---
# ---------------------------------------------------------------------------------------------------------------

	
	if (in.development) {
		setwd("C:\\xampp\\htdocs\\targetTranslator\\r_scripts\\")
		paths.expression <- c("C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\R2\\r2_expression.tsv", 
													"C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\TARGET\\target_expression.tsv")
		paths.clinical   <- c("C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\R2\\r2_clinical.tsv",
													"C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\TARGET\\target_clinical.tsv")
		path.conversions <- "C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\R2\\r2_stratifications.tsv"
		path.settings    <- "C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\R2\\r2_settings.tsv"
		path.signature   <- "C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\R2\\signature.tsv"
		path.signature   <- "C:\\xampp\\htdocs\\targetTranslator\\data\\markers_5c0e33fa6d636.tsv"
		
		paths.expression <- "C:\\xampp\\htdocs\\targetTranslator\\data\\job_5c0e40e4ee5da\\expression_5c0e40e4eec1e.tsv"
		paths.clinical   <- "C:\\xampp\\htdocs\\targetTranslator\\data\\job_5c0e40e4ee5da\\clinical_5c0e40e4eec1e.tsv"
		path.conversions <- "C:\\xampp\\htdocs\\targetTranslator\\data\\job_5c0e40e4ee5da\\stratifications_5c0e40e4eec1e.tsv"
		path.settings    <- "C:\\xampp\\htdocs\\targetTranslator\\data\\job_5c0e40e4ee5da\\settings_5c0e40e4eec1e.tsv"
		job.id           <- "5c0e40e4ee5da"
		path.signature   <- "C:\\xampp\\htdocs\\targetTranslator\\data\\job_5c0e40e4ee5da\\markers_5c0e40e4eec1e.tsv"
		
		paths.expression <- "C:\\xampp\\htdocs\\targetTranslator\\data\\job_5c4196de181b7\\expression_5c4196de18714.tsv"
		paths.clinical   <- "C:\\xampp\\htdocs\\targetTranslator\\data\\job_5c4196de181b7\\clinical_5c4196de18714.tsv"
		path.conversions <- "C:\\xampp\\htdocs\\targetTranslator\\data\\job_5c4196de181b7\\stratifications_5c4196de18714.tsv"
		path.settings    <- "C:\\xampp\\htdocs\\targetTranslator\\data\\job_5c4196de181b7\\settings_5c4196de18714.tsv"
		job.id           <- "5c4196de181b7"
		path.signature   <- "C:\\xampp\\htdocs\\targetTranslator\\data\\job_5c4196de181b7\\markers_5c4196de18714.tsv"
		
		library(tictoc)
		source("C:\\_Caroline\\Projects\\targetTranslator\\development\\Code\\importL1000Matlab.R")
		source("C:\\_Caroline\\Projects\\targetTranslator\\development\\Code\\calculateWeights.R")
		source("C:\\_Caroline\\Projects\\targetTranslator\\development\\Code\\importPriors.R")
		
		# create .Rdata objects for the L1000 dataset
		importL1000Matlab("C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\exported_from_Svens_code\\L1000_shRNA_cleaned.mat", 
											"C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\L1000\\L1000_shRNA.RData")
		importL1000Matlab("C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\exported_from_Svens_code\\L1000_drugs_cleaned.mat", 
											"C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\L1000\\L1000_drugs.RData")
	}

	

	# get parameters
	tic("get parameters      ")
	args <- commandArgs(TRUE)
	path.conversions     <- args[1]
	path.settings        <- args[2]
	paths.expression     <- eval(parse(text = args[3]))
	paths.clinical       <- eval(parse(text = args[4]))
	job.id       				 <- args[5]
	if (length(args) == 6) {
		path.signature       <- args[6]
	} else {
		path.signature       <- NULL
	}
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()

	tic("load functions      ")
	setwd("../r_scripts/")
	source("preprocessData.R")
	source("estimateSignature.R")
	source("estimateScores.R")
	source("estimateFDR.R")
	source("createResultTable.R")
	source("estimateEnrichment.R")
	source("plotEnrichment.R")
	#source("estimateCDF.R")
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()
	
	# extract number of datasets
	tic("extract num datasets")
	num.datasets <- length(paths.expression)
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()

	# load and preprocess datasets
	tic("preprocessing data  ")
	result <- vector(mode = "list", length = num.datasets)
	data <- vector(mode = "list", length = num.datasets)

	for (i in 1:num.datasets) {
		result[[i]] <- preprocessData(path.expression = paths.expression[i],
																	path.clinical = paths.clinical[i],
																	path.conversions = path.conversions,
																	path.settings = path.settings)
		
		data[[i]] <- result[[i]]$data
		
	}
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()

	tic("extract settings    ")
	run.cox <- result[[1]]$run.cox
	L1000.type <- result[[1]]$L1000.type
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()
	

	# estimate signature
	tic("estimate signatures ")
	signatures <- vector(mode = "list", length = num.datasets)
	signatures.null <- vector(mode = "list", length = num.datasets)
	marker.weights.raw <- fread(input = path.signature, na.strings = c("", "NaN", "NA", "NULL" ), showProgress = FALSE, sep = "\t")
	if (!is.na(marker.weights.raw[1, 1])) {
		# read markers if provided
		marker.weights <- as.matrix(marker.weights.raw$direction)
		row.names(marker.weights) <- marker.weights.raw$gene
	} else {
		marker.weights <- NULL
	}

	for (i in 1:num.datasets) {
		signatures[[i]]      <- estimateSignature(clinical = data[[i]]$clinical, expression = data[[i]]$expression, L1000.genes = L1000.genes, marker.weights = marker.weights, run.cox = run.cox)
		signatures.null[[i]] <- estimateSignature(clinical = data[[i]]$clinical, expression = data[[i]]$expression, L1000.genes = L1000.genes, marker.weights = marker.weights, run.cox = run.cox, test.null.hypothesis = TRUE)
	}
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()

	# load L1000
	tic("load L1000          ")
	load("L1000_drugs_reduced.RData")
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()
	
	# load L1000 stability values
	tic("load stability vals ")
	# TODO: are they specific for a certain dataset?
	if (in.development) {
		# use only drugs dataset for this
		multinom <- calculateWeights(L1000)
		#save(multinom, file = "C:\\_Caroline\\Projects\\aida\\development\\Datasets\\L1000\\L1000_shRNA_multinom.RData")
		save(multinom, file = "C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\L1000\\L1000_drugs_multinom.RData")
	} else {
		load("L1000_drugs_multinom.RData")
	}
	
	# TODO: these can belong to the original L1000 object
	L1000$probabilities <- multinom$probabilities
	L1000$coefficients <- multinom$coefficients
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()

	# estimate scores
	tic("estimate scores     ")
	scores <- vector(mode = "list", length = num.datasets)
	scores.null <- vector(mode = "list", length = num.datasets)
	
	# input argument should be a list of signatures for all datasets
	scores <- estimateScores(signatures, L1000)
	scores.null <- estimateScores(signatures.null, L1000)
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()
	
	# clear up space
	tic("clear up space      ")
	rm(L1000, signatures, multinom, result, data, run.cox)
	invisible(gc())
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()

	# estimate FDR
	tic("estimate FDR        ")
	fdr <- estimateFDR(scores, scores.null)
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()

	# create results table
	tic("create results table")
	# TODO: combine result and output it
	result.table <- createResultTable(scores, fdr)
	
	if (identical(L1000.type, "drug")) {
		# if drugs dataset, reformat drug names
		
		# replace the text "MINUS" with - and .... with space
		result.table$perturbation <- gsub('MINUS', '-', result.table$perturbation)
		result.table$perturbation <- gsub('....', ' ', result.table$perturbation, fixed = TRUE)
		
		# add concentration unit
		# the micro symbol makes everything crash, maybe some encoding issue, replave with u instead
		result.table$perturbation <- paste(result.table$perturbation, "uM", sep = "")
		
		# add what type of perturbation it is as the column name
		# if one does this it has to be fixed in the javascript to when printing the table
		#colnames(result.table)[which(names(result.table) == "Perturbation")] <- "Drug"

	}
	
	if (identical(L1000.type, "drug")) {
		# if drugs dataset, reformat drug names
		
		# replace the text "MINUS" with - and remove everything after ....
		row.names(scores) <- gsub('MINUS', '-', row.names(scores))
		row.names(scores) <- gsub("\\..*", '', row.names(scores))
	}
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()
	
	


	
	# load prior data
	tic("load prior data     ")
	if (in.development) {
		
		# # MSIGDB
		# importPriors(
		# 	path.priors.data = "C:\\_Caroline\\Projects\\aida\\development\\Datasets\\exported_datasets_from_Svens_code\\Gene2PathwayMSIGDBdata.txt",
		# 	path.priors.rows = "C:\\_Caroline\\Projects\\aida\\development\\Datasets\\exported_datasets_from_Svens_code\\Gene2PathwayMSIGDBrows.txt",
		# 	path.priors.cols = "C:\\_Caroline\\Projects\\aida\\development\\Datasets\\exported_datasets_from_Svens_code\\Gene2PathwayMSIGDBcols.txt",
		# 	path.output = "C:\\_Caroline\\Projects\\aida\\development\\Datasets\\priors\\msigdb.RData", 
		# 	perturbations = row.names(scores)
		# );
		# 
		# # STRING
		# importPriors(
		# 	path.priors.data = "C:\\_Caroline\\Projects\\aida\\development\\Datasets\\exported_datasets_from_Svens_code\\Gene2GeneSTRINGdata.txt",
		# 	path.priors.rows = "C:\\_Caroline\\Projects\\aida\\development\\Datasets\\exported_datasets_from_Svens_code\\Gene2GeneSTRINGrows.txt",
		# 	path.priors.cols = "C:\\_Caroline\\Projects\\aida\\development\\Datasets\\exported_datasets_from_Svens_code\\Gene2GeneSTRINGcols.txt",
		# 	path.output = "C:\\_Caroline\\Projects\\aida\\development\\Datasets\\priors\\string.RData", 
		# 	perturbations = row.names(scores)
		# );
		
		# STITCH
		importPriors(
			path.priors.data = "C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\exported_from_Svens_code\\Gene2DrugSTITCHdata.txt",
			path.priors.rows = "C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\exported_from_Svens_code\\Gene2DrugSTITCHrows.txt",
			path.priors.cols = "C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\exported_from_Svens_code\\Gene2DrugSTITCHcols.txt",
			path.output = "C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\priors\\stitch.RData", 
			perturbations = row.names(scores)
		);
		
	} else {
		#load("C:\\_Caroline\\Projects\\aida\\development\\Datasets\\priors\\msigdb.RData")
		#load("C:\\_Caroline\\Projects\\aida\\development\\Datasets\\priors\\string.RData")
		load("stitch.RData")
	}
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()
	
	
	if (in.development) {
		scores.pos <- as.matrix(fread(input = "C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\exported_from_Svens_code\\scores_pos.txt", 
																	na.strings = c("", "-", "NaN", "NA", "NULL" ), 
																	showProgress = FALSE, 
																	sep = "\t"))
		
		scores.neg <- as.matrix(fread(input = "C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\exported_from_Svens_code\\scores_neg.txt", 
																	na.strings = c("", "-", "NaN", "NA", "NULL" ), 
																	showProgress = FALSE, 
																	sep = "\t"))
		
		scores <- cbind(scores.pos[1, ], scores.neg[1, ])
		
		row.names(scores) <- make.names(priors$cols, unique = TRUE)

		save(scores, file = "C:\\Users\\carwa895\\Desktop\\scores.RData")
		
	}


	# estimate enrichment
	tic("estimate enrichment ")
	enrichment <- estimateEnrichment(scores, priors, priors.cutoff = 900, job.id)
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()
	
	# find all images and put file names in array
	# TODO: in what order are theses listed?
	# enrichment.files <- list.files(path = paste("..\\data\\job_", job.id, sep = ""), 
	# 					 pattern = "enrichment_",
	# 					 full.names = TRUE)
	
	# encode all images and put in array
	# enrichment.base64 <- lapply(enrichment.files, base64encode)
	
	# extract unique id from the first dataset
	#unique.id <- sub(".*_", "", paths.expression[1], perl = TRUE) # remove first characters up to _
	#unique.id <- sub("....$", "", unique.id, perl = TRUE) # remove last 4 characters

	# plot enrichment
	# TODO: never save file, just print to console
	#png(filename = paste("..\\data\\enrichment_", unique.id, ".png", sep = ""))
	#plotEnrichment(priors.score, priors$rows, subtypes, 20)
	#dev.off()
	
	# estimate cdf and plot
	#png(filename = paste("..\\data\\cdf_", unique.id, ".png", sep = ""))
	# TODO: what to do with the datasets
	#estimateCDF(scores, priors, target.name = 'MTOR', profile.names = c('proneural','neural','classical','mesenchymal'), priors.cutoff = 700)
	#dev.off()

	# convert images to base64 and print to console
	#image.enrichment <- base64encode(paste("..\\data\\enrichment_", unique.id, ".png", sep = ""))
	#image.cdf <- base64encode(paste("..\\data\\cdf_", unique.id, ".png", sep = ""))
	

	# print everything to console
	print(toJSON(result.table))
	print(toJSON(enrichment))
	# print(toJSON(enrichment.base64))
	
#}


}, error = function(e) {
	errors <- c("error", conditionMessage(e))
	print(toJSON(errors))
})





