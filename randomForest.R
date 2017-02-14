#if(require(shiny)) {
#   install.packages("shiny")
# }
# 
# if(require(data.table)) {
#   install.packages("data.table")
# }
# 
# if(require(h2o)) {
#   install.packages("h2o")
# }

library(data.table)
library(h2o)
library(lubridate)

dataset <- newData

# removing columns which are not required in making predictions
dataset$UserId <- NULL
dataset$InteractionId <- NULL
dataset$Date <- NULL

# connect to h2o
localH2O <- h2o.init(ip = 'localhost', port = 54321, max_mem_size = '4g')

# to clean, if an existing h2o cluster exists
h2o.removeAll()

# split the dataset into training, test and validation sets
dataset <- as.h2o(dataset)
splits <- h2o.splitFrame(
  data = dataset, 
  ratios = c(0.7,0.2),   ## only need to specify 2 fractions, the 3rd is implied
  destination_frames = c("train.hex", "valid.hex", "test.hex"), seed = 1234
)
train <- splits[[1]]
valid <- splits[[2]]
test  <- splits[[3]]

rf <- h2o.randomForest(x = 1:20,
                       y = 21,
                       training_frame = train,
                       validation_frame = valid,
                       nfolds = 4, 
                       seed = 0xDECAF)

# make predictions with the test data
data.test.fit <- h2o.predict(object = rf, newdata = test)

# combine predictions with test dataset
final <- h2o.cbind(test, data.test.fit)
final.test <- as.data.frame(final)

# calculate accuracy on test dataset
accuracy <- h2o.performance(rf, newdata = test, xval = TRUE)

# shutdown h2o cluster
h2o.shutdown(prompt = FALSE)