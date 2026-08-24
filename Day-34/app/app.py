import os
from flask import Flask
import redis

app = Flask(__name__)

cache = redis.Redis(host='cache', port=6379)

@app.route('/')
def hello():
    count = cache.incr('hits')
    return f"🛠️ SRE Web App UPDATED! This page has been viewed {count} times."
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)