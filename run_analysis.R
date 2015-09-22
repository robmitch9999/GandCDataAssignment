### bring the various relevant files into R from the working directory, bearing in mind that the test and the 
### train datasets are in sub-folders

### make sure you have some tools available
library(dplyr)
library(tidyr)

### first, the long list of features & short list of activity factors

features <- tbl_df(read.table("features.txt"))
activity_labels <- read.table("activity_labels.txt")


### now read in the test data
subject_test <- tbl_df(read.table("test/subject_test.txt"))
Y_test <- tbl_df(read.table("test/y_test.txt"))
X_test <- tbl_df(read.table("test/X_test.txt"))

### now read in the trial data
X_train <- tbl_df(read.table("train/X_train.txt"))
Y_train <- tbl_df(read.table("train/y_train.txt"))
subject_train <- tbl_df(read.table("train/subject_train.txt"))

### now if I want to label all the columns in the two "X" files
### I first need to turn the entries in "features" into character strings

features$V2 <- as.character(features$V2)

### then I can change the column headings to be (relatively) meaningful!
colnames(X_test) <- features$V2
colnames(X_train) <- features$V2

### now convert the activity files from integers to meaningful labels
### taking care not to screw up their order!
Y_test$order <- seq(along=Y_test$V1)
Y_test <- merge(Y_test, activity_labels, by.x = "V1", by.y = "V1", all = TRUE)
Y_test <- Y_test[order(Y_test$order),]
Y_test$order <- NULL

Y_train$order <- seq(along = Y_train$V1)
Y_train <- merge(Y_train, activity_labels, by.x = "V1", by.y = "V1", all = TRUE)
Y_train <- Y_train[order(Y_train$order),]
Y_train$order <- NULL

### and give both files meaningful column names
colnames(Y_train) <- c("activity_code", "activity")
colnames(Y_test) <- c("activity_code", "activity")


### sort out the subject names with a meaningful title
colnames(subject_test) <- "person"
colnames(subject_train) <- "person"

### delete the activity_code columns
Y_test$activity_code <- NULL
Y_train$activity_code <- NULL

### add the subject keys anc activity codes as new columns at the start of the test/train datasets
testData <- tbl_df(cbind(subject_test, Y_test, X_test))
trainData <- tbl_df(cbind(subject_train, Y_train, X_train))



### put the train and test datasets together ... should end up with 10,299 observations
###     30 subjects and 6 activities
allData <- tbl_df(rbind(trainData, testData))


### remove unwanted columns
### nb there are duplicate column names
### and those columns appear to contain different data
### but none of them are mean/std deviations
### so delete the duplicate columns first
allData <- allData[ , !duplicated(colnames(allData))]

### now a select command to remove all but the columns with Mean or std in their titles ...  
cleanData <- select(allData, person, activity, contains("mean", ignore.case = TRUE), contains("std", ignore.case = TRUE))
### and remove the parentheses and the commas from the column names
names(cleanData) <- gsub("[,]", "", names(cleanData))
names(cleanData) <- gsub("[()]", "", names(cleanData))

### so now I think I have a dataset, cleanData that corresponds
### to the first part of the set task ... lets remove the interim data
rm(X_test, Y_test, Y_train, X_train, activity_labels, allData, features, subject_test, subject_train, testData, trainData)

### now lets make the new table with the average values
### of all readings for each combination of person and activity
newData <- group_by(cleanData, person, activity) %>% summarize_each(funs(mean))

### now write the new dataset to the working folder
write.table(newData, file = "newData.txt", row.name = FALSE)
