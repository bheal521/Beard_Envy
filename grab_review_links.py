import MySQLdb

def pitchRevLinks(page_num):
	import urllib2
	from bs4 import BeautifulSoup

	baseurl= "http://pitchfork.com/reviews/albums/" + str(page_num)
	page = urllib2.urlopen(baseurl).read()

	soup = BeautifulSoup(page)

	review_links = []

	for ul in soup.findAll('ul', { "class" : "object-grid" }):
		for a in ul.findAll('a'):
			review_links.append(a['href'])
			
	return review_links

link_db = []

## Set this up to run through however many pages you're interested in, will fetch link
## Currently there are 809 pages of links
for x in range(1,809):
	link_db = link_db + pitchRevLinks(x)

## Need to write code that will take the list of links and store in DB, also with current status of whether or 
## not the particular review's website has been scraped and successfully stored.
db = MySQLdb.connect(host = "localhost", user = "admin", passwd = "admin", db = "Pitch4k" )

cursor = db.cursor()

for x in range(0,len(link_db)):
	try:
		cursor.execute("""INSERT INTO ReviewLinks(Link, Status) Values (%s, %s)""", (link_db[x], "Waiting"))
	except:
		db.rollback()
		
db.commit()		
# disconnect from server
db.close()