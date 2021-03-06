setwd("/home/belhal.karimi/Desktop/Belhal/Dir2")
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
setwd("/home/belhal.karimi/Desktop/Belhal/mcmc_newkernel")
source('mcmc.R')



require(ggplot2)
require(gridExtra)
require(reshape2)

#####################################################################################
# Doc


data(cow.saemix)
# cow.saemix <- subset(cow.saemix, time!="1620" &time!="1260" &time!="900"&time!="720"&time!="540"&time!="1980")
cow.saemix_less <- cow.saemix[1:10,]
saemix.data<-saemixData(name.data=cow.saemix_less,header=TRUE,name.group=c("cow"), 
  name.predictors=c("time"),name.response=c("weight"), 
  name.covariates=c("birthyear","twin","birthrank"), 
  units=list(x="days",y="kg",covariates=c("yr","-","-")))



# saemix.data<-saemixData(name.data=theo.saemix,header=TRUE,sep=" ",na=NA, name.group=c("Id"),name.predictors=c("Dose","Time"),name.response=c("Concentration"),units=list(x="hr",y="mg/L",covariates=c("kg","-")), name.X="Time")
growthcow<-function(psi,id,xidep) {
# input:
#   psi : matrix of parameters (3 columns, a, b, k)
#   id : vector of indices 
#   xidep : dependent variables (same nb of rows as length of id)
# returns:
#   a vector of predictions of length equal to length of id
  x<-xidep[,1]
  a<-psi[id,1]
  b<-psi[id,2]
  k<-psi[id,3]
  f<-a*(1-b*exp(-k*x))
  return(f)
}
saemix.model<-saemixModel(model=growthcow,
  description="Exponential growth model", 
  psi0=matrix(c(700,0.9,0.02,0,0,0),ncol=3,byrow=TRUE, 
  dimnames=list(NULL,c("A","B","k"))),transform.par=c(1,1,1),fixed.estim=c(1,1,1), 
  covariate.model=matrix(c(0,0,0),ncol=3,byrow=TRUE), 
  covariance.model=matrix(c(1,0,0,0,1,0,0,0,1),ncol=3,byrow=TRUE), 
  omega.init=matrix(c(1,0,0,0,1,0,0,0,1),ncol=3,byrow=TRUE),error.model="constant")


indiv = 1
seed0 = 35644
replicate = 50
iter_mcmc = 100000
burn = 400


saemix.options_rwm<-list(seed=seed0,map=F,fim=F,ll.is=F, nb.chains = 1, nbiter.mcmc = c(iter_mcmc,iter_mcmc,iter_mcmc,0))
saemix.options_linear<-list(seed=seed0,map=F,fim=F,ll.is=F, nb.chains = 1, nbiter.mcmc = c(0,0,0,iter_mcmc))

#reference rwm
ref <- mcmc(saemix.model,saemix.data,saemix.options_rwm,iter_mcmc)
new<-mcmc(saemix.model,saemix.data,saemix.options_linear,iter_mcmc)






#expectations
expec_rwm <- ref$eta[[indiv]]
var_rwm <- ref$eta[[indiv]]

expec_rwm[,2:4] <- 0 
var_rwm[,2:4] <- 0


for (j in 1:replicate){
  print(j)
  saemix.options_rwm<-list(seed=j+seed0,map=F,fim=F,ll.is=F, nb.chains = 1, nbiter.mcmc = c(iter_mcmc,iter_mcmc,iter_mcmc,0))
  post_rwm<-mcmc(saemix.model,saemix.data,saemix.options_rwm,iter_mcmc)$eta
  # print(post_rwm[[indiv]][44,2:4])
  post_rwm[[indiv]]['individual'] <- j
  expec_rwm[,2:4] <- expec_rwm[,2:4] + post_rwm[[indiv]][,2:4]
  var_rwm[,2] <- var_rwm[,2] + (post_rwm[[indiv]][,2] - post_rwm[[indiv]][iter_mcmc,2])^2
  var_rwm[,3] <- var_rwm[,3] + (post_rwm[[indiv]][,3] - post_rwm[[indiv]][iter_mcmc,3])^2
  var_rwm[,4] <- var_rwm[,4] + (post_rwm[[indiv]][,4] - post_rwm[[indiv]][iter_mcmc,4])^2
}
expec_rwm[,2:4] <- expec_rwm[,2:4]/replicate
var_rwm[,2:4] <- var_rwm[,2:4]/replicate

# graphConvMC_twokernels(expec_rwm,expec_rwm, title="Expectations")
# graphConvMC_twokernels(var_rwm,var_rwm, title="Variances")



expec_new <- new$eta[[indiv]]
var_new <- new$eta[[indiv]]
dens <- new$densy[[indiv]]
denseta <- new$denseta[[indiv]]
expec_new[,2:4] <- 0 
dens[,2] <- 0 
denseta[,2] <- 0 
var_new[,2:4] <- 0
for (j in 1:replicate){
  print(j)
  saemix.options_newkernel<-list(seed=j+seed0,map=F,fim=F,ll.is=F, nb.chains = 1, nbiter.mcmc = c(0,0,0,iter_mcmc))
  post_newkernel<-mcmc(saemix.model,saemix.data,saemix.options_newkernel,iter_mcmc)$eta
  density<-mcmc(saemix.model,saemix.data,saemix.options_newkernel,iter_mcmc)$densy[[indiv]]
  density_eta<-mcmc(saemix.model,saemix.data,saemix.options_newkernel,iter_mcmc)$denseta[[indiv]]
  post_newkernel[[indiv]]['individual'] <- j
  expec_new[,2:4] <- expec_new[,2:4] + post_newkernel[[indiv]][,2:4]
  var_new[,2] <- var_new[,2] + (post_newkernel[[indiv]][,2]-post_newkernel[[indiv]][iter_mcmc,2])^2
  var_new[,3] <- var_new[,3] + (post_newkernel[[indiv]][,3]-post_newkernel[[indiv]][iter_mcmc,3])^2
  var_new[,4] <- var_new[,4] + (post_newkernel[[indiv]][,4]-post_newkernel[[indiv]][iter_mcmc,4])^2
  dens[,2] <- dens[,2] + density[,2]
  denseta[,2] <- denseta[,2] + density_eta[,2]
}
expec_new[,2:4] <- expec_new[,2:4]/replicate
var_new[,2:4] <- var_new[,2:4]/replicate
dens[,2] <- dens[,2]/replicate
denseta[,2] <- denseta[,2]/replicate

# graphConvMC_twokernels(expec_new,expec_new, title="Expectations")


Uy1 <- graphConvMC_twokernels(expec_rwm[,c(1,4,5)],expec_new[,c(1,4,5)], title="Expectations")
ggsave(plot = Uy1, file = paste("expec_cow.png"))

Uy2 <- graphConvMC_twokernels(dens,dens, title="density")
ggsave(plot = Uy2, file = paste("dens_cow.png"))


graphConvMC_twokernels(dens,dens, title="densy")

#target is N(0,1)
#proposal is N(0,.01)
