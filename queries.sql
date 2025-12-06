-- шаг 4
-- Выбираем количество (count) ID клиентов и даем псевдоним customers_count
select count(customer_id) as customers_count
-- Из таблицы customers
from customers;

-- шаг 5 отчёт 1
-- Начало выборки
select
    -- Склеиваем имя и фамилию продавца
    concat(e.first_name, ' ', e.last_name) as seller,
    -- Считаем количество операций
    count(s.sales_id) as operations,
    -- Считаем выручку: сумма (кол-во * цена), округляем вниз
    floor(sum(s.quantity * p.price)) as income
-- Из таблицы sales с псевдонимом s
from sales as s
-- Присоединяем таблицу employees (e)
inner join employees as e
    -- По совпадению ID продавца
    on s.sales_person_id = e.employee_id
-- Присоединяем таблицу products (p)
inner join products as p
    -- По совпадению ID продукта
    on s.product_id = p.product_id
-- Группируем по продавцу
group by seller
-- Сортируем по доходу убывающе
order by income desc
-- Берем первые 10
limit 10;

-- шаг 5 отчёт 2
-- Создаем CTE для общей средней выручки
with overall_average_income as (
    -- Считаем среднее от (количество * цена) и округляем
    select floor(avg(s.quantity * p.price)) as overall_average
    -- Из таблицы продаж
    from sales as s
    -- Присоединяем продукты
    inner join products as p
        -- По ID продукта
        on s.product_id = p.product_id
),
-- Создаем CTE для средней выручки по продавцам
seller_average as (
    -- Выбираем данные
    select
        -- Полное имя продавца
        concat(e.first_name, ' ', e.last_name) as seller,
        -- Средняя выручка продавца
        floor(avg(s.quantity * p.price)) as average_income
    -- Из таблицы продаж
    from sales as s
    -- Присоединяем сотрудников
    inner join employees as e
        -- По ID продавца
        on s.sales_person_id = e.employee_id
    -- Присоединяем продукты
    inner join products as p
        -- По ID продукта
        on s.product_id = p.product_id
    -- Группируем по продавцу
    group by seller
)
-- Основной запрос
select
    -- Имя продавца
    seller,
    -- Средняя выручка
    average_income
-- Из CTE продавцов
from seller_average
-- Где личная средняя меньше общей (квалифицируем overall_average)
where average_income < (
    select oa.overall_average
    from overall_average_income as oa
)
-- Сортируем по возрастанию
order by average_income asc;

-- шаг 5 отчёт 3
-- Выбираем данные
select
    -- Имя продавца
    concat(e.first_name, ' ', e.last_name) as seller,
    -- День недели текстом
    to_char(s.sale_date, 'Day') as day_of_week,
    -- Сумма выручки
    floor(sum(s.quantity * p.price)) as income
-- Из таблицы продаж
from sales as s
-- Присоединяем сотрудников
inner join employees as e
    -- По ID
    on s.sales_person_id = e.employee_id
-- Присоединяем продукты
inner join products as p
    -- По ID
    on s.product_id = p.product_id
-- Группируем
group by
    -- По продавцу
    seller,
    -- По номеру дня недели (для сортировки)
    extract(isodow from s.sale_date),
    -- По названию дня
    day_of_week
-- Сортируем
order by
    -- Сначала по номеру дня
    extract(isodow from s.sale_date),
    -- Потом по продавцу
    seller;

-- шаг 6 отчёт 1
-- Выбираем
select
    -- Определяем категорию возраста
    case
        when age between 16 and 25 then '16-25'
        when age between 26 and 40 then '26-40'
        when age >= 41 then '40+'
    end as age_category,
    -- Считаем количество людей
    count(*) as age_count
-- Из клиентов
from customers
-- Группируем по категории
group by age_category
-- Сортируем по категории
order by age_category;

-- шаг 6 отчёт 2
-- Выбираем
select
    -- Дата в формате ГГГГ-ММ
    to_char(s.sale_date, 'YYYY-MM') as selling_month,
    -- Количество уникальных покупателей
    count(distinct s.customer_id) as total_customers,
    -- Общая выручка
    sum(s.quantity * p.price) as income
-- Из продаж
from sales as s
-- Присоединяем продукты
inner join products as p
    -- По ID
    on s.product_id = p.product_id
-- Группируем по месяцу
group by to_char(s.sale_date, 'YYYY-MM')
-- Сортируем по месяцу
order by selling_month asc;

-- шаг 6 отчёт 3
-- Выбираем
select
    -- Имя покупателя (игнорируем правило порядка колонок ST06)
    concat(c.first_name, ' ', c.last_name) as customer, -- noqa: ST06
    -- Дата продажи
    s.sale_date,
    -- Имя продавца
    concat(e.first_name, ' ', e.last_name) as seller
-- Из продаж
from sales as s
-- Присоединяем покупателей
inner join customers as c
    -- По ID
    on s.customer_id = c.customer_id
-- Присоединяем сотрудников
inner join employees as e
    -- По ID
    on s.sales_person_id = e.employee_id
-- Присоединяем продукты
inner join products as p
    -- По ID
    on s.product_id = p.product_id
-- Фильтр
where
    -- Дата равна минимальной дате
    s.sale_date = (select min(s_sub.sale_date) from sales as s_sub)
    -- И цена равна 0
    and p.price = 0
-- Сортировка по ID покупателя
order by c.customer_id;