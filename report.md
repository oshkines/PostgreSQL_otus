# Домашнее задание 1: PostgreSQL в Docker

## Цель
Развернуть PostgreSQL в Docker с внешним подключением и устойчивым хранением данных (volume) для воспроизводимого тестового стенда.

## Ход выполнения

### 1. Подготовка среды
Установлен Docker Engine на ВМ с Ubuntu 24.04 (сервер Aeza). Создан каталог для данных на хосте и выданы права пользователю postgres (UID 999), чтобы контейнер мог писать данные:

```bash
sudo mkdir -p /var/lib/postgresql_docker
sudo chown -R 999:999 /var/lib/postgresql_docker
```

![Скриншот установки Docker](images/img-2026-10-18-18-58-14.png)

![Скриншот установки Docker 2](images/img-2026-10-18-18-59-18.png)

![Скриншот установки Docker 3](images/img-2026-10-18-19-00-06.png)

![Скриншот установки Docker 4](images/img-2026-10-18-19-00-50.png)

![Скриншот установки Docker 5](images/img-2026-10-18-19-10-13.png)

![Скриншот установки Docker 6](images/img-2026-10-18-19-10-39.png)

![Скриншот установки Docker 7](images/img-2026-10-18-19-11-33.png)

### 2. Запуск сервера PostgreSQL
Создана сеть `pg-net` для связи контейнеров. Запущен контейнер с сервером, проброшен порт 5432 и смонтирован volume:

```bash
sudo docker network create pg-net

sudo docker run -d \
  --name pg-server \
  --network pg-net \
  -e POSTGRES_PASSWORD=MyStrongPass123 \
  -p 5432:5432 \
  -v /var/lib/postgresql_docker:/var/lib/postgresql/data \
  postgres:16
```

![Скриншот запуск контейнера pg-server](images/img-2026-10-18-19-12-15.png)

![Скриншот запуск контейнера pg-server 2](images/img-2026-10-18-19-12-29.png)

![Скриншот запуск контейнера pg-server 3](images/img-2026-10-18-19-12-54.png)

![Скриншот запуск контейнера pg-server 4](images/img-2026-10-18-19-13-08.png)

![Скриншот запуск контейнера pg-server 5](images/img-2026-10-18-19-23-10.png)

![Скриншот запуск контейнера pg-server 6](images/img-2026-10-18-19-23-57.png)

### 3. Подключение из контейнера-клиента и создание данных
Запущен временный контейнер с `psql`, подключен к серверу по имени `pg-server`. Выполнены SQL-команды для создания таблицы `orders_test` и вставки двух строк:

```sql
CREATE TABLE orders_test (
    id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    amount DECIMAL(10, 2)
);

INSERT INTO orders_test (customer_name, amount) 
VALUES 
    ('Ivan Petrov', 1500.00), 
    ('Maria Sidorova', 2750.50);
```

![ENTER POSTGRE](images/img-2026-10-18-19-25-14.png)

![CREATE TABLE](images/img-2026-10-18-19-25-54.png)

![CREATE TABLE 2](images/img-2026-10-18-19-26-20.png)

![CREATE TABLE 3](images/img-2026-10-18-19-30-35.png)

![SELECT TABLE](images/img-2026-10-18-19-31-09.png)

### 4. Подключение извне (с рабочего компьютера)
На Windows 11 установлен pgAdmin 4. Настроено подключение к серверу Aeza по внешнему IP-адресу и порту 5432. Выполнен проверочный запрос `SELECT * FROM orders_test;`, данные успешно получены.

![SELECT TABLE 2](images/img-2026-10-18-19-37-12.png)

![SELECT TABLE 3](images/img-2026-10-18-19-37-56.png)

![SELECT TABLE 4](images/img-2026-10-18-19-38-27.png)

### 5. Проверка сохранности данных
Контейнер `pg-server` был остановлен и удален:

```bash
sudo docker rm -f pg-server
```

Затем контейнер создан заново с использованием того же каталога `/var/lib/postgresql_docker`:

```bash
sudo docker run -d \
  --name pg-server \
  --network pg-net \
  -e POSTGRES_PASSWORD=MyStrongPass123 \
  -p 5432:5432 \
  -v /var/lib/postgresql_docker:/var/lib/postgresql/data \
  postgres:16
```

Проверка данных из контейнера-клиента показала, что строки сохранились:

```bash
sudo docker run -it --rm --network pg-net postgres:16 psql -h pg-server -U postgres -c "SELECT * FROM orders_test;"
```

![SELECT TABLE 5](images/img-2026-10-18-19-40-04.png)

![SELECT TABLE 6](images/img-2026-10-19-13-14-06.png)

## Решенные проблемы (Troubleshooting)
В ходе выполнения возникли следующие сложности:

* **Конфликт портов:** При запуске контейнера возникла ошибка *address already in use* (порт 5432). Выяснилось, что на хосте ранее был установлен локальный PostgreSQL. Проблема решена остановкой службы: `sudo systemctl stop postgresql`.
* **Конфликт имен контейнеров:** Ошибка *Conflict. The container name "/pg-server" is already in use*. Решено удалением старого контейнера перед созданием нового: `sudo docker rm -f pg-server`.
* **Проблема с кодировкой:** При вводе данных на кириллице в консоли `psql` появлялись «крякозябры». Для стабильной работы данные вставлены латиницей (*Ivan Petrov*, *Maria Sidorova*).
