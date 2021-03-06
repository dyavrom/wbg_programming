## random sample000facilities/_random_sample/finaldata_join_030222_to_sa
setwd("Z:/userpath/_random_sample")
options(scipen=999)
options(java.parameters = "-Xmx8048m")
library(dplyr)
library(RJDBC)

#rjdbc
## Oracle connection code here
drvr = JDBC("oracle.jdbc.OracleDriver", classPath="C:/userpath/ojdbc8.jar") 
conn = dbConnect(drvr, "jdbc:oracle:thin:@//localhost:####/******",
                 user = "dyn",
                 password = "********")

## once connected to Oracle DB, run sql script to pull data to join (dtj)
source("dtj_sql.r") 

#load data
data = read.csv("data_to_sample.csv", stringsAsFactors = FALSE, header = TRUE)

#subset data and change col names
dtj = dtj[c(3, 8,10)]
colnames(dtj) <- c('Handler_ID','Is_OnCAProgressTrack_Flag','Is_Permitted_Flag')

#join data and relocate columns
data_join = left_join(data, dtj, by = "Handler_ID")
data_join = data_join %>% relocate(Is_OnCAProgressTrack_Flag, Is_Permitted_Flag, .after = Handler_Name)

#split data by region and select a random sample of 5% of the columns
data_join_s = lapply(split(data_join, data_join$Region),
                function(x) x[sample(nrow(x), nrow(x) * 0.05),])

#rename data list entries
names(data_join_s) <- c("R01_sample", "R02_sample", "R03_sample","R04_sample", "R05_sample", "R06_sample", "R07_sample", "R08_sample", "R09_sample", "R10_sample")

##write csv based off of large data list names
lapply(1:length(data_join_s), function(i) write.csv(data_join_s[[i]], 
                                                file = paste0(names(data_join_s[i]), ".csv"),
                                                row.names = FALSE))



