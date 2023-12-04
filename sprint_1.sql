create schema if not exists raw_data;

create table if not exists raw_data.sales
(
    id                      integer,
    auto                    text,
    gasoline_consumption    text,
    price                   numeric(9,2),
    date                    date,
    person_name             text,
    phone                   text,
    discount                float,
    brand_origin            text
);

copy raw_data.sales from 'C:\Temp\cars.csv' with csv header null 'null';

create schema if not exists car_shop;

create table if not exists car_shop.country
(
    country_id              serial,
    name                    varchar(50) not null,
    constraint pk_country primary key (country_id),
    constraint country_unique_name unique (name)
);

create table if not exists car_shop.brand
(
    brand_id                serial,
    name                    varchar(50),
    country_id              integer,
    constraint pk_brand primary key (brand_id),
    constraint fk_country foreign key (country_id) references car_shop.country (country_id),
    constraint brand_unique_name unique (name)
);

create table if not exists car_shop.car
(
    car_id                   serial,
    name                     varchar(50) not null,
    brand_id                 integer not null,
    gasoline_consumption     float,
    constraint pk_car primary key (car_id),
    constraint fk_brand foreign key (brand_id) references car_shop.brand (brand_id),
    constraint car_unique_name unique (name)
);

create table if not exists car_shop.colour
(
    colour_id                serial,
    name                     varchar(50) not null,
    constraint pk_colour primary key (colour_id),
    constraint colour_unique_name unique (name)
);

create table if not exists car_shop.client
(
    client_id                serial,
    name                     varchar(50) not null,
    phone                    varchar(25) not null,
    constraint pk_client primary key (client_id),
    constraint client_unique_phone unique (phone)
);

create table if not exists car_shop.invoice
(
    invoice_id               serial,
    date                     date not null,
    discount                 float not null,
    price                    numeric(9, 2) not null,
    car_id                   integer not null,
    client_id                integer not null,
    colour_id                integer not null,
    constraint pk_invoice primary key (invoice_id),
    constraint fk_car foreign key (car_id) references car_shop.car (car_id),
    constraint fk_client foreign key (client_id) references car_shop.client (client_id),
    constraint fk_colour foreign key (colour_id) references car_shop.colour (colour_id),
    constraint positive_discount check (discount >= 0), -- скидка не может быть отрицательной
    constraint positive_price check (price > 0) -- цена не может быть отрицательной
);

insert into car_shop.colour
    (name)
select
    distinct(split_part(auto, ' ', -1))
from raw_data.sales;

insert into car_shop.client
    (name, phone)
select
    distinct(person_name), phone
from raw_data.sales;

insert into car_shop.country
    (name)
select
    distinct (brand_origin)
from raw_data.sales
where brand_origin is not null;

insert into car_shop.brand
    (name, country_id)
select
    distinct(split_part(auto, ' ', 1)) as brand, cs.country_id
from raw_data.sales rd
    left join car_shop.country cs on rd.brand_origin = cs.name;

insert into car_shop.car
    (name, brand_id, gasoline_consumption)
select
    distinct(substr(auto, strpos(auto, ' '), strpos(auto, ',') - strpos(auto, ' '))) as model,
    cs.brand_id,
    (case
        when gasoline_consumption is not null then gasoline_consumption::float
        else 0
    end)
from raw_data.sales rd
    left join car_shop.brand cs on split_part(auto, ' ', 1) = cs.name;

insert into car_shop.invoice
    (date, discount, price, car_id, client_id, colour_id)
select
    rd.date,
    rd.discount,
    rd.price,
    ca.car_id,
    cl.client_id,
    co.colour_id
from raw_data.sales rd
    left outer join car_shop.car ca on substr(auto, strpos(auto, ' '), strpos(auto, ',') - strpos(auto, ' ')) = ca.name
    left join car_shop.client cl on rd.person_name = cl.name
    left join car_shop.colour co on split_part(auto, ' ', -1) = co.name;


--Задание 1:
select
    ((1 - (count(gasoline_consumption)::real/count(*)))*100)::numeric(4,2) as nulls_percentage_gasoline_consumption
from raw_data.sales;

--Задание 2:
select
    b.name as brand_name,
    extract(year from iv.date) as year,
    round(avg(iv.price), 2) as price_avg
from car_shop.invoice iv
    left join car_shop.car ca on iv.car_id = ca.car_id
    left join car_shop.brand b on b.brand_id = ca.brand_id
group by brand_name, year
order by brand_name, year;

--Задание 3:
select
    extract(month from date) as month,
    extract(year from date) as year, avg(price)::numeric(9,2) as price_avg
from car_shop.invoice
where extract(year from date) = 2022
group by month, year
order by month;

--Задание 4:
select
    cl.name as person,
    string_agg(concat(b.name, c.name), ', ') as cars
from car_shop.client cl
    left join car_shop.invoice i on cl.client_id = i.client_id
    left join car_shop.car c on c.car_id = i.car_id
    left join car_shop.brand b on b.brand_id = c.brand_id
group by cl.name
order by cl.name;

--Задание 5:
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

--Задание 6:
select count(name) as persons_from_usa_count
from car_shop.client
where strpos(phone, '+1') = 1;