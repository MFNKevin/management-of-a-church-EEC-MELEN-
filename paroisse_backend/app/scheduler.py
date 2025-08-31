# app/scheduler.py

from apscheduler.schedulers.background import BackgroundScheduler
from app.database import SessionLocal
from app.utils.stock_alerts import verifier_alertes_stock

def job_verifier_alertes():
    db = SessionLocal()
    try:
        verifier_alertes_stock(db)
    finally:
        db.close()

def start_scheduler():
    scheduler = BackgroundScheduler()
    scheduler.add_job(job_verifier_alertes, 'interval', hours=24)  # exécute toutes les 24h
    scheduler.start()
    return scheduler
