#library(rstan)
setwd("/Users/karimimohammedbelhal/Desktop/variationalBayes/mcmc_R_isolate/Dir2")
  source('compute_LL.R') 
  source('func_aux.R') 
  source('func_cov.R') 
  source('func_distcond.R') 
  source('func_FIM.R') 
  source('func_ggplot2.R') 
  source('func_plots.R') 
  source('func_simulations.R') 
  source('ggplot2_global.R') 
  # source('KL.R') 
  #source('vi.R') 
  source('global.R')
  source('main.R')
  source('mcmc_main.R') 
  source('main_estep.R')
  source('main_estep_mcmc.R') 
  source('main_estep_morekernels.R') 
  # source('main_initialiseMainAlgo.R') 
  source('main_mstep.R') 
  source('SaemixData.R')
  source('plots_ggplot2.R') 
  source('saemix-package.R') 
  source('SaemixModel.R') 
  source('SaemixRes.R') 
  # source('SaemixObject.R') 
  source('zzz.R') 
setwd("/Users/karimimohammedbelhal/Documents/GitHub/saem/new_kernel_saem/timetoevent")
source('main_time.R')
source('main_estep_time.R')
source('main_mstep_time.R') 
source('func_aux_time.R') 
source('SaemixObject_time.R') 
source('main_initialiseMainAlgo_time.R') 
source("mixtureFunctions.R")

library("mlxR")
library("psych")
library("coda")
library("Matrix")
library(abind)
require(ggplot2)
require(gridExtra)
require(reshape2)

#####################################################################################
# Theophylline

# Data - changing gender to M/F
# theo.saemix<-read.table("data/theo.saemix.tab",header=T,na=".")
# theo.saemix$Sex<-ifelse(theo.saemix$Sex==1,"M","F")
# saemix.data<-saemixData(name.data=theo.saemix,header=TRUE,sep=" ",na=NA, name.group=c("Id"),name.predictors=c("Dose","Time"),name.response=c("Concentration"),name.covariates=c("Weight","Sex"),units=list(x="hr",y="mg/L",covariates=c("kg","-")), name.X="Time")
iter_mcmc = 200


timetoevent.saemix <- read.table("/Users/karimimohammedbelhal/Documents/GitHub/saem/new_kernel_saem/timetoevent/timeto.csv", header=T, sep=",")
timetoevent.saemix <- timetoevent.saemix[timetoevent.saemix$ytype==2,]
timetoevent.saemix["nb"] <- 0
for (i in 1:length(unique(timetoevent.saemix$id))) {
    timetoevent.saemix[timetoevent.saemix$id==i,5] <- length(which(timetoevent.saemix[timetoevent.saemix$id==i,3]==1))
  }

saemix.data<-saemixData(name.data=timetoevent.saemix,header=TRUE,sep=" ",na=NA, name.group=c("id"),name.response=c("y"),name.predictors=c("time","y","nb"), name.X=c("time"))


timetoevent.model<-function(psi,id,xidep) {
# T<-xidep[,1]
# y<-xidep[,2]
# nb<-cbind(id,xidep[,3])

# N <- nrow(psi)
# lambda <- psi[,1]

# censoringtime = 60
# logpdf <- vector(length= N)
# for (i in 1:N) {
#   logpdf[i] <- nb[nb[,1]==i,2][1]*log(lambda[i]) - lambda[i]*censoringtime
# }

T<-xidep[,1]
y<-xidep[,2]
nb<-cbind(id,xidep[,3])
N <- nrow(psi)
Nj <- length(T)
inter <- cbind(id, diff(T))

censoringtime = 60

lambda <- psi[id,1]
init <- which(T==0)
cens <- which(T==censoringtime)
ind <- setdiff(1:Nj, append(init,cens))


hazard <- lambda
H <- lambda*T

logpdf <- rep(0,Nj)
logpdf[cens] <- -H[cens] + H[cens-1]
logpdf[ind] <- -H[ind] + H[ind-1] + log(hazard[ind])

return(logpdf)
}



saemix.model<-saemixModel(model=timetoevent.model,description="time model",   
  psi0=matrix(c(1,1),ncol=2,byrow=TRUE,dimnames=list(NULL,   
  c("lambda","beta"))), 
  transform.par=c(1,0),covariance.model=matrix(c(1,0,0,0),ncol=2, 
  byrow=TRUE),error.model="constant")


K1 = 100
K2 = 50

iterations = 1:(K1+K2+1)
gd_step = 0.01

#RWM
options<-list(seed=39546,map=F,fim=F,ll.is=F,nb.chains = 1, nbiter.mcmc = c(2,2,2,0), nbiter.saemix = c(K1,K2),nbiter.sa=0,displayProgress=TRUE, map.range=c(0))
theo_ref<-data.frame(saemix_time(saemix.model,saemix.data,options))
theo_ref <- cbind(iterations, theo_ref)

graphConvMC_saem(theo_ref, title="new kernel")

#ref (map always)
options.cat<-list(seed=39546,map=F,fim=F,ll.is=F,nb.chains = 1, nbiter.mcmc = c(6,0,0,5),nbiter.saemix = c(K1,K2),displayProgress=FALSE, map.range=c(1:90))
cat_saem<-data.frame(saemix_time(saemix.model,saemix.data,options.cat))
cat_saem <- cbind(iterations, cat_saem)

# graphConvMC_saem(cat_saem, title="new kernel")
graphConvMC2_saem(theo_ref,cat_saem, title="VS")

graphConvMC2_saem(theo_ref[290:450,],cat_saem[290:450,], title="VS")
plot(theo_ref[,2])
plot(cat_saem[,2])

final_rwm <- post_rwm[[1]]
for (i in 2:length(post_rwm)) {
  final_rwm <- rbind(final_rwm, post_rwm[[i]])
}


final_foce <- post_foce[[1]]
for (i in 2:length(post_foce)) {
  final_foce <- rbind(final_foce, post_foce[[i]])
}



graphConvMC_twokernels(final_rwm,final_rwm, title="EM")
graphConvMC_twokernels(final_rwm,final_foce, title="EM")


#Autocorrelation
rwm.obj <- as.mcmc(post_rwm[[1]])
corr_rwm <- autocorr(rwm.obj[,2])
autocorr.plot(rwm.obj[,2])

foce.obj <- as.mcmc(post_foce[[1]])
corr_foce <- autocorr(foce.obj[,2])
autocorr.plot(foce.obj[,2])


#MSJD
mssd(post_rwm[[index]][,2])
mssd(post_foce[[index]][,2])



