-- Portfolio addition: populate and check the original maintenance design.
INSERT INTO service_task VALUES ('OIL01', 'Oil change', 'Replace engine oil and filter');
INSERT INTO service_task VALUES ('BRK01', 'Brake inspection', 'Inspect brake components');
INSERT INTO service VALUES (1, '1HGBH41JXMN109186', TIMESTAMP '2026-07-20 09:00:00', NULL, 51000);
INSERT INTO service_log VALUES (1, 'OIL01', 20, 'Synthetic service note: oil and filter replaced');
INSERT INTO service_log VALUES (1, 'BRK01', 21, 'Synthetic service note: brake inspection completed');
UPDATE service SET service_end_datetime = TIMESTAMP '2026-07-20 12:00:00' WHERE service_id = 1;
COMMIT;
