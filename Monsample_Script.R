###################################################################################
###Ryan Butner - Sample for Monsanto###############################################
###################################################################################

#####PART 1: CONTENT COLLECTION OFF TWITTER

#############Collect tweets off of Twitter################  
#####Note: this will not work without your own API access codes

#Libraries we'll be needing
library(streamR)  #loads the streamR package to collect tweets
library(RCurl) #loads some URL utilities
library(ROAuth) #Creates login credentials for streamR

#Functions we'll be needing
neg<-function(x) -x 
#############################
###Init authorization
############################

requestURL <- "https://api.twitter.com/oauth/request_token"
accessURL <- "https://api.twitter.com/oauth/access_token"
authURL <- "https://api.twitter.com/oauth/authorize"

consumerKey="xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"  #Replace with own key
consumerSecret="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"  #Replace with own code
my_oauth <- OAuthFactory$new(consumerKey=consumerKey,
                             consumerSecret=consumerSecret, requestURL=requestURL,
                             accessURL=accessURL, authURL=authURL)
my_oauth$handshake(cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))

save(my_oauth, file = "my_oauth.Rdata")



###########################
#Hashtags for user identification and stream collection - collects all tweets containing the terms specified for an hour and then saves it
#Designed to run indefinitely until the given end date.
##########################
end.date=as.Date("YYYY-MM-DD")
while(Sys.Date()<end.date){
  current.time=format(Sys.time(),"%Y_%m_%d_%H_%M")
  file.name=paste("some_tweets_", current.time, ".json", sep="")
  filterStream( file="tweets.json", track=c("my_hashtags_or_users_here"), timeout=3600, oauth=my_oauth )
  tweets.df=parseTweets("tweets.json", simplify=FALSE)
  write.csv(tweets.df, file="/my/file/location/File.csv", row.names=F)
}


##########################################################################
#####PART 2: PROCESS TEXT - MAKE A SIMPLE GRAPH OF TERM MENTIONS PER HOUR
##########################################################################
library(ggplot2) #Makes plots

#Build a simple time stamp for the data so we can track mentions of a hashtag over time
Hrs <- read.csv("/media/odin/F8DCB3C7DCB37E86/Data Lab/Tweets/Analysis/data/TpD.csv")  #This step would usually be done differently, but here we're interested in a very specific timeframe

#Load the tweets we've collected previously, create a time stamp that helps us track the mentions of a term by hour
tweet.analysis <- read.csv("/media/odin/F8DCB3C7DCB37E86/Data Lab/Tweets/Rebuild/Paris_Sample.csv")
tweet.analysis$Month <- substr(tweet.analysis$created_at,5,7)
tweet.analysis$Day <- substr(tweet.analysis$created_at,9,10)
tweet.analysis$Hour <- substr(tweet.analysis$created_at,12,13)
tweet.analysis$Min <- substr(tweet.analysis$created_at,15,16)
tweet.analysis$TimeStamp <- do.call(paste, c(tweet.analysis[c("Month","Day", "Hour")], sep = "_")) 

#Lets see which tweets mention refugees
refugee.data <- tweet.analysis[grep("refugee*", tweet.analysis$text), ]

#In this experiment, users were known to have particular affiliations for certain conspiracy hashtags
#Let's divide the data set between three archetypes of conspiracy theorists in the sample to
#See how they were reacting to the Paris attacks

users <- read.csv("/media/odin/F8DCB3C7DCB37E86/Data Lab/Tweets/user_tags.csv")
refugee.users <- merge(refugee.data,users, by="screen_name")
refugee.users <- merge(refugee.users,Hrs, by.x="TimeStamp", by.y="Var1")

refugee.users <- subset(refugee.users,refugee.users$screen_name!="HashTagForLikes")  #This particular user was a known spam account, so we will remove them

user.range <- subset(refugee.users, refugee.users$Hrs>neg(24) & refugee.users$Hrs<24)  #Define our period of interest to the 24 hours before and after the attacks

#Cohort 1: Anti-government themed conspiracy theories (chemtrails, mainstream media, new world order, etc)
cohort1 <- subset(user.range, user.range$Cohort=="C1")

#Cohort 2: Anti-science/corporate themed (anti-gmo, big pharma, cannabis, etc) - Exclude all users not inside this group
cohort2 <- subset(user.range, user.range$Cohort=="C2")

#Cohort 3: Users affiliated with the pseudo-libertarian/anti-corporate movement Anonymous
cohort3 <- subset(user.range, user.range$Cohort=="C3" )

terms <- c("refugee*")
#cohort1.trump <- data.frame(table(cohort1$TimeStamp))
cohort1.terms<- cohort1[grep(paste(terms,collapse="|"), cohort1$text), ]
cohort1.terms <- data.frame(table(cohort1.terms$TimeStamp))
cohort1.terms <- merge(cohort1.terms,Hrs, by="Var1")

cohort2.terms<- cohort2[grep(paste(terms,collapse="|"), cohort2$text), ]
cohort2.terms <- data.frame(table(cohort2.terms$TimeStamp))
cohort2.terms <- merge(cohort2.terms,Hrs, by="Var1")

cohort3.terms<- cohort3[grep(paste(terms,collapse="|"), cohort3$text), ]
cohort3.terms <- data.frame(table(cohort3.terms$TimeStamp))
cohort3.terms <- merge(cohort3.terms,Hrs, by="Var1")


###########################################################################################################################
#Create a plot to view mentions per hour before and after 11/13 Paris Attacks
#Notice users within the three groups seem to discuss refugees at very different levels immediately following the attack
###########################################################################################################################


####################################

#USE THESE LINES TO IMPORT PRE-ANALYZED DATA FOR PLOT GENERATION


######################################
cohort1.terms <- read.csv("/my/file/location/Cohort1.csv")
cohort2.terms <- read.csv("/my/file/location/Cohort2.csv")
cohort3.terms <- read.csv("/my/file/location/Cohort3.csv")
library(ggplot2) #Makes plots

p <- ggplot(cohort1.terms,aes(Hrs,Freq.x))+geom_line(aes(color="Mentions of Refugees Among Anti-Gov"),size=1.5)+
  geom_line(data=cohort2.terms, aes(color="Mentions of Refugees Among Anti-GMO"), size=1.5)+
  geom_line(data=cohort3.terms, aes(color="Mentions of Refugees Among Anonymous"),size=1.5)+
  labs(color="Legend")+
  ggtitle("Mentions of Refugees Between Conspiracy Communities on Twitter (per Hour):
          24 hours Before and After the 11/13 Paris Attacks")+
  xlab("Hours to Attack (0)")+
  xlab("Hours to Attack (0)")+
  ylab("Mentions per Hour")+ theme(legend.text=element_text(size=14))+ geom_vline(xintercept = 0, color="red")

p


##########################################################################
#####PART 3: CLEAN TEXT AND CREATE WORD2VEC MODELS
##########################################################################
library(data.table)
library(stringr)
library(tm)
library(wordVectors)

tweet.analysis <- read.csv("/media/odin/F8DCB3C7DCB37E86/Data Lab/Tweets/Rebuild/Paris_Sample.csv")
users <- read.csv("/media/odin/F8DCB3C7DCB37E86/Data Lab/Tweets/user_tags.csv")
#Manipulating this data can be pretty slow, so let's remove weird characters and make sure its ready for word2vec embedding
#Cleaning the data up will also allow us to use data.tables function to merge data frames MUCH faster for later!


data.temp <- tweet.analysis[,c(2,8)] #reduce to only text field
data.temp$text <- as.character(data.temp$text)
data.temp$text <- iconv(data.temp$text, to="UTF-8")
data.temp$text <-tolower(data.temp$text)
data.temp$text <- gsub("[^[:alnum:][:space:]# @]", "", data.temp$text)  #lets remove all punctuation except spaces, @(user_name), and hashtags
data.temp$text <- str_replace_all(data.temp$text, "[\r\n]" , "")  #remove excess carriage returns
data.temp <- data.temp[complete.cases(data.temp),]


#Lets convert these to data.tables to make the operations faster
data.temp <- as.data.table(data.temp)
users <- as.data.table(users)
tagged.data <- merge(data.temp, users, by="screen_name")

#Now lets train a word2vec model for each cohort
#Cohort 1: Anti-government themed conspiracy theories (chemtrails, mainstream media, new world order, etc)
cohort1 <- subset(tagged.data, tagged.data $Cohort=="C1")
write.table(cohort1,"/media/odin/F8DCB3C7DCB37E86/Data Lab/Tweets/Monsample/C1.txt", row.names=FALSE)

#Cohort 2: Anti-science/corporate themed (anti-gmo, big pharma, cannabis, etc) - Exclude all users not inside this group
cohort2 <- subset(tagged.data, tagged.data $Cohort=="C2")
write.table(cohort2,"/media/odin/F8DCB3C7DCB37E86/Data Lab/Tweets/Monsample/C2.txt", row.names=FALSE)

#Cohort 3: Users affiliated with the pseudo-libertarian/anti-corporate movement Anonymous
cohort3 <- subset(tagged.data, tagged.data$Cohort=="C3" )
write.table(cohort3,"/media/odin/F8DCB3C7DCB37E86/Data Lab/Tweets/Monsample/C3.txt", row.names=FALSE)



###########Similarity
#This command lets us see how closely certain terms are to other terms
#Because we left # and @ in our data, we can see which hashtags or users are associated with certain terms
#In this case, we can explore the ways that different groups talk about/think about "islam" during the Paris attacks
#Higher values mean a closer association


modelC1 <- read.vectors("/my/file/location/Cohort1.vectors")
modelC2 <- read.vectors("/my/file/location/Cohort2.vectors")
modelC3 <- read.vectors("/my/file/location/Cohort3.vectors")

terms <- c("islam")
#most similar 50 for C1
sim_C1 = as.data.frame(nearest_to(modelC1,modelC1[[c(terms)]],50))
#most similar 50 for C1
sim_C2 = as.data.frame(nearest_to(modelC2,modelC2[[c(terms)]],50))
#most similar 50 for Anon
sim_C3 = as.data.frame(nearest_to(modelC3,modelC3[[c(terms)]],50))




