-- =========================================================================
-- Домашнее задание 10: Работа с индексами. Итоговый скрипт команд
-- =========================================================================

-- 1. Обычный B-tree индекс на passenger_name
-- Замер плана выполнения до создания индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM tickets WHERE passenger_name = 'EVGENIY MAKAROV';

-- Создание B-tree индекса и сбор статистики
CREATE INDEX idx_passenger_name ON tickets (passenger_name);
ANALYZE tickets;

-- Замер плана выполнения после создания индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM tickets WHERE passenger_name = 'EVGENIY MAKAROV';


-- 2. GIN-индекс для полнотекстового поиска
-- Добавление колонки tsvector и заполнение лексемами
ALTER TABLE tickets ADD COLUMN fio_lexeme tsvector;
UPDATE tickets SET fio_lexeme = to_tsvector('russian', passenger_name);

-- Создание GIN-индекса и обновление статистики
CREATE INDEX idx_fio_gin ON tickets USING GIN (fio_lexeme);
ANALYZE tickets;

-- Проверка полнотекстового поиска
EXPLAIN (ANALYZE, BUFFERS)
SELECT ticket_no, passenger_name
FROM tickets
WHERE fio_lexeme @@ to_tsquery('russian', 'evgeniy & makarov');


-- 3. Функциональный индекс (по выражению lower)
-- Замер плана регистронезависимого поиска до создания индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM tickets WHERE lower(passenger_name) = 'evgeniy makarov';

-- Создание индекса по выражению и актуализация статистики
CREATE INDEX idx_lower_name ON tickets (lower(passenger_name));
ANALYZE tickets;

-- Замер плана после создания функционального индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM tickets WHERE lower(passenger_name) = 'evgeniy makarov';


-- 4. Составной индекс на несколько полей (book_ref, passenger_id)
-- Проверка плана до создания пользовательского индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM tickets WHERE book_ref = 'BD402C' AND passenger_id = '6243 166891';

-- Создание составного индекса и сбор статистики
CREATE INDEX idx_book_pass ON tickets (book_ref, passenger_id);
ANALYZE tickets;

-- Тест 4.1: Поиск по обеим колонкам индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM tickets WHERE book_ref = 'BD402C' AND passenger_id = '6243 166891';

-- Тест 4.2: Поиск только по первой колонке (правило левого префикса)
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM tickets WHERE book_ref = 'BD402C';

-- Тест 4.3: Поиск только по второй колонке
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM tickets WHERE passenger_id = '6243 166891';
