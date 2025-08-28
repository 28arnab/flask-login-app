from flask import Flask, render_template, request, redirect, url_for, session
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
app.secret_key = "supersecretkey"

# SQLite Database
# Database configuration
DATABASE_URL = os.environ.get("DATABASE_URL")  # Provided by Heroku
if DATABASE_URL:
    # Fix Heroku’s postgres:// URL format
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)
    app.config["SQLALCHEMY_DATABASE_URI"] = DATABASE_URL
else:
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
