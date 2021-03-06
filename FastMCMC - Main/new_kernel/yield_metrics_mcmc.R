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
  source('main_initialiseMainAlgo.R') 
  source('main_mstep.R') 
  source('SaemixData.R')
  source('plots_ggplot2.R') 
  source('saemix-package.R') 
  source('SaemixModel.R') 
  source('SaemixRes.R') 
  source('SaemixObject.R') 
  source('zzz.R') 
  source("mixtureFunctions.R")
setwd("/Users/karimimohammedbelhal/Documents/GitHub/saem/new_kernel")
source('newkernel_main.R')
source('main_estep_newkernel.R')


require(ggplot2)
require(gridExtra)
require(reshape2)

#####################################################################################
# Theophylline

# Data - changing gender to M/F
# theo.saemix<-read.table("data/theo.saemix.tab",header=T,na=".")
# theo.saemix$Sex<-ifelse(theo.saemix$Sex==1,"M","F")
# saemix.data<-saemixData(name.data=theo.saemix,header=TRUE,sep=" ",na=NA, name.group=c("Id"),name.predictors=c("Dose","Time"),name.response=c("Concentration"),name.covariates=c("Weight","Sex"),units=list(x="hr",y="mg/L",covariates=c("kg","-")), name.X="Time")



# Doc
data(yield.saemix)
yield.saemix_less <- yield.saemix[1:22,]
saemix.data<-saemixData(name.data=yield.saemix_less,header=TRUE,name.group=c("site"),
  name.predictors=c("dose"),name.response=c("yield"),
  name.covariates=c("soil.nitrogen"),units=list(x="kg/ha",y="t/ha",
  covariates=c("kg/ha")))
yield.LP<-function(psi,id,xidep) {
# input:
#   psi : matrix of parameters (3 columns, ymax, xmax, slope)
#   id : vector of indices 
#   xidep : dependent variables (same nb of rows as length of id)
# returns:
#   a vector of predictions of length equal to length of id
  # browser()
  x<-xidep[,1]
  ymax<-psi[id,1]
  xmax<-psi[id,2]
  slope<-psi[id,3]
  f<-ymax+slope*(x-xmax)
#  cat(length(f),"  ",length(ymax),"\n")
  f[x>xmax]<-ymax[x>xmax]
  return(f)
}
saemix.model<-saemixModel(model=yield.LP,description="Linear plus plateau model",   
  psi0=matrix(c(8,100,0.2,0,0,0),ncol=3,byrow=TRUE,dimnames=list(NULL,   
  c("Ymax","Xmax","slope"))),covariate.model=matrix(c(0,0,0),ncol=3,byrow=TRUE), 
  transform.par=c(0,0,0),covariance.model=matrix(c(1,0,0,0,1,0,0,0,1),ncol=3, 
  byrow=TRUE),error.model="constant")







indiv = 1
seed0 = 35644
replicate = 5
iter_mcmc = 3000
burn = 400



saemix.options_rwm<-list(seed=seed0,map=F,fim=F,ll.is=F, nb.chains = 1, nbiter.mcmc = c(iter_mcmc,0,0,0))
saemix.options_linear<-list(seed=seed0,map=F,fim=F,ll.is=F, nb.chains = 1, nbiter.mcmc = c(0,0,0,iter_mcmc))


ref <- saemix_newkernel(saemix.model,saemix.data,saemix.options_rwm)
new<-saemix_newkernel(saemix.model,saemix.data,saemix.options_linear)

post_rwm<-ref$post_rwm
post_newkernel<-new$post_newkernel

dens_rwm<-ref$dens_rwm
dens_Ueta<-ref$dens_Ueta
dens_newkernel<-new$dens_newkernel

indiv = 1

# U.y <- dens_rwm[[indiv]][20:iter_mcmc,]
# U.eta <- dens_rwm[[indiv]][20:iter_mcmc,]


graphConvMC_twokernels(post_rwm[[indiv]][301:350,],post_rwm[[indiv]][301:350,], title="post")
graphConvMC_twokernels(dens_rwm[[indiv]][301:350,],dens_rwm[[indiv]][301:350,], title="Uy")
graphConvMC_twokernels(dens_Ueta[[indiv]][301:350,],dens_Ueta[[indiv]][301:350,], title="Ueta")

graphConvMC_twokernels(post_rwm[[indiv]][501:550,],post_rwm[[indiv]][501:550,], title="post")
graphConvMC_twokernels(dens_rwm[[indiv]][501:550,],dens_rwm[[indiv]][501:550,], title="Uy")
graphConvMC_twokernels(dens_Ueta[[indiv]][501:550,],dens_Ueta[[indiv]][501:550,], title="Ueta")

graphConvMC_twokernels(post_rwm[[indiv]][301:350,],post_rwm[[indiv]][501:550,], title="post")
graphConvMC_twokernels(dens_Ueta[[indiv]][301:350,],dens_Ueta[[indiv]][501:550,], title="Ueta")
graphConvMC_twokernels(dens_rwm[[indiv]][301:350,],dens_rwm[[indiv]][501:550,], title="Ueta")


graphConvMC_twokernels(post_rwm[[indiv]][301:650,],post_rwm[[indiv]][301:650,], title="post")
graphConvMC_twokernels(dens_rwm[[indiv]][301:650,],dens_rwm[[indiv]][301:650,], title="Uy")
graphConvMC_twokernels(dens_Ueta[[indiv]][301:650,],dens_Ueta[[indiv]][301:650,], title="Ueta")




graphConvMC_twokernels(post_rwm[[indiv]],post_rwm[[indiv]], title="post")
graphConvMC_twokernels(post_rwm[[indiv]],post_newkernel[[indiv]], title="post")

graphConvMC_twokernels(dens_rwm[[indiv]][1:iter_mcmc,],dens_newkernel[[indiv]][1:iter_mcmc,], title="Uy")

graphConvMC_twokernels(dens_rwm[[indiv]][20:iter_mcmc,],dens_newkernel[[indiv]][20:iter_mcmc,], title="dens both methods")


graphConvMC_twokernels(post_rwm[[indiv]][20:iter_mcmc,c(1,4,5)],U.y, title="Uy and post")
graphConvMC_twokernels(post_rwm[[indiv]][20:iter_mcmc,c(1,4,5)],U.eta, title="Ueta and post")




graphConvMC_twokernels(U.y,U.y, title="Uy")
graphConvMC_twokernels(U.eta,U.eta, title="Ueta")
graphConvMC_twokernels(dens_rwm[[indiv]][,],dens_newkernel[[indiv]][,], title="sum")
graphConvMC_twokernels(dens_rwm[[indiv]][,],dens_rwm[[indiv]][,], title="sum")

graphConvMC_twokernels(U.eta,U.y, title="Uy Ueta")
graphConvMC_twokernels(U.eta+U.y,U.y+U.eta, title="Uy Ueta")




#expectations
expec_rwm <- post_rwm[[indiv]]
var_rwm <- post_rwm[[indiv]]
for (j in 1:replicate){
  print(j)
  saemix.options_rwm<-list(seed=j+seed0,map=F,fim=F,ll.is=F, nb.chains = 1, nbiter.mcmc = c(iter_mcmc,0,0,0))
  post_rwm<-saemix_newkernel(saemix.model,saemix.data,saemix.options_rwm)$post_rwm
  # print(post_rwm[[indiv]][44,2:4])
  post_rwm[[indiv]]['individual'] <- j
  expec_rwm[,2:4] <- expec_rwm[,2:4] + post_rwm[[indiv]][,2:4]
  var_rwm[,2] <- var_rwm[,2] + (post_rwm[[indiv]][,2])^2
  var_rwm[,3] <- var_rwm[,3] + (post_rwm[[indiv]][,3])^2
  var_rwm[,4] <- var_rwm[,4] + (post_rwm[[indiv]][,4])^2
}
expec_rwm[,2:4] <- expec_rwm[,2:4]/replicate
var_rwm[,2:4] <- var_rwm[,2:4]/replicate

graphConvMC_twokernels(expec_rwm,expec_rwm, title="Expectations")
graphConvMC_twokernels(var_rwm,var_rwm, title="Variances")



expec_new <- post_newkernel[[indiv]]
var_new <- post_newkernel[[indiv]]
for (j in 1:replicate){
  print(j)
  saemix.options_newkernel<-list(seed=j+seed0,map=F,fim=F,ll.is=F, nb.chains = 1, nbiter.mcmc = c(1,0,0,iter_mcmc))
  post_newkernel<-saemix_newkernel(saemix.model,saemix.data,saemix.options_newkernel)$post_newkernel
  post_newkernel[[indiv]]['individual'] <- j
  expec_new[,2:4] <- expec_new[,2:4] + post_newkernel[[indiv]][,2:4]
  var_new[,2] <- var_new[,2] + (post_newkernel[[indiv]][,2])^2
  var_new[,3] <- var_new[,3] + (post_newkernel[[indiv]][,3])^2
  var_new[,4] <- var_new[,4] + (post_newkernel[[indiv]][,4])^2
}
expec_new[,2:4] <- expec_new[,2:4]/replicate
var_new[,2:4] <- var_new[,2:4]/replicate


graphConvMC_twokernels(expec_rwm,expec_new, title="Expectations")
graphConvMC_twokernels(var_rwm,var_new, title="Variances")





final_rwm <- post_rwm[[1]]
for (i in 2:length(post_rwm)) {
  final_rwm <- rbind(final_rwm, post_rwm[[i]])
}


final_newkernel <- post_newkernel[[1]]
for (i in 2:length(post_newkernel)) {
  final_newkernel <- rbind(final_newkernel, post_newkernel[[i]])
}




#first individual posteriors
graphConvMC_new(post_rwm[[1]], title="EM")

graphConvMC_twokernels(final_rwm,final_rwm, title="EM")
graphConvMC_twokernels(final_new,final_new, title="EM")

graphConvMC_twokernels(final_rwm,final_newkernel, title="EM")
graphConvMC_twokernels(post_rwm[[1]],post_newkernel[[1]], title="EM")
graphConvMC_twokernels(post_rwm[[1]],post_rwm[[1]], title="EM")




# theo.onlypop<-saemix(saemix.model,saemix.data,saemix.options)

# saemix.fit<-saemix(saemix.model,saemix.data,saemix.options)
# plot(saemix.fit,plot.type="individual")

