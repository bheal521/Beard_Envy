# -*- coding: utf-8 -*-
"""
Created on Thu Feb 05 13:04:19 2015

@author: Ben
"""
## First you need to get the MONGO database up and running using the command line
## I got it to work doing the following at the command prompt:
## cd C:\mongodb\bin
## mongod.exe --config="C:\mongodb\log\mongodb.log" --dpath="C:\mongodb\data\db"

from pymongo import Connection
import urllib2
from bs4 import BeautifulSoup


## create a function that grabs the links to all of the Pitchfork reviews
def pitchRevLinks(page_num):

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






## now connect to the MongoDB and store these link values
con = Connection()
    
## if the pitch4kDB rexists it will connect, otherwise it will be created
db = con.pitch4kdb
    
## create a 'tab;e" called links in which to store this list of links
links = db.links
    
    
for x in range(0, len(link_db)):
    links.insert({'link':link_db[x], 'status': 'unscraped'})

## based on the output below we can see that we successfully put all 16,160 links in the DB
links.count()

con.disconnect()