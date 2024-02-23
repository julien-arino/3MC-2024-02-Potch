library(lubridate)
library(dplyr)
library(readr)
library(deSolve)
library(GA)
library(parallel)
library(doParallel)

# The RHS function for KMK with mass action incidence
RHS_KMK_SIR <- function(t, x, p) {
  with(as.list(c(x,p)), {
    dS <- -beta*S*I
    dI <- beta*S*I-gamma*I
    dR <- gamma*I
    return(list(c(dS, dI, dR)))
  })
}

# The RHS function for KMK with standard incidence
RHS_KMK_SIR_standard <- function(t, x, p) {
  with(as.list(c(x, p)), {
    dS <- -beta*S*I/pop
    dI <- beta*S*I/pop-gamma*I
    dR <- gamma*I
    return(list(c(dS, dI, dR)))
  })
}

# Compute the error based on one parameter value. Will also need a few more
# arguments
error_incidence <- function(p_vary, 
                            params, 
                            incidence_data,
                            method = "lsoda") {
  # Anything that changes during optimisation needs to be set here
  params$beta = as.numeric(p_vary["beta"])
  params$gamma = as.numeric(p_vary["gamma"])
  S0 = params$pop
  # Check value of R0. 
  # If it is less than 1, no need to compute ODE solution, 
  # return Inf. Of course, this depends on incidence.
  if (params$MA) {
    R0 = S0 * params$beta / params$gamma
  } else {
    R0 = params$beta / params$gamma
  }
  if (R0<1) {
    return(Inf)
  }
  # I0 is the I that gives us the incidence we are matching in the data.
  # This depends on the type of incidence function used
  if (params$MA) {
    # We are using mass action incidence. Then, since
    # incidence=beta*S*I, we have
    # I(0) = incidence/(beta*S(0))
    I0 = incidence_data$cases[1]/(params$beta*S0)
  } else {
    # We are using standard incidence. Then, since
    # incidence=beta*S*I/N, we have
    # I(0) = incidence*N/(beta*S(0)) ~= incidence/beta
    I0 = incidence_data$cases[1]/params$beta
  }
  IC = c(S = S0, I = I0, R = 0)
  # The times at which we compute the solution to compare with data
  times = as.numeric(incidence_data$date)
  if (params$MA) {
    sol = ode(IC, times, RHS_KMK_SIR, params, 
              method = method)
  } else {
    sol = ode(IC, times, RHS_KMK_SIR_standard, params, 
              method = method)
  }
  # Error checking
  if (sol[dim(sol)[1],"time"] < times[length(times)]) {
    return(Inf)
  }
  # Values required to compute the error
  if (params$MA) {
    # We are using mass action incidence. Then
    # incidence=beta*S*I, we have
    incidence_from_run = 
      params$beta * sol[,"S"] * sol[,"I"]
  } else {
    # We are using standard incidence. Then
    # incidence=beta*S*I/N, we have
    incidence_from_run = 
      params$beta * sol[,"S"] * sol[,"I"] / params$pop
  }
  # Compute the error
  diff_values = incidence_data$cases - incidence_from_run
  diff_values_squared = diff_values^2
  error = sum(diff_values_squared)
  return(error)
}

plot_solution = function(params, data_incidence) {
  S0 = params$pop
  # I0 is the I that gives us the incidence we are matching in the data.
  # This depends on the type of incidence function used
  if (params$MA) {
    # We are using mass action incidence. Then, since
    # incidence=beta*S*I, we have
    # I(0) = incidence/(beta*S(0))
    I0 = incidence_data$cases[1]/(params$beta*S0)
  } else {
    # We are using standard incidence. Then, since
    # incidence=beta*S*I/N, we have
    # I(0) = incidence*N/(beta*S(0)) ~= incidence/beta
    I0 = incidence_data$cases[1]/params$beta
  }
  IC = c(S = S0, I = I0, R = 0)
  dates_num = as.numeric(data_incidence$date)
  times = seq(dates_num[1], dates_num[length(dates_num)], 0.1)
  if (params$MA) {
    sol <- ode(IC, times, RHS_KMK_SIR, params)
    # We are using mass action incidence. Then
    # incidence=beta*S*I, we have
    sol_incidence = 
      params$beta * sol[,"S"] * sol[,"I"]
  } else {
    sol <- ode(IC, times, RHS_KMK_SIR_standard, params)
    # We are using standard incidence. Then
    # incidence=beta*S*I/N, we have
    sol_incidence = 
      params$beta * sol[,"S"] * sol[,"I"] / params$pop
  }
  y_max = max(max(sol_incidence), 
              max(incidence_data$cases))
  # Plot the result
  plot(sol[,"time"], sol_incidence, type = "l",
       xlab = "Date", ylab = "Incidence",
       xaxt = "n", lwd = 2, col = "red",
       ylim = c(0, y_max))
  lines(as.numeric(data_incidence$date), 
        incidence_data$cases,
        type = "b")
  dates_pretty = pretty(dates_num)
  axis(1, at = dates_pretty, 
       labels = as.Date(dates_pretty, origin="1970-01-01"))
}


pop_YWG = 750000

# We select on the relevant columns in the data
data = read_csv("DATA/Winnipeg-SARS-CoV-2.csv") %>%
  select(date, cases)

# We want to work on only one outbreak,  we need to find out
# when it happens. So first we plot things...
plot(data$date, data$cases, type = "l")
# Let's zoom in the three main peaks... (This is by trial
# and error)
peak1 = data %>%
  filter(date >= "2020-09-15" & date <= "2021-02-28") 
plot(peak1$date, peak1$cases)
peak2 = data %>%
  filter(date >= "2021-03-28" & date <= "2021-07-15") 
plot(peak2$date, peak2$cases)
peak3 = data %>%
  filter(date >= "2021-12-01" & date <= "2022-03-01") 
# plot(peak3$date, peak3$cases)


params = list()
params$gamma = 1/3.5   # Let's see if we can fit with this simple value
# Are we using mass action incidence (classic) or standard 
# incidence
params$MA = TRUE
# Add population data to this, for convenience
params$pop = pop_YWG
# An initial estimate of beta based on R0=1.5. Not useful anywhere
# except to debug. Depends on the incidence type, of course.
if (params$MA) {
  # Incidence is mass action, R0=S0*beta/gamma, so
  # beta=R0*gamma/S0
  params$beta = 1.5*params$gamma/params$pop
} else {
  # Incidence is standard, R0=beta/gamma, so
  # beta=R0*gamma
  params$beta = 1.5*params$gamma
}

## Fit using a genetic algorithm
GA = ga(
  type = "real-valued",
  fitness = function(x) 
    -error_incidence(p_vary = c(beta = x[1], gamma = x[2]),
                     params = params,
                     incidence_data = peak2,
                     method = "rk4"),
  parallel = TRUE,
  lower = c(ifelse(params$MA, 1e-8, 0.1), 1/30),
  upper = c(ifelse(params$MA, 1e-3, 10), 1),
  # optim = TRUE,
  suggestions = c(params$beta, params$gamma),
  popSize = 200,
  maxiter = 100
)

params$beta = GA@solution[1]
params$gamma = GA@solution[2]
plot_solution(params, peak2)


# m1 = 
#   optim(par = c(params$beta, params$gamma),
#         fn = function(x)
#           error_incidence(p_vary = c(beta = x[1], gamma = x[2]),
#                           params = params,
#                           incidence_data = peak2,
#                           method = "rk4"),
#         method='L-BFGS-B', 
#         gr = NULL,
#         lower = c(ifelse(params$MA, 1e-5, 0.1), 1/14), 
#         upper = c(ifelse(params$MA, 1e-2, 10), 1/2))
# 
# params$beta = m1$par[1]
# params$gamma = m1$par[2]
# plot_solution(params, peak2)
