estimateScores <- function(signatures, L1000) {
	# Ensures that input data is structured correctly.
	#
	# Args:
	#   path.expression: path to tab-separated data file with expression values.
	#   path.clinical: path to tab-separated data file with clinical values.
	#   path.stratifications: path to tab-separated data file with stratifications.
	#   path.settings: path to tab-separated data file with settings.
	#
	# Returns:
	#   Data matrix with stratifications
	
	useImputed <- TRUE
	
	# preallocate memory
	scores <- matrix(NA, nrow = length(L1000$perturbations), ncol = 2)
	row.names(scores) <- L1000$perturbations
	
	# store correlations in a list of matrices. One matrix for each cohort, and one column in one matrix for each cell line
	correlations <- lapply(1:length(signatures), matrix, data = NA, nrow = length(L1000$perturbations), ncol = length(L1000$cell.lines))
	probabilities <- lapply(1:length(signatures), matrix, data = NA, nrow = length(L1000$perturbations), ncol = length(L1000$cell.lines))
	
	# reorder the signature genes so that the order matches the L1000 dataset
	# set missing values to 0
	for (i in 1:length(signatures)) {
		
		signatures[[i]] <- merge(x = L1000$genes, y = signatures[[i]], by.x = 1, by.y = 0, all = TRUE, sort = FALSE)
		signatures[[i]] <- signatures[[i]][match(L1000$genes, signatures[[i]][, 1]), ]
		signatures[[i]] <- as.numeric(signatures[[i]][, 2])
		signatures[[i]][is.na(signatures[[i]])] <- 0
		
	}
	

	for (signflip in c(1, 2)) { # consider both positive and negative matches
	
		for (cell.line in 1:length(L1000$cell.lines)) { # for each cell line
			# additional for loop needed if multiple cohorts are used
			
			for (cohort in 1:length(signatures)) {
				
				direction <- sign(signflip - 1.5) # direction is either -1 or +1
			
				if (useImputed) {
					# compute correlations between signature and L1000
					# correlate all L1000 profiles in cell line i with all signatures from cohort j
					correlations[[cohort]][, cell.line] <- cor(L1000$expressions.imputed[[cell.line]], direction * signatures[[cohort]])
				} else {
					correlations[[cohort]][, cell.line] <- cor(L1000$expressions[[cell.line]], direction * signatures[[cohort]])
				}
				
			}
			
		}
		
		# transform the correlations to a 0 to 1 pseudo-probability using logistic function,
		# with parameters fitted by permutations as above
		# calculate the probability of something
		for (cohort in 1:length(correlations)) {
			probabilities[[cohort]] <- 1 - 1 / (1 + exp(L1000$coefficients[1] + L1000$coefficients[2] * correlations[[cohort]]))
		}

		# calculate score
		
		# average perturbations across the cell lines (rows),
		# weigh by perturbation specific reproducibility score.
		
		# combine cohort probabilities by multiplying them together giving one matrix with cell lines as columns
		combined.probabilities <- Reduce("*", probabilities)
		
		
		scores[, signflip] <- rowMeans(combined.probabilities) * L1000$probabilities 
		
	}

	# send back for stratification process
	return(scores)
	
}
