



list.of.packages <- c("jsonlite", 
											"base64enc",
											"tictoc",
											"data.table",
											"MASS",
											"ggplot2",
											"dplyr",
											"DiscriMiner",
											"survival",
											"mice")



new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]

print(new.packages)

if (length(new.packages)) {
	install.packages(new.packages, repos = "http://cran.us.r-project.org")
}





