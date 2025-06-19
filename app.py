from flask import Flask, render_template

app = Flask(__name__)

# Simple route handlers
@app.route('/')
def home():
    return render_template('home.html')

@app.route('/about')
def about():
    return render_template('home.html')

@app.route('/resume')
def resume():
    return render_template('resume.html')

# Basic error handlers
@app.errorhandler(404)
def not_found(e):
    return render_template('404.html'), 404

@app.errorhandler(500)
def server_error(e):
    return render_template('500.html'), 500

if __name__ == '__main__':
    # Run with debug=False for production
    app.run(host='0.0.0.0', port=80, debug=False)
  