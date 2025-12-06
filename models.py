from pydantic import BaseModel
from typing import Dict, List, Union, Any

class SQLRequest(BaseModel):
    user_api_key: str
    user_query: str
    table_schema: Union[Dict[str, List[str]], str]
    model_id: str


class SQLResponse(BaseModel):
    sql_query: str
    confidence: float
    tokens_generated: int
    latency_ms: float
    # model_prompt:str
