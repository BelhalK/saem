setwd("/Users/karimimohammedbelhal/Desktop/CSDA_code/Dir")
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
  source('main_initialiseMainAlgo.R') 
  source('main_mstep.R') 
  source('SaemixData.R')
  source('plots_ggplot2.R') 
  source('saemix-package.R') 
  source('SaemixModel.R') 
  source('SaemixRes.R') 
  source('SaemixObject.R') 
  source('zzz.R') 
  source('main_time.R')
  source('main_estep_time.R')
  source('main_mstep_time.R') 
  source('func_aux_time.R') 
  source('SaemixObject_time.R') 
  source('main_initialiseMainAlgo_time.R') 
  
setwd("/Users/karimimohammedbelhal/Desktop/CSDA_code/")
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

timetoevent.saemix <- read.table("/Users/karimimohammedbelhal/Desktop/CSDA_code/rtte/rtte1.csv", header=T, sep=",")
timetoevent.saemix <- timetoevent.saemix[timetoevent.saemix$ytype==2,]
# timetoevent.saemix["nb"] <- 0
# for (i in 1:length(unique(timetoevent.saemix$id))) {
#     timetoevent.saemix[timetoevent.saemix$id==i,5] <- length(which(timetoevent.saemix[timetoevent.saemix$id==i,3]==1))
#   }

saemix.data<-saemixData(name.data=timetoevent.saemix,header=TRUE,sep=" ",na=NA, name.group=c("id"),name.response=c("y"),name.predictors=c("time","y"), name.X=c("time"))
# write.table(timetoevent.saemix[,1:3],"rtte.txt",sep=",",row.names=FALSE)


timetoevent.model<-function(psi,id,xidep) {
T<-xidep[,1]
y<-xidep[,2]
N <- nrow(psi)
Nj <- length(T)

censoringtime = 20

lambda <- psi[id,1]
beta <- psi[id,2]

init <- which(T==0)
cens <- which(T==censoringtime)
ind <- setdiff(1:Nj, append(init,cens))


hazard <- (beta/lambda)*(T/lambda)^(beta-1)
H <- (T/lambda)^beta

logpdf <- rep(0,Nj)
logpdf[cens] <- -H[cens] + H[cens-1]
logpdf[ind] <- -H[ind] + H[ind-1] + log(hazard[ind])

return(logpdf)
}



saemix.model<-saemixModel(model=timetoevent.model,description="time model",   
  psi0=matrix(c(10,1),ncol=2,byrow=TRUE,dimnames=list(NULL,   
  c("lambda","beta"))), 
  transform.par=c(1,1),covariance.model=matrix(c(1,0,0,1),ncol=2, 
  byrow=TRUE))


K1 = 200
K2 = 50

iterations = 1:(K1+K2+1)
gd_step = 0.01
end = K1+K2
#RWM
options<-list(seed=39546,map=F,fim=F,ll.is=F,nb.chains = 1, nbiter.mcmc = c(2,2,2,0), nbiter.saemix = c(K1,K2),nbiter.sa=0,displayProgress=TRUE, map.range=c(0),nbiter.burn =0)
theo_ref<-data.frame(saemix_time(saemix.model,saemix.data,options))
theo_ref <- cbind(iterations, theo_ref)

# graphConvMC_saem(theo_ref, title="new kernel")

#ref (map always)
options.cat<-list(seed=39546,map=F,fim=F,ll.is=F,nb.chains = 1, nbiter.mcmc = c(2,2,2,6),nbiter.saemix = c(K1,K2),displayProgress=FALSE, map.range=c(1:10),nbiter.burn =0)
cat_saem<-data.frame(saemix_time(saemix.model,saemix.data,options.cat))
cat_saem <- cbind(iterations, cat_saem)

# graphConvMC_saem(cat_saem, title="new kernel")
graphConvMC2_saem(theo_ref,cat_saem, title="new kernel")






replicate = 4
seed0 = 395246

#RWM
final_rwm <- 0
final_mix <- 0
for (m in 1:replicate){
  print(m)
  l = list(c(10,1),c(9,0.8),c(11,1.2),c(12,1.4))

  saemix.model<-saemixModel(model=timetoevent.model,description="time model",   
  psi0=matrix(l[[m]],ncol=2,byrow=TRUE,dimnames=list(NULL,   
  c("lambda","beta"))), 
  transform.par=c(1,1),covariance.model=matrix(c(1,0,0,1),ncol=2, 
  byrow=TRUE),omega.init=matrix(c(1/m,0,0,1/m),ncol=2,byrow=TRUE))

  options<-list(seed=39546,map=F,fim=F,ll.is=F,nb.chains = 1, nbiter.mcmc = c(2,2,2,0), nbiter.saemix = c(K1,K2),nbiter.sa=0,displayProgress=TRUE, map.range=c(0),nbiter.burn =0)
  theo_ref<-data.frame(saemix_time(saemix.model,saemix.data,options))
  theo_ref <- cbind(iterations, theo_ref)
  theo_ref['individual'] <- m
  final_rwm <- rbind(final_rwm,theo_ref)

  options.new<-list(seed=39546,map=F,fim=F,ll.is=F,nb.chains = 1, nbiter.mcmc = c(2,2,2,6),nbiter.saemix = c(K1,K2),displayProgress=FALSE, map.range=c(1:10),nbiter.burn =0)
  theo_mix<-data.frame(saemix_time(saemix.model,saemix.data,options.new))
  theo_mix <- cbind(iterations, theo_mix)
  theo_mix['individual'] <- m
  final_mix <- rbind(final_mix,theo_mix)
}

graphConvMC_new(final_rwm, title="RWM")
graphConvMC_diff(final_rwm,final_mix, title="RWM")
