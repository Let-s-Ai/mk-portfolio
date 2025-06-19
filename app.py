from flask import Flask, render_template, send_from_directory
import os

app = Flask(__name__)

# Ensure the static/images directory exists
os.makedirs(os.path.join(app.static_folder, 'images'), exist_ok=True)

@app.route('/')
def home():
    return render_template('home.html')

@app.route('/resume')
def resume():
    return render_template('resume.html')

# Serve static files from the static directory
@app.route('/static/<path:filename>')
def serve_static(filename):
    return send_from_directory('static', filename)

if __name__ == '__main__':
    app.run(debug=True)
