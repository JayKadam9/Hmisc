require(Hmisc)
n <- 100
set.seed(1)
d <- data.frame(sbp=rnorm(n, 120, 10),
                dbp=rnorm(n, 80, 10),
                age=rnorm(n, 50, 10),
                days=sample(1:n, n, TRUE),
                S1=Surv(2*runif(n)), S2=Surv(runif(n)),
                race=sample(c('Asian', 'Black/AA', 'White'), n, TRUE),
                sex=sample(c('Female', 'Male'), n, TRUE),
                treat=sample(c('A', 'B'), n, TRUE),
                region=sample(c('North America','Europe'), n, TRUE),
                meda=sample(0:1, n, TRUE), medb=sample(0:1, n, TRUE))

d <- upData(d, labels=c(sbp='Systolic BP', dbp='Diastolic BP',
                 race='Race', sex='Sex', treat='Treatment', days='Time Since Randomization',
                 S1='Hospitalization', S2='Re-Operation', meda='Medication A', medb='Medication B'),
            units=c(sbp='mmHg', dbp='mmHg', age='Year', days='Days'))

#png('/tmp/summaryP.png', width=550, height=550)
s <- summaryS(age + sbp + dbp ~ days + region + treat,  data=d)
# plot(s)   # 3 pages
plot(s, groups='treat', datadensity=TRUE, scat1d.opts=list(lwd=.5, nhistSpike=0))
plot(s, groups='treat', panel=panel.loess, key=list(space='bottom', columns=2),
     datadensity=TRUE, scat1d.opts=list(lwd=.5))
# Show both points and smooth curves:
plot(s, groups='treat', panel=function(...) {panel.xyplot(...); panel.loess(...)})
plot(s, y ~ days | yvar * region, groups='treat')

# Make your own plot using data frame created by summaryP
xyplot(y ~ days | yvar * region, groups=treat, data=s,
        scales=list(y='free', rot=0))

# Use loess to estimate the probability of two different types of events as
# a function of time
s <- summaryS(meda + medb ~ days + treat + region, data=d)
pan <- function(...) panel.plsmo(..., type='l', label.curves=max(which.packet()) == 1,
                                 datadensity=TRUE)
plot(s, groups='treat', panel=pan, paneldoesgroups=TRUE, scat1d.opts=list(lwd=.7),
     cex.strip=.8)

# Demonstrate dot charts of summary statistics
s <- summaryS(age + sbp + dbp ~ region + treat, data=d, fun=mean)
plot(s)
plot(s, groups='treat', funlabel=expression(bar(X)))
# Compute parametric confidence limits for mean, and include sample sizes
f <- function(x) {
  x <- x[! is.na(x)]
  c(smean.cl.normal(x, na.rm=FALSE), n=length(x))
}
s <- summaryS(age + sbp + dbp ~ region + treat, data=d, fun=f)
plot(s, funlabel=expression(bar(X) %+-% t[0.975] %*% s))
plot(s, textonly='n', textplot='Mean', digits=1)

# Customize printing of statistics to use X bar symbol and smaller
# font for n=...
cust <- function(y) {
  means <- format(round(y[, 'Mean'], 1))
  ns    <- format(y[, 'n'])
  simplyformatted <- paste('X=', means, ' n=', ns, '  ', sep='')
  s <- NULL
  for(i in 1:length(ns)) {
    w <- paste('paste(bar(X)==', means[i], ',~~scriptstyle(n==', ns[i],
               '))', sep='')
    s <- c(s, parse(text=w))
  }
  list(result=s,
       longest=simplyformatted[which.max(nchar(simplyformatted))])
}
plot(s, groups='treat', cex.values=.65,
     textplot='Mean', custom=cust,
     key=list(space='bottom', columns=2,
       text=c('Treatment A:','Treatment B:')))

## Stratifying by region and treat fit an exponential distribution to
## S1 and S2 and estimate the probability of an event within 0.5 years

f <- function(y) {
  hazard <- sum(y[,2]) / sum(y[,1])
  1. - exp(- hazard * 0.5)
}

s <- summaryS(S1 + S2 ~ region + treat, data=d, fun=f)
plot(s, groups='treat', funlabel='Prob[Event Within 6m]', xlim=c(.3, .7))




