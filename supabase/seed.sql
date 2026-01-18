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

