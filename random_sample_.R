## random sample000facilities/_random_sample/finaldata_join_030222_to_sa
setwd("Z:/ArcGIS/Projects/36_EJ_Analysis_Opt3/ArcGIS/_output_files/1_perc_selection/4000facilities/_random_sample")
options(scipen=999)
library(dplyr)


#rjdbc
## Oracle connection code here
drvr = JDBC("oracle.jdbc.OracleDriver", classPath="C:/users/dyavrom/github/rcra-public-web/target/rcra-public-web/WEB-INF/lib/ojdbc8.jar") 
conn = dbConnect(drvr, "jdbc:oracle:thin:@//localhost:####/******",
                 user = "dyn",
                 password = "********")

## run sql script to pull permitted data
source("dtj_sql.r") ## sql not written by me. 

#load data
data = read.csv("finaldata_join_030222_to_sample.csv", stringsAsFactors = FALSE, header = TRUE)

#subset data and change col names
dtj = dtj[c(3, 8,10)]
colnames(dtj) <- c('Handler_ID','Is_OnCAProgressTrack_Flag','Is_Permitted_Flag')

#join data and relocate columns
data_join = left_join(data, dtj, by = "Handler_ID")
data_join = data_join %>% relocate(Is_OnCAProgressTrack_Flag, Is_Permitted_Flag, .after = Handler_Name)

#split data and select a random sample of 5% of the columns per Region
data_join_s = lapply(split(data_join, data_join$Region),
                function(x) x[sample(nrow(x), nrow(x) * 0.05),])

#rename data list entries
names(data_join_s) <- c("R01_sample", "R02_sample", "R03_sample","R04_sample", "R05_sample", "R06_sample", "R07_sample", "R08_sample", "R09_sample", "R10_sample")


##write csv based off of large data list names
lapply(1:length(data_join_s), function(i) write.csv(data_join_s[[i]], 
                                                file = paste0(names(data_join_s[i]), ".csv"),
                                                row.names = FALSE))



