require(ggplot2)
require(gridExtra)
require(reshape2)

mixt.simulate <-function(n,weight,mu,sigma)
{
  G <- length(mu)
  Z <- sample(1:G, n, prob=weight, replace=T)
  x<-NULL
  for (g in 1:G)
  {
    x<-c(x,rnorm(length(which(Z==g)),mu[g],sigma[g]))
  }
  return(x)
}



#-------------------------------------

mixt.em <- function(x, theta0, K)
{
  G<-length(mu)
  col.names <- c("iteration", paste0("p",1:G), paste0("mu",1:G), paste0("sigma",1:G))
  
  theta.est <- matrix(NA,K+1,3*G+1)
  theta.est[1,] <- c(0, theta0$p, theta0$mu, theta0$sigma)
  
  theta<-theta0
  for (k in 1:K)
  {
    s<-step.E(x,theta)
    theta<-step.M(s,n)
    theta.est[k+1,] <- c(k, theta$p, theta$mu, theta$sigma)
  }
  
  df <- as.data.frame(theta.est)
  names(df) <- col.names
  return(df)
}

mixt.iem <- function(x, theta0, K,nbr)
{
  G<-length(mu)
  col.names <- c("iteration", paste0("p",1:G), paste0("mu",1:G), paste0("sigma",1:G))
  
  theta.est <- matrix(NA,K+1,3*G+1)
  theta.est[1,] <- c(0, theta0$p, theta0$mu, theta0$sigma)
  tau <- compute.tau(x,theta0)
  theta<-theta0
  tau.old <- compute.tau(x[1],theta0)
  s <- compute.stat_iem(x,tau, tau.old,1)

  l <- rep(sample(1:n,n), K/n)
  i <- 1:nbr
  for (k in 1:K)
  {

    if (k%%(n/nbr) == 1)
    { 
      # l<-sample(1:n,n)
      # l<-1:n
      i<-1:nbr
    }
    # tau.new <- compute.tau(x[i],theta)
    # s <- compute.stat_iem(x,tau, tau.new, i)
    tau[l[i],] <- compute.tau(x[l[i]],theta)
    s <- compute.stat(x,tau)
    theta<-step.M(s,n)
    theta.est[k+1,] <- c(k, theta$p, theta$mu, theta$sigma)
    i = i+nbr
  }
  
  df <- as.data.frame(theta.est)
  names(df) <- col.names
  return(df)
}


# mixt.oem <- function(x, theta0, K,nbr)
# {
#   G<-length(mu)
#   kiter = 1:K
#   rho = 1/(kiter+1)
#   col.names <- c("iteration", paste0("p",1:G), paste0("mu",1:G), paste0("sigma",1:G))
  
#   theta.est <- matrix(NA,K+1,3*G+1)
#   theta.est[1,] <- c(0, theta0$p, theta0$mu, theta0$sigma)
#   theta<-theta0
  
#   tau<-compute.tau(x,theta)
#   s<-compute.stat(x,tau)
#   s.old <- s
#   theta<-step.M(s,n)
#   n<-length(x)
#   l <- NULL
#   l <- rep(sample(1:n,n), K/n)
#   i <- 1:nbr
#   for (k in 1:K)
#   {
#     if (k%%(n/nbr) == 1)
#     { 
#       i<-1:nbr
#     }
#     tau.new <- compute.tau(x[l[i]],theta)
#     s <- compute.stat_oem(x,tau,s.old, tau.new, l[i],rho[k])
#     s.old <- s
#     i <- i+nbr
#     theta<-step.M(s,n)
#     theta.est[k+1,] <- c(k, theta$p, theta$mu, theta$sigma)
#   }
  
#   df <- as.data.frame(theta.est)
#   names(df) <- col.names
#   return(df)
# }

# mixt.oemvr <- function(x, theta0, K,nbr,rho)
# {
#    G<-length(mu)
#   col.names <- c("iteration", paste0("p",1:G), paste0("mu",1:G), paste0("sigma",1:G))
#   rho = 0.0001
#   theta.est <- matrix(NA,K+1,3*G+1)
#   theta.est[1,] <- c(0, theta0$p, theta0$mu, theta0$sigma)
#   tau <- compute.tau(x,theta0)
#   tau.old.init <- tau[1,]
#   theta<-theta0
#   s<-compute.stat(x,tau)
#   s.old <- s
#   s.old.init <- s
#   l <- rep(sample(1:n,n), K/n)
#   i <- 1:nbr
#   for (k in 1:K)
#   {
#     if (k%%(n/nbr) == 1)
#     { 
#       i<-1:nbr
#       tau.old.init <- compute.tau(x[i],theta)
#       s.old.init <- compute.stat(x,tau)
#     }
#     tau.new <- compute.tau(x[i],theta)
#     s <- compute.stat_oemvr(x,tau, tau.new,s.old,s.old.init,tau.old.init, i,rho)
#     s.old <- s
#     i <- i+nbr
#     theta<-step.M(s,n)
#     theta.est[k+1,] <- c(k, theta$p, theta$mu, theta$sigma)
#   }
  
#   df <- as.data.frame(theta.est)
#   names(df) <- col.names
#   return(df)
# }



mixt.oem <- function(x, theta0, K,nbr,rho)
{
   G<-length(mu)
  col.names <- c("iteration", paste0("p",1:G), paste0("mu",1:G), paste0("sigma",1:G))
  theta.est <- matrix(NA,K+1,3*G+1)
  theta.est[1,] <- c(0, theta0$p, theta0$mu, theta0$sigma)
  theta<-theta0

  #Init
  tau <- compute.tau(x,theta)
  s<-compute.stat(x,tau)
  
  l <- NULL
  l <- rep(sample(1:n,n), K/n)
  i <- 1:nbr
  
  for (k in 1:K)
  {
    if (k%%(n/nbr) == 1)
    { 
      i<-1:nbr
    }

    tau.indiv.new <- compute.tau(x[l[i]],theta)

    #Update statistic
    s$s1 <- s$s1 + rho[k]*(tau.indiv.new  - s$s1)
    s$s2 <- s$s2 + rho[k]*(x[l[i]]*tau.indiv.new  - s$s2)
    s$s3 <- s$s3 + rho[k]*(x[l[i]]^2*tau.indiv.new  - s$s3)
    theta <- step.M(s,n)
    theta.est[k+1,] <- c(k, theta$p, theta$mu, theta$sigma)

    #Update index
    i <- i+nbr

  }
  
  df <- as.data.frame(theta.est)
  names(df) <- col.names
  return(df)
}

mixt.oemvr <- function(x, theta0, K,nbr,rho)
{
   G<-length(mu)
  col.names <- c("iteration", paste0("p",1:G), paste0("mu",1:G), paste0("sigma",1:G))
  theta.est <- matrix(NA,K+1,3*G+1)
  theta.est[1,] <- c(0, theta0$p, theta0$mu, theta0$sigma)
  theta<-theta0
  
  #Init
  tau <- compute.tau(x,theta)
  s<-compute.stat(x,tau)
  
  l <- NULL
  l <- rep(sample(1:n,n), K/n)
  i <- 1:nbr
  
  for (k in 1:K)
  {
    if (k%%(n/nbr) == 1)
    { 
      i<-1:nbr
      theta.e.0 <- theta
    }

    tau.indiv.new <- compute.tau(x[l[i]],theta)
    s.indiv.new <- x[l[i]]*tau.indiv.new

    tau.indiv.e.0 <- compute.tau(x[l[i]],theta.e.0)
    s.indiv.e.0 <- x[l[i]]*tau.indiv.e.0

    tau.e.0 <- compute.tau(x,theta.e.0)
    s.e.0 <- x%*%tau.e.0

    #Update statistic
    s$s1 <- s$s1 + rho*(tau.indiv.new - tau.indiv.e.0 + colSums(tau.e.0) - s$s1)
    s$s2 <- s$s2 + rho*(s.indiv.new - s.indiv.e.0 + s.e.0 - s$s2)
    s$s3 <- s$s3 + rho*(x[l[i]]*s.indiv.new - x[l[i]]*s.indiv.e.0 + (x^2)%*%tau.e.0 - s$s3)

    theta <- step.M(s,n)
    theta.est[k+1,] <- c(k, theta$p, theta$mu, theta$sigma)

    #Update index
    i <- i+nbr

  }
  
  df <- as.data.frame(theta.est)
  names(df) <- col.names
  return(df)
}




