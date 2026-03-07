from pymongo import MongoClient

# ===== MongoDB =====
mongo_client = MongoClient("mongodb://127.0.0.1:27017")
db = mongo_client.voicenotex
users = db.users
