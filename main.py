from fastapi import FastAPI
from .routes.sql_generator import router

app = FastAPI(
    title="SQL Generator Backend",
    version="1.0.0"
)

app.include_router(router)



@app.get("/")
def root():
    return {"message": "SQL Generator Backend Running"}
