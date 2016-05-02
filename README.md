##########################################
# Monsanto-Sample:  AKA - "Monsample"
############################################

Description:  Sample of some R code for collecting tweets, saving them, analyzing them, plotting term mention frequency, and use of word2vec


About:
This work originated under my own curiosity to examine the ways individuals talk about conspiracy theories on social media, as well as explore how semantically related various conspiracy theory communities were in the wild.  The experiment ran approximately 2 months with off-and-on collection of tweets from approximately 2,500 individuals.  

Individuals identified and included in this study are users who were highly active on specific hashtags or communities centered on a diverse range of conspiracy theories in October of 2015.  The users who posted under select hashtags most frequently over a 2 week period were identified, and then had all of their tweets collected via Twitter's streaming API in R for approximately 2 months.  


Contents:

1.  Monsample_Script.R: This is an example script of saving tweets, processing them, performing a simple analysis, and then generating word2vec embeddings using the "wordVectors" package in R.  Note that this package is still in development, and is NOT the preferred method for generating word embeddings at this time.

2.  Cohort_Data.zip:  These files (3, one for each cohort) can be used to generate the plots in Part II of the code (lines 117 to 132).  All other data has been withheld from this git due to both its size and the volume of personally identifiable information (PII) within them.

3.  Word2Vec_Assoc.zip:  3 files containing the top 50 terms most commonly associated with the term "islam" following the Paris attacks on November 13, 2015.  Hashtags and @ signs (denoting users) have been left in.  Some stray characters appear to be getting into the model, and this is likely due to the developmental nature of "WordVectors", or a possible flaw in my cleanup script.  Ideally words should also be stemmed prior to analysis, but in this instance it was unclear if there were meaningful distinctions to be preserved.

Overview of User Cohorts:
C1:  These users are generally defined as "anti-government" as they are prominent users identified on conspiracy theories that involve excessive government (US or International) power.  These theories include; 9/11 truthers, Agenda 21, New World Order, Chemtrails (perpetrated by the government), and others.

C2:  These users are generally agitated towards science and large corporations, and were identified by their activity in conspiracies involving pharmaceuticals, genetically modified foods, and others.  

C3:  This collected active users under the "Anonymous" hashtag.  As a group they are politically diverse on social issues, but typically anti-corporate and anti-establishment.  

