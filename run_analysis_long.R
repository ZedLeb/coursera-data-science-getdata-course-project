# The course does not teach us data.table, but I prefer to use it at all times
# for its lightning speed when working with huge data sets and versatility.
# See benchmarks here:
# https://github.com/Rdatatable/data.table/wiki/Benchmarks-%3A-Grouping
# If you are not familiar with data.table I recommend these reads
# https://github.com/Rdatatable/data.table/wiki/vignettes/datatable-intro.pdf
# https://github.com/Rdatatable/data.table/wiki/vignettes/datatable-faq.pdf
# and the wiki here https://github.com/Rdatatable/data.table/wiki
library("data.table")

##############################################################################
# THE SCRIPT ASSUMES THAT WORKING DIRECTORY IS SET TO THE ROOT OF DATA FILES #
# AND ENDS WITH A SLASH                                                      #
##############################################################################
# Set working directory appropriately!!!
# setwd("D:\\GDrive\\GitHub\\coursera-data-science-getdata-course-project\\rawdata")
##############################################################################
# Check whether working directory contains activity_labels.txt file, which
# means it is the root directory of our data.
if (!file.exists("activity_labels.txt"))
  stop("Could not find activity_labels.txt file.\nPlease, set working directory to the root of the data folder!")

# Load activity labels. We will need them to fullfil the following requirement:
# 3. Uses descriptive activity names to name the activities in the data set
a.labels <- fread("activity_labels.txt")

# Load variable(column) names. We will need them to fullfill the following:
# 2. Extracts only the measurements on the mean and standard deviation for each
#    measurement.
# 4. Appropriately labels the data set with descriptive variable names. 
v.names <- fread("features.txt")

# Now we need to decide which columns we must keep. We obviously must keep
# columns with -mean() and -std(). There are also columns with -meanFreq() and
# seven columns with angles of some means. I believe neither -meanFreq() nor
# angles columns should be included in the tidy set since they are not
# "mean and standard deviation for each measurement", they are some additional
# characteristics of these measurements. So I keep only -mean() and -std() columns.
# "perl = T" param is for PCRE syntax, which is generally faster.
v.names <- v.names[grepl("(-mean\\(\\))|(-std\\(\\))", V2, perl = T)]
# We are down to 66 columns. Now let's cleanup these names a bit, so that it's
# easier to use them in the code for anybody using our data in the future.
# Get rid of parenthesis.
# This is data.table syntax and it does update the values! It probably does not
# work the same way in data.frame.
v.names[, V2:=gsub("()", "", V2, fixed = T)]
# Replace "-" with "."
v.names[, V2:=gsub("-", ".", V2, fixed = T)]

# Let's make a function, which reads and processes data from a training/testing 
# subset.
ReadFilesAndMerge <- function(data.set = "train") {
  # Reads data files for a data set (train or test), converts activity to
  # labeled factor, filters out unneeded columns and merges everything together.
  
  # Subject IDs for each observation
  s <- fread(sprintf("%s/subject_%s.txt", data.set, data.set))
  # Set sensible column name. setnames(x, names(x), v.names$V2) is faster 
  # than names(x) <- v.names$V2 because the latter copies the table, while
  # the former does its changes by reference.
  setnames(s, names(s), c("Subject"))
  
  # Activity IDs for each observation
  y <- fread(sprintf("%s/y_%s.txt", data.set, data.set))
  
  # Replace activity IDs with descriptive activity labels.
  # In our case, when items in a.labels are already correctly ordered from 1 to 6
  # and ids in y are also from 1 to 6, we could disregard a.labels$V1 column and
  # just do left_join by row numbers in a.labels
  #
  # y <- a.labels[y$V1, V2]
  #
  # This takes rows from a.labels according to numbers in y$V1. This would not
  # work if ids were not consecutively numbered from 1 to 6.
  # In case of arbitrary ids, and when using data.tables, the correct way would be
  #
  # y <- a.labels[V1 == y$V1, V2]
  #
  # But IMHO both solutions are not ideal, since by replacing numbers with
  # strings we lose their relative ordering. It doesn't matter much here, but
  # if ids in Y where not just dumb numbers, but encoded relative order from the
  # least physical strain to the highest physical strain, replacing them with
  # bare labels would lose meaningful ordering information. So the ideal solution
  # should replace activity IDs with an ordered factor variable, where labels 
  # will both be informative and keep the relative ordering of activities.
  # Thus here I convert y to a factor vector with descriptive activity labels.
  y <- factor(y$V1, a.labels$V1, a.labels$V2, ordered = T)
  
  # Convert to data.table just to keep using the same syntax everywhere
  y <- as.data.table(y)
  
  # Set sensible column name.
  setnames(y, names(y), c("Activity"))
    
  # fread is a very fast data.table's file reader, but it chokes on this file.
  # Thus I have to use read.table and convert to data.table.
  # If you know how to read this file using fread, please tell me!
  x <- read.table(sprintf("%s/X_%s.txt", data.set, data.set))
  # convert to data.table to keep using the same syntax everywhere
  x <- as.data.table(x)
  
  # Now let's get rid of unneeded columns
  # First create a list of x columns, using IDs in v.names$V1
  cols <- names(x)[v.names$V1]
  # Now let's get only those columns that we need.
  # This one is tricky in data.table! Everything is easy when you know column
  # names and can type them in, but when column names have to be provided 
  # programmatically data.table gets tricky. "with=FALSE" is important here.
  # See datatable-faq.pdf Q:1.5
  x <- x[, cols, with=F]
  # Finally set column names
  setnames(x, names(x), v.names$V2)
  
  # Ok, we are ready to merge everything using cbind, convert to data.table
  # and return the resulting data.table
  as.data.table(cbind(y, s, x))
}
# Load files and do the magic.
train <- ReadFilesAndMerge("train")
test <- ReadFilesAndMerge("test")
# We could do that without a function, if we were merging them immediately after
# reading from files, but this way we have a nice data.table for each set and
# can work with each separately if needed.

# Now let's rbind them.
data <- rbind(train, test)

# Create data.table index by Activity, Subject
setkey(data, Activity, Subject)

# Now the real magic begins!
# The following will group our data.table by Activity, Subject and calculate
# an average for each of the other columns within a group.
# .(Activity, Subject) is data.table's shortcut for list(Activity, Subject)
# .SD represents the Subset of Data for all the columns not included in the groups.
tidydata <- data[, lapply(.SD, mean), by = .(Activity, Subject)]

# Now let's write it to disk. 
write.table(tidydata, file = "tidydata.txt", row.names = F)

# That's it! :-)
# Comments are very welcome!

# Heck, just for the fun of it, a few hours before the deadline I decided to
# write the code, which converts my wide tidydata into long narrow tidy data.
library(reshape2)
t.long <- melt(tidydata, 1:2, 3:68)
# Now we have narrow long tidydata, but we also need to split "variable" column
# into 3 columns for Signal, Axis and Feature.
# This is a quick last minute dash, so probably there is a better solution.
library(stringr)
# The split pattern is a reqular expression, so the dot has to be escaped.
v <- str_split_fixed(t.long$variable, "\\.", 3)
# Add columns to t.long
t.long$Signal <- v[, 1]
t.long$Feature <- v[, 2]
t.long$Axis <- v[, 3]
# drop "variable" column
t.long[, variable := NULL]
# Now, since all our Signals,Axis groups have exactly two measures, which are 
# mean and std, and since the data is considered messy if we store more than one
# distinct value in one column/variable. We should unmelt them to two separate 
# Mean and Std columns.
s <- t.long[Feature=="std", value]
t.long <- t.long[Feature=="mean"]
t.long[, Std:=s]
# rename "value" to "Mean"
setnames(t.long, c("value"), c("Mean"))
# drop Feature column
t.long[, Feature := NULL]
# But in fact that's not the end of the story! They really want us to go insane
# and split the Signal value into many sub values:
# 1) Unit of measurement (t denoting "time" and f denoting "frequency")
t.long[, Unit:=ifelse(substr(Signal, 1, 1) == "t", "time", "freq")]
# 2) Originator - Body or Gravity
t.long[, Originator:=ifelse(substr(Signal, 2, 5) == "Body", "Body", "Gravity")]
# 3) Device - Accelerator or Gyroscope
t.long[, Device:=ifelse(grepl("Gyro", Signal, fixed = T), "Gyro", "Acc")]
# 4) Jerk - TRUE or FALSE for if it's a Jerk signal
t.long[, Jerk:=ifelse(grepl("Jerk", Signal, fixed = T), T, F)]
# 5) Magnitude - TRUE or FALSE for if it's a measure of a magnitude of the signal
t.long[, Magnitude:=ifelse(grepl("Mag", Signal, fixed = T), T, F)]
# Now let's drop the Signal column and reorder the columns
t.long[, Signal := NULL]
setcolorder(t.long, neworder = c("Activity", 
                                 "Subject", 
                                 "Unit", 
                                 "Device", 
                                 "Originator", 
                                 "Jerk", 
                                 "Magnitude", 
                                 "Axis", 
                                 "Mean", 
                                 "Std"))
# OK, now let's write it to "tidydata-long.txt"
write.table(t.long, file = "tidydata-long.txt", row.names = F)
# The End