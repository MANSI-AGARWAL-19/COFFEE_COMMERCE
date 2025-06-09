--coffee_commerce_schemas

create table city (
city_id int primary key,
city_name varchar(15),
population int,
estimated_rent float,
city_rank int );

create table customers (
customer_id int primary key,
customer_name varchar(25),
city_id int,
foreign key (city_id) references city(city_id)
);

create table products (
product_id int primary key,
product_name varchar(35),
price float );

create table sales (
sale_id int primary key,
sale_date date,
product_id int,
customer_id int,
total float,
rating int,
foreign key (product_id) references products (product_id),
foreign key (customer_id) references customers (customer_id)
);
