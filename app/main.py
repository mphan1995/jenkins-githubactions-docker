from fastapi import FastAPI
import os

app = FastAPI(title="Max Phan API")

@app.get("/")
def read_root():
    return {
        "message": "Hello from Max Phan CI/CD demo , this from the PY",
        "env": os.getenv("ENV", "dev")
    }
