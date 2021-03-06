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
  
setwd("/Users/karimimohammedbelhal/Documents/GitHub/saem/new_kernel_saem")
source('newkernel_main.R')
source('main_new.R')
source('main_estep_new.R')
source('main_gd.R')
source('main_estep_gd.R')
source('main_estep_newkernel.R')
source('main_gd_mix.R')
source('main_estep_gd_mix.R')
source('main_estep_mix.R')
source('main_estep_newkernel.R')
source("mixtureFunctions.R")

library(sgd)
#####################################################################################
# Theophylline

# Data - changing gender to M/F
# theo.saemix<-read.table("data/theo.saemix.tab",header=T,na=".")
# theo.saemix$Sex<-ifelse(theo.saemix$Sex==1,"M","F")
# saemix.data<-saemixData(name.data=theo.saemix,header=TRUE,sep=" ",na=NA, name.group=c("Id"),name.predictors=c("Dose","Time"),name.response=c("Concentration"),name.covariates=c("Weight","Sex"),units=list(x="hr",y="mg/L",covariates=c("kg","-")), name.X="Time")


# Doc
data(theo.saemix)
theo.saemix_less <- theo.saemix[1:120,]
# theo.saemix<-read.table("data/theo.saemix.tab",header=T,na=".")
saemix.data<-saemixData(name.data=theo.saemix_less,header=TRUE,sep=" ",na=NA, name.group=c("Id"),name.predictors=c("Dose","Time"),name.response=c("Concentration"),name.covariates=c("Weight","Sex"),units=list(x="hr",y="mg/L",covariates=c("kg","-")), name.X="Time")

model1cpt<-function(psi,id,xidep) { 
	dose<-xidep[,1]
	tim<-xidep[,2]  
	ka<-psi[id,1]
	V<-psi[id,2]
	k<-psi[id,3]
	CL<-k*V
	ypred<-dose*ka/(V*(ka-k))*(exp(-k*tim)-exp(-ka*tim))
	return(ypred)
}
# Default model, no covariate
saemix.model<-saemixModel(model=model1cpt,description="One-compartment model with first-order absorption"
  ,psi0=matrix(c(1.,20,0.5,0.1,0,-0.01),ncol=3,byrow=TRUE, dimnames=list(NULL, c("ka","V","CL"))),transform.par=c(1,1,1))

K1 = 100
K2 = 50
iterations = 1:(K1+K2+1)
gd_step = 0.01


#RWM
options<-list(seed=395246,map=F,fim=F,ll.is=F,nb.chains = 1, nbiter.mcmc = c(2,2,2,0), nbiter.saemix = c(K1,K2))
theo_ref<-data.frame(saemix_new(saemix.model,saemix.data,options))
theo_ref <- cbind(iterations, theo_ref)


ref <- theo_ref[250,]
#ref (map always)
options.new<-list(seed=395246,map=F,fim=F,ll.is=F,nb.chains = 1, nbiter.mcmc = c(1,0,0,5),nbiter.saemix = c(K1,K2))
theo_new_ref<-data.frame(saemix_new(saemix.model,saemix.data,options.new))
theo_new_ref <- cbind(iterations, theo_new_ref)


new <- theo_new_ref[(K1+K2+1),]


# #MAP once and  NO GD
# options.nogd<-list(seed=39546,map=F,fim=F,ll.is=F,nb.chains = 1, nbiter.mcmc = c(1,0,0,5),nbiter.saemix = c(K1,K2),step.gd = 0)
# theo_nogd<-data.frame(saemix_gd(saemix.model,saemix.data,options.nogd))
# theo_nogd <- cbind(iterations, theo_nogd)


# #MAP once and GD
# options.gd<-list(seed=39546,map=F,fim=F,ll.is=F,nb.chains = 1, nbiter.mcmc = c(1,0,0,5),nbiter.saemix = c(K1,K2),step.gd=gd_step)
# theo_gd<-data.frame(saemix_gd(saemix.model,saemix.data,options.gd))
# theo_gd <- cbind(iterations, theo_gd)

#mix (RWM and MAP new kernel for liste of saem iterations)
# options.mix<-list(seed=395246,map=F,fim=F,ll.is=F,nb.chains = 1, nbiter.mcmc = c(2,2,2,4,0),nbiter.saemix = c(K1,K2),step.gd=gd_step,map.range=3)
# theo_mix<-data.frame(saemix_gd_mix(saemix.model,saemix.data,options.mix))
# theo_mix <- cbind(iterations, theo_mix)


# options.foce<-list(seed=39546,map=F,fim=F,ll.is=F,nb.chains = 1, nbiter.mcmc = c(2,2,2,0,4),nbiter.saemix = c(K1,K2),step.gd=gd_step,map.range=3)
# theo_foce<-data.frame(saemix_gd_mix(saemix.model,saemix.data,options.foce))
# theo_foce <- cbind(iterations, theo_foce)

graphConvMC_twokernels(theo_ref,theo_ref, title="new kernel")

graphConvMC_twokernels(theo_ref,theo_mix, title="new kernel")


#RWM vs always MAP (ref)
graphConvMC_twokernels(theo_ref,theo_new_ref, title="new kernel")
#ref vs map once no gd
graphConvMC_twokernels(theo_new_ref,theo_nogd, title="ref vs NOGD")
#map once no gd vs map once and gd
graphConvMC_twokernels(theo_nogd,theo_gd, title="NO GD vs GD")
#ref vs map once gd
graphConvMC_twokernels(theo_new_ref,theo_gd, title="ref vs GD")
#RWM vs GD
graphConvMC_twokernels(theo_ref,theo_gd, title="ref vs GD")



# Dimensions
N <- 1e5  # number of data points
d <- 1e2  # number of features

# Generate data.
X <- matrix(rnorm(N*d), ncol=d)
theta <- rep(5, d+1)
eps <- rnorm(N)
y <- cbind(1, X) %*% theta + eps
dat <- data.frame(y=y, x=X)

sgd.theta <- sgd(y ~ ., data=dat, model="lm")