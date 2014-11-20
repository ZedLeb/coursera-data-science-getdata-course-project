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
v.names <- v.names[grep("(-mean\\(\\))|(-std\\(\\))", V2, perl = T)]
# We are down to 66 columns. Now let's cleanup these names a bit, so that it's
# easier to use them in the code for anybody using our data in the future.
# Get rid of parenthesis
v.names[, V2:=gsub("\\(\\)", "", V2)]
# Replace "-" with "."
v.names[, V2:=gsub("-", ".", V2)]

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
  y <- fread(sprintf("%s/Y_%s.txt", data.set, data.set))
  
  # Convert y to a factor vector with descriptive activity labels.
  # IMPORTANT: THIS DOES NOT REORDER y!
  y <- cut(y$V1, nrow(a.labels), labels = a.labels$V2)
  # convert to data.table to keep using the same syntax everywhere
  y <- as.data.table(y)
  # Nevertheless I am not sure whether that's the best solution.
  # Correct me if you know a better solution!
  
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
