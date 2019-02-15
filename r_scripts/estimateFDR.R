estimateFDR <- function(scores, scores.null) {
	# Calculates expression signatures
	#
	# Args:
	#   clinical: 
	#   expression: 
	#
	# Returns:
	#   signature:
	#
	
	#scores <- t(read.table("C:\\_Caroline\\GoogleDrive\\Projects\\Elin\\1_Ongoing\\Datasets\\exported_datasets_from_Svens_code\\scores.txt", header = TRUE))
	#scores.null <- t(read.table("C:\\_Caroline\\GoogleDrive\\Projects\\Elin\\1_Ongoing\\Datasets\\exported_datasets_from_Svens_code\\scores_null.txt", header = TRUE))
	
	fdr <- matrix(NA, nrow = dim(scores)[1], dim(scores)[2]) # one col for each signflip
	row.names(fdr) <- row.names(scores)
	
	iterations <- 10
	
	#for (i in 1:iterations) { # perform 10 iterations
	# These iterations do not make sense. The FDR-value that is reported in the end does not depend on these
	# iterations. However, the FDR-values are in the end divided by the number of iterations. Can this really 
	# be correct?
		
		for (signflip in 1:2) { # for each signflip
			#s <- scores[cohort, , signflip]
			#s.null <- scores.null[cohort, , signflip]
			
			s <- scores[ , signflip]
			s.null <- scores.null[ , signflip]
			
			for (perturbation in 1:length(s)) {
				
				# count the number of perturbations where the random score is higher than the real score
				# fdr[cohort, perturbation, signflip] <- sum(s.null > s[perturbation])
				fdr[perturbation, signflip] <- sum(s.null > s[perturbation])
				
			}
			
		}
		
	#}
	
	fdr <- fdr / dim(scores)[1]
	fdr <- fdr / iterations
	
	# send back for stratification process
	return(fdr)
	
}
