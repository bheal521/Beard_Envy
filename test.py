import urllib2
import MySQLdb
from bs4 import BeautifulSoup


baseurl= "http://pitchfork.com/reviews/albums/19125-the-range-panasonic-ep/"
link = "/reviews/albums/19125-the-range-panasonic-ep/"
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

db = MySQLdb.connect(host = "localhost", user = "admin", passwd = "admin", db = "Pitch4k" )
cursor = db.cursor()

cursor.execute("""SELECT idReviewLinks FROM ReviewLinks WHERE Link = %s""", [(link)])
id = str(cursor.fetchone()[0])


cursor.execute("""INSERT INTO ReviewContent(artist, album, score, label, date_of_review, reviewr, editorial, ReviewLinks_idReviewLinks) Values (%s, %s, %s, %s, %s, %s, %s, %s)""", (artist, album, score, label, rev_date, reviewer, editorial, id))
cursor.execute("""UPDATE ReviewLinks SET Status=%s WHERE Link=%s""", [('Complete', link)])

		
db.commit()
db.close()
