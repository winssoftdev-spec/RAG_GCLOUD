def build_sql_prompt(user_query: str, table_schema):
    """
    Build a clean, structured SQL generation prompt for LLMs.
    Supports dict-structured schemas and plain text schemas.
    """

    # -------------------------
    # Format table schema
    # -------------------------
    schema_text = ""

    # Case 1: schema = dict { "table": [cols...] }
    if isinstance(table_schema, dict):
        schema_lines = ["Database Schema:"]
        for table_name, columns in table_schema.items():
            col_list = ", ".join(columns)
            schema_lines.append(f"- {table_name}({col_list})")
        schema_text = "\n".join(schema_lines)

    # Case 2: schema is already a string
    elif isinstance(table_schema, str):
        schema_text = f"Database Schema:\n{table_schema}"

    # -------------------------
    # Build final prompt
    # -------------------------
    prompt = f"""
You are an SQL query generator. Convert the user question into a safe,
syntactically correct SQL query.

RULES:
- ONLY output a JSON object with TWO keys:
  - "query": SQL string
  - "confidence": decimal between 0 and 1
- Output must be valid JSON.
- Do NOT output natural language explanations.
- Do NOT hallucinate table names or columns.
-If you output anything other than a JSON object, the system will throw an error.
-DO NOT use markdown formatting.
-DO NOT wrap code in ```json or ```sql.
-Return ONLY the raw JSON object.

- If unsure, return:
  {{
    "query": "",
    "confidence": 0.0
  }}

{schema_text}

User Question:
{user_query}

Return ONLY the JSON.
"""

    return prompt.strip()
