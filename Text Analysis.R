library("RODBC")
library("wordcloud")
library("tm")
library("RColorBrewer")
library("ggplot2")
library("SnowballC")
library("sqldf")


Pitch4k <- odbcConnect("Pitch4k", uid="admin", pwd="admin") 

## Use the syntax below to get at the text in the blob field!
sql  <- paste("select convert(editorial USING utf8) as text from ReviewContent where artist = 'Sky Ferreira'")

sql2 <- paste("select STR_TO_DATE(date_of_review, '%m %d, %Y') from reviewcontent where artist='Radiohead'")

#Below is how I altered the score variable from string to decimal
#sql3 <- paste("alter table reviewcontent modify column score decimal(4,2)")
sqlQuery(Pitch4k, sql2, error=TRUE)


## Find all Reviewers and create summary: number of reviews, average score, median score
sum_sql <- paste("select reviewr, count(idReview) as num_reviews, avg(score), 
                 avg(char_length(convert(editorial USING utf8)) - char_length(REPLACE(convert(editorial USING utf8), ' ', '')) + 1) as Avg_review_length
                 from ReviewContent
                 group by reviewr
                 order by num_reviews")

reviewers <- as.data.frame(sqlQuery(Pitch4k, sum_sql, error=TRUE))
top_reviewers <- reviewers[reviewers$num_reviews > 100, ]
colnames(top_reviewers) <- c("Writer", "num_reviews", "Average_Score", "avg_review_length")
top_reviewers$Reviews <- ifelse(top_reviewers$num_reviews<200, "100+", 
                              ifelse(top_reviewers$num_reviews<300, "200+",
                                     ifelse(top_reviewers$num_reviews<400, "300+",
                                            ifelse(top_reviewers$num_reviews<500, "400+", "500+"))))#group number of reviews for coloring in bar chart

#need to factor the num_reviews so bars will plot in correct order
top_reviewers$Writer <- factor(top_reviewers$Writer, levels = top_reviewers$Writer[order(top_reviewers$num_reviews)])

## Truncate the avg word length
top_reviewers$avg_review_length <- trunc(top_reviewers$avg_review_length)

## Create a bar plot of the top_reviewers table
reviews <- ggplot(data=top_reviewers, aes(x=Writer, y=Average_Score, fill=Reviews)) + geom_bar(stat="identity") + 
  scale_fill_manual(values=c("#0A2547", "#14407A", "#105EC4", "#448CEB", "#8CBEFF")) + 
  theme(axis.text.x = element_text(angle=320, size=12, colour="black", hjust=0)) +
  scale_y_continuous(limits = c(0, 10), breaks=0:10) +
  geom_text(data=top_reviewers,aes(x=Writer,y=Average_Score, label=avg_review_length),vjust=-1, size=3)

ggsave("C:/users/ben/documents/github/Beard_Envy/output/Reviewers_BarChart.png", reviews, width=10, height=7, units="in")


song_summary <- paste("select artist, count(distinct album) as albums, avg(score) as avg_score 
                      from ReviewContent 
                      group by artist 
                      order by avg_score")


best_artists <- sqlQuery(Pitch4k, song_summary, error=TRUE)

## subset to just the bands with more than 5 albums
most_albums <- best_artists[best_artists$albums>7,]
highest_rated <- best_artists[best_artists$avg_score>9,]

test_mem <- paste("select reviewr, convert(editorial USING utf8) as review from reviewcontent")
BIG <- sqlQuery(Pitch4k, test_mem, error=TRUE)


#subset to only our top 30 writers
test <- BIG[BIG$reviewr %in% top_reviewers$Writer,]

#create corpus
pitch4k_rev_text <- Corpus(VectorSource(test$review))
#clean up
pitch4k_rev_text <- tm_map(pitch4k_rev_text, tolower) 
pitch4k_rev_text <- tm_map(pitch4k_rev_text, removePunctuation)
pitch4k_rev_text <- tm_map(pitch4k_rev_text, function(x) removeWords(x,stopwords("english")))
# So... stemming real f-es everything up eh?
#pitch4k_rev_text <- tm_map(pitch4k_rev_text, stemDocument)

#list of other words to remove
stop_words <- c("actual", "albums",  "actually", "one", "since", "now", "also", "doesnt", "dont", "put", "get", "around", "just", "though", 
                "thereds", "theyre", "called", "like", "ultimately", "hes", "come", "got", "goes", "gets", "youre", "side",
                "didnt", "let", "may", "thats", "almost", "along", "also", "alway", "made", "actually",  "along", "already", 
                "also", "always", "another", "anything", "around",   "away",  "back", "bands", "beats", "behind",
                "can", "cant", "come", "comes", "didnt", "doesnt", "dont", "drums", "either", "enough", "especially",
                "even", "ever", "every", "everything", "feels", "get", "gets", "give", "goes", "going", "got", "guitars",
                "hes", "however", "instead", "isnt", "just", "keep", "know", "later", "left", "let", "like", "lines", "lot",
                "made", "make", "makes", "making", "man", "many", "may", "maybe", "melody", "might", "moment", "mostly", 
                "much", "nearly", "need", "nothing", "now", "perhaps", "playing", "probably", "put", "quite", "rather",
                "really", "records", "released", "say", "second", "see", "seem", "seems", "side", "since", "someone", 
                "something", "sometimes", "songs", "sort", "sounds", "take", "takes", "thats", "theres", "theyre", "theyve",
                "thing", "things", "though", "times", "vocals", "way", "whether", "whose", "will", "without", "words", "works",
                "years", "said", "used", "arent", "shows", "came", "certainly", "getting", "sure", "else", "played", "plays", "coming",
                "use", "john", "ways", "shes", "within", "ones", "several", "whats", "gives", "likely", "particularly", "guy", "guys", 
                "taking", "certain", "still")
pitch4k_rev_text <- tm_map(pitch4k_rev_text, function(x) removeWords(x,stop_words))


## Check the document term matrix for words that you want to get rid of
dtm <- DocumentTermMatrix(pitch4k_rev_text)

# Take a peek at the high freq words that will be in wordcloud, if any should be removed, add to list above and re-run the stripping of
## stop words
findFreqTerms(dtm, lowfreq=800)






pal2 <- brewer.pal(3,"Dark2")

#
#p4.tdm=TermDocumentMatrix(pitch4k_rev_text)
#p4.m=as.matrix(p4.tdm)
#p4.v=sort(rowSums(p4.m),decreasing=TRUE)



png("C:/users/ben/documents/github/Beard_Envy/output/Reviews_WrdCld.png", width=12,height=8, units='in', res=350)
wordcloud(pitch4k_rev_text, max.words=250, random.color=TRUE, colors=pal2, scale=c(5,.5))
dev.off()

## Method below doesn't allow for choosing the resulution like above, but does allow for preview
wrd_cld <- wordcloud(pitch4k_rev_text, max.words=250, random.color=TRUE, colors=pal2, scale=c(4.5,.2))
ggsave("C:/users/ben/documents/github/Beard_Envy/output/Reviews_WrdCld.png", wrd_cld, width=8, height=8, units="in")




### Look at bands with 5+ reviews and observe change in score

sql <- paste("select artist, album, score, date_of_review from ReviewContent") 
album_scores <- sqlQuery(Pitch4k, sql, error=TRUE)


moar_albums <- sqldf("select artist, count(album) as albums, avg(score) as avg_score from album_scores group by artist")

most_albums <- moar_albums[moar_albums$albums>=5,]
most_scores <- album_scores[album_scores$artis %in% most_albums$artist, ]

## Look at the relationship between the number of albums reviewed and the average score
num.albs.score <- sqldf("select albums, avg(avg_score) as avg_score from moar_albums group by albums")

#get rid of the "various artist" 
num.albs.score <- num.albs.score[num.albs.score$albums < 100,]

#plot the results
avg.by.reviews <- ggplot(data=num.albs.score, aes(x=albums, y=avg_score)) + geom_bar(stat="identity") +
  scale_y_continuous(limits = c(0, 10), breaks=0:10, name="Average Score") +
  scale_x_discrete(name="Number of Albums Reviewed") +
  theme(axis.title.x = element_text(face="bold", size=20), axis.title.y = element_text(face="bold", size=20))


# scatter plot of individual bands by number of albums reviewd and their avg score
#First need to get rid of the "Various Artists" row which f-es everything up
moar_albums <- moar_albums[moar_albums$albums<200,]
test <- moar_albums[moar_albums$albums>1,]

## can use the 'test' or 'moar_albums' dataframe below and get similar result.
ggplot(data=moar_albums, aes(x=albums, y=avg_score)) +  geom_point(shape="a") +
  geom_smooth(method=lm) +
  scale_y_continuous(limits = c(0, 10), breaks=0:10, name="Average Score") +
  scale_x_discrete(name="Number of Albums Reviewed") +
  theme(axis.title.x = element_text(face="bold", size=20), axis.title.y = element_text(face="bold", size=20))


## Order the albums in in order to plot the change in an albums first through last
ordered <- sqldf("select a.*, b.albums as num_albs from album_scores as a left join moar_albums as b on a.artist=b.artist order by artist")

#Get rid of the 'Various Artists'
ordered <- ordered[ordered$artist!="Various Artists",]
ordered$alb_num <- "1"
ordered <- as.matrix(ordered)

a=1
for (x in 1:(nrow(ordered)-1)){
  if(a==1){
    ordered[x,6] <- "1"
  }
  else {
   ordered[x,6]<- as.character(as.numeric((ordered[(x-1),6])) + 1) 
  }
  
  if(ordered[x,1]==ordered[(x+1),1]) {
    a <- a+1
  }
  else {
    a <- 1
  }
}

## Convert that matrix back to a data frame
ordered <- as.data.frame(ordered)


## The number of albums is currently a string so need to factor and order
#ordered$alb_num <- factor(ordered$alb_num, levels=c("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19"), ordered=TRUE)
ordered$alb_num <- as.numeric(levels(ordered$alb_num))[ordered$alb_num]
ordered$score <- as.numeric(levels(ordered$score))[ordered$score]
ordered$num_albs <- as.numeric(levels(ordered$num_albs))[ordered$num_albs]

## create a color scheme for # albums reviewed
ordered$color <- ifelse(ordered$num_albs==1, 1, ifelse(ordered$num_albs<=5,2, ifelse(ordered$num_albs<=10, 3, ifelse(ordered$num_albs<=15, 4, 5))))

## create another layer that shows just the average
avg <- sqldf("select alb_num, avg(score) as avg_score from ordered group by alb_num")
avg$alb_num <- as.numeric(levels(avg$alb_num))[avg$alb_num]

##plot the # album from a band against its score and overlay the average points
improving <- ggplot(data=ordered, aes(x=alb_num, y=score)) + geom_point(shape=10, size=2) +
  #stat_smooth(method = "lm", formula = y ~ poly(x,2), size = 1) +
  geom_point(data=avg, mapping=aes(x=alb_num, y=avg_score), color="blue", size=5) +
  scale_y_continuous(limits = c(0, 10), breaks=0:10, name="Album Score") +
  scale_x_discrete(name="Band's Reviewed Album Number") +
  theme(axis.title.x = element_text(face="bold", size=20), axis.title.y = element_text(face="bold", size=20))

ggsave("C:/users/ben/documents/github/Beard_Envy/output/pitchfork_bias.png", improving, width=10, height=7, units="in")

## Model
mod <- lm(ordered$alb_num ~ ordered$score)
head(fortify(mod))


## Take a peek at the most reviewed bands
freq.bands <- paste("select artist, count(album) as Albums_Reviewed, avg(score) as avg_score, 
                    avg(char_length(convert(editorial USING utf8)) - char_length(REPLACE(convert(editorial USING utf8), ' ', '')) + 1) as Avg_review_length
                    from ReviewContent
                    group by artist")

freq.bands <- sqlQuery(Pitch4k, freq.bands, error=TRUE)

#get rid of the various artists
freq.bands <- freq.bands[freq.bands$artist!="Various Artists",]
freq.bands$color <- ifelse(freq.bands$Albums_Reviewed<6, 1, ifelse(freq.bands$Albums_Reviewed<=7,2, ifelse(freq.bands$Albums_Reviewed<=8, 3, ifelse(freq.bands$Albums_Reviewed<=9, 4, 5))))


score.vs.length <- ggplot(data=freq.bands, aes(x=avg_score, y=Avg_review_length)) + geom_point(shape="a") +
  stat_smooth(method = "lm", formula = y ~ poly(x,4), size = 1) +
  scale_y_continuous(limits = c(0, 2750), breaks=c(0, 500, 1000, 1500, 2000, 2500), name="Average Review Word Count") +
  scale_x_continuous(breaks=c(1:10), name="Average Review Score") +
  theme(axis.title.x = element_text(face="bold", size=20), axis.title.y = element_text(face="bold", size=20))

ggsave("C:/users/ben/documents/github/Beard_Envy/output/pitchfork_scoreVSlength.png", score.vs.length, width=10, height=7, units="in")

mod <- lm(freq.bands$avg_score ~ poly(freq.bands$Avg_review_length, 4))
summary(mod)

