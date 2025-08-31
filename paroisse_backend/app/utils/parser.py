# app/utils/parser.py
import json
from app.models.reunion import Reunion

def parse_reunion_convoques(reu: Reunion):
    if reu.convoques:
        try:
            reu.convoques = json.loads(reu.convoques)
        except Exception:
            reu.convoques = []
    else:
        reu.convoques = []
    return reu
