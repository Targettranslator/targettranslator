estimateSignature <- function(clinical, expression, L1000.genes, marker.weights=NULL, run.cox=FALSE, test.null.hypothesis=FALSE) {
	# Calculates expression signatures
	#
	# Args:
	#   clinical: 
	#   expression: 
	#   test.null.hypothesis: 
	#
	# Returns:
	#   signature:
	#
	
	require(DiscriMiner) # within-class covariance
	require(survival) # cox
	#require(klaR) # for the rda function, might not be used in the end


	# load L1000 genes
	tic("load L1000 genes    ")
	load("L1000_drugs_genes.RData")
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()
	
	
	
	
	

	
	#signature.weights.filtered <- signature.weights.all[gene %in% row.names(data[[1]]$expression)]
	
	
	# TODO: only use genes that are present in both datasets
	# only keep genes that exists in both populations (data1 and data2)
	#data1.expression <- data1.expression[genes %in% data2.expression$genes]
	#data2.expression <- data2.expression[genes %in% data1.expression$genes]
	
	# if (signature) {
	# 	
	# 	expression.subset <- vector(mode = "list", length = num.datasets)
	# 	z.scores.expression <- vector(mode = "list", length = num.datasets)
	# 
	# 	# Just set the ridge parameter to 10, this should be validated
	# 	penalty <- 10
	# 	
	# 	
	# 	for (i in 1:num.datasets) {
	# 		
	# 		# extract all genes from the expression data
	# 		expression.subset[[i]] <- data[[i]]$expression[row.names(signature.weights), ]
	# 		
	# 		# center and scale data
	# 		# scale in R is zscores in MATLAB
	# 		z.scores.expression[[i]] <- scale(t(expression.subset[[i]]))
	# 		
	# 		# add penalty to the diagonal elements in the v * v' matrix (rpinv)
	# 		x <- z.scores.expression[[i]] %*% t(z.scores.expression[[i]])
	# 		diag(x) <- diag(x) + penalty
	# 		
	# 		signature <- ginv(x) %*% z.scores.expression[[i]] %*% expression.subset[[i]]
	# 	}
	# 	
	# 	# center and scale data
	# 	# scale in R is zscores in MATLAB
	# 	#z.scores.stratification <- scale(t(stratification))
	# 	#z.scores.expression <- scale(t(expression))
	# 	
	# 	# scale divides by the standard deviation, if the sd is zero the result will be 0 / 0 = NaN
	# 	# in MATLAB the result is zero...
	# 	#z.scores.stratification[is.nan(z.scores.stratification)] <- 0
	# 	#z.scores.expression[is.nan(z.scores.expression)] <- 0
	# 	
	# 	#stratification.svd <- svd(t(z.scores.stratification), nu = nrow(t(z.scores.stratification)), nv = ncol(t(z.scores.stratification)))
	# 	#v <- as.matrix(stratification.svd$v[, 1])
	# 	
	# 	
	# 	
	# 	# add penalty to the diagonal elements in the v * v' matrix (rpinv)
	# 	x <- v %*% t(v)
	# 	diag(x) <- diag(x) + penalty
	# 	
	# 	signature <- t(z.scores.expression) %*% ginv(x) %*% v
	# 	
	# 	#column centering
	# 	signature <- signature - mean(signature)
	# 	
	# 	
	
	
	
	
	# extract the stratification variable
	stratification <- clinical
	
	
	# if univariate
	if (nrow(stratification) == 1 & run.cox == FALSE & is.null(marker.weights)) {
		
		if (test.null.hypothesis) {
			# shuffle and turn to matrix row
			stratification <- t(as.matrix(sample(stratification)))
			rownames(stratification) <- rownames(clinical)
		}
		
		# only keep genes that intersect with the L1000 dataset
		expression <- expression[which(rownames(expression) %in% L1000.genes), ]
		
		# order genes according to L1000
		# this is not done in MATLAB
		# expression <- expression[order(match(rownames(expression), L1000.genes)), ]
	
		# if binary
		if (all(stratification %in% 0:1)) { 
			# If the stratification variable contains binary data
			# Fit a linear discriminant analysis classifier and extract the means
			
			# This generates the same as in MATLAB
			#rda.model <- suppressWarnings(rda(formula = t(stratification) ~ t(expression), gamma = 1, lambda = 0.5))
			lda.model <- suppressWarnings(lda(formula = t(stratification) ~ t(expression)))
			
			# Calculate the within-class covariance matrix
			# TODO: everything is correct, except the covariance matrix
			cov.matrix <- withinCov(t(expression), as.factor(stratification))
			# TODO: the row labels thing might not be correct...
			row.labels <- rownames(cov.matrix)
			
			# development test
			# if (!test.null.hypothesis) {
			# 	cov.matrix <- as.matrix(read.table("C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\exported_from_Svens_code\\mycn_sigma.txt", header = TRUE))
			# 	lda.model$means <-  as.matrix(read.table("C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\exported_from_Svens_code\\mycn_mu.txt", header = TRUE))
			# 	expression <-  as.matrix(read.table("C:\\_Caroline\\Projects\\targetTranslator\\development\\Datasets\\exported_from_Svens_code\\mycn_rna.txt", header = TRUE))
			# } else {
			# 	cov.matrix <- as.matrix(read.table("C:\\_Caroline\\GoogleDrive\\Projects\\Elin\\1_Ongoing\\Datasets\\exported_datasets_from_Svens_code\\mycn_sigma_null.txt", header = TRUE))
			# }
		
			# this is correct
			# Calculate something to get the final vector where each gene is represented with one value...
			# Two models are created, one for each group. 
			# take the pseudoinverse of the variances * difference between the means of the two models
			signature <- as.matrix(diag(ginv(diag(diag(cov.matrix)), tol = 0) * (lda.model$means[1, ] - lda.model$means[2, ])))
			
			rownames(signature) <- row.labels
			
		} else { 
			# if continous
			signature <- cor(t(expression), t(stratification), method = "pearson")
		}
		
		
		# this is the sign fix
		# this is correct
		if (cor(t(cor(signature, expression)), t(stratification)) < 0) {
			signature <- -1 * signature
		}
		
		
		
	} else if (run.cox == FALSE) {
		
		if (test.null.hypothesis) {
			# shuffle within each row
			stratification <- t(apply(stratification, 1, sample))
			colnames(stratification) <- colnames(clinical)
		}
		
		if (!is.null(marker.weights)) {
			# Extract expression values for the genes that have weights
			stratification <- expression[which(rownames(expression) %in% rownames(marker.weights)), ]
			
			if (test.null.hypothesis) {
				# shuffle columns
				stratification <- stratification[, sample(colnames(stratification))]
			}
			
		}
		
		# only keep genes that intersect with the L1000 dataset
		expression <- expression[which(rownames(expression) %in% L1000.genes), ]
		
		# Just set the ridge parameter to 10, this should be validated
		penalty <- 10

		# center and scale data
		# scale in R is zscores in MATLAB
		z.scores.stratification <- scale(t(stratification))
		z.scores.expression <- scale(t(expression))
		
		# scale divides by the standard deviation, if the sd is zero the result will be 0 / 0 = NaN
		# in MATLAB the result is zero...
		z.scores.stratification[is.nan(z.scores.stratification)] <- 0
		z.scores.expression[is.nan(z.scores.expression)] <- 0

		
		if (!is.null(marker.weights)) {
			u <- marker.weights[rownames(stratification), ]
			
			# add penalty to the diagonal elements in the v * v' matrix (rpinv)
			x <- u %*% t(u)
			diag(x) <- diag(x) + penalty
			v <- t(ginv(x) %*% u) %*% t(z.scores.stratification)
			v <- t(v)
		} else {
			stratification.svd <- svd(t(z.scores.stratification), nu = nrow(t(z.scores.stratification)), nv = ncol(t(z.scores.stratification)))
			v <- as.matrix(stratification.svd$v[, 1])
			
			# correction of arbitrary sign
			if (mean(stratification.svd$u[, 1]) < 0) {
				v <- -1 * v
			}

		}
		
		# add penalty to the diagonal elements in the v * v' matrix (rpinv)
		x <- v %*% t(v)
		diag(x) <- diag(x) + penalty
		signature <- t(z.scores.expression) %*% ginv(x) %*% v
		
		#column centering
		signature <- signature - mean(signature)
		
		
	} else if (run.cox == TRUE) {
		
		if (test.null.hypothesis) {
			# shuffle within each row
			stratification <- t(apply(stratification, 1, sample))
			colnames(stratification) <- colnames(clinical)
		}
		
		# calculate cox proportional hazard regression (Integrated hazard)

		# The Cox proportional-hazards model (Cox, 1972) is essentially a regression model commonly used statistical 
		# in medical research for investigating the association between the survival time of patients and one or more 
		# predictor variables. -http://www.sthda.com/english/wiki/cox-proportional-hazards-model
		#
		# For example, suppose a study is conducted to measure the impact of a drug on mortality rate. In such a study, 
		# it may be known that an individual's age at death is at least 75 years (but may be more). Such a situation 
		# could occur if the individual withdrew from the study at age 75, or if the individual is currently alive at 
		# the age of 75.
		#
		# Left censoring 			- a data point is below a certain value but it is unknown by how much.
		# Interval censoring 	- a data point is somewhere on an interval between two values.
		# Right censoring 		- a data point is above a certain value but it is unknown by how much.
		#
		# This algorithm only supports right censoring - which is ok in this case

		# make sure that age survival and death data is available in the data, else error
		# make sure that number of variables are below 20, else error
		
		# extract rows for all variables except for survival and is.alive (this is not done in the new code...)
		if (dim(stratification)[1] == 3) {
			# only one additional variable - must force row vector with row name
			x <- t(stratification[setdiff(rownames(stratification), c("survival", "is.alive")), ])
			rownames(x) <- rownames(stratification)[1]
		} else {
			x <- stratification[setdiff(rownames(stratification), c("survival", "is.alive")), ]
		}
		
		# calculate the z-score for all covariate variables
		x <- t(scale(t(x)))

		# extract data for survival (time)
		
		# extract data for is.alive (censored variable)
		# censored is a binary vector indicating 1 for observations that are right censored and 0 for observations that are fully observed.
		# http://rdc.uwo.ca/events/docs/presentation_slides/2009-10/Jones-SurvivalR-2010.pdf

		# correct up to here, and why it is not equal to MATLAB's function
		# https://se.mathworks.com/matlabcentral/answers/96185-why-are-the-results-from-the-coxphfit-function-in-the-statistics-toolbox-ver-5-1-matlab-7-1-r14s
		# https://stackoverflow.com/questions/3471651/cox-regression-in-matlab
		# extract variable names 
		survival <- stratification["survival", ]
		is.alive <- !stratification["is.alive", ]
		
		survival.time <- 'Surv(survival, is.alive)'
		predictors <- paste(rownames(x), collapse = " + ")
		
		# create a formula object
		survival.formula <- as.formula(paste(survival.time, predictors, sep = " ~ "))
		
		# create cox model
		survival.model <- suppressWarnings(coxph(survival.formula, data = as.data.frame(t(x))))
		
		survival.coefficients <- as.matrix(survival.model$coefficients) 
		# the coefficients are not right, the use of cox is weird in MATLAB
		
		z.scores.stratification <- scale(t(x) %*% survival.coefficients) # correct
		z.scores.expression <- scale(t(expression)) # correct
		
		
		# add penalty to the diagonal elements in the v * v' matrix (rpinv)
		penalty <- 1
		a <- z.scores.stratification %*% t(z.scores.stratification)
		diag(a) <- diag(a) + penalty
		
		signature <- t(z.scores.expression) %*% ginv(a) %*% z.scores.stratification
		
		#column centering
		signature <- signature - mean(signature)
		
		
	}
	
	
	# send back for stratification process
	return(signature)
	
}
