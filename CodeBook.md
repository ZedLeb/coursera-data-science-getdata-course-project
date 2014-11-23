# CodeBook #
This is a CodeBook for Course Project in Getting and Cleaning Data course at Coursera.
## The Raw Data ##
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

The task does not clearly state which of these we should use.
Let's read the **features_info.txt** file:

> These signals were used to estimate variables of the feature vector for each pattern:  
'-XYZ' is used to denote 3-axial signals in the X, Y and Z directions.
>
> tBodyAcc-XYZ<br/>
> tGravityAcc-XYZ<br/>
> tBodyAccJerk-XYZ<br/>
> tBodyGyro-XYZ<br/>
> tBodyGyroJerk-XYZ<br/>
> tBodyAccMag<br/>
> tGravityAccMag<br/>
> tBodyAccJerkMag<br/>
> tBodyGyroMag<br/>
> tBodyGyroJerkMag<br/>
> fBodyAcc-XYZ<br/>
> fBodyAccJerk-XYZ<br/>
> fBodyGyro-XYZ<br/>
> fBodyAccMag<br/>
> fBodyAccJerkMag<br/>
> fBodyGyroMag<br/>
> fBodyGyroJerkMag<br/>
>
>The set of variables that were estimated from these signals are: 
>
>mean(): Mean value<br/>
>std(): Standard deviation<br/>
>mad(): Median absolute deviation<br/>
>max(): Largest value in array<br/>
>min(): Smallest value in array<br/>
>sma(): Signal magnitude area<br/>
>energy(): Energy measure. Sum of the squares divided by the number of values.<br/>
>iqr(): Interquartile range<br/>
>entropy(): Signal entropy<br/>
>arCoeff(): Autorregresion coefficients with Burg order equal to 4<br/>
>correlation(): correlation coefficient between two signals<br/>
>maxInds(): index of the frequency component with largest magnitude<br/>
>meanFreq(): Weighted average of the frequency components to obtain a mean frequency<br/>
>skewness(): skewness of the frequency domain signal<br/>
>kurtosis(): kurtosis of the frequency domain signal<br/>
>bandsEnergy(): Energy of a frequency interval within the 64 bins of the FFT of each window.<br/>
>angle(): Angle between to vectors.<br/>
>
>Additional vectors obtained by averaging the signals in a signal window sample. These are used on the angle() variable:
>
>gravityMean<br/>
>tBodyAccMean<br/>
>tBodyAccJerkMean<br/>
>tBodyGyroMean<br/>
>tBodyGyroJerkMean<br/>

In my opinion it is now very obvious that we should only extract the 66 features, which include **-mean()** and **-std()** in their names, since **meanFreq()** is a different kind of variable for the same signal, and while **angles** do use mean values of signals, they are not themselves means or standard deviations of signals.

### 2. What was done to the data?
The original data was not changed. New file named **tidydata.txt** with new data.table was created in the root directory of the original data.

I've processed the data in a slightly different order to the task and using **data.table** package instead of **data.frame** for storing and manipulating data.

1. Loaded **activity_labels.txt** file
2. Loaded **features.txt**, selected 66 features, which include **-mean()** and **-std()** in their names and slightly processed the names. Namely removed "()" and replaced "-" with ".". These names are quite informative and can be easily used for referencing columns in R scripts.
3. Next I defined a function, which accepts either "test" or "train" as parameter, loads appropriate data and does steps 1-4 from the task. Loads relevant subjects file. Loads relevant activity file. Replaces activity IDs with an activity labels factor variable. Reads relevant X-file. Drops irrelevant columns and renames columns with names prepared in step 2. Then it cbinds 3 pieces of data together and returns it.
4. After running my function for the "train" and "test" data I have two data.tables. Which I then rbind together, group by activity and subject, and calculate means for each of the rest of columns within each group.

So finally we have a table with 68 columns. The first two columns are Activity and Subject ids and serve as table's key. The rest of the columns are 66 variables, which were calculated as average(mean) on mean and std variables for each signal in the original data set as described above and in the **features_info.txt** file.

My R script is extensively commented.
Please, examine comments there.

### 3. Wide or narrow tidy data?
I've carefully read through all the discussion in Course forum [Tidy data and the assignment](https://class.coursera.org/getdata-009/forum/thread?thread_id=192) on whether to narrow the data, making it more tidy, or to leave it wide. I am still not convinced that narrowing this particular data set will make it any easier to work with for any particular purpose. More so because the resulting data doesn't seem to have any meaningfull purpose except to test our ability to manipulate data in R.

More over, as the swirl assignment on **dplyr** and **tidyr** is left for the 4th week, it implies that narrowing tidy data was not intended for this Course Project.

And finally instructions for markers/evaluators explicitely state that "*Either a* **wide** *or a* **long** *form of the data is acceptable if it meets the tidy data principles of week 1 (Each variable you measure should be in one column, Each different observation of that variable should be in a different row)*"

So for this particular assignment I decided to leave tidy data **wide**.