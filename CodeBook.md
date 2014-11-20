# CodeBook #
This is a CodeBook for Course Project in Getting and Cleaning Data course at Coursera.
## 1. Raw Data ##
The experiments have been carried out with a group of 30 volunteers within an age bracket of 19-48 years. Each person performed six activities (WALKING, WALKING_UPSTAIRS, WALKING_DOWNSTAIRS, SITTING, STANDING, LAYING) wearing a smartphone (Samsung Galaxy S II) on the waist. Using its embedded accelerometer and gyroscope, we captured 3-axial linear acceleration and 3-axial angular velocity at a constant rate of 50Hz. The experiments have been video-recorded to label the data manually. The obtained dataset has been randomly partitioned into two sets, where 70% of the volunteers was selected for generating the training data and 30% the test data. 

The sensor signals (accelerometer and gyroscope) were pre-processed by applying noise filters and then sampled in fixed-width sliding windows of 2.56 sec and 50% overlap (128 readings/window). The sensor acceleration signal, which has gravitational and body motion components, was separated using a Butterworth low-pass filter into body acceleration and gravity. The gravitational force is assumed to have only low frequency components, therefore a filter with 0.3 Hz cutoff frequency was used. From each window, a vector of features was obtained by calculating variables from the time and frequency domain. 

Check the README.txt file for further details about this dataset.

http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones

## The Task ##
The task set up on us by the instructors is the following:

You should create one R script called run_analysis.R that does the following. 

1. Merges the training and the test sets to create one data set.
2. Extracts only the measurements on the mean and standard deviation for each measurement.
3. Uses descriptive activity names to name the activities in the data set.
4. Appropriately labels the data set with descriptive variable names.
5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

## Processing of Data ##

### 1. What data are we asked to process?
The task says: "*extract only the measurements on the mean and standard deviation for each measurement*". This means that we should disregard raw accelerometer and gyroscope data stored in **Inertial Signals** folders and should extract relevant features from **X_test.txt** and **X_train.txt** files.

Reading through **features.txt** file we discover that these are ultra short descriptions to the 561 columns contained in the **X_test.txt** and **X_train.txt** files. There are 3 types of features that are of interest for us:

 1. 66 features which have **-mean()** and **-std()** in them.
 2. 6 features that look like **angle(tBodyAccJerkMean),gravityMean)**
 3. 13 features that look like **fBodyAccJerk-meanFreq()-X**

The task does not clearly state which of these we should use. Based on the information provided in the **features_info.txt** file I believe that we should only extract the 66 features, which include **-mean()** and **-std()** in their names.

### 2. What was done to the data?
The original data was not changed. New file named **tidydata.txt** with new data.table was created in the root directory of the original data.

I've processed the data in a slightly different order to the task and using **data.table** package instead of **data.frame** for storing and manipulating data.

1. Loaded **activity_labels.txt** file
2. Loaded **features.txt**, selected 66 features, which include **-mean()** and **-std()** in their names and slightly processed the names. Namely removed "()" and replaced "-" with ".". These names a quite informative and can be easily used for referencing columns.
3. Next I defined a function, which accepts either "test" or "train" as parameter, loads appropriate data and does steps 1-4 from the task. Loads relevant subjects file. Loads relevant activity file. Replaces activity IDs with activity labels. Reads relevant X-file. Drops irrelevant columns and renames columns with names prepared in step 2. Then it cbinds 3 pieces of data together and returns it.
4. After running my function for "train" and "test" data I have two data.tables. Which I then rbind together, group by activity and subject columns and calculate means for all the rest of the columns within each group.

Comments and a couple readability luxuries aside it took only 22 lines of R code!