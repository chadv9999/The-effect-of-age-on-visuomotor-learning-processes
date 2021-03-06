
plotReachAftereffects <- function(target='inline') {
  
  if (target == 'svg') {
    svglite(file='doc/fig/Fig8.svg', width=4, height=4, system_fonts=list(sans='Arial'))
  }
  
  styles <- getStyle()
  
  par(mfrow=c(1,1), mar=c(4,4,2,0.1))
  
  ylims=c(-.2*max(styles$rotation),max(styles$rotation)+(.2*max(styles$rotation)))
  plot(c(0.5,2.5),c(0,0),type='l',lty=2,col=rgb(.5,.5,.5),main='reach aftereffects',xlim=c(0.5,2.5),ylim=ylims,bty='n',
       xaxt='n',yaxt='n',xlab='strategy use',ylab='reach deviation [°]')
  
  for (groupno in c(1:length(styles$group))) {
    
    group <- styles$group[groupno]

    reachaftereffects <- read.csv(sprintf('data/%s_reachaftereffects.csv',group), stringsAsFactors=FALSE)
    
    meanExc <- mean(reachaftereffects$exclusive)
    meanInc <- mean(reachaftereffects$inclusive)
    
    coord.x <- c(1,1,2,2)
    coord.y <- c(t.interval(reachaftereffects$exclusive),rev(t.interval(reachaftereffects$inclusive)))
    polygon(coord.x, coord.y, col=as.character(styles$color_trans[groupno]), border=NA)
    
  }
  
  for (groupno in c(1:length(styles$group))) {
    
    group <- styles$group[groupno]
    offset <- (groupno - ((length(styles$group) - 1) / 2)) * .035
    
    reachaftereffects <- read.csv(sprintf('data/%s_reachaftereffects.csv',group), stringsAsFactors=FALSE)
    
    meanExc <- mean(reachaftereffects$exclusive)
    meanInc <- mean(reachaftereffects$inclusive)
    
    lines(c(1,2),c(meanExc,meanInc),col=as.character(styles$color_solid[groupno]),lty=styles$linestyle[groupno],lw=2)
    
  }
  
  axis(side=1, at=c(1,2), labels=c('without strategy','with strategy'),cex.axis=0.85)
  if (max(styles$rotation) == 30) {
    axis(side=2, at=c(0,10,20,30),cex.axis=0.85)
  }
  
  # legend(0.5,max(styles$rotation)*(7/6),styles$label,col=as.character(styles$color),lty=styles$linestyle,bty='n',cex=0.85)
  legend(1.2,13,styles$label,col=as.character(styles$color_solid),lw=2,lty=styles$linestyle,bty='n',cex=0.85)
  
  
  
  if (target == 'svg') {
    dev.off()
  }

}

getRAE4ANOVA <- function(styles) {
  
  agegroup       <- c()
  instructed     <- c()
  participant    <- c()
  strategy       <- c()
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
    
    df <- read.csv(sprintf('data/%s_reachaftereffects.csv',group),stringsAsFactors=F)
    
    # we need to know the number of participants to replicate some values:
    N <- dim(df)[1]
    
    for (thisstrategy in c('exclusive','inclusive')) {
      
      agegroup        <- c(agegroup, rep(thisagegroup, N))
      instructed      <- c(instructed, rep(thisinstructed, N))
      participant     <- c(participant, c(startingID : (startingID + N - 1)))
      strategy        <- c(strategy, rep(thisstrategy, N))
      reachdeviation  <- c(reachdeviation, df[,thisstrategy])
      
    }
    
    startingID <- startingID + N
    
  }
  
  # put it in a data frame:
  RAEaov <- data.frame(agegroup, instructed, participant, strategy, reachdeviation)
  
  # set relevant columns as factors:
  RAEaov$agegroup <- as.factor(RAEaov$agegroup)
  RAEaov$instructed <- as.factor(RAEaov$instructed)
  RAEaov$strategy <- as.factor(RAEaov$strategy)
  
  return(RAEaov)
  
}

RAE.ANOVA <- function() {
  
  styles <- getStyle()

  RAE4aov <- getRAE4ANOVA(styles)                      
  
  #learning curve ANOVA's
  # for ez, case ID should be a factor:
  RAE4aov$participant <- as.factor(RAE4aov$participant)
  print(ezANOVA(data=RAE4aov, wid=participant, dv=reachdeviation, within=strategy, between=c(instructed, agegroup),type=3))
  
}

NoCursorANOVA <- function() {
  
  styles <- getStyle()
  
  NC4aov <- getNoCursors4ANOVA(styles)
  
  NC4aov$participant <- as.factor(NC4aov$participant)
  print(ezANOVA(data=NC4aov, wid=participant, dv=reachdeviation, within=training, between=c(instructed, agegroup),type=3))
  
}

getNoCursors4ANOVA <- function(styles) {
  
  # placeholder for data frame:
  NC4aov <- NA
  
  # loop through groups to collect their data:
  for (groupno in c(1:length(styles$group))) {
    
    group <- styles$group[groupno]
    
    # set up some basic descriptors that apply to the group:
    if (substr(group, 1, 5) == 'aging') {
      thisagegroup <- 'older'
    } else {
      thisagegroup <- 'younger'
    }
    thisinstructed <- grepl('explicit', group)
    
    df <- read.csv(sprintf('data/%s_nocursors.csv',group),stringsAsFactors=F)
    
    AL.NC <- df[,c('participant','aligned')]
    colnames(AL.NC)[2] <- 'reachdeviation'
    AL.NC$training <- 'aligned'
    
    RO.NC <- df[,c('participant','exclusive')]
    colnames(RO.NC)[2] <- 'reachdeviation'
    RO.NC$training <- 'rotated'
    
    df <- rbind(AL.NC, RO.NC)
    df$agegroup <- thisagegroup
    df$instructed <- thisinstructed
    
    if (is.data.frame(NC4aov)) {
      NC4aov <- rbind(NC4aov, df)
    } else {
      NC4aov <- df
    }
    
  }
  
  NC4aov$instructed <- as.factor(NC4aov$instructed)
  NC4aov$agegroup <- as.factor(NC4aov$agegroup)
  NC4aov$training <- as.factor(NC4aov$training)
  
  return(NC4aov)
  
}
