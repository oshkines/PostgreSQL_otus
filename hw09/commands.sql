-- =========================================================================
-- Домашнее задание 9: Работа с JOIN. Итоговый скрипт команд
-- =========================================================================

-- 1. Создание структуры данных
CREATE TABLE buses (bus_id serial PRIMARY KEY, name varchar);
CREATE TABLE drivers (driver_id serial PRIMARY KEY, first_name varchar, second_name varchar);
CREATE TABLE routes (route_id serial PRIMARY KEY, name varchar, bus_id int, driver_id int);

-- 2. Наполнение тестовыми данными
INSERT INTO buses (bus_id, name) VALUES (1, 'PAZ'), (2, 'LIAZ'), (3, 'MAN'), (4, 'MAZ'), (5, 'HENDAY');
INSERT INTO drivers (driver_id, first_name, second_name) VALUES 
(1, 'Ivan', 'Ivanov'), (2, 'Petr', 'Petrov'), (3, 'Saveliy', 'Sidorov'),
(4, 'Anton', 'Shtorkkin'), (5, 'Oleg', 'Zashigaev'), (6, 'Arkadiy', 'Parovozov');
INSERT INTO routes (route_id, name, bus_id, driver_id) VALUES 
(1, 'Moskow-Bolshevo', 1, 1), (2, 'Moskow-Pushkino', 1, 2),
(3, 'Moskow-Yroslavl', 2, 3), (4, 'Moskow-Kostroma', 2, 4),
(5, 'Moskow-Volgograd', 3, 5), (6, 'Moskow-Ivanovo', null, null);

-- 3. Проверка типов соединений
-- INNER
SELECT r.name AS route, b.name AS bus, d.first_name || ' ' || d.second_name AS driver
FROM routes r JOIN buses b ON r.bus_id = b.bus_id JOIN drivers d ON r.driver_id = d.driver_id;

-- LEFT
SELECT r.name AS route, b.name AS bus FROM routes r LEFT JOIN buses b ON r.bus_id = b.bus_id;

-- RIGHT
SELECT r.name AS route, b.name AS bus FROM routes r RIGHT JOIN buses b ON r.bus_id = b.bus_id;

-- CROSS
SELECT r.name AS route, b.name AS bus FROM routes r CROSS JOIN buses b;

-- FULL
SELECT r.name AS route, b.name AS bus FROM routes r FULL JOIN buses b ON r.bus_id = b.bus_id;

-- MIXED
SELECT r.name AS route, b.name AS bus, d.first_name || ' ' || d.second_name AS driver
FROM routes r LEFT JOIN buses b ON r.bus_id = b.bus_id JOIN drivers d ON r.driver_id = d.driver_id;

-- 4. Анализ планов запроса (План 1: Hash Join)
SET join_collapse_limit = 1;
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM routes r JOIN buses b ON r.bus_id = b.bus_id JOIN drivers d ON r.driver_id = d.driver_id;

-- План 2: Принудительный Nested Loop
SET enable_hashjoin = off;
SET enable_mergejoin = off;
SET join_collapse_limit = 1;
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM routes r JOIN buses b ON r.bus_id = b.bus_id JOIN drivers d ON r.driver_id = d.driver_id;

-- Возврат настроек сессии в дефолт
RESET enable_hashjoin;
RESET enable_mergejoin;
RESET join_collapse_limit;

-- 5. Сбор и актуализация статистики
ANALYZE routes;
ANALYZE buses;
ANALYZE drivers;

SELECT relname, n_live_tup, n_dead_tup, last_analyze
FROM pg_stat_user_tables WHERE relname IN ('routes', 'buses', 'drivers');
