library(rmongodb)


### Connect the the pitch4kdb MongoDB ###
### List the collections within db    ###

mongo <- mongo.create(host="127.0.0.1" , db="pitch4kdb")
mongo.is.connected(mongo)
mongo.get.database.collections(mongo, "pitch4kdb")


