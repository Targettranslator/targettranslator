#' createResultTable
#'
#' Generates a summary of the results in table format
#'
#' @param scores matrix of scores for each gene where column corresponds to two different drections of the correlations
#' @param fdr matrix of fdrs for each gene where column corresponds to two different drections of the correlations
#' @param table.length number of rows to show for each direction of the correlation
#' @return data.frame of rank, perturbation, score, fdr and direction of the correlation
#' @export
#' @examples
#' createResultTable(scores, fdr)

createResultTable <- function(scores, fdr, table.length = 10) {

	# preallocate memory for result
	result <- data.frame("rank"         = rep(as.numeric(NA), table.length), 
											 "perturbation" = rep(as.character(NA), table.length), 
											 "score"        = rep(as.numeric(NA), table.length),
											 "fdr"          = rep(as.numeric(NA), table.length),
											 "direction"    = rep(as.character(NA), table.length),
											 stringsAsFactors = FALSE) 
	
	# start with row one
	row.num <- 1

	for (signflip in 2:1) { # for each signflip, positive correlations before negative
		
		for (signature in 1:1) { # for each signature
		
			# rank all perturbations according to their score
			score.rank <- rank(-scores[, signflip], na.last = "keep", ties.method = "average")
			
			# sort by ranking, placing the top ranking perturbations at the top
			score.rank <- sort(score.rank)
		
			for (ranking in 1:table.length) { # for each result row
				
				# extract perturbations name
				pert.name <- names(score.rank[ranking])
				
				# set values
				result[row.num, "rank"] <- ranking
				result[row.num, "perturbation"] <- pert.name
				result[row.num, "score"] <- scores[pert.name, signflip]
				result[row.num, "fdr"] <- fdr[pert.name, signflip]
				result[row.num, "direction"] <- if (signflip == 1) {"negative"} else {"positive"}
	
				# move on to next row
				row.num <- row.num + 1
			}
		}
	}
	

	# return summary data.frame
	return(result)
	
}
