### Автосалон «Врум-Бум»

Необходимо нормализовать и структурировать существующие сырые данные из файла [cars.csv](https://github.com/msmkdenis/sql-practicum/blob/main/sprint_1/cars.csv).

К полученной БД написать ряд запросов. Результатом должен быть скрипт sql, выполняющийся без ошибок.

Скрипт создания и заполнения таблиц данными на основе файла [cars.csv](https://github.com/msmkdenis/sql-practicum/blob/main/sprint_1/cars.csv), 
а также запросы (полное решение) доступны в файле [sprint_1.sql](https://github.com/msmkdenis/sql-practicum/blob/main/sprint_1/sprint_1.sql).
Ниже приведено решение задач по запросам к БД.

#### Задание 1
Напишите запрос, который выведет процент моделей машин, у которых нет параметра gasoline_consumption.
```sql
select
((1 - (count(gasoline_consumption)::real/count(*)))*100)::numeric(4,2) as nulls_percentage_gasoline_consumption
from raw_data.sales;
```
#### Задание 2
Напишите запрос, который покажет название бренда и среднюю цену его автомобилей в разбивке по всем годам с учётом скидки. 
Итоговый результат отсортируйте по названию бренда и году в восходящем порядке. 
Среднюю цену округлите до второго знака после запятой.
```sql
select
    b.name as brand_name,
    extract(year from iv.date) as year,
    round(avg(iv.price), 2) as price_avg
from car_shop.invoice iv
    left join car_shop.car ca on iv.car_id = ca.car_id
    left join car_shop.brand b on b.brand_id = ca.brand_id
group by brand_name, year
order by brand_name, year;
```
#### Задание 3
Посчитайте среднюю цену всех автомобилей с разбивкой по месяцам в 2022 году с учётом скидки. 
Результат отсортируйте по месяцам в восходящем порядке. 
Среднюю цену округлите до второго знака после запятой.
```sql
select
    extract(month from date) as month,
    extract(year from date) as year, avg(price)::numeric(9,2) as price_avg
from car_shop.invoice
where extract(year from date) = 2022
group by month, year
order by month;
```
#### Задание 4
Используя функцию STRING_AGG, напишите запрос, который выведет список купленных машин у каждого пользователя через запятую. 
Пользователь может купить две одинаковые машины — это нормально. 
Название машины покажите полное, с названием бренда — например: Tesla Model 3.
Отсортируйте по имени пользователя в восходящем порядке. Сортировка внутри самой строки с машинами не нужна.
```sql
select
    cl.name as person,
    string_agg(concat(b.name, c.name), ', ') as cars
from car_shop.client cl
         left join car_shop.invoice i on cl.client_id = i.client_id
         left join car_shop.car c on c.car_id = i.car_id
         left join car_shop.brand b on b.brand_id = c.brand_id
group by cl.name
order by cl.name;
```
#### Задание 5
Напишите запрос, который вернёт самую большую и самую маленькую цену продажи автомобиля с разбивкой по стране без учёта скидки. 
Цена в колонке price дана с учётом скидки.
```sql
select
    co.name as brand_origin,
    max((price/(1-discount::real/100))::numeric(9,2)) as price_max,
    min((price/(1-discount::real/100))::numeric(9,2)) as price_min
from car_shop.invoice iv
         left join car_shop.car ca on ca.car_id = iv.car_id
         left join car_shop.brand br on br.brand_id = ca.brand_id
         left join car_shop.country co on co.country_id = br.country_id
where co.name is not null
group by brand_origin;
```
#### Задание 6
Напишите запрос, который покажет количество всех пользователей из США. 
Это пользователи, у которых номер телефона начинается на +1.
```sql
select count(name) as persons_from_usa_count
from car_shop.client
where strpos(phone, '+1') = 1;
```