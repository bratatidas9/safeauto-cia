# safeauto-cia
This repository contains the R code for visualizing CIA data from SafeAuto.

# Packages used
shiny, data.table, DT, plotly, h2o, lubridate, devtools, googleVis, sunburstR

# Note
To install googleVis and sunburstR, run the following commands:

install.packages(c("devtools","RJSONIO", "knitr", "shiny", "httpuv"))

library(devtools)

install_github("mages/googleVis")

install_github("timelyportfolio/sunburstR")

# How to run
1. Make sure safeAuto_data_challenge.csv is placed in the same directory as ui.R and server.R files.
2. runApp()

# Preprocessing
1. Removed the missing values from the dataset since they constituted less than 5% of the dataset. No significant data loss happened here.
2. Made logical groupings for the Browser, Browser Version, Device Brand, Resolution (computed from ScreenWidth and ScreenHeight attributes), DeviceIsMobile attributes.
3. The combination {UserId, InteractionId, State} identifies each session of a particular user. Reshaped the data using these attributes to get one session per row of the dataset. This significantly reduced the number of rows in the dataset, which makes handling of the dataset easier. Also, we get the sequence of events that a user goes through on the website. This helped later when creating the sunburst diagram.
4. Added new attributes for every event in the quote-sale process. Their values are indicated as 1 if the user has visited the website at this particular step, 0 if not.

# Analysis
The dashboard has three tabs - User Pathways, Time Dependency and Predictive Analysis. The three tabs cater to three different aspects of CIA data as mentioned below. Also, there are filters based on the technographic aspects of the device that the customer uses to access the website.

User Pathways

User pathways focus on the number of sessions that convert from a quote to a sale. [It, also, includes the number of sessions which begin at a particular step]. The Sankey Diagram depicts the processes in the step and how many sessions are being converted from one step to the other [Considered only the most significant steps here, since adding the steps like Add Vehicles, Choose Coverage etc. would have complicated the diagram and made it visually unappealing to read]. 

The sunburst diagram depicts the percentage of users which convert from one step of the process to the next and how they are moving across the process - meaning what percentage of users is moving across the process and which steps do they follow.

Time Dependency

Time Dependency focusses on how much time the user spends on the SafeAuto website and what time of the day a user tends to convert to a sale. The darker bubble represents a converted sale. The larger the bubble, the more time the user spends on the SafeAuto website. It can be seen from the first bubble chart that even thought a user spends more time on the website, he might not convert into a sale. Also, the most amount of conversions happen in the afternoon-to-evening time. The second bubble chart tries to capture the seasonal aspect of sales. The user is most likely to make a sale on a Sunday, Wednesday and Thursday.

Predictive Analysis
The main goal of this analysis is figuring out which user would be possessing the ideal technographic statistics to purchase a policy. The Random Forest model is being used here. I have divided the dataset into three parts - Train, Test and Validation. The Random Forest gives an accuracy of about 97%, compared to kmeans which was about 41%. The prediction column determines the probability of a user to purchase a policy. Following variables were the most important contributors in the predictions (in this order): Payment Start, Add Vehicles, Duration, Add Drivers, Bind Start, Time of Day, Get Premium, Retrieve Premium, Choose Coverage, Pre-Quote Portal, Quote Start. It can be inferred that if a user is most likely to purchase a policy if he is further into the quote-sale process. Also, the probability of a user to purchase a policy increases if he/she spends an optimum amount of time on the website and is, also, affected by the day of the week, when he is accessing the website. 

# Future Work
The dashboard lacks in performance. The User Pathways tab renders in a decent amount of time. The Time Dependency tab takes a lot of time to render. [Can I blame it on Plotly?] This can be improved by using other packages in R or further pre-processing of the dataset. Predictive Analysis tab renders pretty quickly but internally the h2o cluster can take up quite some time to make the prediction. This can be improved by preparing the model on the h2o UI and downloading the model locally.
