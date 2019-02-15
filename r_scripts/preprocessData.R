#' Process tab-separated files with clinical and expression data
#'
#' Process tab-separated files containing clinical variables and expression values. This ensures that 
#' the data going into the analysis is structured correctly.
#'
#' @param path.expression path to tab-separated data file with expression values
#' @param path.clinical path to tab-separated data file with clinical values
#' @param path.conversions path to tab-separated data file with conversions of stratifications
#' @param path.settings path to tab-separated data file with settings
#' @return list of data frames; the first containing expression values and the second containing clinical vairables 
#' @export
#' @examples
#' preprocessData(path.expression, path.clinical, path.conversions, path.settings)


preprocessData <- function(path.expression, path.clinical, path.conversions, path.settings) {
	
	info = c()
	
	require(mice)
	
	# make sure the file exists at specified path
	if (!file.exists(path.expression) || !file.exists(path.clinical) || !file.exists(path.conversions) || !file.exists(path.settings)) {
		stop("The files were not uploaded correctly, please try again. -R")
	}

	# load files
	# TODO: compare with read_delim. I have written that read_delim is about 3x faster than fread in this case
	# TODO: put stratifications and settings outside this function
	expression 	    <- fread(input = path.expression,      na.strings = c("", "NaN", "NA", "NULL" ), showProgress = FALSE, header = TRUE, sep = "\t") 
	clinical 		    <- fread(input = path.clinical,        na.strings = c("", "NaN", "NA", "NULL" ), showProgress = FALSE, header = TRUE, sep = "\t")
	settings 		    <- fread(input = path.settings,        na.strings = c("", "NaN", "NA", "NULL" ), showProgress = FALSE, sep = "\t")

	# the stratification file is empty if a gene list was provided. In this case, set stratifications to the empty string
	info = file.info(path.conversions)
	if (info$size == 0) {
		stratifications <- ""
	} else {
		stratifications <- fread(input = path.conversions,     na.strings = c("", "NaN", "NA", "NULL" ), showProgress = FALSE, header = FALSE, sep = "\t")
	}
	
	
	# if there are any character columns other than stratification names, return error
	# this has been handled differently further down...
	# if ("character" %in% sapply(clinical[, -1], class)) {
	# 	stop("Analysis Error: Stratification values in you clinical data should only contain numeric data, please clean up your dataset and try again")
	# } else if ("character" %in% sapply(expression[, -1], class)) {
	# 	stop("Analysis Error: Expression values in your expression data should only contain numeric data, please clean up your dataset and try again")
	# }
	
	# if row identifiers are duplicated or missing, return error
	# this has been handled differently further down...
	# if (anyDuplicated(clinical[, 1]) || anyNA(clinical[, 1])) {
	# 	stop("Analysis Error: There are duplicated or missing stratification names in your clinical data, please clean up your dataset and try again")
	# } else if (anyDuplicated(expression[, 1]) || anyNA(expression[, 1])) {
	# 	stop("Analysis Error: There are duplicated or missing gene symbols in your clinical data, please clean up your dataset and try again")
	# }
	
	# transpose clinical data table or rewrite all code...
	patient.names <- clinical[[1]]
	stratification.names <- colnames(clinical)
	clinical <- transpose(clinical[, -1])
	colnames(clinical) <- patient.names
	clinical <- cbind(stratification.names[-1], clinical)
	
	
	
	# name column containing gene symbols
	setnames(expression, old = 1, new = "genes")
	setnames(clinical, old = 1, new = "stratifications")
	
	# remove rows where gene symbols / clincial variable names are missing
	expression <- na.omit(expression, cols = "genes")
	clinical <- na.omit(clinical, cols = "stratifications")
	info <- c(info, "There were xx missing gene symbols. These have been removed along with associated expression data")
	info <- c(info, "There were xx missing clinical variable names. These have been removed along with associated clinical data")

	# if there are duplicated gene symbols / clincial variable names, calculate mean expressions
	expression <- expression[, lapply(.SD, mean), by = genes]
	clinical <- clinical[, lapply(.SD, mean), by = stratifications]
	info <- c(info, "There were xx duplicated gene symbols. The mean expression values have been calculated for these")
	info <- c(info, "There were xx duplicated clinical variable names. The mean values have been calculated for these")
	
	# only keep patients that exists in both datasets (expression and clinical)
	patients <- intersect(colnames(expression), colnames(clinical))
	expression <- expression[, c("genes", patients), with = FALSE]
	clinical <- clinical[, c("stratifications", patients), with = FALSE]
	
	# remove patients without any expression data or any clinical data
	expression <- expression[, which(unlist(lapply(expression, function(x) !all(is.na(x))))), with = FALSE]
	clinical <- clinical[, which(unlist(lapply(clinical, function(x) !all(is.na(x))))), with = FALSE]
	info <- c(info, "There were xx patients without any associated clinical data. These patients have been removed.")
	info <- c(info, "There were xx patients without any associated expression data. These patients have been removed.")
	
	# TODO: remove genes without any expression data
	# TODO: remove variables without any clinical data

	
	
	# TODO: should below be done? in that case for each dataset separatly?
	# log2 transformation
	# apply function log2(x + 0.5) for each expression value x
	if (settings[setting == "log2_transformed", value] == FALSE) {
		# add a small value to every expression value to avoid taking the log2 of 0
		# there are no zeros in the r2 dataset
		# However, this might not be a perfect solution:
		# https://www.researchgate.net/post/Log_transformation_of_values_that_include_0_zero_for_statistical_analyses2
		expression <- cbind(expression[, "genes"], expression[, lapply(.SD, function(x) log2(x + 0.5)), .SDcols = -"genes"])
	}
	
	
	# impute and convert to data matrices
	# TODO: read up on how to impute correct values with the mice package
	# https://github.com/stefvanbuuren/mice/issues/48
	# output is data.frames
	if (anyNA(clinical)) {
		row.labels <- as.matrix(clinical[, "stratifications"])
		clinical <- mice(t(clinical[, !"stratifications", with = FALSE]), m = 5, maxit = 5, meth = 'pmm', seed = 500, remove_collinear = FALSE, print = FALSE)
		clinical <- complete(clinical, 1)
		clinical <- as.matrix(t(clinical))
		rownames(clinical) <- row.labels
	} else {
		row.labels <- as.matrix(clinical[, "stratifications"])
		clinical <- as.matrix(clinical[, !"stratifications", with = FALSE])
		rownames(clinical) <- row.labels
	}
	if (anyNA(expression)) {
		row.labels <- as.matrix(expression[, "genes"])
		expression <- mice(t(expression[, !"genes", with = FALSE]), m = 5, maxit = 5, meth = 'pmm', seed = 500, remove_collinear = FALSE, print = FALSE)
		expression <- complete(expression, 1)
		expression <- as.matrix(t(expression))
		rownames(expression) <- row.labels
	} else {
		row.labels <- as.matrix(expression[, "genes"])
		expression <- as.matrix(expression[, !"genes", with = FALSE])
		rownames(expression) <- row.labels
	}

	# only keep the given stratifications from the stratification file
	# matrix should be formatted as rows=variables, cols=samples
	if (stratifications[1] == "") {
		# do nothing
	}	else if (dim(stratifications)[1] == 1) {
		clinical <- t(as.matrix(clinical[unlist(stratifications), ]))
	} else {
		clinical <- as.matrix(clinical[unlist(stratifications), ])
	}
	
	# change row names for survival and life status
	# TODO: something fishy, the data do not have row names
	rownames(clinical)[rownames(clinical) == settings[setting == "survival", value]] <- "survival"
	rownames(clinical)[rownames(clinical) == settings[setting == "is_alive", value]] <- "is.alive"
	
	# change all row labels to valid ones
	rownames(clinical) <- make.names(rownames(clinical))
	rownames(expression) <- make.names(rownames(expression))
	
	# save the algorithm setting
	algorithm <- as.logical(settings[setting == "run_cox", value])
	
	# save which type of perturbations to use
	type <- settings[setting == "L1000_type", value]

	# send back for stratification process
	return(list(data = list("expression" = expression, "clinical" = clinical, "info" = info), run.cox = algorithm, L1000.type = type))
	
}
