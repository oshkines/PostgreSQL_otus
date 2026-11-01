-- =========================================================================
-- Домашнее задание 8: Механизм блокировок. Список команд
-- =========================================================================

-- 1. Первоначальная конфигурация
ALTER SYSTEM SET log_lock_waits = on;
ALTER SYSTEM SET deadlock_timeout = '200ms';
SELECT pg_reload_conf();

-- 2. Создание объектов и проверка очереди
CREATE TABLE lock_test (id INT PRIMARY KEY, value TEXT);
INSERT INTO lock_test VALUES (1, 'initial');

-- Запрос мониторинга pg_locks (выполнять в служебной сессии)
SELECT pid, locktype, relation::regclass AS relation, mode, granted, pg_blocking_pids(pid) AS blocked_by
FROM pg_locks WHERE relation = 'lock_test'::regclass ORDER BY pid;

-- 3. Моделирование Deadlock через UPDATE
DROP TABLE IF EXISTS deadlock_test;
CREATE TABLE deadlock_test (id INT PRIMARY KEY, value TEXT);
INSERT INTO deadlock_test VALUES (1, 'one'), (2, 'two');

-- Сессия 1: UPDATE deadlock_test SET value = 's1_row1' WHERE id = 1; -> UPDATE deadlock_test SET value = 's1_row2' WHERE id = 2;
-- Сессия 2: UPDATE deadlock_test SET value = 's2_row2' WHERE id = 2; -> UPDATE deadlock_test SET value = 's2_row1' WHERE id = 1;

-- 4. Задание со звездочкой: Deadlock через SELECT FOR UPDATE
-- Сессия 2:
BEGIN;
SELECT * FROM deadlock_test WHERE id = 1 FOR UPDATE;
UPDATE deadlock_test SET value = 'test' WHERE id = 2;
ROLLBACK;

-- Сессия 3:
BEGIN;
SELECT * FROM deadlock_test WHERE id = 2 FOR UPDATE;
UPDATE deadlock_test SET value = 'test' WHERE id = 1;
ROLLBACK;

-- 5. Чтение логов из терминала Linux
-- sudo tail -n 50 /var/log/postgresql/postgresql-16-main.log