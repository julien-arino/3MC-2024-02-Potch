# Sample code that downloads Sentinelles data for France
# 

# Read in the data for France
data = readr::read_csv("https://www.sentiweb.fr/datasets/incidence-PAY-3.csv",
                       skip = 1)
# Show the top of the table (always useful)
head(data)
# Week is by epi week, let's sort this out. Four first digits are year, last 
# two are week. Let us rename the first column as yyyyww, to avoid confusion
# with week
colnames(data)[1] = "yyyyww" 
data$year = substr(data$yyyyww, 1, 4)
data$week = substr(data$yyyyww, 5, 6)
# It will be easier to work with days as days, so we convert dates
data$date = lubridate::parse_date_time(paste(data$year, data$week, 1, sep="/"),
                                       'Y/W/w')
# There are some issues, let us fix without thinking: if something went wrong, it 
# is typically because of a week numbered 53. We make that day 31 December of 
# that year
idx = which(is.na(data$date))
data$date[idx] = ymd(paste0(data$year[idx],"-12-31"))

# Ah, yes, don't forget: let's flip the order of the table, as it is sorted
# by decreasing dates
data = data %>%
  arrange(date)

# Type of incidence to use (column name in the data)
which_incidence = "inc"

# Let us now select one epidemic season (mid year to next). Use another variable
# so we don't have to reload the data if we do weird edits..
# We take a flu season prior to the pandemic (they are weird after that)
beg_year = 2018
end_year = 2019
data_subset = data %>%
  filter(date > paste0(beg_year,"-12-15")) %>%
  filter(date <= ymd(paste0(end_year,"-04-30")))

plot(data_subset$date, data_subset[[which_incidence]],
     type = "b",
     xlab = "Month", ylab = "Incidence",
     main = paste0(beg_year, "-", end_year, " flu season"))
