tryCatch({
	

require(jsonlite)
require(base64enc)
require(tictoc)
require(data.table)
require(MASS)
	

# --------------------------------------------------------------------------------------------- Load packages ---
# ---------------------------------------------------------------------------------------------------------------

	
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
	load("L1000_drugs_multinom.RData")
		
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
	result.table <- createResultTable(scores, fdr)
	
	if (identical(L1000.type, "drug")) {
		# if drugs dataset, reformat drug names
		
		# replace the text "MINUS" with - and .... with space
		result.table$perturbation <- gsub('MINUS', '-', result.table$perturbation)
		result.table$perturbation <- gsub('....', ' ', result.table$perturbation, fixed = TRUE)
		result.table$perturbation <- gsub('PLUS', '+', result.table$perturbation)
		result.table$perturbation <- gsub('COMMA', ',', result.table$perturbation)
		
		# replace the text "MINUS" with - and remove everything after .... in the row names
		row.names(scores) <- gsub('MINUS', '-', row.names(scores))
		row.names(scores) <- gsub("\\..*", '', row.names(scores))
		result.table$perturbation <- gsub('PLUS', '+', result.table$perturbation)
		result.table$perturbation <- gsub('COMMA', ',', result.table$perturbation)
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
	load("stitch.RData")
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()
	
	# estimate enrichment
	tic("estimate enrichment ")
	enrichment <- estimateEnrichment(scores, priors, priors.cutoff = 900, job.id)
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()
	
	# print everything to console
	print(toJSON(result.table))
	print(toJSON(enrichment))

}, error = function(e) {
	errors <- c("error", conditionMessage(e))
	print(toJSON(errors))
})
