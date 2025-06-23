# Load the data


# Load the necessary packages
#library(mice)
library(readr)
library(janitor)
library(readxl)
library(lares)
library(dplyr)

# Load the data
data <- read_excel("Realestate.xlsx")

# Explore the data
print(summary(data))
dim(data)


####      DATA PREPARATION       ####

# Clean variable names and remove special characters
data <- clean_names(data) 

# Select variables of interest
selected_cols <- c("price", "number_of_units", "total_area", "number_of_stories", "lot_size", "type", "year_built")
realestate <- data[, selected_cols]


# Remove rows with missing values
realestate <- na.omit(realestate)

# Remove SF and AC units on total area and lot_size and convert to acres
realestate$total_area <- round(as.numeric(gsub(",", "", gsub(" SF", "", realestate$total_area))) / 43560, 2)
realestate$lot_size <- ifelse(grepl("SF", realestate$lot_size),
                              round(as.numeric(gsub(",", "", gsub(" SF", "", realestate$lot_size))) / 43560, 2),
                              as.numeric(gsub(" AC", "", realestate$lot_size)))






# covert variable formats
realestate$price <- as.numeric(gsub(",", "", gsub("\\$", "", realestate$price)))
realestate$number_of_units <- as.integer(realestate$number_of_units)
realestate$year_built <- as.integer(realestate$year_built)
realestate$number_of_stories <- as.factor(realestate$number_of_stories)


# calculate the age of property
realestate$age <- 2022 - realestate$year_built
realestate_cleaned <- subset(realestate, select = -c(year_built, type))



# display the first few rows
print(head(realestate_cleaned))

dim(realestate_cleaned)



# Save the cleaned data
write_csv(realestate_cleaned, "cleaned_realestate.csv")




# Read the data from the CSV file
data <- read.csv("cleaned_realestate.csv")
# Convert price to thousands
data$price <- data$price / 1000

## Summary statistics
Mean <- data %>% summarise_all(list(mean))
Median <- data %>% summarise_all(list(median))
Range <- data %>% summarise_all(list(range))
I_QR <- data %>% summarise_all(list(IQR))
Var <- data %>% summarise_all(list(var))
Stdv <- data %>% summarise_all(list(sd))
A <- rbind(Mean, Median)
C = rbind(A, I_QR)
D = rbind(C, Var)
E = rbind(D, Stdv)
Statistics <- cbind(Measure = c("Mean","Median",
                                "I_Range","Variance","STDeviation"), E)

# Print Descriptive Statistics
print(Statistics %>% select(-number_of_stories))




####### VISUALIZATIONS  #######

# Create a histogram of prices (filtered)
ggplot(data, aes(x = price)) +
  geom_histogram(bins = 10, fill = "steelblue", color = "black") +
  labs(x = "Price (in thousands)", y = "Frequency") +
  ggtitle("Histogram of Prices")

# Define the outlier threshold (>=30,000)
outlier_threshold <- 25000

# Remove outlier prices above the threshold
data <- data %>%
  filter(price <= outlier_threshold)



# Summary statistics for number_of_stories
data %>%
  group_by(number_of_stories) %>%
  summarize(
    count = n(),
  )


# Bar plot of number_of_stories
ggplot(data, aes(x = factor(number_of_stories))) +
  geom_bar() +
  labs(x = "Number of Stories", y = "Count") +
  ggtitle("Bar plot of Number of Stories")+
  theme_bw()


# Summarize mean price by number_of_stories
# Filter the data to remove number_of_stories > 5
data <- data %>%
  filter(number_of_stories <= 5)
data %>%
  group_by(number_of_stories) %>%
  summarize(count = n(),
    mean_price = mean(price))%>%
  arrange(desc(mean_price))



###  Correlations analysis
price_corr <- corr_var(data, price)
price_corr



# Scatter plot with linear regression line and R-squared value
p <- data %>%
  ggplot(aes(x = total_area, y = price)) +
  geom_point(colour = "blue") +
  geom_smooth(method = "lm", fill = NA, colour = "red") +
  ggtitle("Relationship between Price and Total Area") +
  theme_pubr()

# Calculate R-squared
model <- lm(price ~ total_area, data = data)
r_squared <- summary(model)$r.squared

# Add R-squared to the plot
p <- p + annotate(
  "text",
  x = Inf, y = Inf,
  label = paste("R-squared =", round(r_squared, 3)),
  hjust = 1, vjust = 1,
  size = 4
)

# Print the plot
print(p)



### REGRESSION MODEL   ####

# Perform regression analysis
data$number_of_stories <- as.integer(data$number_of_stories)
model <- lm(price ~ ., data = data)

# Print the summary of the regression model
summary(model)


