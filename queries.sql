-- шаг 4
select count(customer_id) as customers_count -- Выбираем подсчет (count) идентификаторов клиентов и называем колонку customers_count
from customers; -- Указываем таблицу-источник customers

-- шаг 5 отчёт 1
select -- Начало выборки данных
    concat(e.first_name, ' ', e.last_name) as seller, -- Склеиваем имя и фамилию продавца через пробел, даем псевдоним seller
    count(s.sales_id) as operations, -- Считаем количество продаж по ID продажи, даем псевдоним operations
    floor(sum(s.quantity * p.price)) as income -- Умножаем кол-во на цену, суммируем, округляем вниз (floor), псевдоним income
from sales as s -- Из основной таблицы sales, даем ей псевдоним s
inner join employees as e -- Присоединяем таблицу employees (псевдоним e)
    on s.sales_person_id = e.employee_id -- Условие связи: ID продавца в продажах равен ID сотрудника
inner join products as p -- Присоединяем таблицу products (псевдоним p)
    on s.product_id = p.product_id -- Условие связи: ID продукта в продажах равен ID продукта в товарах
group by seller -- Группируем результаты по полному имени продавца (сформированному выше)
order by income desc -- Сортируем по доходу от большего к меньшему (desc)
limit 10; -- Оставляем только верхние 10 строк

-- шаг 5 отчёт 2
with overall_average_income as ( -- Начало CTE (временной таблицы) для расчета общей средней выручки
    select floor(avg(s.quantity * p.price)) as overall_average -- Считаем среднее (avg) от выручки (кол-во * цена) и округляем вниз
    from sales as s -- Из таблицы продаж
    inner join products as p -- Присоединяем продукты
        on s.product_id = p.product_id -- Связываем по ID продукта
), -- Завершение первого CTE

seller_average as ( -- Начало второго CTE для расчета средней выручки по каждому продавцу
    select -- Выбираем данные
        concat(e.first_name, ' ', e.last_name) as seller, -- Формируем имя продавца
        floor(avg(s.quantity * p.price)) as average_income -- Считаем среднюю выручку этого продавца и округляем
    from sales as s -- Из таблицы продаж
    inner join employees as e -- Присоединяем сотрудников
        on s.sales_person_id = e.employee_id -- Связываем продавцов
    inner join products as p -- Присоединяем продукты
        on s.product_id = p.product_id -- Связываем товары
    group by seller -- Группируем расчеты по каждому продавцу
) -- Завершение второго CTE

select -- Основной запрос выборки из подготовленных CTE
    seller, -- Выбираем имя продавца
    average_income -- Выбираем его среднюю выручку
from seller_average -- Из временной таблицы со средними по продавцам
where average_income < (select overall_average from overall_average_income) -- Фильтр: где личная средняя меньше общей средней
order by average_income asc; -- Сортируем результат по возрастанию выручки

-- шаг 5 отчёт 3
select -- Начало выборки
    concat(e.first_name, ' ', e.last_name) as seller, -- Формируем полное имя продавца
    to_char(s.sale_date, 'Day') as day_of_week, -- Преобразуем дату в название дня недели (например, 'Monday')
    floor(sum(s.quantity * p.price)) as income -- Считаем общую выручку и округляем вниз
from sales as s -- Из таблицы продаж
inner join employees as e -- Присоединяем сотрудников
    on s.sales_person_id = e.employee_id -- Связываем по ID
inner join products as p -- Присоединяем продукты
    on s.product_id = p.product_id -- Связываем по ID
group by -- Группировка результатов
    seller, -- По продавцу
    extract(isodow from s.sale_date), -- По порядковому номеру дня недели (1-7), чтобы сортировка шла не по алфавиту
    day_of_week -- По названию дня недели
order by -- Сортировка
    extract(isodow from s.sale_date), -- Сначала по порядку дней недели (Понедельник, затем Вторник...)
    seller; -- Затем по имени продавца

-- шаг 6 отчёт 1
select -- Начало выборки
    case -- Конструкция CASE для создания категорий
        when age between 16 and 25 then '16-25' -- Если возраст от 16 до 25, то категория '16-25'
        when age between 26 and 40 then '26-40' -- Если возраст от 26 до 40, то категория '26-40'
        when age >= 41 then '40+' -- Если возраст 41 и больше, то категория '40+'
    end as age_category, -- Называем полученную колонку age_category
    count(*) as age_count -- Считаем количество строк (людей) в каждой группе
from customers -- Из таблицы клиентов
group by age_category -- Группируем по созданным категориям
order by age_category; -- Сортируем по названию категории

-- шаг 6 отчёт 2
select -- Начало выборки
    to_char(s.sale_date, 'YYYY-MM') as selling_month, -- Преобразуем дату в формат 'Год-Месяц'
    count(distinct s.customer_id) as total_customers, -- Считаем уникальных (distinct) клиентов
    sum(s.quantity * p.price) as income -- Считаем общую выручку
from sales as s -- Из таблицы продаж
inner join products as p -- Присоединяем таблицу продуктов
    on s.product_id = p.product_id -- Связываем по ID товара, чтобы узнать цену
group by to_char(s.sale_date, 'YYYY-MM') -- Группируем по месяцам
order by selling_month asc; -- Сортируем по месяцам в хронологическом порядке

-- шаг 6 отчёт 3
select -- Начало выборки
    concat(c.first_name, ' ', c.last_name) as customer, -- Имя покупателя
    s.sale_date, -- Дата продажи
    concat(e.first_name, ' ', e.last_name) as seller -- Имя продавца
from sales as s -- Из таблицы продаж
inner join customers as c -- Присоединяем клиентов
    on s.customer_id = c.customer_id -- Связываем по ID
inner join employees as e -- Присоединяем сотрудников
    on s.sales_person_id = e.employee_id -- Связываем по ID
inner join products as p -- Присоединяем продукты
    on s.product_id = p.product_id -- Связываем по ID
where -- Фильтрация данных
    s.sale_date = (select min(s_sub.sale_date) from sales as s_sub) -- Где дата равна самой минимальной (ранней) дате во всей таблице
    and p.price = 0 -- И при этом цена товара равна 0
order by c.customer_id; -- Сортируем по ID покупателя