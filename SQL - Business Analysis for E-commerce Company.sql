select *
from customers_dataset

select *
from order_items_dataset

select *
from order_payments_dataset

select *
from order_reviews_dataset

select *
from orders_dataset

select *
from product_category_name_translation

select *
from products_dataset

/*Tổng số lượng order*/
select distinct count(order_id) as total_orders
from orders_dataset

/*Tổng số lượng order theo khu vực*/
SELECT customer_state, count(order_id) total_area_orders
from orders_dataset o right JOIN customers_dataset c on o.customer_id = c.customer_id 
group by customer_state
order by total_area_orders

/*Tổng doanh thu*/
select sum(b.payment_value) total_revenue
from orders_dataset a right join order_payments_dataset b on a.order_id = b.order_id
where a.order_id not in (select order_id from orders_dataset where order_delivered_customer_date is null)

/*Doanh thu theo tháng*/
SELECT month(order_delivered_customer_date) month, sum(payment_value) total_month_revenue
from orders_dataset a RIGHT join order_payments_dataset b on a.order_id = b.order_id 
where a.order_id not in (select order_id from orders_dataset where order_delivered_customer_date is null)
group by month(order_delivered_customer_date)

/*Doanh thu theo năm*/
SELECT year(order_delivered_customer_date) year, sum(payment_value) total_year_revenue
from orders_dataset a RIGHT join order_payments_dataset b on a.order_id = b.order_id 
where a.order_id not in (select order_id from orders_dataset where order_delivered_customer_date is null)
group by year(order_delivered_customer_date)

/*Doanh thu theo khu vực*/
SELECT c.customer_state, sum(b.payment_value) total_area_revenue
from orders_dataset a join order_payments_dataset b on a.order_id = b.order_id join customers_dataset c on a.customer_id = c.customer_id
where a.order_id not in (select order_id from orders_dataset where order_delivered_customer_date is null)
group by c.customer_state

/*Tổng order theo tháng*/
SELECT month(a.order_purchase_timestamp) month, count(a.order_id) total_month_orders
from orders_dataset a 
group by month(a.order_purchase_timestamp)
order by [month]

/* Thời gian giao hàng trung bình (kể từ lúc đặt đơn đến lúc nhận được hàng) */
SELECT avg(DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date)) as average_delivery_day
from orders_dataset

/* Có bao nhiêu đơn hàng bị trễ so với thời gian giao dự kiến */
SELECT distinct count(*) as lated_order
from orders_dataset
where order_delivered_customer_date > order_estimated_delivery_date

/* Có bao nhiêu đơn hàng vẫn trong trạng thái shipped trước 10/2018 */
select count(*) as pending_order
from orders_dataset
where order_status = 'shipped'

/* Thời gian xác nhận đơn hàng trung bình */
SELECT avg(DATEDIFF(minute, order_purchase_timestamp ,order_approved_at)) as average_confirmation_minute
from orders_dataset

/* Thời gian từ lúc xác nhận đơn hàng đến lúc shipper lấy hàng */
SELECT avg(DATEDIFF(HOUR, order_approved_at ,order_delivered_carrier_date)) as average_takeaway_hour
from orders_dataset

/* Thời gian giao hàng, xác nhận đơn hàng, shipper lấy hàng trung bình theo khu vực */
SELECT customer_state, avg(DATEDIFF(HOUR, order_purchase_timestamp, order_delivered_customer_date)) as average_delivery_hour_state,
avg(DATEDIFF(HOUR, order_purchase_timestamp ,order_approved_at)) as average_confirmation_hour_state,
avg(DATEDIFF(HOUR, order_approved_at ,order_delivered_carrier_date)) as average_takeaway_hour_state
from orders_dataset a join customers_dataset b on a.customer_id = b.customer_id
group by customer_state

/* Ảnh hưởng của Seller đến những đơn hàng giao chậm và review 1-3 sao --> Lí do chủ yếu đến từ việc shipper đến lấy hàng chậm/đóng hàng chậm */
SELECT seller_id as lated_seller, count(review_score) as quantity_1to3, 
avg(DATEDIFF(HOUR, order_purchase_timestamp, order_delivered_customer_date)) as average_delivery_hour_seller,
avg(DATEDIFF(HOUR, order_purchase_timestamp ,order_approved_at)) as average_confirmation_hour_seller,
avg(DATEDIFF(HOUR, order_approved_at ,order_delivered_carrier_date)) as average_takeaway_hour_seller
from order_items_dataset a join orders_dataset b on a.order_id = b.order_id join order_reviews_dataset c on a.order_id = c.order_id join customers_dataset d on b.customer_id = d.customer_id
where order_delivered_customer_date > order_estimated_delivery_date and review_score < 4
group by seller_id
order by quantity_1to3 desc

/* Ảnh hưởng của Seller đến những đơn hàng giao chậm và review trung bình */
SELECT seller_id as lated_seller, avg(review_score) as average_score, 
avg(DATEDIFF(HOUR, order_purchase_timestamp, order_delivered_customer_date)) as average_delivery_hour_seller,
avg(DATEDIFF(HOUR, order_purchase_timestamp ,order_approved_at)) as average_confirmation_hour_seller,
avg(DATEDIFF(HOUR, order_approved_at ,order_delivered_carrier_date)) as average_takeaway_hour_seller
from order_items_dataset a join orders_dataset b on a.order_id = b.order_id join order_reviews_dataset c on a.order_id = c.order_id join customers_dataset d on b.customer_id = d.customer_id
where order_delivered_customer_date > order_estimated_delivery_date
group by seller_id
order by average_score

/* Hình thức thanh toán phổ biến nhất và ít phổ biến nhất */
SELECT payment_type, count(order_id) as number_payment
from order_payments_dataset
group by payment_type
order by number_payment

/* Kỳ hạn phổ biến nhất & ít phổ biến nhất */
SELECT payment_installments, count(order_id) as total_installments, sum(payment_value) as total_value 
from order_payments_dataset
group by payment_installments
ORDER by total_installments DESC

/* Top 5 ngành hàng khách hàng thường thanh toán trả góp và thời hạn trả góp trung bình */
    /* B1: tạo bảng installments_category với thời hạn thanh toán trên 1 tháng, group by theo ngành hàng */
select c.product_category_name, count(payment_installments) as num_installments_1
into installments_category
from order_payments_dataset a join order_items_dataset b on a.order_id = b.order_id join products_dataset c on b.product_id = c.product_id
where payment_installments > 1
group by c.product_category_name
    /* B2: tạo bảng installments_category_2 group by theo ngành hàng */
select c.product_category_name, count(payment_installments) as num_installments
into installments_category_2
from order_payments_dataset a join order_items_dataset b on a.order_id = b.order_id join products_dataset c on b.product_id = c.product_id
group by c.product_category_name
select *
from installments_category
    /* B3: thêm bớt giá trị để join được 2 bảng --> thực hiện toán tử chia lấy phần trăm */
insert into installments_category
values ('seguros_e_servicos', 0)
    /* B4: lấy tỉ lệ thanh toán bằng hình thức trả góp của từng ngành hàng và thời hạn trả góp trung bình của từng ngành hàng*/
select x.product_category_name, x.percentage_installments, y.average_installments_time
from 
(SELECT a.product_category_name, num_installments_1*100/num_installments as percentage_installments
from installments_category a join installments_category_2 b on a.product_category_name = b.product_category_name) x
JOIN
(select c.product_category_name, avg(payment_installments) as average_installments_time
from order_payments_dataset a join order_items_dataset b on a.order_id = b.order_id join products_dataset c on b.product_id = c.product_id
where product_category_name is not NULL
group by c.product_category_name) y
on x.product_category_name = y.product_category_name
order by percentage_installments DESC

