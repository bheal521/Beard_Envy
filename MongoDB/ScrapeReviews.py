# -*- coding: utf-8 -*-
"""
Created on Thu Feb 05 19:43:32 2015

@author: Ben
"""

import urllib2
from pymongo import Connection
from bs4 import BeautifulSoup

## Main program that will scrape Pitchfork data using other functions created by ME

## Connect to the MongoDB
con = Connection()
db = con.pitch4kdb
links = db.links

## Function that scrapes an individual review
def reviewScrape(link):
    baseurl= "http://pitchfork.com" + str(link)
    
    try:
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
        post = {'link':link, 'status':'scraped', 'artist':artist, 'album': album, 'score': score, 'label':label, 'rev_date': rev_date, 'reviewer':reviewer, 'review': editorial}
        links.update({'link':link}, {'$set':post}, upsert=False)
    except:
        print "Didn't Work: " + str(link)


## Query DB for all links that have a status of 'unscraped'
unscraped = []
for link in links.find({"status": "unscraped"}):
    unscraped.append(link['link'].encode('ascii', 'ignore'))

## Loop through to run the scrape on each link fed to it
for x in range(0,len(unscraped)):
	reviewScrape(unscraped[x])
	print x ## not needed but I want to see progress in terminal


## close out the connection with the MongoDB
con.close()