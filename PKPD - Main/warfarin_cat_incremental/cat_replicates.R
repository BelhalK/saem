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
setwd("/Users/karimimohammedbelhal/Documents/GitHub/saem/warfarin_cat")
source('main_cat2.R')
source('main_estep_cat2.R')
source('main_mstep_cat.R') 
source('func_aux_cat.R') 
source('SaemixObject_cat.R') 
source('main_initialiseMainAlgo_cat.R') 
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


# cat_data.saemix<-read.table("data/categorical1_data.txt",header=T,na=".")
# cat_data.saemix<-read.table("data/categorical1_data_less.txt",header=T,na=".")
# cat_data.saemix<-read.table("data/categorical1_data_less2.txt",header=T,na=".")
# cat_data.saemix<-read.table("/Users/karimimohammedbelhal/Documents/GitHub/saem/warfarin_cat/data/cat.csv", header=T, sep=",")
cat_data.saemix<-read.table("/Users/karimimohammedbelhal/Documents/GitHub/saem/warfarin_cat/data/cat1.csv", header=T, sep=",")
saemix.data<-saemixData(name.data=cat_data.saemix,header=TRUE,sep=" ",na=NA, name.group=c("id"),name.response=c("y"),name.predictors=c("y"), name.X=c("time"))
# saemix.data<-saemixData(name.data=cat_data.saemix,header=TRUE,sep=" ",na=NA, name.group=c("ID"),name.response=c("Y"),name.predictors=c("Y"), name.X=c("TIME"))



cat_data.model<-function(psi,id,xidep) {
level<-xidep[,1]

th1 <- psi[id,1]
th2 <- psi[id,2]
th3 <- psi[id,3]

P0 <- 1/(1+exp(-th1))
Pcum1 <- 1/(1+exp(-th1-th2))
Pcum2 <- 1/(1+exp(-th1-th2-th3))


P1 <- Pcum1 - P0
P2 <- Pcum2 - Pcum1
P3 <- 1 - Pcum2

P.obs = (level==0)*P0+(level==1)*P1+(level==2)*P2+(level==3)*P3

return(P.obs)
}


saemix.model<-saemixModel(model=cat_data.model,description="cat model",   
  psi0=matrix(c(0.5,0.5,0.5),ncol=3,byrow=TRUE,dimnames=list(NULL,   
  c("th1","th2","th3"))),covariate.model=matrix(c(0,0,0),ncol=3,byrow=TRUE), 
  transform.par=c(0,1,1),covariance.model=matrix(c(1,0,0,0,0,0,0,0,0),ncol=3, 
  byrow=TRUE),error.model="constant")


saemix.options_rwm<-list(seed=39546,map=F,fim=F,ll.is=F, nb.chains = 1, nbiter.mcmc = c(iter_mcmc,0,0,0))
saemix.foce<-list(seed=39546,map=F,fim=F,ll.is=F, nb.chains = 1, nbiter.mcmc = c(1,0,0,iter_mcmc))


# post_rwm<-saemix_post_cat(saemix.model,saemix.data,saemix.options_rwm)$post_rwm
# post_foce<-saemix_post_cat(saemix.model,saemix.data,saemix.foce)$post_newkernel


K1 = 300
K2 = 50

iterations = 1:(K1+K2+1)
gd_step = 0.01
end = K1+K2
seed0 = 444

#RWM
theo_ref <- NULL
options<-list(seed=seed0,map=F,fim=F,ll.is=F,nb.chains = 1, nbiter.mcmc = c(2,2,2,0), nbiter.saemix = c(K1,K2),displayProgress=FALSE, map.range=c(0),nbiter.sa=0)
theo_ref<-data.frame(saemix_cat2(saemix.model,saemix.data,options))
theo_ref <- cbind(iterations, theo_ref)


graphConvMC_saem(theo_ref, title="new kernel")



theo_ref[end,]

#MAP then RWM
cat_saem <- NULL
options.cat<-list(seed=seed0,map=F,fim=F,ll.is=F,nb.chains = 1, nbiter.mcmc = c(2,2,2,6),nbiter.saemix = c(K1,K2),displayProgress=FALSE, map.range=c(1:200))
cat_saem<-data.frame(saemix_cat2(saemix.model,saemix.data,options.cat))
cat_saem <- cbind(iterations, cat_saem)

graphConvMC2_saem(theo_ref,cat_saem, title="new kernel")


cat_saem[end,]



replicate = 20
seed0 = 39546

#RWM
final_rwm <- 0
final_mix <- 0
for (j in 1:replicate){

  model2 <- inlineModel("

              [LONGITUDINAL]
              input = {th1, th2, th3}

              EQUATION:
              lgp0 = th1
              lgp1 = lgp0 + th2
              lgp2 = lgp1 + th3

              DEFINITION:
              level = { type = categorical,  categories = {0, 1, 2, 3},
              logit(P(level<=0)) = th1
              logit(P(level<=1)) = th1 + th2
              logit(P(level<=2)) = th1 + th2 + th3
              }

              [INDIVIDUAL]
              input={th1_pop, o_th1,th2_pop, o_th2,th3_pop, o_th3}
                      

              DEFINITION:
              th1  ={distribution=normal, prediction=th1_pop,  sd=o_th1}
              th2  ={distribution=lognormal, prediction=th2_pop,  sd=o_th2}
              th3  ={distribution=lognormal, prediction=th3_pop,  sd=o_th3}
                      
                      ")

p <- c(th1_pop=3, o_th1=0.8,
       th2_pop=2, o_th2=0.1, 
       th3_pop=1, o_th3=0.1)



  y1 <- list(name='level', time=seq(1,to=50,by=5))



  res2a2 <- simulx(model = model2,
                 parameter = p,
                 group = list(size=200, level="individual"),
                 output = y1)
  writeDatamlx(res2a2, result.file = "/Users/karimimohammedbelhal/Documents/GitHub/saem/warfarin_cat/data/cat_rep.csv")
  cat_data.saemix<-read.table("/Users/karimimohammedbelhal/Documents/GitHub/saem/warfarin_cat/data/cat_rep.csv", header=T, sep=",")
  saemix.data<-saemixData(name.data=cat_data.saemix,header=TRUE,sep=" ",na=NA, name.group=c("id"),name.response=c("y"),name.predictors=c("y"), name.X=c("time"))


  options<-list(seed=seed0,map=F,fim=F,ll.is=F,nb.chains = 1, nbiter.mcmc = c(2,2,2,0), nbiter.saemix = c(K1,K2),displayProgress=FALSE, map.range=c(0),nbiter.sa=0)
  theo_ref<-data.frame(saemix_cat2(saemix.model,saemix.data,options))
  theo_ref <- cbind(iterations, theo_ref)
  theo_ref['individual'] <- j
  final_rwm <- rbind(final_rwm,theo_ref)

  print(j)

  options.cat<-list(seed=seed0,map=F,fim=F,ll.is=F,nb.chains = 1, nbiter.mcmc = c(2,2,2,6),nbiter.saemix = c(K1,K2),displayProgress=FALSE, map.range=c(1:300))
  theo_mix<-data.frame(saemix_cat2(saemix.model,saemix.data,options.cat))
  theo_mix <- cbind(iterations, theo_mix)
  theo_mix['individual'] <- j
  final_mix <- rbind(final_mix,theo_mix)
}


names(final_rwm)[1]<-paste("time")
names(final_rwm)[6]<-paste("id")
final_rwm1 <- final_rwm[c(6,1,2)]
final_rwm2 <- final_rwm[c(6,1,3)]
final_rwm3 <- final_rwm[c(6,1,4)]
final_rwm4 <- final_rwm[c(6,1,5)]


prctilemlx(final_rwm4[-1,],band = list(number = 8, level = 80)) + ggtitle("RWM")

#mix (RWM and MAP new kernel for liste of saem iterations)

# for (j in 3:replicate){
#   print(j)
#   options.cat<-list(seed=j*seed0,map=F,fim=F,ll.is=F,nb.chains = 1, nbiter.mcmc = c(2,2,2,6),nbiter.saemix = c(K1,K2),displayProgress=FALSE, map.range=c(1:200))
#   theo_mix<-data.frame(saemix_cat2(saemix.model,saemix.data,options.cat))
#   theo_mix <- cbind(iterations, theo_mix)
#   theo_mix['individual'] <- j
#   final_mix <- rbind(final_mix,theo_mix)
# }


names(final_mix)[1]<-paste("time")
names(final_mix)[6]<-paste("id")
final_mix1 <- final_mix[c(6,1,2)]
final_mix2 <- final_mix[c(6,1,3)]
final_mix3 <- final_mix[c(6,1,4)]
final_mix4 <- final_mix[c(6,1,5)]




final_rwm1['group'] <- 1
final_mix1['group'] <- 2
final_mix1$id <- final_mix1$id +1


final1 <- rbind(final_rwm1[-1,],final_mix1[-1,])
labels <- c("ref","new")
# prctilemlx(final1[c(1,4,2,3)], band = list(number = 4, level = 80),group='group', label = labels) 
# plt1 <- prctilemlx(final1, band = list(number = 4, level = 80),group='group', label = labels) 

# rownames(final1) <- 1:nrow(final1)

plot.S1 <- plot.prediction.intervals(final1[c(1,4,2,3)], 
                                    labels       = labels, 
                                    legend.title = "algos",
                                    colors       = c('red', '#c17b01'))
plot.S <- plot.S1  + ylab("th1")+ theme(legend.position=c(0.9,0.8))+ theme_bw()
# print(plot.S1)



final_rwm2['group'] <- 1
final_mix2['group'] <- 2
final_mix2$id <- final_mix2$id +1
final2 <- rbind(final_rwm2[-1,],final_mix2[-1,])
labels <- c("ref","new")
# prctilemlx(final2[c(1,4,2,3)], band = list(number = 4, level = 80),group='group', label = labels) 
# plt1 <- prctilemlx(final1, band = list(number = 4, level = 80),group='group', label = labels) 

# rownames(final1) <- 1:nrow(final1)

plot.S2 <- plot.prediction.intervals(final2[c(1,4,2,3)], 
                                    labels       = labels, 
                                    legend.title = "algos",
                                    colors       = c('red', '#c17b01'))
plot.S2 <- plot.S2  + ylab("th2")+ theme(legend.position=c(0.9,0.8))+ theme_bw()


final_rwm3['group'] <- 1
final_mix3['group'] <- 2
final_mix3$id <- final_mix3$id +1


final3 <- rbind(final_rwm3[-1,],final_mix3[-1,])
labels <- c("ref","new")
# prctilemlx(final3[c(1,4,2,3)], band = list(number = 4, level = 80),group='group', label = labels) 
# plt1 <- prctilemlx(final1, band = list(number = 4, level = 80),group='group', label = labels) 

# rownames(final1) <- 1:nrow(final1)

plot.S3 <- plot.prediction.intervals(final3[c(1,4,2,3)], 
                                    labels       = labels, 
                                    legend.title = "algos",
                                    colors       = c('red', '#c17b01'))
plot.S3 <- plot.S3  + ylab("th3")+ theme(legend.position=c(0.9,0.8))+ theme_bw()




final_rwm4['group'] <- 1
final_mix4['group'] <- 2
final_mix4$id <- final_mix4$id +1


final4 <- rbind(final_rwm4[-1,],final_mix4[-1,])
labels <- c("ref","new")
# prctilemlx(final4[c(1,4,2,3)], band = list(number = 4, level = 80),group='group', label = labels) 
# plt1 <- prctilemlx(final1, band = list(number = 4, level = 80),group='group', label = labels) 

# rownames(final1) <- 1:nrow(final1)

plot.S4 <- plot.prediction.intervals(final4[c(1,4,2,3)], 
                                    labels       = labels, 
                                    legend.title = "algos",
                                    colors       = c('red', '#c17b01'))
plot.S4 <- plot.S4  + ylab("w1")+ theme(legend.position=c(0.9,0.8))+ theme_bw()





grid.arrange(plot.S, plot.S2,plot.S3,plot.S4,ncol=3)





plot.prediction.intervals <- function(r, plot.median=TRUE, level=1, labels=NULL, 
                                      legend.title=NULL, colors=NULL) {
  P <- prctilemlx(r, number=1, level=level, plot=FALSE)
  if (is.null(labels))  labels <- levels(r$group)
  if (is.null(legend.title))  legend.title <- "group"
  names(P$y)[2:4] <- c("p.min","p50","p.max")
  pp <- ggplot(data=P$y)+ylab(NULL)+ 
    geom_ribbon(aes(x=time,ymin=p.min, ymax=p.max,fill=group),alpha=.5) 
  if (plot.median)
    pp <- pp + geom_line(aes(x=time,y=p50,colour=group))
  
  if (is.null(colors)) {
    pp <- pp + scale_fill_discrete(name=legend.title,
                                   breaks=levels(r$group),
                                   labels=labels)
    pp <- pp + scale_colour_discrete(name=legend.title,
                                     breaks=levels(r$group),
                                     labels=labels, 
                                     guide=FALSE)
  } else {
    pp <- pp + scale_fill_manual(name=legend.title,
                                 breaks=levels(r$group),
                                 labels=labels,
                                 values=colors)
    pp <- pp + scale_colour_manual(name=legend.title,
                                   breaks=levels(r$group),
                                   labels=labels,
                                   guide=FALSE,values=colors)
  }  
  return(pp)
}





# index = 1
# graphConvMC_twokernels(post_rwm[[index]],post_rwm[[index]], title="rwm vs foce")
# graphConvMC_twokernels(post_rwm[[index]],post_foce[[index]], title="rwm vs foce")


# final_rwm <- post_rwm[[1]]
# for (i in 2:length(post_rwm)) {
#   final_rwm <- rbind(final_rwm, post_rwm[[i]])
# }


# final_foce <- post_foce[[1]]
# for (i in 2:length(post_foce)) {
#   final_foce <- rbind(final_foce, post_foce[[i]])
# }



# graphConvMC_twokernels(final_rwm,final_rwm, title="EM")
# graphConvMC_twokernels(final_rwm,final_foce, title="EM")


# #Autocorrelation
# rwm.obj <- as.mcmc(post_rwm[[1]])
# corr_rwm <- autocorr(rwm.obj[,2])
# autocorr.plot(rwm.obj[,2])

# foce.obj <- as.mcmc(post_foce[[1]])
# corr_foce <- autocorr(foce.obj[,2])
# autocorr.plot(foce.obj[,2])


# #MSJD
# <mssd(post_rwm[[index]][,2])
# mssd(post_foce[[index]][,2])



