import time
from fastapi import APIRouter, Request
from ..models import SQLRequest, SQLResponse
from ..prompts import build_sql_prompt
from ..ollama_client import query_ollama_with_client
from ..logger import log_request, log_response
from ..config import DEFAULT_MODEL

router = APIRouter()
@router.get("/health")
def health_check():
    return {"status": "ok"}

@router.post("/generate_sql", response_model=SQLResponse)
async def generate_sql(req: SQLRequest, request: Request):

    # -------------------------
    # Log incoming request
    # -------------------------
    log_request({
        "event": "request_received",
        "path": request.url.path,
        "user_api_key": req.user_api_key,
        "user_query": req.user_query,
        "table_schema": req.table_schema
    })

    start_time = time.time()

    prompt = build_sql_prompt(req.user_query, req.table_schema)

    model = req.model_id or DEFAULT_MODEL
   
    result = query_ollama_with_client(prompt, model)


    sql = result["query"]
    conf = result["confidence"]
    tokens = result["tokens"]
    # raw_op = result["raw_output"]

    latency_ms = round((time.time() - start_time) * 1000, 2)

    # -------------------------
    # Log outgoing response
    # -------------------------
    log_response({
        "event": "response_sent",
        "sql_query": sql,
        "confidence": conf,
        "tokens_generated": tokens,
        "latency_ms": latency_ms
    })

    return SQLResponse(
        sql_query=sql,
        confidence=conf,
        tokens_generated=tokens,
        latency_ms=latency_ms,
        # model_prompt=raw_op
    )

