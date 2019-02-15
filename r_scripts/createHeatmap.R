
tryCatch({
	#stop("funkar")

	require(jsonlite)
	require(base64enc)
	require(data.table)
	require(ggplot2)
	#require(reshape2)
	require(dplyr)
	#require(scales)
	
	# --------------------------------------------------------------------------------------------- Load packages ---
	# ---------------------------------------------------------------------------------------------------------------

	# for testing only
	#setwd("C:\\xampp\\htdocs\\targetTranslator\\r_scripts\\")
	#path.selections <- "C:/xampp/htdocs/targettranslator/data/job_12345/stratifications_5baa1933bb0dc.tsv"
	#paths.clinical  <- eval(parse(text = "c('C:/xampp/htdocs/targettranslator/data/job_12345/clinical_5baa1933bb0dc.tsv')"))
	#paths.clinical  <- eval(parse(text = "c('C:/xampp/htdocs/targettranslator/data/target_clinical.tsv')"))
	#paths.clinical  <- eval(parse(text = "c('C:/xampp/htdocs/targettranslator/data/r2_clinical.tsv', 'C:/xampp/htdocs/targettranslator/data/target_clinical.tsv')"))
	
	#path.selections <- "C:/xampp/htdocs/targettranslator/data/job_5c4051144734c/stratifications_5c40511447644.tsv"
	#paths.clinical  <- eval(parse(text = "c('C:/xampp/htdocs/targettranslator/data/job_5c4051144734c/clinical_5c40511447644.tsv')"))
	
	# Elins stuff
	#setwd("C:\\xampp\\htdocs\\targetTranslator\\r_scripts\\")
	#path.selections <- "C:/Users/carwa895/Desktop/selections.txt"
	#paths.clinical  <- eval(parse(text = "c('C:/Users/carwa895/Desktop/Clinical2.txt')"))
	
	# for testing stop

	# get parameters
	args <- commandArgs(TRUE)
	path.selections    <- args[1]
	paths.clinical     <- eval(parse(text = args[2]))
	job.id             <- args[3]
	
	# extract number of datasets
	num.datasets <- length(paths.clinical)

	# parse selection file and extract first column -> turn into vector
	selections <- fread(input = path.selections, na.strings = c("", "NaN", "NA", "NULL" ), showProgress = FALSE, header = FALSE, sep = "\t")
	selections <- selections[[1]]

	# filter datasets on selections
	clinical <- list()
	clinical.normalized <- list()
	clinical.mat <- list()
	clinical.reordered <- list()
	#clinical.selected <- data.frame()
	clinical.data <- data.frame()
	clinical.scaled <- data.frame()
	patient.names <- list()

	for (i in 1:num.datasets) {

		# load file
		clinical[[i]] <- as.data.frame(fread(input = paths.clinical[[i]], na.strings = c("", "NaN", "NA", "NULL" ), showProgress = FALSE, header = TRUE, sep = "\t"))

		# store which patients are included in which dataset
		patient.names[[i]] <- clinical[[i]][, 1]
		
	}

	
	# keep only columns that are present in both datasets
	common.col.names <- Reduce(intersect, lapply(clinical, colnames))
	clinical.filtered <- lapply(clinical, function(x) x[common.col.names])


	for (i in 1:num.datasets) {
		
		# apply a unit normalization to every column in the data frame 
		clinical.normalized[[i]] <- as.data.frame(apply(clinical.filtered[[i]][, -1], 2, function(x) {
			# normalize each column in dataframe to be between 0 and 1, unity based noramlization or min-max normalization
			# if denominator is zero, set values to 0.0 if all values are 0 or less, 1.0 otherwise.
			if (max(x, na.rm = TRUE) == min(x, na.rm = TRUE)) {
				
				if (max(x, na.rm = TRUE) <= 0) {
					rep(0, length(x))
				} else {
					rep(1, length(x))
				}
				
			} else {
				(x - min(x, na.rm = TRUE)) / (max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
			}
		} 
		)) 
		
		# add patient names to the dataframe again
		clinical.normalized[[i]] <- cbind(clinical.filtered[[i]][, 1], clinical.normalized[[i]])
		
		# rename row column
		colnames(clinical.normalized[[i]])[1] <- "patient"
		
		# extract numerical values and set row names instead
		clinical.mat[[i]] <- clinical.normalized[[i]][, -1]
		rownames(clinical.mat[[i]]) <- clinical.normalized[[i]][, 1]
		
		
		# cluster by row and column
		row.order <- hclust(dist(clinical.mat[[i]]))$order
		col.order <- hclust(dist(t(clinical.mat[[i]])))$order
		
		# re-order matrix according to clustering
		clinical.reordered[[i]] <- clinical.mat[[i]][row.order, col.order]
		
		# reformat matrix to dataframe
		clinical.reordered[[i]] <- as.data.frame(clinical.reordered[[i]])
		clinical.reordered[[i]] <- cbind("patient" = rownames(clinical.reordered[[i]]), clinical.reordered[[i]])
		rownames(clinical.reordered[[i]]) <- c()
		
		# add column with dataset number
		clinical.reordered[[i]]$category <- paste("dataset", i, sep = "")
		
	}


	
	# merge all dataframes in list into one dataframe
	clinical.data <- bind_rows(clinical.reordered)
	
	# reformat patient ID column to factors again
	clinical.data$patient <- as.factor(clinical.data$patient)
	
	# melt dataset into long format
	clinical.complete <- melt(clinical.data, id.vars = c("patient", "category"))
	
	# turn factors into characters and limit the number of characters in the variable names and add dots at the end
	# this is not good, if the variables names are long and the uique part is at the end, it will be impossible to differentiate between them
	#clinical.complete$variable <- as.character(clinical.complete$variable)
	#for (i in 1:length(clinical.complete$variable)) {
	# 	variable.name <- clinical.complete$variable[i]
	# 	if (nchar(variable.name) > 20) {
	# 		variable.name <- strtrim(variable.name, 20)
	# 		clinical.complete$variable[i] <- paste(variable.name, "...", sep = "")
	# 	}
	#}
	# turn variable names back to factor again
	#clinical.complete$variable <- factor(clinical.complete$variable)
	
	# turn patient into factors
	clinical.complete$patient <- factor(clinical.complete$patient)
	
	# mark selected stratifications
	clinical.complete$selected <- clinical.complete$variable %in% selections

	
	# create breaks for the asthetics, patients are the one that should be grouped
	# TODO: should I use this?
	#clinical.complete <- ddply(clinical.complete, .(patient), transform, rescale = scale(value))

	# create a list of which patients belong to the different datasets 
	# TODO: what happens if patients are called the same in more than one dataset? what happens to levels?
	# TODO:fulhax!!
	# clinical.complete$category <- clinical.complete$patient
	levels(clinical.complete$category) <- unstack(clinical.complete[, 1:2])
	# if (num.datasets == 1) {
	# 	levels(clinical.complete$category) <- list("dataset 1" = patient.names[[1]])
	# } else if (num.datasets == 2) {
	# 	levels(clinical.complete$category) <- list("dataset 1" = patient.names[[1]], "dataset 2" = patient.names[[2]])
	# }
	
	# reorder levels
	clinical.complete$patient <- factor(clinical.complete$patient, levels = unique(as.character(clinical.complete$patient)))
	clinical.complete$variable <- factor(clinical.complete$variable, levels = unique(as.character(clinical.complete$variable)))
	
	lapply(clinical.complete, levels)


	
	# names(patient.names) <- as.character(1:num.datasets)
	# 
	# 
	# levels(clinical.complete$category) <- patient.names
	# levels(clinical.complete$category) <- list("r2" = patient.names[[1]], "target" = patient.names[[2]])
	# 
	# levels(clinical.complete$category) <- list(names(patient.names)[1] = patient.names[[1]])
	# 
	# since rescale is within a few (3 or 4) of 0, the different categories can be offset by a hundred to keep them separate
	# TODO: Warning says that NAs are introcuced by coercion
	# clinical.complete$rescaleoffset <- clinical.complete$rescale + 100 * (as.numeric(clinical.complete$category) - 1)
	
	# determine where the endpoints of each color gradient should be, in terms of both rescaled values and colors
	# TODO: this can take a maximum number of datasets of 3!!
	# TODO: what does each mean? is it one less than the number of datasets?
	# scalerange <- range(clinical.complete$rescale)
	# gradientends.array <- c(0, 100, 200)
	# gradientends <- scalerange + rep(gradientends.array[1:num.datasets], each = 2)
	# 
	# num.colors <- num.datasets * 2
	# colors.array <- c("white", "red", "white", "green", "white", "blue")
	# colorends <- colors.array[1:num.colors]
	
	
	
	# normalize the rescale to between 0 and 1, unity based noramlization or min-max normalization
	#clinical.complete$rescale = (clinical.complete$rescale - min(clinical.complete$rescale, na.rm = TRUE)) / (max(clinical.complete$rescale, na.rm = TRUE) - min(clinical.complete$rescale, na.rm = TRUE))
	#clinical.complete$rescale = (clinical.complete$value - min(clinical.complete$value, na.rm = TRUE)) / (max(clinical.complete$value, na.rm = TRUE) - min(clinical.complete$value, na.rm = TRUE))
	
	# TODO: scaling, scale columns independently of other columns
	# TODO: negative values are not represented, what happens to them?


	#plot heatmap
	# heatmap = ggplot(data = clinical.complete, mapping = aes(x = patient, y = variable, fill = value)) +
	# 	#heatmap = ggplot(data = clinical.complete, mapping = aes(x = patient, y = variable, fill = value)) +
	# 	geom_tile() + # geom_raster is a high performance special case for genom_tile when all the tiles are the same size
	# 	scale_x_discrete(expand = c(0, 0)) + # remove the padding
	# 	scale_y_discrete(expand = c(0, 0)) + # remove the padding
	# 	xlab(label = "Patients") +
	# 	#facet_grid(~ category, switch = "x", scales = "free_x", space = "free_x") + # divide heatmap based on datasets and only display patients that have values
	# 	scale_fill_gradientn(colours = c("#f8e5e5", "#dc6468"), na.value = "snow1", breaks = c(min(clinical.complete$value), max(clinical.complete$value)), labels = c("Low", "High")) +
	# 	theme_bw() + # Use the black and white theme
	# 	theme(strip.placement = "outside", # place dataset number below the x axis label
	# 				plot.title = element_text(hjust = 0.5), # center title of plot
	# 				axis.title.y = element_blank(), # remove y-axis title
	# 				axis.ticks.y = element_blank(), # remove y tickmarks
	# 				axis.text.x = element_blank(),  # remove labels for x tickmarks
	# 				axis.ticks.x = element_blank(), # remove x tickmarks
	# 				text = element_text(size = 20),
	# 				legend.title = element_blank()
	# 				) +
	# 	geom_tile(mapping = aes(x = patient, y = variable, fill = ifelse(selected, 0, 0.6)), alpha = 0.5) + # add overlay to highlight selected variables
	# 	#scale_color_gradientn(colours = c("#000000", "#000000")) + # create a n colour gradient
	# 	#geom_tile(fill = "#000000", alpha = ifelse(clinical.complete$selected, 0, 0.6)) + # add overlay to highlight selected variables
	# 	facet_grid(. ~ category, switch = "x", scales = "free_x", space = "free_x") # divide heatmap based on datasets and only display patients that have values
	# 
	# 
	# # must print to be able to save file
	# png(filename = paste("..\\data\\job_", job.id, "\\filter_heatmap.png", sep = ""), width = 800, height = 400, units = "px")
	# print(heatmap)
	# dev.off()

	heatmap = ggplot(data = clinical.complete, mapping = aes(x = patient, y = variable )) +
		geom_tile(mapping = aes(alpha = value, fill = category)) +            # specify value for each tile. geom_raster is a high performance special case for genom_tile when all the tiles are the same size
		scale_x_discrete(expand = c(0, 0)) +                        # remove the padding
		scale_y_discrete(expand = c(0, 0)) +                        # remove the padding

		#scale_fill_gradientn(colours = colorends, values = rescale(gradientends)) +
		#scale_fill_gradient(low = "white", high = "steelblue", na.value = "snow1") +    # create a two colour gradient
		#scale_fill_manual(values = c("#544DA2", "#544DA2")) +
		ylab("") +
		xlab("Patients") +
		labs(fill = "") +
		theme_bw() +
		theme(
			legend.position = "none",
			strip.placement = "outside", # place dataset number below the x axis label
			#plot.title = element_text(hjust = 0.5) # center title of plot
			axis.title.y = element_blank(), # remove y-axis title
			axis.ticks.y = element_blank(), # remove y tickmarks
			axis.text.x = element_blank(),  # remove labels for x tickmarks
			axis.ticks.x = element_blank(), # remove x tickmarks
			text = element_text(size = 20),
			#legend.title = element_blank()

			# legend.title = element_text(size = 10),               # title for gradient key
			# 		legend.text = element_text(size = 10),                # numbers on gradient key
			# 		axis.title = element_text(size = 10),                 # titles for x and y axis
			panel.grid.major = element_blank(),                   # remove verticle lines for ticks in background
			panel.background = element_blank()                    # remove grey background
		) +
		geom_tile(mapping = aes(x = patient, y = variable, alpha = ifelse(selected, 0, 0.7))) + # add overlay to highlight selected variables
		#geom_tile(mapping = aes(x = patient, y = variable, alpha = ifelse(is.na(value), 1, 0))) +   # add overlay to mask NA values
	  facet_grid(. ~ category, switch = "x", scales = "free_x", space = "free_x")

	# must print to be able to save file
	png(filename = paste("../data/job_", job.id, "/filter_heatmap.png", sep = ""), width = 800, height = 400, units = "px")
	print(heatmap)
	dev.off()
	
	# 
	# # plot heatmap
	# svg(filename = paste("..\\data\\filter_heatmap_", unique.id, ".svg", sep = ""))
	# 
	# # TODO: scaling, scale columns independently of other columns
	# # TODO: negative values are not represented, what happens to them?
	# 
	# heatmap = ggplot(data = clinical.complete, mapping = aes(x = patient, y = variable )) +
	# 	geom_tile(mapping = aes(alpha = value, fill = category)) +            # specify value for each tile. geom_raster is a high performance special case for genom_tile when all the tiles are the same size
	# 	scale_x_discrete(expand = c(0, 0)) +                        # remove the padding
	# 	scale_y_discrete(expand = c(0, 0)) +                        # remove the padding
	# 
	# 	#scale_fill_gradientn(colours = colorends, values = rescale(gradientends)) +
	# 	#scale_fill_gradient(low = "white", high = "steelblue", na.value = "snow1") +    # create a two colour gradient
	# 	ylab("") +
	# 	xlab("Patients") +
	# 	labs(fill = "") +
	# 	theme_light() +
	# 	theme(legend.title = element_text(size = 10),               # title for gradient key
	# 				legend.text = element_text(size = 10),                # numbers on gradient key
	# 				axis.title = element_text(size = 10),                 # titles for x and y axis
	# 				axis.text.x = element_blank(),                        # remove labels for x tickmarks
	# 				axis.ticks.x = element_blank(),                       # remove x tickmarks
	# 				panel.grid.major = element_blank(),                   # remove verticle lines for ticks in background
	# 				panel.background = element_blank()                    # remove grey background
	# 				) +
	# 	geom_tile(mapping = aes(x = patient, y = variable, alpha = ifelse(selected, 0, 0.7))) + # add overlay to highlight selected variables
	# 	geom_tile(mapping = aes(x = patient, y = variable, alpha = ifelse(is.na(value), 1, 0)))   # add overlay to mask NA values

	# 
	# # must print to be able to save file
	# print(heatmap)
	# 
	# dev.off()

	# convert images to base64 and print to console
	image.filter.heatmap <- base64encode(paste("../data/job_", job.id, "/filter_heatmap.png", sep = ""))

	# print image to console
	print(image.filter.heatmap)
	
	# print information about missing values
	print("You have this many missing values in your selected dataset.")

}, error = function(e) {
	errors <- c("error", conditionMessage(e))
	print(toJSON(errors))
})





