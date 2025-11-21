-- шаг 4

select count(customer_id) as customers_count
from customers; -- подсчитываем количество клиентов в таблице customers



-- шаг 5 отчёт 1
select
concat(e.first_name, ' ', e.last_name) as seller, -- склеиваем имя и фамилию продавца в одну строку
count(s.sales_id) as operations, -- подсчитываем количество продаж
floor(sum(s.quantity * p.price)) as income -- подсчитываем общую сумму продаж, округляем вниз
from sales s
inner join employees e on s.sales_person_id = e.employee_id -- объединяем с таблицей employees
inner join products p on s.product_id = p.product_id -- объединяем с таблицей products
group by seller --группируем по продавцу
order by income desc -- сортируем по сумме товаров от большей к меньшей
limit 10 -- ограничиваем выборку
;



-- шаг 5 отчёт 2
with overall_average_income as -- объявляем запрос, который подсчитывает среднюю выручку за сделку по всем продавцам
(
select
floor(avg(s.quantity * p.price)) as overall_average
from sales s
inner join products p on s.product_id = p.product_id
),
seller_average as -- объявляем запрос, подсчитывающий среднюю выручку за сделку по каждому продавцу
(
select
concat(e.first_name, ' ', e.last_name) as seller,
floor(avg(s.quantity * p.price)) as average_income
from sales s
inner join employees e on s.sales_person_id = e.employee_id
inner join products p on s.product_id = p.product_id
group by seller
)
select -- просим показать имя-фамилию и среднюю сумму за сделку тех продавцов, у которых средняя сумма меньше средней суммы по всем продавцам
seller,
average_income
from seller_average
where average_income < (select overall_average from overall_average_income)
order by average_income asc;


-- шаг 5 отчёт 3
select
concat(e.first_name, ' ', e.last_name) as seller, -- склеиваем имя и фамилию продавца
to_char(s.sale_date, 'Day') as day_of_week, -- извлекаем из даты название дня недели
floor(sum(s.quantity * p.price)) as income -- подсчитываем среднюю выручку, округляем вниз
from sales s -- соединяем все три таблицы
inner join employees e on s.sales_person_id = e.employee_id
inner join products p on s.product_id = p.product_id
group by seller, -- группируем по продавцу
extract(isodow from s.sale_date), -- группируем по ISO-номеру дня недели
day_of_week -- группируем по названию дня недели
order by extract(isodow from s.sale_date), seller; -- сортируем по номеру дня недели, продавцу


--шаг 6 отчёт 1
SELECT
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25' -- фильтруем возраст
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age >= 41 THEN '40+'
    END AS age_category, 
    COUNT(*) AS age_count -- объявляем категории
FROM customers
GROUP by age_category 
ORDER by age_category;
 
--шаг 6 отчёт 2
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month, -- Форматируем дату в виде 'ГГГГ-ММ'
    COUNT(DISTINCT s.customer_id) AS total_customers,     -- Подсчитываем уникальных покупателей за месяц
    SUM(s.quantity * p.price) AS income -- Рассчитываем выручку: сумма (количество * цена)
FROM sales s
JOIN products p ON s.product_id = p.product_id -- Присоединяем таблицу products для получения цены
GROUP BY TO_CHAR(s.sale_date, 'YYYY-MM') -- Группируем по отформатированной дате
ORDER BY selling_month ASC; -- Сортируем по дате в порядке возрастания


-- шаг 6 отчёт 3
SELECT
    CONCAT(c.first_name, ' ', c.last_name) AS customer,  -- Объединяем имя и фамилию покупателя из таблицы customers
    s.sale_date,                                         -- Выбираем дату продажи из таблицы sales
    CONCAT(e.first_name, ' ', e.last_name) AS seller     -- Объединяем имя и фамилию продавца из таблицы employees
FROM sales s                                             -- Основная таблица: sales (сокращённо как "s")
JOIN customers c ON s.customer_id = c.customer_id        -- Связываем sales с customers по идентификатору покупателя
JOIN employees e ON s.sales_person_id = e.employee_id    -- Связываем sales с employees по идентификатору продавца
JOIN products p ON s.product_id = p.product_id           -- Связываем sales с products по идентификатору товара
WHERE s.sale_date =                                    -- Начало условия "дата продажи равна..."
    (SELECT MIN(sale_date)  
    from sales) -- находим  минимальную (самую раннюю) дату покупки
AND p.price = 0                                          -- Фильтруем только те товары, у которых цена равна нулю
-- Сортируем результат по идентификатору покупателя (в порядке возрастания)
ORDER BY c.customer_id