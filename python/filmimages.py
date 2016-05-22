from flask import Flask, send_file
import requests
import io

app = Flask(__name__)

api_url = "http://omdbapi.com/?"
cert_root = "<REDACTED>"

@app.route("/img/<imdbID>")
def get_img(imdbID):
    payload = {'i': imdbID, 'r': 'json'}
    response = requests.post(api_url, params=payload)
    retval = response.json()

    img_url = retval["Poster"]
    img = requests.get(img_url)
    file = io.BytesIO(img.content)

    return send_file(file)

if (__name__) == "__main__":
    context = (cert_root + "cert.pem", cert_root + "privkey.pem")
    print(context)
    app.run(host='0.0.0.0', ssl_context=context)
