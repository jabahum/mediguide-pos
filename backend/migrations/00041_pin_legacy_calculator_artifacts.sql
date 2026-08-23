-- +goose Up

-- Pin each quarantined legacy artifact to the reviewed source checksum. The
-- runtime independently verifies the packaged bytes before serving them.
UPDATE calculators
SET app_file_json = jsonb_set(
  app_file_json,
  '{sha256}',
  to_jsonb(CASE app_file_json->>'path'
    WHEN 'apgar-score-calculator.html' THEN '4b4ba682704ce5a95e745117e459b8a76a9bb6bce0e960cee57ff7d72106a677'
    WHEN 'blood-pressure-assessment.html' THEN '7a3ca6bb79e40c2ca14124287f025c375ba10809134a7c63f794a9102b0c4e2a'
    WHEN 'bmi-calculator.html' THEN '5317c90a25a1e1f00df9f3bfdb934e5f91c1e5944e8bde266497640804d98391'
    WHEN 'cardiac-risk-assessment.html' THEN '3f801e2205c368fdda49af1b428a6fc00bd9235cf3e59e62564fc4bf6e1e9f6a'
    WHEN 'dehydration-assessment.html' THEN '1e007a6d5908a4f25739e73a7424df0c44b14b81216258c800f6ec161e4d9597'
    WHEN 'emergency-triage-assessment.html' THEN '086efb599f8c535faa94f589d19b477e0bef3afd635ca0a0ccb7ee3c061c7420'
    WHEN 'fluid-balance-calculator.html' THEN '6aaf110ccee6d2032c0ada4a16e60c7247641372317e69f7bead65cb9269f090'
    WHEN 'glasgow-coma-scale.html' THEN '5f2ac864c148997e5f126b4691dda1226780e8ca61322637fa57af9de32e99d4'
    WHEN 'immunization-schedule-checker.html' THEN '6a5bf25184ccc0c9df9b666d1a50346851ff36d755cff146180536a7dac54030'
    WHEN 'medication-dosage-calculator.html' THEN '0b97e86b8cf06fb99e090afa852dc824b6f19e296d032ce24516c178974850bb'
    WHEN 'pain-assessment-scale.html' THEN '6f4231a0c9e348aa4479511328d683f81db3c6fc3b066322a076a47578dc7db5'
    WHEN 'pediatric-fever-management.html' THEN 'db1ae667c44ebe12a1cd6227e9faa033e2cd04e07d56b1d02f96cdf7f244e39d'
    WHEN 'pregnancy-due-date-calculator.html' THEN '4298a2ee251e8d9f0a6ec74d748cb37c1c694dae78aedc67c1ecf490fa4d4e5a'
    WHEN 'wound-assessment-tool.html' THEN '5fa5f696c90a583d61e8363068b914e1e1d5fadc57af7b7389a2609aff511675'
  END),
  true
)
WHERE runtime_type = 'legacy_html'
  AND app_file_json ? 'path'
  AND app_file_json->>'path' IN (
    'apgar-score-calculator.html', 'blood-pressure-assessment.html',
    'bmi-calculator.html', 'cardiac-risk-assessment.html',
    'dehydration-assessment.html', 'emergency-triage-assessment.html',
    'fluid-balance-calculator.html', 'glasgow-coma-scale.html',
    'immunization-schedule-checker.html', 'medication-dosage-calculator.html',
    'pain-assessment-scale.html', 'pediatric-fever-management.html',
    'pregnancy-due-date-calculator.html', 'wound-assessment-tool.html'
  );

-- +goose Down

UPDATE calculators
SET app_file_json = app_file_json - 'sha256'
WHERE runtime_type = 'legacy_html'
  AND app_file_json->>'path' IN (
    'apgar-score-calculator.html', 'blood-pressure-assessment.html',
    'bmi-calculator.html', 'cardiac-risk-assessment.html',
    'dehydration-assessment.html', 'emergency-triage-assessment.html',
    'fluid-balance-calculator.html', 'glasgow-coma-scale.html',
    'immunization-schedule-checker.html', 'medication-dosage-calculator.html',
    'pain-assessment-scale.html', 'pediatric-fever-management.html',
    'pregnancy-due-date-calculator.html', 'wound-assessment-tool.html'
  );
