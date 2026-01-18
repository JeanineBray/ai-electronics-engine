import random
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from app.auth import get_current_user_id
from app.db import supabase

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"status": "ok"}

@app.get("/health/db")
def health_db():
    # Try a real query: fetch up to 5 topics
    res = supabase.table("topics").select("id,name,description").limit(5).execute()

    # supabase-py returns an object; .data is the rows
    return {
        "ok": True,
        "row_count": len(res.data or []),
        "topics": res.data
    }

@app.get("/objectives")
def list_objectives():
    res = supabase.table("objectives").select("id,code,statement").order("code").execute()
    return {"objectives": res.data}

def pick_params(schema: dict) -> dict:
    props = schema.get("properties", {})
    required = schema.get("required", [])
    params = {}

    for k in required:
        spec = props[k]
        lo = float(spec.get("minimum", 1))
        hi = float(spec.get("maximum", 10))

        # nice resistor values (E12-ish) for readability
        if k.startswith("R"):
            params[k] = random.choice([100, 220, 330, 470, 680, 1000, 2200, 3300, 4700])
        else:
            params[k] = random.randint(int(lo), int(hi))

    return params

def render_prompt(prompt_template: str, params: dict) -> str:
    text = prompt_template
    for k, v in params.items():
        text = text.replace("{{" + k + "}}", str(v))
    return text

@app.post("/problems/generate/{objective_code}")
def generate_problem(objective_code: str):
    # 1) find objective
    obj = supabase.table("objectives").select("id,code").eq("code", objective_code).limit(1).execute().data
    if not obj:
        raise HTTPException(404, f"Objective code not found: {objective_code}")
    objective_id = obj[0]["id"]

    # 2) find a template for that objective
    tmpl = (
        supabase.table("problem_templates")
        .select("id,params_schema,generator_spec,solution_spec,difficulty,title")
        .eq("objective_id", objective_id)
        .limit(1)
        .execute()
        .data
    )
    if not tmpl:
        raise HTTPException(404, f"No problem templates found for objective: {objective_code}")
    tmpl = tmpl[0]

    # 3) choose parameters + render
    params = pick_params(tmpl["params_schema"])
    prompt = render_prompt(tmpl["generator_spec"]["prompt_template"], params)

    rendered = {
        "prompt": prompt,
        "params": params,
        "units": tmpl["generator_spec"].get("answer_units", "")
    }

    # 4) store problem instance
    inserted = supabase.table("problems").insert({
        "template_id": tmpl["id"],
        "objective_id": objective_id,
        "params": params,
        "rendered": rendered,
        "answer_key": tmpl["solution_spec"]
    }).execute().data[0]

    return {
        "problem_id": inserted["id"],
        "objective_code": objective_code,
        "prompt": rendered["prompt"],
        "params": rendered["params"],
        "expected_units": rendered["units"]
    }

@app.post("/attempts/grade/{problem_id}")
def grade_attempt(problem_id: str, value: float, units: str = "V", user_id: str = Depends(get_current_user_id)):
    # load problem
    prob = supabase.table("problems").select("id,params,answer_key").eq("id", problem_id).limit(1).execute().data
    if not prob:
        raise HTTPException(404, "Problem not found")
    prob = prob[0]

    params = prob["params"]
    # KCL-01 solver: Vx = Vs * (Req / (R1 + Req)), Req = 1/(1/R2 + 1/R3)
    Vs = float(params["Vs"])
    R1 = float(params["R1"])
    R2 = float(params["R2"])
    R3 = float(params["R3"])

    Req = 1.0 / (1.0/R2 + 1.0/R3)
    correct = Vs * (Req / (R1 + Req))

    # tolerance (match what we seeded)
    tol_rel = 0.02
    tol_abs = 0.05
    ok_units = units.strip().lower() in ["v", "volt", "volts"]
    ok_value = abs(value - correct) <= max(tol_abs, tol_rel * abs(correct))
    is_correct = ok_units and ok_value

    feedback = f"Correct Vx ≈ {correct:.2f} V. " + ("✅ Nice work." if is_correct else "❌ Recheck your setup/units.")

    # Store attempt (user_id/session_id later; for now use a placeholder user_id)
    # NOTE: We'll wire real user_id from Supabase Auth when we connect frontend.
    attempt = supabase.table("attempts").insert({
        "user_id": user_id,
        "session_id": None,
        "problem_id": prob["id"],
        "answer": {"value": value, "units": units},
        "work_shown": None,
        "is_correct": is_correct,
        "score": 1.0 if is_correct else 0.0,
        "error_tags": ([] if is_correct else ["units_error"] if not ok_units else ["algebra_error"]),
        "feedback": feedback
    }).execute().data[0]

    return {
        "is_correct": is_correct,
        "your_value": value,
        "your_units": units,
        "correct_value": round(correct, 4),
        "feedback": feedback,
        "attempt_id": attempt["id"]
    }

@app.get("/me")
def me(user_id: str = Depends(get_current_user_id)):
    return {"user_id": user_id}