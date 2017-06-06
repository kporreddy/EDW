-- Setting configuration at run time
set io.sort.mb 256M;

-- Create pig_demo.txt file with the following text.
This will have some text to test word count program using pig script.

This will also used to demonstrate to get started using pig in Hadoop eco system.

-- Getting started
load_data = LOAD '/user/root/pig_demo.txt';
DUMP load_data;

-- Create script pig_demo.pig
-- Launch grunt
-- Run script using "exec pig_demo.pig", one can use absolute or relative path
-- Also you can run pig scripts using "pig -f pig_demo.pig" (either by using absolute or relative path)

-- Word count program
lines = LOAD '/user/root/pig_demo.txt' AS (line:chararray);
words = FOREACH lines GENERATE FLATTEN(TOKENIZE(line)) as word;
grouped = GROUP words BY word;
wordcount = FOREACH grouped GENERATE group, COUNT(words);
DUMP wordcount;

-- Run the sqoop command, to load data into sqoop_import directory in HDFS.
sqoop import-all-tables \
  -m 1 \
  --connect "jdbc:mysql://sandbox.hortonworks.com:3306/retail_db" \
  --username=retail_dba \
  --password=hadoop \
  --warehouse-dir /user/root/sqoop_import

-- Load data into a Pig relation without a schema
departments = LOAD '/user/root/sqoop_import/departments' USING PigStorage(',');
DESCRIBE departments;

department_id = FOREACH departments GENERATE $1;
DESCRIBE department_id;

-- Cast elements in department_id to integer
department_id = FOREACH departments GENERATE (int) $1;
DESCRIBE department_id;

DUMP department_id;

-- Load data into a Pig relation with a schema
departments = LOAD '/user/root/sqoop_import/departments' USING PigStorage(',') AS (department_id:int, department_name:chararray);
DESCRIBE departments;

department_id = FOREACH departments GENERATE department_id;
DESCRIBE department_id;

DUMP department_id;

-- Load data from a Hive table into a Pig relation
-- Launch grunt using "pig -useHCatalog"
customer_details = LOAD 'xademo.customer_details' USING org.apache.hive.hcatalog.pig.HCatLoader();
DESCRIBE customer_details;
customer_details_phone_number = FOREACH customer_details GENERATE phone_number;
DUMP customer_details_phone_number;

-- Use Pig to remove records with null values from a relation
customer_details_wo_schema = LOAD '/apps/hive/warehouse/xademo.db/customer_details' USING PigStorage('|');
customer_details_not_null = FILTER customer_details_wo_schema BY ($5 is not null);
DUMP customer_details_not_null;

-- Use Pig to transform data into a specified format
-- Transform data to match a given Hive schema

-- Group the data of one or more Pig relations
-- Make sure you create hive database pig_demo, create all tables and load data into them using pig
-- It is under the section of "Store the data from a Pig relation into a Hive table"

-- GROUP ALL (select count(*) from xademo.customer_details)
customer_details = LOAD 'xademo.customer_details' USING org.apache.hive.hcatalog.pig.HCatLoader();
customer_details_grouped = GROUP customer_details ALL;
customer_details_count = FOREACH customer_details_grouped GENERATE COUNT_STAR(customer_details) AS cnt;
DUMP customer_details_count;

-- GROUP ALL (select count(*) from xademo.customer_details where imei is not null)
customer_details = LOAD 'xademo.customer_details' USING org.apache.hive.hcatalog.pig.HCatLoader();
customer_details_filtered = FILTER customer_details BY (imei != '');
customer_details_grouped = GROUP customer_details_filtered ALL;
customer_details_count = FOREACH customer_details_grouped GENERATE COUNT_STAR(customer_details) AS cnt;
DUMP customer_details_count;

-- GROUP ALL by position (with out schema)
customer_details = LOAD '/apps/hive/warehouse/xademo.db/customer_details' USING PigStorage('|');
customer_details_not_null = FILTER customer_details_wo_schema BY ($5 is not null);
customer_details_grouped = GROUP customer_details_not_null ALL;
customer_details_count = FOREACH customer_details_grouped GENERATE COUNT_STAR(customer_details_filtered) AS cnt;
DUMP customer_details_count;

-- GROUP BY (select order_status, count(1) from orders group by order_status)
-- Make sure you have pig_demo db, retail_db tables and data in Hive
orders = LOAD 'pig_demo.orders' USING org.apache.hive.hcatalog.pig.HCatLoader();
ordersgrouped = GROUP orders BY order_status;
DESCRIBE ordersgrouped
orderscount = FOREACH ordersgrouped GENERATE group, COUNT(orders) AS cnt;
DUMP orderscount;

-- Filter with schema using positional notation
customer_details_with_schema = LOAD '/apps/hive/warehouse/xademo.db/customer_details' USING PigStorage('|') AS (phone_number: chararray,plan: chararray,rec_date: chararray,status: chararray,balance: chararray,imei: chararray,region: chararray);
customer_details_not_null = FILTER customer_details_with_schema BY ($5 is not null);
DUMP customer_details_not_null;

-- Filter with schema using name notation
customer_details_with_schema = LOAD '/apps/hive/warehouse/xademo.db/customer_details' USING PigStorage('|') AS (phone_number: chararray,plan: chararray,rec_date: chararray,status: chararray,balance: chararray,imei: chararray,region: chararray);
customer_details_not_null = FILTER customer_details_with_schema BY (imei is not null);
DUMP customer_details_not_null;

-- Filter with HCatalog
-- Launch grunt using "pig -useHCatalog"
customer_details_hive = LOAD 'xademo.customer_details' USING org.apache.hive.hcatalog.pig.HCatLoader();
customer_details_not_null = FILTER customer_details_hive BY (imei != '');
DUMP customer_details_not_null;

-- Store the data from a Pig relation into a folder in HDFS
-- Launch grunt using "pig"
-- Validate, by running "fs -ls /user/root/sqoop_import"
departments = LOAD '/user/root/sqoop_import/departments';
STORE departments INTO '/user/root/pig_demo/departments';
-- Validate "fs -cat /user/root/pig_demo/departments/part*"

-- Changing the delimiter
-- Delete target directory if exists "fs -rm -R /user/root/pig_demo/departments"
departments = LOAD '/user/root/sqoop_import/departments' USING PigStorage(',');
STORE departments INTO '/user/root/pig_demo/departments' USING PigStorage('|');
-- Validate
-- Both source and target files are of text format

-- Changing file type (from text to binary)
departments = LOAD '/user/root/sqoop_import/departments' USING PigStorage(',');
STORE departments INTO '/user/root/pig_demo/departments' USING BinStorage('|');
-- Validate
departments_bin = LOAD '/user/root/pig_demo/departments' USING BinStorage('|');
DUMP departments_bin;

-- Store the data from a Pig relation into a Hive table
-- Launch hive using "hive"
-- Create Hive database
create database pig_demo;
use pig_demo;

-- Create Hive tables
create table departments (department_id int, department_name string);

create table categories (category_id int, category_department_id int, category_name string);

create table customers (customer_id int, 
  customer_fname string, 
  customer_lname string, 
  customer_email string, 
  customer_password string, 
  customer_street string, 
  customer_city string, 
  customer_state string, 
  customer_zipcode string);

create table order_items (order_item_id int,
  order_item_order_id int,
  order_item_product_id int,
  order_item_quantity int,
  order_item_subtotal float,
  order_item_product_price float);

create table orders (order_id int,
  order_date string,
  order_customer_id int,
  order_status string);

create table products (product_id int,
  product_category_id int,
  product_name string,
  product_description string,
  product_price float,
  product_image string);

-- Loading into hive tables
-- Launch pig using "pig -useHCatalog"
-- Loading data into hive tables
departments = LOAD '/user/root/sqoop_import/departments' USING PigStorage(',') AS (department_id: int, department_name: chararray);
STORE departments INTO 'pig_demo.departments' USING org.apache.hive.hcatalog.pig.HCatStorer();
-- Validate, go to hive and run "select * from departments" (make sure you are using right database pig_demo)

categories = LOAD '/user/root/sqoop_import/categories' USING PigStorage(',') AS (categor_id: int, category_department_id: int, category_name: chararray);
STORE categories INTO 'pig_demo.categories' USING org.apache.hive.hcatalog.pig.HCatStorer();

customers = LOAD '/user/root/sqoop_import/customers' USING PigStorage(',') AS (customer_id: int, customer_fname: chararray, customer_lname: chararray, customer_email: chararray, customer_password: chararray, customer_street: chararray, customer_city: chararray, customer_state: chararray, customer_zipcode: chararray);
STORE customers INTO 'pig_demo.customers' USING org.apache.hive.hcatalog.pig.HCatStorer();

order_items = LOAD '/user/root/sqoop_import/order_items' USING PigStorage(',') AS (order_item_id: int, order_item_order_id: int, order_item_product_id: int, order_item_quantity: int, order_item_subtotal: float, order_item_product_price: float);
STORE order_items INTO 'pig_demo.order_items' USING org.apache.hive.hcatalog.pig.HCatStorer();

orders = LOAD '/user/root/sqoop_import/orders' USING PigStorage(',') AS (order_id: int, order_date: chararray, order_customer_id: int, order_status: chararray);
STORE orders INTO 'pig_demo.orders' USING org.apache.hive.hcatalog.pig.HCatStorer();

products = LOAD '/user/root/sqoop_import/products' USING PigStorage(',') AS (product_id: int, product_category_id: int, product_name: chararray, product_description: chararray, product_price: float, product_image: chararray);
STORE products INTO 'pig_demo.products' USING org.apache.hive.hcatalog.pig.HCatStorer();

-- Sort the output of a Pig relation
-- select * from departments order by department_id;
departments = LOAD 'pig_demo.departments' USING org.apache.hive.hcatalog.pig.HCatLoader();
orderby = ORDER departments BY department_id;
orderbydesc = ORDER departments BY department_id DESC;

-- Remove the duplicate tuples of a Pig relation
-- select distinct order_status from orders;
orders = LOAD 'pig_demo.orders' USING org.apache.hive.hcatalog.pig.HCatLoader();
orderstatus = FOREACH orders GENERATE order_status;
grouped = GROUP orderstatus BY order_status;
orderstatusdistinct = FOREACH grouped {
  odistinct = DISTINCT orderstatus.order_status;
  GENERATE FLATTEN(odistinct);
};
DUMP orderstatusdistinct;

orders = LOAD 'pig_demo.orders' USING org.apache.hive.hcatalog.pig.HCatLoader();
orderstatus = FOREACH orders GENERATE order_status;
orderstatusdistinct = DISTINCT orderstatus;
DUMP orderstatusdistinct;

-- Specify the number of reduce tasks for a Pig MapReduce job
orders = LOAD 'pig_demo.orders' USING org.apache.hive.hcatalog.pig.HCatLoader();
ordersgrouped = GROUP orders BY order_status PARALLEL 2;
DESCRIBE ordersgrouped
orderscount = FOREACH ordersgrouped GENERATE group, COUNT(orders) AS cnt;
DUMP orderscount;

-- Join two datasets using Pig
-- select o.order_date, sum(oi.order_item_subtotal) from orders o join order_items oi
-- on o.order_id = oi.order_item_order_id
-- group by o.order_date;
orders = LOAD 'pig_demo.orders' USING org.apache.hive.hcatalog.pig.HCatLoader();
order_items = LOAD 'pig_demo.order_items' USING org.apache.hive.hcatalog.pig.HCatLoader();
ordersjoin = JOIN orders BY order_id, order_items BY order_item_order_id;
-- DESCRIBE ordersjoin;
orderdatewithrevenuebyorder = FOREACH ordersjoin GENERATE orders::order_date, order_items::order_item_subtotal;
orderdatewithrevenuebyordergrouped = GROUP orderdatewithrevenuebyorder BY orders::order_date;
revenuebydate = FOREACH orderdatewithrevenuebyordergrouped GENERATE group, SUM(orderdatewithrevenuebyorder.order_items::order_item_subtotal) AS revenue_per_day;
DUMP revenuebydate;

-- Left outer join
-- select * from orders o left outer join order_items oi 
-- on o.order_id = oi.order_item_order_id 
-- where oi.order_item_id is null;
orders = LOAD 'pig_demo.orders' USING org.apache.hive.hcatalog.pig.HCatLoader();
order_items = LOAD 'pig_demo.order_items' USING org.apache.hive.hcatalog.pig.HCatLoader();
ordersleftjoin = JOIN orders BY order_id LEFT OUTER, order_items BY order_item_order_id;
ordersfiltered = FILTER ordersleftjoin BY order_items::order_item_id IS NULL;
DUMP ordersfiltered;

orders = LOAD '/user/root/sqoop_import/orders' USING PigStorage(',') AS (order_id: int, order_date: chararray, order_customer_id: int, order_status: chararray);
order_items = LOAD '/user/root/sqoop_import/order_items' USING PigStorage(',') AS (order_item_id: int, order_item_order_id: int, order_item_product_id: int, order_item_quantity: int, order_item_subtotal: float, order_item_product_price: float);
ordersleftjoin = JOIN orders BY order_id LEFT OUTER, order_items BY order_item_order_id;
ordersfiltered = FILTER ordersleftjoin BY order_items::order_item_id IS NULL;
DUMP ordersfiltered;

orders = LOAD '/user/root/sqoop_import/orders' USING PigStorage(',');
order_items = LOAD '/user/root/sqoop_import/order_items' USING PigStorage(',');
ordersleftjoin = JOIN orders BY $0 LEFT OUTER, order_items BY $1;
-- If you DUMP or try to perform other operations on ordersleftjoin it will fail as there is no schema on the relations.
-- JOINS work only when schema is defined for relations.

-- Counting
grouped = GROUP ordersfiltered ALL;
counted = FOREACH grouped GENERATE COUNT_STAR(ordersfiltered);
DUMP counted;

-- Right outer join
orders = LOAD 'pig_demo.orders' USING org.apache.hive.hcatalog.pig.HCatLoader();
order_items = LOAD 'pig_demo.order_items' USING org.apache.hive.hcatalog.pig.HCatLoader();
ordersrightjoin = JOIN orders BY order_id RIGHT OUTER, order_items BY order_item_order_id;
ordersfiltered = FILTER ordersrightjoin BY orders::order_id IS NULL;
DUMP ordersfiltered;
grouped = GROUP ordersfiltered ALL;
counted = FOREACH grouped GENERATE COUNT_STAR(ordersfiltered);
DUMP counted;

-- Full outer join
orders = LOAD 'pig_demo.orders' USING org.apache.hive.hcatalog.pig.HCatLoader();
order_items = LOAD 'pig_demo.order_items' USING org.apache.hive.hcatalog.pig.HCatLoader();
ordersfulljoin = JOIN orders BY order_id FULL OUTER, order_items BY order_item_order_id;
ordersfiltered = FILTER ordersfulljoin BY order_items::order_item_id IS NULL;
DUMP ordersfiltered;
grouped = GROUP ordersfiltered ALL;
counted = FOREACH grouped GENERATE COUNT_STAR(ordersfiltered);
DUMP counted;

-- Perform a replicated join using Pig
-- select o.order_date, sum(oi.order_item_subtotal) from orders o join order_items oi
-- on o.order_id = oi.order_item_order_id
-- group by o.order_date;
orders = LOAD 'pig_demo.orders' USING org.apache.hive.hcatalog.pig.HCatLoader();
order_items = LOAD 'pig_demo.order_items' USING org.apache.hive.hcatalog.pig.HCatLoader();
ordersjoin = JOIN orders BY order_id, order_items BY order_item_order_id USING 'replicated';
--DESCRIBE ordersjoin;
orderdatewithrevenuebyorder = FOREACH ordersjoin GENERATE orders::order_date, order_items::order_item_subtotal;
orderdatewithrevenuebyordergrouped = GROUP orderdatewithrevenuebyorder BY orders::order_date;
revenuebydate = FOREACH orderdatewithrevenuebyordergrouped GENERATE group, SUM(orderdatewithrevenuebyorder.order_items::order_item_subtotal) AS revenue_per_day;
DUMP revenuebydate;
