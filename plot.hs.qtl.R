library(GenomicRanges)
library(BSgenome.Mmusculus.UCSC.mm10)

# This is the plot function.  Source this into your scripts and you
# should be able to plot.
plot.hs.qtl = function(qtl, bin.width = 100, ...) {

  new.qtl = NULL
  for(chr in 1:length(qtl)) {

    print(chr)

    # Create 100 SNP bins.
    brks = cut(x = 1:length(qtl[[chr]]), breaks = length(qtl[[chr]]) / bin.width)
    # Split up the SNP positions and get the mean.
    pos = split(start(qtl[[chr]]), brks)
    pos = sapply(pos, mean)
    # Split up the p-values and get the max.
    pv = split(mcols(qtl[[chr]])$p.value, brks)
    pv = sapply(pv, min)

    # Make a single new GRanges object to return.
    gr = GRanges(seqnames = seqnames(qtl[[chr]])[1],
                 ranges = IRanges(start = pos, width = 1), p.value = pv)

    if(chr == 1) {
      new.qtl = gr
    } else {
      new.qtl = c(new.qtl, gr)
    } # else

  } # for(chr)

  # Get the chromosome lengths.
  chrlen = seqlengths(BSgenome.Mmusculus.UCSC.mm10)
  names(chrlen) = sub("^chr", "", names(chrlen))
  chrlen = chrlen[seqlevels(new.qtl)] * 1e-6

  # Add the chr lengths to the chromosomes for plotting.
  # Switch positions to genome Mb.
  gmb = start(new.qtl) * 1e-6
  for(chr in 2:length(chrlen)) {

    wh = which(seqnames(new.qtl) == names(chrlen)[chr])
    gmb[wh] = gmb[wh] + sum(chrlen[1:(chr - 1)])

  } # for(chr)

  # Get chromosome mid-points for plotting the Chr name.
  chrmid = (chrlen / 2) + cumsum(c(1, chrlen[-length(chrlen)]))

  # Make the plot.
  col = rep(rgb(0,0,0), length(new.qtl))
  even.chr = which(seqnames(new.qtl) %in% (1:10 * 2))
  col[even.chr] = rgb(0.7,0.7,0.7)
  plot(gmb, -log10(new.qtl$p.value), pch = 20, xaxt = "n", 
       col = col, las = 1, xlab = "", ylab = "-log10(p-value)", ...)
  mtext(side = 1, line = 0.5, at = chrmid, text = names(chrlen), cex = 1.2)

  return(new.qtl)

} # plot.hs.qtl


# Test the fucntion.
setwd("HS")
load("AMQTL.HCC.Rdata")
png("qtl.png", width = 1200, height = 800, res = 128)
qtl.smaller = plot.hs.qtl(qtl, main = "HCC")
dev.off()
qtl.smaller = plot.hs.qtl(qtl, bin.width = 1000, main = "HCC")

# Look at a Quantile-Quantile plof of the p-values.
pv = unlist(sapply(AM.qtl, function(z) { z$p.value }))
qqnorm(-log10(pv[sample(1:length(pv), 50000)]))
qqline(-log10(pv[sample(1:length(pv), 50000)]))
# This looks weird. Are there other covariates (like batch) that
# should be in your model? Or is the data full of 0 values with
# only a few non-zero values?


