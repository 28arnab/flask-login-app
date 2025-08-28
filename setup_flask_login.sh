#!/data/data/com.termux/files/usr/bin/bash

# Go to home dir
cd ~

# Make project directory
mkdir -p flask_login_app/templates
cd flask_login_app

# Install dependencies
pip install flask flask_sqlalchemy werkzeug gunicorn

# Create app.py
cat > app.py << 'EOF'
from flask import Flask, render_template, request, redirect, url_for, session
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
app.secret_key = "supersecretkey"

# SQLite Database
app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///users.db"
db = SQLAlchemy(app)

# User Model
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(150), unique=True, nullable=False)
    password = db.Column(db.String(150), nullable=False)
    role = db.Column(db.String(50), nullable=False)  # student or teacher

# Routes
@app.route("/")
def home():
    if "user" in session:
        if session["role"] == "student":
            return redirect(url_for("student_dashboard"))
        elif session["role"] == "teacher":
            return redirect(url_for("teacher_dashboard"))
    return redirect(url_for("login"))

@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        email = request.form["email"]
        password = request.form["password"]
        role = request.form["role"]

        hashed_pw = generate_password_hash(password, method="sha256")
        new_user = User(email=email, password=hashed_pw, role=role)

        db.session.add(new_user)
        db.session.commit()
        return redirect(url_for("login"))

    return render_template("register.html")

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email = request.form["email"]
        password = request.form["password"]
        role = request.form["role"]

        user = User.query.filter_by(email=email, role=role).first()

        if user and check_password_hash(user.password, password):
            session["user"] = user.email
            session["role"] = user.role
            if user.role == "student":
                return redirect(url_for("student_dashboard"))
            elif user.role == "teacher":
                return redirect(url_for("teacher_dashboard"))
        else:
            return "Invalid credentials or role!"
    return render_template("login.html")

@app.route("/student/dashboard")
def student_dashboard():
    if "user" in session and session["role"] == "student":
        return render_template("student_dashboard.html", user=session["user"])
    return redirect(url_for("login"))

@app.route("/teacher/dashboard")
def teacher_dashboard():
    if "user" in session and session["role"] == "teacher":
        return render_template("teacher_dashboard.html", user=session["user"])
    return redirect(url_for("login"))

@app.route("/logout")
def logout():
    session.pop("user", None)
    session.pop("role", None)
    return redirect(url_for("login"))

if __name__ == "__main__":
    with app.app_context():
        db.create_all()
    app.run(debug=True)
EOF

# requirements.txt
cat > requirements.txt << 'EOF'
flask
flask_sqlalchemy
werkzeug
gunicorn
EOF

# Procfile
cat > Procfile << 'EOF'
web: gunicorn app:app
EOF

# Templates
cat > templates/base.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Flask Login</title>
</head>
<body>
    <h1>Flask Login Example</h1>
    {% block content %}{% endblock %}
</body>
</html>
EOF

cat > templates/register.html << 'EOF'
{% extends "base.html" %}
{% block content %}
<form method="POST">
    <p>Email: <input type="email" name="email" required></p>
    <p>Password: <input type="password" name="password" required></p>
    <p>User Type:
        <select name="role" required>
            <option value="student">Student</option>
            <option value="teacher">Teacher</option>
        </select>
    </p>
    <button type="submit">Register</button>
</form>
<a href="{{ url_for('login') }}">Already have an account? Login</a>
{% endblock %}
EOF

cat > templates/login.html << 'EOF'
{% extends "base.html" %}
{% block content %}
<form method="POST">
    <p>Email: <input type="email" name="email" required></p>
    <p>Password: <input type="password" name="password" required></p>
    <p>User Type:
        <select name="role" required>
            <option value="student">Student</option>
            <option value="teacher">Teacher</option>
        </select>
    </p>
    <button type="submit">Login</button>
</form>
<a href="{{ url_for('register') }}">Don’t have an account? Register</a>
{% endblock %}
EOF

cat > templates/student_dashboard.html << 'EOF'
{% extends "base.html" %}
{% block content %}
<h2>Welcome, {{ user }}!</h2>
<p>This is the <b>Student Dashboard</b>.</p>
<a href="{{ url_for('logout') }}">Logout</a>
{% endblock %}
EOF

cat > templates/teacher_dashboard.html << 'EOF'
{% extends "base.html" %}
{% block content %}
<h2>Welcome, {{ user }}!</h2>
<p>This is the <b>Teacher Dashboard</b>.</p>
<a href="{{ url_for('logout') }}">Logout</a>
{% endblock %}
EOF

echo "✅ Setup complete!"
echo "Run the app with: python app.py"
