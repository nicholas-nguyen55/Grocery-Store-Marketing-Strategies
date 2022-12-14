retail <- read.csv("C:/Users/tythn/Downloads/media prediction and its cost.csv"
                 , header = TRUE
                 , stringsAsFactors = FALSE)

# Check data structure
str(retail)
summary(retail)
summary(retail$food_category)

# Check missing data
colSums(is.na(retail))

# Load library
library(dplyr)

# Remove unnecessary columns
retail_1 <- retail %>% select(-c(food_family, education, houseowner, avg_cars_at.home.approx., avg_cars_at.home.approx..1,
                                 brand_name, num_children_at_home, SRP, gross_weight, net_weight))

# Select values in the USA only
retail_1 <- retail_1[retail_1$sales_country == "USA",]

# Check the data structure again
str(retail_1)

# Load lirabry again
library(ggplot2)
library(scales)
library(ggpubr)

# Store Sales By Cost Graph
ggplot(retail_1) + aes(x = store_sales.in.millions., y = store_cost.in.millions., color = unit_sales.in.millions. > 3) + 
  geom_point() + ggtitle("Store Sales By Cost Spotted By Unit Sales")

# Unit Sales By Food Department Graph
b <- aggregate(retail_1$unit_sales.in.millions., list(food_department = retail_1$food_department), sum)
colnames(b)[2] <- "unit_sales"

ggplot(b) + aes(x = food_department, y = unit_sales, fill = food_department) + geom_bar(stat = "identity") + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) + ggtitle(" Unit Sales By Food Department")

# Cost By Media Type Graph
a <- aggregate(retail_1$cost, list(media_type = retail_1$media_type), sum)
colnames(a)[2] <- "cost"

ggplot(a) + aes(x = media_type, y = cost, fill = media_type) + geom_bar(stat = "identity") + 
  scale_x_discrete(guide = guide_axis(n.dodge=3)) + scale_y_continuous(labels = comma) +
  ggtitle("Cost By Media Type")

# Occupation By Membership Card Graph
ggplot(retail_1, aes(x=occupation, fill = member_card))+
  geom_bar() + ggtitle("Occupation By Membership Card")

# Average Income By Gender Graph
ggplot(retail_1, aes(x=avg..yearly_income, fill = gender))+
  geom_bar() + ggtitle("Average Income By Gender")

############# Association Model #################

# Load libraries
library(arules)
library(arulesViz)
library(ggplot2)
library(tidyverse)

# Remove a few more columns
retail_2 <- retail_1 %>% select(-c(sales_country,recyclable_package,low_fat,units_per_case, store_sqft, food_department
                                   ,grocery_sqft, frozen_sqft, meat_sqft, coffee_bar, video_store, salad_bar
                                   , florist, prepared_food))

# No need of this column for prediction model
retail_2$sales_country <- NULL

# Check the data set again
View(retail_2)
str(retail_2)

# Convert char features to factors
retail_2$food_category <- factor(retail_2$food_category)
retail_2$food_department <- factor(retail_2$food_department)
retail_2$promotion_name <- factor(retail_2$promotion_name)
retail_2$marital_status <- factor(retail_2$marital_status)
retail_2$member_card <- factor(retail_2$member_card)
retail_2$occupation <- factor(retail_2$occupation)
retail_2$avg..yearly_income <- factor(retail_2$avg..yearly_income)
retail_2$store_type <- factor(retail_2$store_type)
retail_2$store_city <- factor(retail_2$store_city)
retail_2$store_state <- factor(retail_2$store_state)
retail_2$media_type <- factor(retail_2$media_type)
retail_2$unit_sales.in.millions.<- factor(retail_2$unit_sales.in.millions.)
retail_2$gender <- factor(retail_2$gender)

# Discretize tocal_children and cost
retail_2$total_children <- cut(retail_2$total_children
                               , breaks = c(0,1,2,3)
                               , labels = c("0", "1-2", "3-4")
                               , right = FALSE
)

retail_2$cost <- cut(retail_2$cost
                               , breaks = c(0,55,80,105,130,155)
                               , labels = c("0-55", "56-80", "81-105", "106-130", "131+")
                               , right = FALSE
)

str(retail_2)
# Check the frequency
transactions <- as(retail_2, "transactions")
itemFrequencyPlot(transactions, topN = 20, type = "absolute")

# Check the rule. With the support of 0.002 and conf = 0.5. So many rules.
rules_pep <- apriori(transactions
                     , parameter = list(supp = 0.002
                                        , conf = 0.5)
)
# Check the rule again with different supp and conf. Just a few rules.
rules_pep_1 <- apriori(transactions
                       , parameter = list(supp = 0.2
                                          , conf = 0.8)
)

# Check the rule again with supp = 0.11 and conf = 0.8
rules_pep_2 <- apriori(transactions
                       , parameter = list(supp = 0.11
                                          , conf = 0.8)
)

# Top 10 rules with supp = 0.11 and conf = 0.8
rules_pep_2 <- sort(rules_pep_2
                    , decreasing = TRUE
                    , by = "lift")
inspect(rules_pep_2[1:10])

# Check the rule showing occupation=Professional
rules_pep_3 <- apriori(transactions
                       , parameter = list(supp = 0.01
                                          , conf = 0.5)
                       , appearance = list(default = 'lhs'
                                           , rhs = 'occupation=Professional')
)
rules_pep_3 <- sort(rules_pep_3
                    , decreasing = TRUE
                    , by = "lift")
inspect(rules_pep_3[1:5])

# Check the rule showing cost=56-80
rules_pep_4 <- apriori(transactions
                       , parameter = list(supp = 0.01
                                          , conf = 0.5)
                       , appearance = list(default = 'lhs'
                                           , rhs = 'cost=56-80')
)
rules_pep_4 <- sort(rules_pep_4
                    , decreasing = TRUE
                    , by = "lift")
inspect(rules_pep_4[1:10])

# Check the rule showing cost=81-105
rules_pep_5 <- apriori(transactions
                       , parameter = list(supp = 0.01
                                          , conf = 0.5)
                       , appearance = list(default = 'lhs'
                                           , rhs = 'cost=81-105')
)
rules_pep_5 <- sort(rules_pep_5
                    , decreasing = TRUE
                    , by = "lift")
inspect(rules_pep_5[1:10])

#---------------------- K-Method ------------------------------------

# Load libraries
library(ggplot2)
library(cluster)
library(factoextra)
library(dendextend)
library(dplyr)
library(tibble)
library(useful)

combine <- data.frame(retail_1[,c('media_type', 'cost')])

str(combine)
combine_1 <- combine[,-1]
str(combine_1)

set.seed(20000)
# Run k-means with k = 4
Cluster <- kmeans(combine_1, 4)
combine_1$Cluster <- as.factor(Cluster$cluster)

# Add the clustering results back to the original dataframe
combine_3 <- combine
combine_3$Cluster <- as.factor(Cluster$cluster)
str(combine_3)

# Plot results
ggplot(data = combine_3, aes(x=media_type, fill=Cluster))+
  geom_bar(stat = "count")+
  labs(title = "K = ?")+
  theme(plot.title = element_text(hjust = 0.5), text = element_text(size = 15)) +
  scale_x_discrete(guide = guide_axis(n.dodge=3))

# Run again k-means with k = 6
# Run again k-means with k = 8

# --------- Hierarchical Clustering Algorithms (HAC) ----------------
# Calculate distance in a variety of ways
distance <- dist(combine_1, method = "euclidean")
distance2 <- dist(combine_1, method = "maximum")
distance3 <- dist(combine_1, method = "manhattan")
distance4 <- dist(combine_1, method = "canberra")
distance5 <- dist(combine_1, method = "binary")
distance6 <- dist(combine_1, method = "minkowski")

# Display result
HAC2 <- hclust(distance, method = "ward.D2")
plot(HAC2, cex=0.6, hang=-1)
rect.hclust(HAC2, k=4, border=2:5)

# Another display result
HAC <- hclust(distance, method = "complete")
plot(HAC, cex=0.6, hang=-1)
rect.hclust(HAC, k=4, border = 2:5)

#-------------------------- Tree Model --------------------------------------
library(tm)
library(stringr)
library(stringi)
library(Matrix)
library(tidytext) 
library(dplyr)
library(ggplot2)
library(factoextra)
library(rpart)
library(rattle)
library(rpart.plot)
library(RColorBrewer)
library(caret)

# Using data set from retail_1

# Remove a few more columns
retail_3 <- retail_1 %>% select(-c(food_category,sales_country,recyclable_package,low_fat,units_per_case, store_sqft, 
                                   food_department,grocery_sqft, frozen_sqft, meat_sqft, coffee_bar, video_store, salad_bar
                                   , florist, prepared_food, store_sales.in.millions., store_cost.in.millions., 
                                   unit_sales.in.millions.,))

# Convert chr to num
retail_3$gender <- ifelse(retail_3$gender=="M", 1, 0) #Male = 1; Female = 0

retail_3$marital_status <- ifelse(retail_3$marital_status=="M", 1, 0) #Married = 1; Single = 0

retail_3$member_card <- ifelse(retail_3$member_card == 'Normal', 0,
                                 ifelse(retail_3$member_card == 'Bronze', 1,
                                        ifelse(retail_3$member_card == 'Silver', 2,
                                               ifelse(retail_3$member_card == 'Golden', 3, NA))))

retail_3$occupation <- ifelse(retail_3$occupation == 'Clerical', 0,
                                ifelse(retail_3$occupation == 'Management', 1,
                                       ifelse(retail_3$occupation == 'Manual', 2,
                                              ifelse(retail_3$occupation == 'Skilled Manual', 3,
                                                     ifelse(retail_3$occupation == 'Professional', 4, NA)))))

retail_3$store_type <- ifelse(retail_3$store_type == 'Small Grocery', 0,
                                ifelse(retail_3$store_type == 'Supermarket', 1,
                                       ifelse(retail_3$store_type == 'Gourmet Supermarket', 2,
                                              ifelse(retail_3$store_type == 'Deluxe Supermarket', 3, NA))))

# Check the data set again
str(retail_3)

##Make Train and Test sets
numMedia = 13
numTotalRetail = nrow(retail_3)
trainRatio <- .70
set.seed(123) # Set Seed so that same sample can be reproduced in future also
sample <- sample.int(n = numTotalRetail-numMedia, 
                     size = floor(trainRatio*numTotalRetail), replace = FALSE)
newSample = sample + numMedia
retailtrain <- retail_3[newSample, ]
retailtest <- retail_3[-newSample, ]
# train / test ratio
length(newSample)/nrow(retail_3)

#Train Tree Model 1: media type with cost
train_tree1 <- rpart(media_type ~ cost, data = retailtrain, method="class", 
                     control=rpart.control(cp=0, minsplit = 2, maxdepth = 3, 
                                           minbucket = round(10/3) ))
summary(train_tree1)
#predict the test dataset using the model for train tree No. 1
predicted1= predict(train_tree1, retailtest, type="class")
#plot number of splits
rsq.rpart(train_tree1)
plotcp(train_tree1)
#plot the decision tree
fancyRpartPlot(train_tree1)
#confusion matrix to find correct and incorrect predictions
table_mat <- table(media_type=predicted1, true=retailtest$media_type)
# Show the accuracy for the test
accuracy_Test <- sum(diag(table_mat)) / sum(table_mat)
print(paste('Accuracy for test', accuracy_Test))

#### Run again Decision Tree with different maxdepth
maxdepth = 10


