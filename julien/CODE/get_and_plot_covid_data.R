# Get COVID-19 data at the local level from a variety of sources,
# Do some plotting

library(dplyr)
library(lubridate)
library(EpiCurve)

source("functions_useful.R")
ma <- function(x, n = 7){stats::filter(x, rep(1 / n, n), sides = 2)}

REFRESH_DATA = FALSE
REPROCESS_DATA = TRUE
PDF_OR_PNG = "pdf"
ALL_PLOTS = FALSE
FIGURE_TITLE = FALSE

if (REFRESH_DATA) {
  # Set a long timeout in case of bad internet connection
  options(timeout=120)
  # Get started
  DATA = list()
  ###
  ### USA
  ###
  # For USA, get data from the NYT: https://github.com/nytimes/covid-19-data
  # Note that their data is cumulative, we will need to "decumulate"
  DATA$USA = list()
  # Process states
  writeLines("Getting USA - States")
  DATA$USA$states = list()
  DATA$USA$states$data_raw = read.csv("https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv")
  DATA$USA$states$data_raw = DATA$USA$states$data_raw %>%
    arrange(DATA$USA$states$data_raw$state, DATA$USA$states$data_raw$date)
  colnames(DATA$USA$states$data_raw)[which(colnames(DATA$USA$states$data_raw) == "cases")] = "cum_cases"
  colnames(DATA$USA$states$data_raw)[which(colnames(DATA$USA$states$data_raw) == "deaths")] = "cum_deaths"
  # Save info on states
  DATA$USA$states$info = unique(DATA$USA$states$data_raw[,c("state", "fips")])
  rownames(DATA$USA$states$info) = DATA$USA$states$info$fips
  # Process counties (we remove data where the county is unknown)
  writeLines("Getting USA - Counties")
  DATA$USA$counties = list()
  DATA$USA$counties$data_raw = read.csv("https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv")
  DATA$USA$counties$data_raw = DATA$USA$counties$data_raw %>%
    arrange(DATA$USA$counties$data_raw$state,
            DATA$USA$counties$data_raw$county,
            DATA$USA$counties$data_raw$date) %>%
    filter(DATA$USA$counties$data_raw$county != "Unknown")
  colnames(DATA$USA$counties$data_raw)[which(colnames(DATA$USA$counties$data_raw) == "cases")] = "cum_cases"
  colnames(DATA$USA$counties$data_raw)[which(colnames(DATA$USA$counties$data_raw) == "deaths")] = "cum_deaths"
  # Save info on counties
  DATA$USA$counties$info = unique(DATA$USA$counties$data_raw[,c("state", "county", "fips")]) %>%
    filter(county != "Unknown")
  rownames(DATA$USA$counties$info) = 1:dim(DATA$USA$counties$info)[1]
  ###
  ### CAN
  ###
  # For CAN, get data from the usual suspects
  writeLines("Getting CAN - Health regions")
  DATA$CAN = list()
  DATA$CAN$health_regions = list()
  DATA$CAN$health_regions$data_raw =
    read.csv("https://raw.githubusercontent.com/ccodwg/Covid19Canada/master/timeseries_hr/cases_timeseries_hr.csv")
  colnames(DATA$CAN$health_regions$data_raw) =
    c("prov_or_terr", "health_region", "date", "cases", "cum_cases")
  DATA$CAN$health_regions$data_raw$date = dmy(DATA$CAN$health_regions$data_raw$date)
  # Save info on health regions
  DATA$CAN$health_regions$info =
    unique(DATA$CAN$health_regions$data_raw[,c("prov_or_terr", "health_region")]) %>%
    filter(health_region != "Not Reported")
  ###
  ### Save the result
  ###
  saveRDS(DATA, file = "DATA/COVID-19-data-raw.Rds")
} else {
  DATA = readRDS(file = "DATA/COVID-19-data-raw.Rds")
}

if (REPROCESS_DATA) {
  DATA = readRDS(file = "DATA/COVID-19-data-raw.Rds")
  ###
  ### Some post-load processing
  ###
  DATA$USA$counties$data_by_geog = list()
  for (i in 1:dim(DATA$USA$counties$info)[1]) {
    writeLines(paste0("Processing ", DATA$USA$counties$info$county[i], " (", DATA$USA$counties$info$state[i], ")"))
    DATA$USA$counties$data_by_geog[[i]] = DATA$USA$counties$data_raw %>%
      dplyr::filter(state == DATA$USA$counties$info$state[i]) %>%
      dplyr::filter(county == DATA$USA$counties$info$county[i])
    # uncumsumify (:)) the USA data
    DATA$USA$counties$data_by_geog[[i]]$cases = c(DATA$USA$counties$data_by_geog[[i]]$cum_cases[1],
                                                  diff(DATA$USA$counties$data_by_geog[[i]]$cum_cases))
    DATA$USA$counties$data_by_geog[[i]]$deaths = c(DATA$USA$counties$data_by_geog[[i]]$cum_deaths[1],
                                                   diff(DATA$USA$counties$data_by_geog[[i]]$cum_deaths))
    DATA$USA$counties$data_by_geog[[i]]$time_since_first =
      as.numeric(ymd(DATA$USA$counties$data_by_geog[[i]]$date) -
                   ymd(DATA$USA$counties$data_by_geog[[i]]$date[1]))
    # Process health regions of Canada
    DATA$CAN$health_regions$data_by_geog = list()
    for (i in 1:dim(DATA$CAN$health_regions$info)[1]) {
      DATA$CAN$health_regions$data_by_geog[[i]] = DATA$CAN$health_regions$data_raw %>%
        filter(prov_or_terr == DATA$CAN$health_regions$info$prov_or_terr[i] &
                 health_region == DATA$CAN$health_regions$info$health_region[i]) %>%
        filter(cases > 0)
      DATA$CAN$health_regions$data_by_geog[[i]]$time_since_first =
        as.numeric(ymd(DATA$CAN$health_regions$data_by_geog[[i]]$date) -
                     ymd(DATA$CAN$health_regions$data_by_geog[[i]]$date[1]))
    }
  }
  ###
  ### Save the result
  ###
  saveRDS(DATA, file = "DATA/COVID-19-data-processed.Rds")
} else {
  DATA = readRDS(file = "DATA/COVID-19-data-processed.Rds")
}


# Do crazy number of plots
if (ALL_PLOTS) {
  for (i in 1:dim(DATA$USA$counties$info)[1]) {
    file_name = sprintf("OUTPUT/USA-%s-%s_points.png", DATA$USA$counties$info$state[i], DATA$USA$counties$info$county[i])
    file_name = gsub(" ", "_", file_name)
    figure_title = sprintf("USA-%s-%s", DATA$USA$counties$info$state[i], DATA$USA$counties$info$county[i])
    writeLines(figure_title)
    tmp = data.frame(date = as.character(DATA$USA$counties$data_by_geog[[i]]$date),
                     time_since_first = DATA$USA$counties$data_by_geog[[i]]$time_since_first,
                     value = DATA$USA$counties$data_by_geog[[i]]$cases)
    tmp = tmp %>%
      dplyr::filter(value>0)
    # We need to recreate the entire time line to do the moving average
    timeline = seq(ymd(tmp$date[1]), ymd(tmp$date[length(tmp$date)]), by = "day")
    timeline = as.numeric(timeline - timeline[1])
    if (length(timeline)>14) {
      cases = mat.or.vec(nr = length(timeline), nc = 1)
      idx_in_timeline = which(timeline %in% tmp$time_since_first)
      cases[idx_in_timeline] = tmp$value
      tmp_ma = data.frame(time_since_first = timeline, ma = ma(cases, n = 7))
      tmp_ma$ma[is.na(tmp_ma$ma)] = 0
    }
    if (dim(tmp)[1]>0) {
      png(file = file_name, width = 800, height = 600)
      plot(tmp$time_since_first, tmp$value,
           xlab = "Days since first case",
           ylab = "Incidence",
           pch = 19,
           main = ifelse(FIGURE_TITLE, figure_title, ""))
      if (length(timeline)>14) {
        lines(tmp_ma$time_since_first, tmp_ma$ ma, type = "l", col = "darkorange4", lwd = 2)
      }
      dev.off()
      crop_figure(file_name)
    }
  }
}

if (ALL_PLOTS) {
  for (i in 1:dim(DATA$CAN$health_regions$info)[1]) {
    file_name = sprintf("OUTPUT/CAN-%s-%s_points.png",
                        DATA$CAN$health_regions$info$prov_or_terr[i],
                        DATA$CAN$health_regions$info$health_region[i])
    file_name = gsub(" ", "_", file_name)
    file_name = gsub("\\(", "_", file_name)
    file_name = gsub("\\)", "_", file_name)
    file_name = gsub("\\&", "and", file_name)
    figure_title = sprintf("CAN-%s-%s",
                           DATA$CAN$health_regions$info$prov_or_terr[i],
                           DATA$CAN$health_regions$info$health_region[i])
    writeLines(figure_title)
    tmp = data.frame(date = as.character(DATA$CAN$health_regions$data_by_geog[[i]]$date),
                     time_since_first = DATA$CAN$health_regions$data_by_geog[[i]]$time_since_first,
                     value = DATA$CAN$health_regions$data_by_geog[[i]]$cases)
    # We need to recreate the entire time line to do the moving average
    timeline = seq(ymd(tmp$date[1]), ymd(tmp$date[length(tmp$date)]), by = "day")
    timeline = as.numeric(timeline - timeline[1])
    cases = mat.or.vec(nr = length(timeline), nc = 1)
    idx_in_timeline = which(timeline %in% tmp$time_since_first)
    cases[idx_in_timeline] = tmp$value
    tmp_ma = data.frame(time_since_first = timeline, ma = ma(cases, n = 7))
    tmp_ma$ma[is.na(tmp_ma$ma)] = 0
    # Now fix the data itself
    tmp = tmp %>%
      dplyr::filter(value>0)
    if (dim(tmp)[1]>0) {
      png(file = file_name, width = 800, height = 600)
      plot(tmp$time_since_first, tmp$value,
           xlab = "Days since first case",
           ylab = "Incidence",
           pch = 19,
           main = ifelse(FIGURE_TITLE, figure_title, ""))
      lines(tmp_ma$time_since_first, tmp_ma$ ma, type = "l", col = "darkorange4", lwd = 2)
      dev.off()
      crop_figure(file_name)
    }
  }
}

###
###
###
# Plot some stuff with selected locations
to_plot = matrix(nc = 3, byrow = TRUE,
                     data = c("CAN", "Manitoba", "Winnipeg",
                              "CAN", "Nunavut", "Nunavut",
                              "USA", "Illinois", "Cook",
                              "USA", "Kentucky", "Jefferson",
                              "USA", "New York", "Orange",
                              "USA","Wyoming", "Campbell"
                              ))
to_plot = as.data.frame(to_plot)
colnames(to_plot) = c("ctry", "prov_state", "hr_county")

selected_locations = list()
for (i in 1:dim(to_plot)[1]) {
  figure_title = sprintf("%s-%s-%s",
                         to_plot$ctry[i],
                         to_plot$prov_state[i],
                         to_plot$hr_county[i])
  writeLines(figure_title)
  if (to_plot$ctry[i] == "CAN") {
    idx1 = which(DATA$CAN$health_regions$info$prov_or_terr == to_plot$prov_state[i])
    idx2 = which(DATA$CAN$health_regions$info$health_region == to_plot$hr_county[i])
    idx = intersect(idx1,idx2)
    selected_locations[[i]] = 
      data.frame(date = DATA$CAN$health_regions$data_by_geog[[idx]]$date,
                 time_since_first = DATA$CAN$health_regions$data_by_geog[[idx]]$time_since_first,
                 value = DATA$CAN$health_regions$data_by_geog[[idx]]$cases)
  } else {
    idx1 = which(DATA$USA$counties$info$state == to_plot$prov_state[i])
    idx2 = which(DATA$USA$counties$info$county == to_plot$hr_county[i])
    idx = intersect(idx1,idx2)
    selected_locations[[i]] = 
      data.frame(date = DATA$USA$counties$data_by_geog[[idx]]$date,
                 time_since_first = DATA$USA$counties$data_by_geog[[idx]]$time_since_first,
                 value = DATA$USA$counties$data_by_geog[[idx]]$cases)
  }
  date_end = ymd(selected_locations[[i]]$date[1])+365
  selected_locations[[i]] = selected_locations[[i]] %>%
    dplyr::filter(value>0)
  tmp = selected_locations[[i]] %>%
    dplyr::filter(value>0 & date<date_end)
  if (dim(selected_locations[[i]])[1]>0) {
    file_name = sprintf("OUTPUT/select_%s-%s_bars.png",
                        to_plot$prov_state[i],
                        to_plot$hr_county[i])
    file_name = gsub(" ", "_", file_name)
    EpiCurve(tmp,
             date = "date",
             period = "day",
             freq = "value",
             xlabel = "Date",
             ylabel = "Incidence",
             square = FALSE)
    ggsave(filename = file_name, width = 8, height = 6, units = "in")
    crop_figure(file_name)
  }
}
