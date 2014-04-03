library("RODBC")
library("wordcloud")
library("tm")
library("RColorBrewer")
library("ggplot2")
library("grep")
library("SnowballC")


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

#list of other words to remove
stop_words <- c("one", "since", "now", "also", "doesnt", "dont", "put", "get", "around", "just", "though", 
                "thereds", "theyre", "called", "like", "ultimately", "hes", "come", "got", "goes", "gets", "youre", "side",
                "didnt", "let", "may", "thats")
pitch4k_rev_text <- tm_map(pitch4k_rev_text, function(x) removeWords(x,stop_words))
pitch4k_rev_text <- tm_map(pitch4k_rev_text, stemDocument)



pal2 <- brewer.pal(8,"Dark2")

#
#p4.tdm=TermDocumentMatrix(pitch4k_rev_text)
#p4.m=as.matrix(p4.tdm)
#p4.v=sort(rowSums(p4.m),decreasing=TRUE)

png("C:/users/ben/documents/github/Beard_Envy/output/Reviews_WrdCld.png", width=12,height=8, units='in', res=300)
wordcloud(pitch4k_rev_text, max.words=250, random.color=TRUE, colors=pal2, scale=c(4.5,.2))
dev.off()

ggsave("C:/users/ben/documents/github/Beard_Envy/output/Reviews_WrdCld.png", wrd_cld, width=8, height=8, units="in")
