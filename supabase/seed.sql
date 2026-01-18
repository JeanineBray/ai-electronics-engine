-- supabase/seed.sql
-- Seed data for AI Electronics Learning Engine (v1)
-- Inserts initial curriculum for DC Circuits foundations

insert into topics (id, name, description)
values (
  '11111111-1111-1111-1111-111111111111',
  'DC Circuits Foundations',
  'Fundamental DC circuit analysis: Ohm’s Law, KCL, KVL, and resistive networks.'
);

insert into objectives (
  topic_id,
  code,
  statement,
  rubric,
  common_errors
)
values (
  '11111111-1111-1111-1111-111111111111',
  'KCL-01',
  'Apply Kirchhoff’s Current Law to solve for an unknown node voltage.',
  '{
    "checks": [
      { "type": "units", "expected": "V" },
      { "type": "numeric_tolerance", "rel": 0.02, "abs": 0.05 }
    ]
  }',
  '[
    "sign_error",
    "wrong_reference_node",
    "units_error"
  ]'
);

insert into objectives (
  topic_id,
  code,
  statement,
  rubric,
  common_errors
)
values (
  '11111111-1111-1111-1111-111111111111',
  'KVL-01',
  'Apply Kirchhoff’s Voltage Law to write loop equations and solve for unknown currents or voltages.',
  '{
    "checks": [
      { "type": "units", "expected": "V" },
      { "type": "numeric_tolerance", "rel": 0.02, "abs": 0.05 }
    ]
  }',
  '[
    "sign_error",
    "incorrect_loop_direction",
    "algebra_error"
  ]'
);

insert into objectives (
  topic_id,
  code,
  statement,
  rubric,
  common_errors
)
values (
  '11111111-1111-1111-1111-111111111111',
  'RES-01',
  'Analyze series and parallel resistive networks to compute equivalent resistance and voltages.',
  '{
    "checks": [
      { "type": "units", "expected": "Ohms" },
      { "type": "numeric_tolerance", "rel": 0.01, "abs": 0.1 }
    ]
  }',
  '[
    "series_parallel_confusion",
    "arithmetic_error",
    "units_error"
  ]'
);

-- ===========================================================
-- Problem templates: KCL-01 (Kirchhoff’s Current Law)
-- ===========================================================

insert into problem_templates (
  objective_id,
  title,
  difficulty,
  params_schema,
  generator_spec,
  solution_spec
)
select
  o.id,
  'KCL node voltage with source resistor and two resistors to ground',
  1,
  '{
    "type": "object",
    "required": ["Vs", "R1", "R2", "R3"],
    "properties": {
      "Vs": { "type": "number", "minimum": 1, "maximum": 24 },
      "R1": { "type": "number", "minimum": 10, "maximum": 100000 },
      "R2": { "type": "number", "minimum": 10, "maximum": 100000 },
      "R3": { "type": "number", "minimum": 10, "maximum": 100000 }
    }
  }',
  '{
    "prompt_template": "A voltage source Vs feeds a resistor R1 into node Vx. From Vx to ground are R2 and R3 in parallel. Given Vs={{Vs}} V, R1={{R1}} Ω, R2={{R2}} Ω, R3={{R3}} Ω, find Vx (in volts).",
    "answer_units": "V",
    "constraints": [
      "Apply KCL at node Vx or reduce R2 and R3 to an equivalent resistance",
      "Assume ideal resistors and an ideal voltage source"
    ],
    "difficulty_notes": "Single-node KCL with parallel equivalent resistance"
  }',
  '{
    "answer_field": "Vx",
    "method": "parallel_equivalent_then_divider",
    "formula": {
      "Req": "1 / (1/R2 + 1/R3)",
      "Vx": "Vs * (Req / (R1 + Req))"
    },
    "numeric": {
      "tolerance_rel": 0.02,
      "tolerance_abs": 0.05
    },
    "common_error_tags": [
      "sign_error",
      "wrong_reference_node",
      "algebra_error",
      "units_error"
    ]
  }'
from objectives o
where o.code = 'KCL-01';
