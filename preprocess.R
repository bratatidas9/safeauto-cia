library(data.table)

# read data from csv file
data <- data.frame(fread("safeAuto_data_challenge.csv",
                         header = TRUE, stringsAsFactors = FALSE,
                         na.strings = ""))

# adding appropriate column names to data
colnames(data) <- c("InteractionId",
                    "UserId",
                    "State",
                    "UserAgentString",
                    "Browser",
                    "BrowserVersion",
                    "DeviceIsMobile",
                    "DeviceBrand",
                    "ScreenWidth",
                    "ScreenHeight",
                    "EventType",
                    "Event",
                    "Date")

# deleting rows which have NAs
data[data == ""] <- NA
data <- data[complete.cases(data), ]

# make logical groups for browser column
data$Browser[data$Browser == "InternetExplorer" |
               data$Browser == "IE" | 
               data$Browser == "IEMobile"] <- "Internet Explorer"
data$Browser[data$Browser == "Mozilla" |
               data$Browser == "Firefox"] <- "Mozilla Firefox"


# grouping Browser Versions
data$BrowserVersion <- sub("*\\..*", "", data$BrowserVersion)
data$BrowserVersion <- floor(as.numeric(data$BrowserVersion))

# grouping Device Brand
data$DeviceBrand[data$DeviceBrand == "iPhone" |
                   data$DeviceBrand == "IPhone" |
                   data$DeviceBrand == "IPad" |
                   data$DeviceBrand == "iPad" | 
                   data$DeviceBrand == "IPod" |
                   data$DeviceBrand == "iPod touch"] <- "IPhone"

# bucketing the resolutions into the following categories:
# Greater Than 1920 x 1080
# 1920 x 1080
# 1600 x 900
# 1280 x 720
# 720 x 480
# Less Than or Equal To 640 x 480
# taking max of height and width and assigning to width
data$ScreenWidth <- 
  ifelse(data$ScreenWidth < data$ScreenHeight,
         data$ScreenHeight, data$ScreenWidth)

# resolutions with unknown values are treated as 640
data$ScreenWidth[data$ScreenWidth == "NULL"] <- 640

data$Resolution <- 
  cut(
    as.numeric(data$ScreenWidth), 
    breaks = c(-Inf, 640, 720, 1280, 1600, 1920, Inf),
    labels = c("<= 640 x 480",
               "720 x 480",
               "1280 x 720",
               "1600 x 900",
               "1920 x 1080",
               "> 1920 x 1080")
  )

# deleting the ScreenHeight and ScreenWidth
# attributes as they are no longer required
data$ScreenHeight <- NULL
data$ScreenWidth <- NULL

# assigning default resolution to missing values 
# in resolution attribute
data$Resolution[is.na(data$Resolution)] <- "<= 640 x 480"

data$Resolution <- factor(data$Resolution,
                                levels = c("<= 640 x 480",
                                           "1600 x 900",
                                           "1280 x 720",
                                           "1920 x 1080",
                                           "720 x 480",
                                           "> 1920 x 1080"))

# convert true/false values of DeviceIsMobile Attribute
data$DeviceIsMobile[data$DeviceIsMobile == "TRUE"] <- "Mobile"
data$DeviceIsMobile[data$DeviceIsMobile == "FALSE"] <- "Non-Mobile"
data$DeviceIsMobile <- factor(data$DeviceIsMobile,
                              levels = c("Mobile", "Non-Mobile"))

# make one row per user and interaction
newData <- setDT(data)[, lapply(.SD, function(x) toString(na.omit(x))), 
                              by = list(UserId, State, InteractionId)]

# remove duplicate values
newData$Browser <- gsub("[[:punct:]] .*$", "", newData$Browser)
newData$BrowserVersion <- gsub("[[:punct:]] .*$", "", newData$BrowserVersion)
newData$DeviceIsMobile <- gsub("[[:punct:]] .*$", "", newData$DeviceIsMobile)
newData$DeviceBrand <- gsub("[[:punct:]] .*$", "", newData$DeviceBrand)
newData$EventType <- gsub("[[:punct:]] .*$", "", newData$EventType)
newData$Resolution <- gsub(", .*$", "", newData$Resolution)

# calulate how much time a user spends on the website, in minutes
newData$Duration <- sapply(newData$Date, function(x) {
  x <- as.POSIXct(strptime(unlist(strsplit(x, split = ", ")), 
                           format = "%Y-%m-%d %H:%M:%S"))
  x <- difftime(x[length(x)], x[1], units = "mins")
})

# calculate time of day for each interaction
newData$TimeOfDay <- sapply(newData$Date, function(x) {
  x <- as.POSIXct(strptime(unlist(strsplit(x, split = ", ")), 
                           format = "%Y-%m-%d %H:%M:%S"))
  x <- as.numeric(format(x, "%H"))
  x[1]
})

# convert Date column to appropriate format
newData$Date <- gsub(", .*$", "", newData$Date)

# add day of the week
newData$DayOfWeek <- c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", 
                       "Friday", "Saturday")[as.POSIXlt(newData$Date)$wday + 1]

# segregate on events
newData$PreQuotePortal <- sapply(newData$Event, function(x) {
  x <- unlist(strsplit(x, split = ", "))
  x <- as.numeric(ifelse("Pre-Quote Portal" %in% x, 1, 0))
})

# assuming a new quote and an existing customer as one event
newData$QuoteStart <- sapply(newData$Event, function(x) {
  x <- unlist(strsplit(x, split = ", "))
  x <- as.numeric(ifelse("Quote Start" %in% x | 
                           "Retrieve Existing Policy" %in% x, 1, 0))
})

newData$RetrievePremium <- sapply(newData$Event, function(x) {
  x <- unlist(strsplit(x, split = ", "))
  x <- as.numeric(ifelse("Retrieve Premium" %in% x, 1, 0))
})

newData$BindStart <- sapply(newData$Event, function(x) {
  x <- unlist(strsplit(x, split = ", "))
  x <- as.numeric(ifelse("Bind Start" %in% x, 1, 0))
})

newData$AddDrivers <- sapply(newData$Event, function(x) {
  x <- unlist(strsplit(x, split = ", "))
  x <- as.numeric(ifelse("Add Drivers" %in% x, 1, 0))
})

newData$AddVehicles <- sapply(newData$Event, function(x) {
  x <- unlist(strsplit(x, split = ", "))
  x <- as.numeric(ifelse("Add Vehicles" %in% x, 1, 0))
})

newData$ChooseCoverage <- sapply(newData$Event, function(x) {
  x <- unlist(strsplit(x, split = ", "))
  x <- as.numeric(ifelse("Choose Coverage" %in% x, 1, 0))
})

newData$GetPremium <- sapply(newData$Event, function(x) {
  x <- unlist(strsplit(x, split = ", "))
  x <- as.numeric(ifelse("Get Premium" %in% x, 1, 0))
})

newData$PaymentStart <- sapply(newData$Event, function(x) {
  x <- unlist(strsplit(x, split = ", "))
  x <- as.numeric(ifelse("Payment Start" %in% x, 1, 0))
})

# assuming Payment Complete and Download Receipt as a converted customer
newData$PaymentComplete <- sapply(newData$Event, function(x) {
  x <- unlist(strsplit(x, split = ", "))
  x <- as.numeric(ifelse("Payment Complete" %in% x |
                           "Download Receipt" %in% x, 1, 0))
})

# remove event column since it is no longer required
newData$Event <- NULL