#setwd("~/R/coursera-data-science-getdata-course-project/rawdata")
#library("microbenchmark")
library("data.table")
a.labels <- fread("activity_labels.txt")
v.names <- fread("features.txt")[grepl("-(mean|std)\\(\\)", V2, perl = T)]
v.names[, V2:=gsub("()", "", V2, fixed = T)][, V2:=gsub("-", ".", V2, fixed = T)]
s <- rbind(fread("test/subject_test.txt"), fread("train/subject_train.txt"))
setnames(s, names(s), c("Subject"))
y <- rbind(fread("test/y_test.txt"), fread("train/y_train.txt"))
y <- as.data.table(factor(y$V1, a.labels$V1, a.labels$V2, ordered = T))
setnames(y, names(y), c("Activity"))
system("sed 's/  / /g' test/X_test.txt >test/X_test.txt.1")
system("sed 's/  / /g' train/X_train.txt >train/X_train.txt.1")
x <- rbind(
  fread("test/X_test.txt.1", sep = " ", select = (v.names$V1 + 1), colClasses = "numeric"),
  fread("train/X_train.txt.1", sep = " ", select = (v.names$V1 + 1), colClasses = "numeric")
)
setnames(x, names(x), v.names$V2)
data <- cbind(y, s, x)
setkey(data, Activity, Subject)  
tidydata <- data[, lapply(.SD, mean), by = .(Activity, Subject)]
write.table(tidydata, file = "tidydata.txt", row.names = F)