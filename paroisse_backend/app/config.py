# app/config.py
import os

DATABASE_URL = os.getenv("DATABASE_URL", "mysql+pymysql://root:@localhost/paroisse_db")
