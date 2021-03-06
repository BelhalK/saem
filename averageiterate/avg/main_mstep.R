################## Stochastic approximation - compute sufficient statistics (M-step) #####################
mstep<-function(kiter, Uargs, Dargs, opt, structural.model, DYF, phiM, varList, phi, betas, suffStat,saemixObject,newsuffStat) {
	# M-step - stochastic approximation
	# Input: kiter, Uargs, structural.model, DYF, phiM (unchanged)
	# Output: varList, phi, betas, suffStat (changed)
	#					mean.phi (created)
	# Update variances - TODO - check if here or elsewhere
	saemix.options <- saemixObject["options"]
	oldsuffStat<-newsuffStat

	newvarList<-varList
    newphi<-phi
    newbetas<-betas

	nb.etas<-length(varList$ind.eta)
	domega<-cutoff(mydiag(varList$omega[varList$ind.eta,varList$ind.eta]),.Machine$double.eps)
	omega.eta<-varList$omega[varList$ind.eta,varList$ind.eta,drop=FALSE]
	omega.eta<-omega.eta-mydiag(mydiag(varList$omega[varList$ind.eta,varList$ind.eta]))+mydiag(domega)
	#  print(varList$omega.eta)
	chol.omega<-try(chol(omega.eta))
	d1.omega<-Uargs$LCOV[,varList$ind.eta]%*%solve(omega.eta)
	d2.omega<-d1.omega%*%t(Uargs$LCOV[,varList$ind.eta])
	comega<-Uargs$COV2*d2.omega

	newdomega<-cutoff(mydiag(newvarList$omega[newvarList$ind.eta,newvarList$ind.eta]),.Machine$double.eps)
	newomega.eta<-newvarList$omega[newvarList$ind.eta,newvarList$ind.eta,drop=FALSE]
	newomega.eta<-newomega.eta-mydiag(mydiag(newvarList$omega[varList$ind.eta,varList$ind.eta]))+mydiag(newdomega)
	#  print(varList$omega.eta)
	newchol.omega<-try(chol(newomega.eta))
	newd1.omega<-Uargs$LCOV[,newvarList$ind.eta]%*%solve(newomega.eta)
	newd2.omega<-newd1.omega%*%t(Uargs$LCOV[,newvarList$ind.eta])
	newcomega<-Uargs$COV2*newd2.omega


	psiM<-transphi(phiM,Dargs$transform.par)
	fpred<-structural.model(psiM, Dargs$IdM, Dargs$XM)
	if(Dargs$error.model=="exponential")
		fpred<-log(cutoff(fpred))
	ff<-matrix(fpred,nrow=Dargs$nobs,ncol=Uargs$nchains)
	for(k in 1:Uargs$nchains) phi[,,k]<-phiM[((k-1)*Dargs$N+1):(k*Dargs$N),]
	# overall speed similar
	#    phi<-aperm(array(phiM,c(N,nchains,3)),c(1,3,2))
	stat1<-apply(phi[,varList$ind.eta,,drop=FALSE],c(1,2),sum) # sum on columns ind.eta of phi, across 3rd dimension
	stat2<-matrix(data=0,nrow=nb.etas,ncol=nb.etas)
	stat3<-apply(phi**2,c(1,2),sum) #  sum on phi**2, across 3rd dimension
	statr<-0
	for(k in 1:Uargs$nchains) {
		phik<-phi[,varList$ind.eta,k]
		stat2<-stat2+t(phik)%*%phik
		fk<-ff[,k]
		if(!is.na(match(Dargs$error.model,c("constant","exponential"))))
			resk<-sum((Dargs$yobs-fk)**2) else {
				if(Dargs$error.model=="proportional")
					resk<-sum((Dargs$yobs-fk)**2/cutoff(fk**2,.Machine$double.eps)) else resk<-0
			}
		statr<-statr+resk
	}

	
	# Update sufficient statistics
	suffStat$statphi1<-suffStat$statphi1+opt$stepsize[kiter]*(stat1/Uargs$nchains-suffStat$statphi1)
	suffStat$statphi2<-suffStat$statphi2+opt$stepsize[kiter]*(stat2/Uargs$nchains-suffStat$statphi2)
	suffStat$statphi3<-suffStat$statphi3+opt$stepsize[kiter]*(stat3/Uargs$nchains-suffStat$statphi3)
	suffStat$statrese<-suffStat$statrese+opt$stepsize[kiter]*(statr/Uargs$nchains-suffStat$statrese)

	if(saemix.options$avg==1){
		if (kiter>saemix.options$nbiter.saemix[1]){
			q <- kiter-saemix.options$nbiter.saemix[1]
			newsuffStat$statphi1<-(q-1)/q*oldsuffStat$statphi1 + 1/q*suffStat$statphi1
			newsuffStat$statphi2<-(q-1)/q*oldsuffStat$statphi2 + 1/q*suffStat$statphi2
			newsuffStat$statphi3<-(q-1)/q*oldsuffStat$statphi3 + 1/q*suffStat$statphi3
			newsuffStat$statrese<-(q-1)/q*oldsuffStat$statrese + 1/q*suffStat$statrese
		} else{
			newsuffStat$statphi1<-suffStat$statphi1
			newsuffStat$statphi2<-suffStat$statphi2
			newsuffStat$statphi3<-suffStat$statphi3
			newsuffStat$statrese<-suffStat$statrese
		} 
	}else{
			newsuffStat$statphi1<-suffStat$statphi1
			newsuffStat$statphi2<-suffStat$statphi2
			newsuffStat$statphi3<-suffStat$statphi3
			newsuffStat$statrese<-suffStat$statrese
		}

	############# Maximisation
	##### fixed effects
	if (opt$flag.fmin && kiter>=opt$nbiter.sa) {
		temp<-d1.omega[Uargs$ind.fix11,]*(t(Uargs$COV1)%*%(suffStat$statphi1-Uargs$dstatCOV[,varList$ind.eta]))
		betas[Uargs$ind.fix11]<-solve(comega[Uargs$ind.fix11,Uargs$ind.fix11],rowSums(temp)) 
		# ECO TODO: utiliser optimise dans le cas de la dimension 1
		if(Dargs$type=="structural"){
			beta0<-optim(par=betas[Uargs$ind.fix10],fn=compute.Uy_c,phiM=phiM,pres=varList$pres,args=Uargs,Dargs=Dargs,DYF=DYF,control=list(maxit=opt$maxim.maxiter))$par # else
		} else {
			beta0<-optim(par=betas[Uargs$ind.fix10],fn=compute.Uy_d,phiM=phiM,args=Uargs,Dargs=Dargs,DYF=DYF,control=list(maxit=opt$maxim.maxiter))$par
		}
		betas[Uargs$ind.fix10]<-betas[Uargs$ind.fix10]+opt$stepsize[kiter]*(beta0-betas[Uargs$ind.fix10])
	} else {
		temp<-d1.omega[Uargs$ind.fix1,]*(t(Uargs$COV1)%*%(suffStat$statphi1-Uargs$dstatCOV[,varList$ind.eta]))
		newtemp<-newd1.omega[Uargs$ind.fix1,]*(t(Uargs$COV1)%*%(newsuffStat$statphi1-Uargs$dstatCOV[,varList$ind.eta]))
		betas[Uargs$ind.fix1]<-solve(comega[Uargs$ind.fix1,Uargs$ind.fix1],rowSums(temp)) 
		newbetas[Uargs$ind.fix1]<-solve(newcomega[Uargs$ind.fix1,Uargs$ind.fix1],rowSums(newtemp)) 
	}
	
	varList$MCOV[Uargs$j.covariate]<-betas
	mean.phi<-Uargs$COV %*% varList$MCOV
	e1.phi<-mean.phi[,varList$ind.eta,drop=FALSE]

	newvarList$MCOV[Uargs$j.covariate]<-newbetas
	newmean.phi<-Uargs$COV %*% newvarList$MCOV
	newe1.phi<-newmean.phi[,newvarList$ind.eta,drop=FALSE]

	# Covariance of the random effects
	omega.full<-matrix(data=0,nrow=Uargs$nb.parameters,ncol=Uargs$nb.parameters)
	omega.full[varList$ind.eta,varList$ind.eta]<-suffStat$statphi2/Dargs$N + t(e1.phi)%*%e1.phi/Dargs$N - t(suffStat$statphi1)%*%e1.phi/Dargs$N - t(e1.phi)%*%suffStat$statphi1/Dargs$N
	varList$omega[Uargs$indest.omega]<-omega.full[Uargs$indest.omega]

	
	newomega.full<-matrix(data=0,nrow=Uargs$nb.parameters,ncol=Uargs$nb.parameters)
	newomega.full[newvarList$ind.eta,newvarList$ind.eta]<-newsuffStat$statphi2/Dargs$N + t(newe1.phi)%*%newe1.phi/Dargs$N - t(newsuffStat$statphi1)%*%newe1.phi/Dargs$N - t(newe1.phi)%*%newsuffStat$statphi1/Dargs$N
	newvarList$omega[Uargs$indest.omega]<-newomega.full[Uargs$indest.omega]
	
	# Simulated annealing (applied to the diagonal elements of omega)
	if(opt$av==0){
		if (kiter<=opt$nbiter.sa) {
			diag.omega.full<-mydiag(omega.full)
			vec1<-diag.omega.full[Uargs$i1.omega2]
			vec2<-varList$diag.omega[Uargs$i1.omega2]*opt$alpha1.sa
			idx<-as.integer(vec1<vec2)
			varList$diag.omega[Uargs$i1.omega2]<-idx*vec2+(1-idx)*vec1
			varList$diag.omega[Uargs$i0.omega2]<-varList$diag.omega[Uargs$i0.omega2]*opt$alpha0.sa
		} else {
			varList$diag.omega<-mydiag(varList$omega)
			newvarList$diag.omega<-mydiag(newvarList$omega)
		}
		varList$omega<-varList$omega-mydiag(mydiag(varList$omega))+mydiag(varList$diag.omega)
		newvarList$omega<-newvarList$omega-mydiag(mydiag(newvarList$omega))+mydiag(newvarList$diag.omega)
	}

	#Decreasing omega for param without variability
	if(opt$flag.fmin && opt$av==1){
		if (kiter<=opt$nbiter.sa) {
			diag.omega.full<-mydiag(omega.full)
			vec1<-diag.omega.full[Uargs$i1.omega2]
			varList$diag.omega[Uargs$i1.omega2]<-vec1
			varList$omega<-varList$omega-mydiag(mydiag(varList$omega))+mydiag(varList$diag.omega)
			varList$diag.omega[Uargs$i0.omega2]<-varList$diag.omega[Uargs$i0.omega2]*opt$alpha0.sa
		} else {
			varList$diag.omega<-mydiag(varList$omega)
		}
	}

	# Residual error
	if (Dargs$error.model=="constant" | Dargs$error.model=="exponential") {
		sig2<-suffStat$statrese/Dargs$nobs
		varList$pres[1]<-sqrt(sig2)

		newsig2<-newsuffStat$statrese/Dargs$nobs
		newvarList$pres[1]<-sqrt(newsig2)
	}
	if (Dargs$error.model=="proportional") {
		sig2<-suffStat$statrese/Dargs$nobs
		varList$pres[2]<-sqrt(sig2)
	}
	if (Dargs$error.model=="combined") {
		# ECO TODO: check and secure (when fpred<0 => NaN, & what happens if bres<0 ???)
		ABres<-optim(par=varList$pres,fn=ssq,y=Dargs$yM,f=fpred)$par
		if (kiter<=opt$nbiter.saemix[1]) {
			varList$pres[1]<-max(varList$pres[1]*opt$alpha1.sa,ABres[1])
			varList$pres[2]<-max(varList$pres[2]*opt$alpha1.sa,ABres[2])
		} else {
			varList$pres[1]<-varList$pres[1]+opt$stepsize[kiter]*(ABres[1]-varList$pres[1])
			varList$pres[2]<-varList$pres[2]+opt$stepsize[kiter]*(ABres[2]-varList$pres[2])
		}
	}
	return(list(varList=varList,mean.phi=mean.phi,phi=phi,betas=betas,suffStat=suffStat,newvarList=newvarList,newmean.phi=newmean.phi,newphi=newphi,newbetas=newbetas,newsuffStat=newsuffStat))
}
