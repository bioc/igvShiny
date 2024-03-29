library(shiny)
library(igvShiny)
library(GenomicAlignments)

#----------------------------------------------------------------------------------------------------
f <- system.file(package="igvShiny", "extdata", "gwas.RData")
stopifnot(file.exists(f))
tbl.gwas <- get(load(f))
print(dim(tbl.gwas))
printf <- function(...) print(noquote(sprintf(...)))
#----------------------------------------------------------------------------------------------------
tbl.bed <- data.frame(chr=c("1","1", "1"),
                      start=c(7432951, 7437000, 7438000),
                      end=  c(7436000, 7437500, 7440000),
                      value=c(-2.239, 3.0, 0.5),
                      sampleID=c("sample1", "sample2", "sample3"),
                      stringsAsFactors=FALSE)
#----------------------------------------------------------------------------------------------------
ui = shinyUI(fluidPage(

  sidebarLayout(
     sidebarPanel(
        actionButton("searchButton", "Search"),
        textInput("roi", label=""),
        h5("One simple data.frame, three igv formats:"),
        actionButton("addBedTrackButton", "Add as Bed"),
        actionButton("addBedGraphTrackButton", "Add as BedGraph"),
        actionButton("addSegTrackButton", "Add as SEG"),
        br(),
        actionButton("addGwasTrackButton", "Add GWAS Track"),
        actionButton("addBamViaHttpButton", "BAM from URL"),
        actionButton("addBamLocalFileButton", "BAM local data"),
        actionButton("addCramViaHttpButton", "CRAM from URL"),
        actionButton("removeUserTracksButton", "Remove User Tracks"),
        actionButton("getChromLoc", "Get Region"),
        htmlOutput("chromLocDisplay"),
        hr(),
        width=2
        ),
     mainPanel(
        igvShinyOutput('igvShiny_0'),
        igvShinyOutput('igvShiny_1'),
        width=10
        )
     ) # sidebarLayout
))
#----------------------------------------------------------------------------------------------------
server = function(input, output, session) {

   observeEvent(input$searchButton, {
      printf("--- search")
      searchString = isolate(input$roi)
      if(nchar(searchString) > 0)
        showGenomicRegion(session, id="igvShiny_0", searchString)
      })

   observeEvent(input$addBedTrackButton, {
      showGenomicRegion(session, id="igvShiny_0", "chr1:7,426,231-7,453,241")
      loadBedTrack(session, id="igvShiny_0", trackName="bed", tbl=tbl.bed, color="green");
      })

   observeEvent(input$addBedGraphTrackButton, {
      showGenomicRegion(session, id="igvShiny_0", "chr1:7,426,231-7,453,241")
      loadBedGraphTrack(session, id="igvShiny_0", trackName="wig", tbl=tbl.bed, color="blue", autoscale=TRUE)
      })

   observeEvent(input$addSegTrackButton, {
      showGenomicRegion(session, id="igvShiny_0", "chr1:7,426,231-7,453,241")
      loadSegTrack(session, id="igvShiny_0", trackName="seg", tbl=tbl.bed)
      })

   observeEvent(input$addGwasTrackButton, {
      printf("---- addGWASTrack")
      printf("current working directory: %s", getwd())
      showGenomicRegion(session, id="igvShiny_0", "chr19:45,248,108-45,564,645")
      loadGwasTrack(session, id="igvShiny_0", trackName="gwas", tbl=tbl.gwas, deleteTracksOfSameName=FALSE)
      })

   observeEvent(input$addBamViaHttpButton, {
      printf("---- addBamViaHttpTrack")
      showGenomicRegion(session, id="igvShiny_0", "chr5:88,733,959-88,761,606")
      base.url <- "https://1000genomes.s3.amazonaws.com/phase3/data/HG02450/alignment"
      url <- sprintf("%s/%s", base.url, "HG02450.mapped.ILLUMINA.bwa.ACB.low_coverage.20120522.bam")
      indexURL <- sprintf("%s/%s", base.url, "HG02450.mapped.ILLUMINA.bwa.ACB.low_coverage.20120522.bam.bai")
      loadBamTrackFromURL(session, id="igvShiny_0",trackName="1kg.bam", bamURL=url, indexURL=indexURL)
      })

   observeEvent(input$addBamLocalFileButton, {
      printf("---- addBamLocalFileButton")
      showGenomicRegion(session, id="igvShiny_0", "chr21:10,397,614-10,423,341")
      bamFile <- system.file(package="igvShiny", "extdata", "tumor.bam")
      x <- readGAlignments(bamFile)
      loadBamTrackFromLocalData(session, id="igvShiny_0", trackName="tumor.bam", data=x)
      })

   observeEvent(input$addCramViaHttpButton, {
      printf("---- addCramViaHttpTrack")
      showGenomicRegion(session, id="igvShiny_0", "chr5:88,733,959-88,761,606")
      base.url <- "https://s3.amazonaws.com/1000genomes/phase3/data/HG00096/exome_alignment"
      url <- sprintf("%s/%s", base.url, "HG00096.mapped.ILLUMINA.bwa.GBR.exome.20120522.bam.cram")
      indexURL <- sprintf("%s/%s", base.url, "HG00096.mapped.ILLUMINA.bwa.GBR.exome.20120522.bam.cram.crai")
      loadCramTrackFromURL(session, id="igvShiny_0",trackName="CRAM", cramURL=url, indexURL=indexURL)
      })

   observeEvent(input$removeUserTracksButton, {
      printf("---- removeUserTracks")
      removeUserAddedTracks(session, id="igvShiny_0")
      })


   observeEvent(input$trackClick, {
       printf("--- trackclick event")
       x <- input$trackClick
       print(x)
       })

   observeEvent(input[["igv-trackClick"]], {
       printf("--- igv-trackClick event")
       x <- input[["igv-trackClick"]]
       print(x)
       })

   observeEvent(input$getChromLoc, {
      printf("--- getChromLoc event")
      output$chromLocDisplay <- renderText({" "})
      getGenomicRegion(session, id="igvShiny_0")
      })

   observeEvent(input$currentGenomicRegion, {
      printf("--- currentGenomicRegion event")
      chromLocRegion <- input$currentGenomicRegion
      output$chromLocDisplay <- renderText({
         chromLocRegion
         })
       })

   genomes <- c("hg38", "hg19", "mm10", "tair10", "rhos")
   loci <- c("chr5:88,466,402-89,135,305", "MEF2C", "Mef2c", "1:7,432,931-7,440,395", "NC_007494.2:370,757-378,078")
   i <- 2

   output$igvShiny_0 <- renderIgvShiny({
     genomeOptions <- parseAndValidateGenomeSpec(genomeName=genomes[i],  initialLocus=loci[i])
     igvShiny(genomeOptions)
     })

   output$igvShiny_1 <- renderIgvShiny({
     genomeOptions <- parseAndValidateGenomeSpec(genomeName="hg38",
                                                 initialLocus="chr2:232,983,999-233,283,872")
     igvShiny(genomeOptions)
     })

} # server
#----------------------------------------------------------------------------------------------------
print(sessionInfo())
runApp(shinyApp(ui = ui, server = server), port=9832)
#shinyApp(ui = ui, server = server)
