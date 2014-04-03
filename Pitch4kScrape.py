import urllib2
import MySQLdb
from bs4 import BeautifulSoup


## Main program that will scrape Pitchfork data using other functions created by ME

## Function that scrapes an individual review
def reviewScrape(link):

	baseurl= "http://pitchfork.com" + link
	page = urllib2.urlopen(baseurl).read()

	soup = BeautifulSoup(page)

	## Extract the meta-data for the album
	for ul in soup.findAll('ul', {"class" : "review-meta"}):
		for div in ul.findAll('div', {"class" : "info"}):
			artist = div.find('h1').text.strip()
			album = div.find('h2').text.strip()
			score = div.findAll('span')[1].text.strip()
			label = div.find('h3').text.strip()
			rev_date = div.find('h4').text.split(";")[1].strip()
			reviewer = div.find('h4').text.split(";")[0].strip()[3:]

	editorial = soup.find('div', {"class" : "editorial"}).text.encode("ascii", "ignore").strip()

	## Connect to database and create cursor
	db = MySQLdb.connect(host = "localhost", user = "admin", passwd = "admin", db = "Pitch4k" )
	cursor = db.cursor()
	
	## Get the row number for this link/review to put in the ID of this table
	cursor.execute("""SELECT idReviewLinks FROM ReviewLinks WHERE Link = %s""", [(link)])
	id = str(cursor.fetchone()[0])
	
	
	try:
		cursor.execute("""INSERT INTO ReviewContent(artist, album, score, label, date_of_review, reviewr, editorial, ReviewLinks_idReviewLinks) Values (%s, %s, %s, %s, %s, %s, %s, %s)""", (artist, album, score, label, rev_date, reviewer, editorial, id))
		cursor.execute("""UPDATE ReviewLinks SET Status=%s WHERE Link=%s""", ('complete', link))
	except:
		db.rollback()
		
	db.commit()
	db.close()


## Connect to database
db = MySQLdb.connect(host = "localhost", user = "admin", passwd = "admin", db = "Pitch4k" )
cursor = db.cursor()

##Run query to get the links of reviews that have not been scraped yet, Status = 'Waiting'
cursor.execute("""SELECT Link from ReviewLinks WHERE Status = %s""", [('Waiting')])
links = cursor.fetchall()
db.close()

## Loop through to run the scrape on each link fed to it
for x in range(0,len(links)):
	reviewScrape(links[x][0])
	print x ## not needed but I want to see progress in terminal