
plotLearningCurves <- function(target='inline') {
  
  styles <- getStyle()
  
  if (target == 'svg') {
    svglite(file='doc/fig/Fig7.svg', width=8, height=4, system_fonts=list(sans='Arial'))
  }
  
  par(mfrow=c(1,2), mar=c(4,4,2,0.1))
  
  # # # # # # # # # #
  # panel A: actual learning curves
  
  ylims=c(-.2*max(styles$rotation),max(styles$rotation)+(.2*max(styles$rotation)))
  plot(c(-1,36),c(0,0),col=rgb(0.5,0.5,0.5),type='l',lty=2,xlim=c(-1,36),ylim=ylims,xlab='trial',ylab='reach deviation [°]',xaxt='n',yaxt='n',bty='n',main='learning - by trial')
  
  mtext('A', side=3, outer=TRUE, at=c(0,1), line=-1, adj=0, padj=1)
  
  for (groupno in c(1:length(styles$group))) {
    
    group  <- styles$group[groupno]
    curves <- read.csv(sprintf('data/%s_curves.csv',group), stringsAsFactors=FALSE)  
    curve  <- apply(curves, c(1), mean, na.rm=T)
    
    lines(c(1:15),curve[1:15],col=as.character(styles$color_solid[groupno]),lty=styles$linestyle[groupno],lw=2)
    
    lines(c(21:35),curve[76:90],col=as.character(styles$color_solid[groupno]),lty=styles$linestyle[groupno],lw=2)
  }
  
  # axis(side=1, at=c(1,10,20,30))
  axis(side=1, at=c(1,5,10,25,30,35), labels=c('1','5','10','80','85','90'),cex.axis=0.85)
  axis(side=2, at=c(0,10,20,30),cex.axis=0.85)
  
  legend(10,15,styles$label,col=as.character(styles$color_solid),lty=styles$linestyle,bty='n',lw=2,cex=0.85)
  
  
  # # # # # # # # # #
  # panel B: blocked learning curves
  
  plot(c(0,5),c(0,0),col=rgb(0.5,0.5,0.5),type='l',lty=2,xlim=c(0.5,4.5),ylim=ylims,xlab='trial set',ylab='',xaxt='n',yaxt='n',bty='n',main='learning - blocked')
  
  mtext('B', side=3, outer=TRUE, at=c(1/2,1), line=-1, adj=0, padj=1)
  
  blockdefs <- list(c(1,3),c(4,3),c(76,15))
  
  alllines <- array(NA,dim=c(length(styles$group),length(blockdefs)))
  allpolys <- array(NA,dim=c(length(styles$group),2*length(blockdefs)))
  
  for (groupno in c(1:length(styles$group))) {
    
    group <- styles$group[groupno]
    
    blocked <- getBlockedLearningCurves(group, blockdefs)
    
    alllines[groupno,] <- apply(blocked, c(2), mean, na.rm=T)
    
    blockedCI <- apply(blocked, c(2), t.interval)
    allpolys[groupno,] <- c(blockedCI[1,], rev(blockedCI[2,]))
    
  }
  
  # first plot all the polygons representing confidence intervals, so those are in the background
  
  for (groupno in c(1:length(styles$group))) {
    
    polX <- c(c(1,2,4),rev(c(1,2,4)))
    polY <- allpolys[groupno,]
    polygon(polX,polY,col=as.character(styles$color_trans[groupno]),border=NA)
    
  }
  
  # then plot the lines representing the means, so those are in the foreground
  
  for (groupno in c(1:length(styles$group))) {
    
    lines(c(1,2,4),alllines[groupno,],col=as.character(styles$color_solid[groupno]),lty=styles$linestyle[groupno],lw=2)
    
  }
  
  # legend(2,0.45,styles$label,col=as.character(styles$color),lty=styles$linestyle,bty='n',cex=0.7)
  
  axis(side=1, at=c(1,2,4), labels=c('1-3','4-6','76-90'),cex.axis=0.85)
  axis(side=2, at=c(0,10,20,30),labels=c('0','10','20','30'),cex.axis=0.85)
  
  if (target == 'svg') {
    dev.off()
  }
  
  
}


getBlockedLearningCurves <- function(group, blockdefs) {
  
  curves <- read.csv(sprintf('data/%s_curves.csv',group), stringsAsFactors=FALSE)  
  
  # R <- dim(curves)[1] # should always be 90
  N <- dim(curves)[2]
  
  blocked <- array(NA, dim=c(N,length(blockdefs)))
  
  for (ppno in c(1:N)) {
    
    for (blockno in c(1:length(blockdefs))) {
      
      blockdef <- blockdefs[[blockno]]
      blockstart <- blockdef[1]
      blockend <- blockstart + blockdef[2] - 1
      samples <- curves[blockstart:blockend,ppno]
      blocked[ppno,blockno] <- mean(samples, na.rm=TRUE)
      
    }
    
  }
  
  return(blocked)
  
}

learningCurveANOVA <- function() {
  
  styles <- getStyle()
  blockdefs <- list(c(1,3),c(4,3),c(76,15))
  
  LC4aov <- getLearningCurves4ANOVA(styles, blockdefs)                      
  
  #learning curve ANOVA's
  # for ez, case ID should be a factor:
  LC4aov$participant <- as.factor(LC4aov$participant)
  print(ezANOVA(data=LC4aov, wid=participant, dv=reachdeviation, within=block,between=c(instructed, agegroup),type=3))
  
}

getLearningCurves4ANOVA <- function(styles, blockdefs) {
  
  # set up vectors that will form a data frame for the ANOVA(s):
  agegroup       <- c()
  instructed     <- c()
  participant    <- c()
  block          <- c()
  reachdeviation <- c()
  
  # keeping count of unique participants:
  startingID <- 0
  
  for (groupno in c(1:length(styles$group))) {
    
    group <- styles$group[groupno]
    
    # set up some basic descriptors that apply to the group:
    if (substr(group, 1, 5) == 'aging') {
      thisagegroup <- 'older'
    } else {
      thisagegroup <- 'younger'
    }
    thisinstructed <- grepl('explicit', group)
    
    # block the data:
    blocked <- getBlockedLearningCurves(group, blockdefs)
    # this is now the exact same data as the data that is plotted!
    
    # we need to know the number of participants to replicate some values:
    N <- dim(blocked)[1]
    
    for (blockno in c(1:length(blockdefs))) {
      
      agegroup        <- c(agegroup, rep(thisagegroup, N))
      instructed      <- c(instructed, rep(thisinstructed, N))
      participant     <- c(participant, c(startingID : (startingID + N - 1)))
      block           <- c(block, rep(blockno, N))
      reachdeviation  <- c(reachdeviation, blocked[,blockno])
      
    }
    
    startingID <- startingID + N
    
  }
  
  # put it in a data frame:
  LCaov <- data.frame(agegroup, instructed, participant, block, reachdeviation)
  
  # set relevant columns as factors:
  LCaov$agegroup <- as.factor(LCaov$agegroup)
  LCaov$instructed <- as.factor(LCaov$instructed)
  LCaov$block <- as.factor(LCaov$block)
  
  return(LCaov)
  
}


blockLearningANOVA <- function(block=1) {
  
  styles <- getStyle()
  blockdefs <- list(c(1,3),c(4,3),c(76,15))
  
  LC4aov <- getLearningCurves4ANOVA(styles, blockdefs)
  
  LC4aov <- LC4aov[which(LC4aov$block == block),]
  
  #learning curve ANOVA's
  # for ez, case ID should be a factor:
  LC4aov$participant <- as.factor(LC4aov$participant)
  print(ezANOVA(data=LC4aov, wid=participant, dv=reachdeviation, between=c(instructed, agegroup),type=3))
  
}

blockLearningTtest <- function(block=1, groups=list(list('agegroup'='older', 'instructed'=TRUE),list('agegroup'='older', 'instructed'=FALSE))) {
  
  styles <- getStyle()
  blockdefs <- list(c(1,3),c(4,6),c(76,15))
  
  LC4aov <- getLearningCurves4ANOVA(styles, blockdefs)
  
  LC4aov <- LC4aov[which(LC4aov$block == block),]
  
  DVs <- list()
  
  main <- ""
  
  # first collect the data from the data frame:
  for (groupno in c(1,2)) {
    
    properties <- groups[[groupno]]
    
    if (properties$instructed) {
      instr <- 'instructed'
    } else {
      instr <- 'non-instructed'
    }
    main <- sprintf('%s%s%s %s',main,c('',' vs. ')[groupno],properties$agegroup, instr)
    
    DVs[[groupno]] <- LC4aov$reachdeviation[which(LC4aov$agegroup==properties$agegroup & LC4aov$instructed==properties$instructed)]
    
  }
  
  cat(sprintf('\n%s\n',main))
  print(t.test(DVs[[1]], DVs[[2]]))
  
}