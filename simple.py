from flask import Flask
from sentence_transformers import SentenceTransformer


app = Flask(__name__)
model = SentenceTransformer("all-MiniLM-L6-v2")


@app.route("/")
def hello_world():
    model.encode("this is a test")
    return "ok"
