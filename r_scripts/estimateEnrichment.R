#' estimateEnrichment
#'
#' Estimates target enrichment among the scores
#'
#' @param scores matrix of scores for each gene where column corresponds to two different drections of the correlations
#' @param priors matrix of fdrs for each gene where column corresponds to two different drections of the correlations
#' @param priors.cutoff number of rows to show for each direction of the correlation
#' @param job.id name of the output folder
#' @return data.frame with top targets, D-values, p-values, directions of correlation and plots of ecdfs
#' @export
#' @examples
#' estimateEnrichment(scores, priors)

estimateEnrichment <- function(scores, priors, priors.cutoff = 900, job.id = "1", num.results = 10) {
	
	# add row names for priors data (do this in the Rdata, not here)
	# only keep columns that has column names. The data for all of these columns are 0 anyway. TODO: check if this is true, the number in s2 will be smaller...
	row.names(priors$data) <- priors$rows
	colnames(priors$data) <- priors$cols
	#? priors <- priors$data[, -which(is.na(colnames(priors$data)))]
	priors <- priors$data

	# preallocate memory for the resulting lists
	result <- vector(mode = "list", length = 2)
	top.targets <- vector(mode = "list", length = 2)

	# precalculate the number of targets included in the following calculations
	num.rows <- dim(priors)[1]
	
	tic("perform ks test     ")
	for (signflip in 1:2) { # for each sign

		# preallocate memory for each list item 
		result[[signflip]] <- data.frame(target       = character(num.rows),
			                               dvalue       = numeric(num.rows), 
			                               pvalue       = numeric(num.rows), 
			                               direction    = character(num.rows), 
			                               distribution = character(num.rows),
			                               stringsAsFactors = FALSE)
		row.names(result[[signflip]]) <- row.names(priors)

		for (gene in row.names(priors)) { # for each gene (row)
			
			# for each gene, find all drugs that have a prior value greater than or less/equal than the cutoff respectively
			# find indices for gene i, where the prior value is greater than or less/equal than the cutoff respectively
			# i.e. put all drugs that has a high value for gene i in one group, and all drugs that have a low value for gene i into another group
		  drugs.high <- which(priors[gene, ] >  priors.cutoff)
			drugs.low  <- which(priors[gene, ] <= priors.cutoff)

			# the second group will always contain many values.
			# the first group however might not contain many values.
			# since the ks.test is not good for very small sample sizes, a samples size of at least 3 must exist
			if (length(drugs.high) > 3) {
				
				# extract scores for drugs above threshold
				s1 <- scores[drugs.high, signflip]

				# extract all other scores
				s2 <- scores[drugs.low, signflip]

				# use a two-sample Kolmogorov-Smirnov test to compare the targettranslator scores for perturbation i vs all other perturbations
				# compare the distrbutions for the perturbations that are higher vs. lower than cutoff
				hypothesis.result <- suppressWarnings(ks.test(s1, s2, alternative = "less"))
				
				# save result
				result[[signflip]][gene, "target"] <- gene
				result[[signflip]][gene, "dvalue"] <- hypothesis.result$statistic
				result[[signflip]][gene, "pvalue"] <- hypothesis.result$p.value
				result[[signflip]][gene, "direction"] <- if (signflip == 1) {"negative"} else {"positive"}

			} else {
				
				result[[signflip]][gene, "target"] <- gene
				result[[signflip]][gene, "dvalue"] <- 1 # TODO: is this resonable?
				result[[signflip]][gene, "pvalue"] <- 1
				result[[signflip]][gene, "direction"] <- if (signflip == 1) {"negative"} else {"positive"}
				
			}

		}
		
	}
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()


	# TODO: this could be added to the loop above
	for (signflip in 1:2) {
		# sort according to p-values (increasing) and D-values (decreasing)
		result[[signflip]] <- result[[signflip]][with(result[[signflip]], order(pvalue, -dvalue)), ]
		
		# select top 10 targets
		top.targets[[signflip]] <- row.names(result[[signflip]])[1:10]
	}


	tic("plot distributions  ")
	# the complete loop below takes 18.64 sec to execute
	# for each sign
	for (signflip in 1:2) {
		
		# for each gene (row)
		for (gene in top.targets[[signflip]]) {
			
			#for (perturbation.j in 1:dim(scores)[1]) {
			
			# for each gene, find all drugs that have a prior value greater than or less/equal than the cutoff respectively
			# find indices for gene i, where the prior value is greater than or less/equal than the cutoff respectively
			# i.e. put all drugs that has a high value for gene i in one group, and all drugs that have a low value for gene i into another group
			# the two lines below take 0 - 0.02 sec to execute
			
			# do it with indecies instead of colnames
			drugs.high <- which(priors[gene, ] >  priors.cutoff)
			drugs.low  <- which(priors[gene, ] <= priors.cutoff)
			
			# the second group will always contain many value. Is this really true?
			# the first group however might not contain many values.
			# since the ks.test is not good for very small sample sizes, a samples size of at least 3 must exist

			# extract scores for drugs above threshold
			s1 <- scores[drugs.high, signflip]
			
			# extract all other scores
			s2 <- scores[drugs.low, signflip]
			
			# plot dsitribution and save it
			tic("plot distributions  ")
			path.plot <- plotEnrichment(s1, s2, job.id, gene)
			toc(log = TRUE, quiet = TRUE)
			lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
			tic.clearlog()

			result[[signflip]][gene, "distribution"] <- base64encode(path.plot)

		}
		
	}
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()

	# return only the first results
	top.result <- rbind(result[[2]][1:10, ], result[[1]][1:10, ])

	return(top.result)
	
}
