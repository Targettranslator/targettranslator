plotEnrichment <- function(s1, s2, job.id, feature.index) {

	require("ggplot2")

	# create dataframe with the two samples in one column and group belonging in the other
	group <- c(rep("sample1", length(s1)), rep("sample2", length(s2)))
	all.data <- data.frame(samples = c(s1, s2), group = group)
	
	# create ECDF of data
	# this is not needed when using the plotting function stat_ecdf
	# tic("calculate ecdfs     ")
	# cdf1 <- ecdf(s1) 
	# cdf2 <- ecdf(s2) 
	# toc(log = TRUE, quiet = TRUE)
	# lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	# tic.clearlog()
	
	# find min and max statistics to draw line between points of greatest distance
	# there is some weirdness going on here so exclude for now
	# tic("find min and max    ")
	# minMax <- seq(min(s1, s2), max(s1, s2), length.out = length(s1)) 
	# x0 <- minMax[which( abs(cdf1(minMax) - cdf2(minMax)) == max(abs(cdf1(minMax) - cdf2(minMax))) )] 
	# y0 <- cdf1(x0) 
	# y1 <- cdf2(x0) 
	# toc(log = TRUE, quiet = TRUE)
	# lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	# tic.clearlog()
	
	# density(all.data$sample[all.data$group == "sample1"])
	# density(all.data$sample[all.data$group == "sample1"])
	# which.max(density(all.data$sample[all.data$group == "sample1"])$y)
	
	# max.val <- max(c(max(density(all.data$sample[all.data$group == "sample1"])$y), max(density(all.data$sample[all.data$group == "sample2"])$y)))
	# rug1.pos <- max.val / 10 * -1
	# rug2.pos <- max.val / 10 * 2 * -1
	# 
	# all.data$rug.pos <- NA
	# all.data$rug.pos[all.data$group == "sample1"] <- rug1.pos
	# all.data$rug.pos[all.data$group == "sample2"] <- rug2.pos

	# tic("plot density        ")
	# 
	# density.plot <- ggplot(all.data, aes(x = samples, colour = group, fill = group)) + 
	# 	geom_density(alpha = 0.1) + 
	# 	theme_minimal(base_size = 16) +
	# 	theme(panel.grid.major = element_blank(), 
	# 				panel.grid.minor = element_blank(),
	# 				plot.title = element_text(hjust = 0.5),
	# 				#axis.title.x = element_blank(),
	# 				#axis.text.x = element_blank(),
	# 				axis.ticks.x = element_blank(),
	# 				#legend.title = element_blank(),
	# 				#legend.position = "top",
	# 				legend.position = "none",
	# 				plot.background = element_rect(fill = "#f9f9fd", colour = "#f9f9fd"),
	# 				panel.background = element_rect(color = "grey", size = 1)) +
	# 	#scale_x_continuous(expand = c(0, 0)) + 
	# 	#scale_y_continuous(expand = c(0, 0)) +
	# 	#ggtitle("Density Plot") +
	# 	xlab("Score") +
	# 	ylab("Density") +
	# 	scale_color_manual(values = c("#a6cee3", "#1f78b4")) +
	# 	scale_fill_manual(values = c("#a6cee3", "#1f78b4")) + 
	# 	geom_point(data = all.data, aes(x = samples, y = rug.pos, colour = group), alpha = 0.5, size = 1, stroke = 0)
	# 
	# toc(log = TRUE, quiet = TRUE)
	# lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	# tic.clearlog()
	
	tic("plot ecdf           ")
	ecdf.plot <- ggplot(all.data, aes(x = samples, group = group, color = group)) +
		stat_ecdf(size = 1) +
		theme_minimal(base_size = 16) +
		theme(panel.grid.major = element_blank(), 
				  panel.grid.minor = element_blank(),
				  plot.title = element_text(hjust = 0.5),
				  #legend.position = "none",
				  axis.ticks.x = element_blank(),
					legend.position = "none",
					plot.background = element_rect(fill = "#f4f3fa", colour = "#f4f3fa"),
					panel.background = element_rect(color = "grey", size = 1)) +
		scale_x_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) + 
		scale_y_continuous(expand = c(0, 0), breaks = c(0, 1)) +
		xlab("Score") +
		ylab("ECDF") +
	 	#ggtitle("ECDF") +
	 	# geom_segment(aes(x = x0[1], y = y0[1], xend = x0[1], yend = y1[1]), linetype = "dashed", color = "black", size = 1) +
	 	# geom_point(aes(x = x0[1] , y = y0[1]), color = "black", size = 8, shape = "-") +
	 	# geom_point(aes(x = x0[1] , y = y1[1]), color = "black", size = 8, shape = "-") +
	 	scale_color_manual(values = c("#a6cee3", "#1f78b4")) #+ 
		#scale_fill_manual(values = c("#a6cee3", "#1f78b4")) #+ 
		#geom_point(data = all.data, aes(x = samples, y = rug.pos, colour = group), alpha = 0.5, size = 1, stroke = 0)
	
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()
	
	# tic("combine plots       ")
	# combined.plots <- plot_grid(density.plot, ecdf.plot, nrow = 2, align = "v")
	# toc(log = TRUE, quiet = TRUE)
	# lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	# tic.clearlog()
	
	tic("save plots          ")
	png(paste("../data/job_", job.id, "/enrichment_", feature.index, ".png", sep = ""), width = 200, height = 200, units = "px", type = "cairo")
	print(ecdf.plot)
	dev.off()
	
	toc(log = TRUE, quiet = TRUE)
	lapply(tic.log(format = TRUE), write, "timelog.txt", append = TRUE)
	tic.clearlog()
	
	return(paste("../data/job_", job.id, "/enrichment_", feature.index, ".png", sep = ""))
	
}
