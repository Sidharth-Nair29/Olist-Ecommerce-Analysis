-- E-commerce Sales & Customer Behaviour Analysis
-- Dataset: Brazilian E-Commerce Public Dataset by Olist

-- Objective: The objective of this project is to analyze e-commerce sales data to uncover key business insights
-- related to sales analysis, product performance, customer behavior, revenue distribution and payment analysis.
-- The analysis focuses on identifying high-value customer behaviour, understanding purchasing patterns, evaluating
-- product category performance, and assessing revenue concentration to support data-driven decision-making.

-- Author: Sidharth R. Nair
-- Tool Used: MySQL Workbench 


-- ---------------
-- SALES OVERVIEW
-- ---------------

-- Total revenue, Total orders registered and delivered, Delivery rate, Average order value and Total Customers.

select
    round(sum(oi.price + oi.freight_value), 2) as total_revenue,
    count(distinct o.order_id) as total_orders_delivered,
    round(sum(oi.price + oi.freight_value) / count(distinct o.order_id), 2) as avg_order_value,
    (select count(*) from orders) as total_orders_registered,
    round(count(distinct o.order_id) * 100.0 / (select count(*) from orders), 2) as delivery_rate,
    (select count(distinct customer_unique_id) from customers c join orders o on c.customer_id = o.customer_id where o.order_status = 'delivered') as total_customers
from orderitems oi
join orders o on oi.order_id = o.order_id
where o.order_status = 'delivered';


-- Monthly order trends

select
	date_format(o.order_purchase_timestamp, '%Y-%m') as month,
	count(distinct o.order_id) as total_orders,
	round(sum(oi.price + oi.freight_value), 2) as revenue
from orders o
join orderitems oi on o.order_id = oi.order_id
where o.order_status = 'delivered'
group by month
order by month;
 
-- Note:
-- Data covers September 2016 to August 2018. 
-- Early 2016 months reflect low order volumes or no orders at all due to the platform being in its initial growth phase.

-- -----------------
-- PRODUCT ANALYSIS 
-- -----------------

-- Category segmentation by total revenue, volume and average product value.

with category_stats as (
    select
        coalesce(nullif(trim(p.product_category_name), ''), 'Unknown') as product_category,
        round(sum(oi.price + oi.freight_value), 2) as total_revenue,
        count(*) as total_item_purchases,
        round(sum(oi.price + oi.freight_value) / count(*), 2) as avg_revenue_per_item
    from orders o
    join orderitems oi on o.order_id = oi.order_id
    join products p on oi.product_id = p.product_id
    where o.order_status = 'delivered'
    group by product_category
),

segmented as (
    select
        *,
        ntile(3) over(order by total_revenue desc) as revenue_segment,
        ntile(3) over(order by total_item_purchases desc) as volume_segment,
        ntile(3) over(order by avg_revenue_per_item desc) as value_segment
    from category_stats
)

select
    *,
	case
		when revenue_segment = 1 and volume_segment = 1 and value_segment = 1
			then 'Star Category'
		when revenue_segment = 1 and volume_segment = 1
			then 'Core Driver'
		when revenue_segment = 1 and value_segment = 1
			then 'High Value Leader'
		when value_segment = 1 and volume_segment = 3
			then 'Premium Niche'
		when revenue_segment = 2 and value_segment = 1
			then 'Premium Growth'
		when revenue_segment = 2 and volume_segment = 1
			then 'Volume Growth'
		when revenue_segment = 3 and (volume_segment = 3 or value_segment = 3)
			then 'Low Impact'
		else 'Balanced'
	end as category_segmented
from segmented;


-- Top 10 frequently purchased product categories.

with product_frequency as (
    select
        oi.product_id,
        count(*) as order_line_count,
        count(distinct oi.order_id) as order_count,
        sum(oi.price + oi.freight_value) as revenue
    from orderitems oi
    join orders o on oi.order_id = o.order_id
    where o.order_status = 'delivered'
    group by oi.product_id
)

select
    coalesce(nullif(trim(pr.product_category_name), ''), 'Unknown') as product_category_name,
    sum(pf.order_line_count) as order_line_count,
    sum(pf.order_count) as order_count,
    round(sum(pf.revenue), 2) as revenue,
    round(sum(pf.revenue) / sum(pf.order_line_count), 2) as avg_revenue_per_line
from product_frequency pf
join products pr on pf.product_id = pr.product_id
group by product_category_name
order by order_line_count desc
limit 10;


-- Categories with low performance

with category_stats as (
    select
        coalesce(nullif(trim(p.product_category_name), ''), 'Unknown') as category,
        count(*) as total_products_ordered,
        round(sum(oi.price + oi.freight_value), 2) as total_revenue,
        round(sum(oi.price + oi.freight_value)/count(*), 2) as avg_value
    from orders o
    join orderitems oi on o.order_id = oi.order_id
    join products p on oi.product_id = p.product_id
    where o.order_status = 'delivered'
    group by category
),

segmented as (
    select *,
        ntile(3) over(order by total_revenue desc) as revenue_segment,
        ntile(3) over(order by total_products_ordered desc) as volume_segment,
        ntile(3) over(order by avg_value desc) as value_segment
    from category_stats
)

select *
from segmented
where revenue_segment = 3 and volume_segment = 3 and value_segment = 3;


-- -----------------
-- CUSTOMER ANALYSIS
-- -----------------

-- Top customers by revenue.

with customer_stats as (
    select
        c.customer_unique_id,
        count(distinct o.order_id) as number_of_orders,
        round(sum(oi.price + oi.freight_value),2) as total_revenue
    from orderitems oi
    join orders o on oi.order_id = o.order_id
    join customers c on o.customer_id = c.customer_id
    where o.order_status = 'delivered'
    group by c.customer_unique_id
)

select
    *,
    round(total_revenue / number_of_orders, 2) as avg_order_value
from customer_stats
order by total_revenue desc, number_of_orders desc
limit 100;


-- Classification of customers based on purchase frequency

with customer_data as (
select
	c.customer_unique_id,
	round(sum(oi.price + oi.freight_value),2) as revenue_per_customer,
	count(distinct o.order_id) as number_of_orders
from orderitems oi
join orders o on oi.order_id = o.order_id
join customers c on o.customer_id = c.customer_id
where o.order_status = 'delivered'
group by c.customer_unique_id
),

cust_type as (
select
	*,
	case when number_of_orders > 1 then 'repeat' else 'one-time' end as customer_type,
    round(revenue_per_customer / number_of_orders, 2) as avg_order_value
from customer_data
),

segment_data as ( 
select
	customer_type,
	round(sum(revenue_per_customer),2) as total_revenue,
	sum(number_of_orders) as total_orders,
	count(customer_unique_id) as total_customers,
	round(avg(revenue_per_customer),2) as avg_revenue_per_customer,
	round(avg(number_of_orders),1) as avg_orders_per_customer,
    round(avg(avg_order_value),2) as avg_order_value
from cust_type
group by customer_type
),

totals as (
select
	round(sum(oi.price + oi.freight_value), 2) as overall_revenue,
	count(distinct c.customer_unique_id) as overall_customers
from orderitems oi
join orders o on oi.order_id = o.order_id
join customers c on o.customer_id = c.customer_id
where o.order_status = 'delivered'
)

select
	sd.*,
	round(total_revenue / overall_revenue * 100, 2) as revenue_contribution,
	round(total_customers / overall_customers * 100, 2) as customer_contribution
from segment_data sd
cross join totals;

-- INSIGHTS :
-- Extreme skew toward one-time purchases, which is not healthy for long-term business sustainability.
-- Revenue is not driven by loyal customers, it is heavily dependent on continuous acquisition.
-- Repeat customers generate 2 times more revenue per customer. Retaining a customer is far more valuable than acquiring a new one.
-- Repeat customers make multiple smaller purchases, are individually high-value but underrepresented in the customer base.
-- One-time customers tend to make slightly higher-value single purchases.

-- CORE BUSINESS PROBLEM :
-- Repeat purchase rate appears low within the observed timeframe suggesting inefficient retention strategy.

-- STRATEGIC INSIGHTS :
-- The business is acquisition-heavy, retention-poor.
-- Increasing repeat customer % from 3% to even 10% could significantly boost revenue.
-- There is strong potential in : Loyalty programs, Retargeting campaigns, Personalized recommendations.


-- --------------------
-- REVENUE DISTRIBUTION 
-- --------------------

with basket as (
select
	o.order_id,
	o.customer_id,
	count(oi.order_item_id) as items_per_order
from orderitems oi
join orders o on oi.order_id = o.order_id
where o.order_status = 'delivered'
group by
	o.order_id,
	o.customer_id
),

basket_per_customer as (
select
	c.customer_unique_id,
	avg(b.items_per_order) as avg_items_per_order
from customers c
join basket b on c.customer_id = b.customer_id
group by c.customer_unique_id
),

revenue_per_customer as (
select
	c.customer_unique_id,
	bpc.avg_items_per_order,
	sum(oi.price + oi.freight_value) as total_revenue_per_customer,
	count(distinct o.order_id) as number_of_orders
from orderitems oi
join orders o on oi.order_id = o.order_id
join customers c on o.customer_id = c.customer_id
join basket_per_customer bpc on c.customer_unique_id = bpc.customer_unique_id
where o.order_status = 'delivered'
group by
	c.customer_unique_id,
    bpc.avg_items_per_order
),

segment_assignment as (
select
	*,
	total_revenue_per_customer/number_of_orders as average_order_value,
	ntile(10) over(order by total_revenue_per_customer desc) as segment
from revenue_per_customer
),

segment_stats as (
select
	segment,
	case
		when segment = 1 then 'VIP Customers'
		when segment between 2 and 3 then 'High Value Customers'
		when segment between 4 and 6 then 'Mid Value Customers'
		when segment between 7 and 8 then 'Low Value Customers'
		else 'Very Low Value Customers'
    end as segment_label,
	round(sum(total_revenue_per_customer),2) as revenue_contribution,
	count(*) as number_of_customers,
	round(avg(number_of_orders),1) as avg_number_of_orders_per_customer,
	round(avg(average_order_value),2) as avg_order_value_per_segment,
	round(avg(avg_items_per_order),1) as avg_basket_size
from segment_assignment
group by segment
),

totals as (
select round(sum(oi.price + oi.freight_value), 2) as overall_revenue
from orderitems oi
join orders o on oi.order_id = o.order_id
where o.order_status = 'delivered'
)

select
	ss.*,
	round((revenue_contribution / t.overall_revenue) * 100, 2) as revenue_percentage,
    round(sum(ss.revenue_contribution) over(order by ss.segment), 2) as cumulative_revenue,
    round(sum(ss.revenue_contribution) over(order by ss.segment) * 100.0 / t.overall_revenue, 2) as cumulative_revenue_percentage
from segment_stats ss
cross join totals t
order by ss.segment;


-- INSIGHTS :
-- Top 10% of customers contribute ~38% of total revenue, indicating strong revenue concentration.
-- Top 30% of customers generate ~64% of revenue, shows strong revenue concentration, though not strictly Pareto (80/20).
-- Bottom 50% of customers contribute less than 20% of revenue, highlighting low-value segments.
-- Significant gap in average order value between top and bottom segments (R$600 vs R$30), indicating different
-- 		purchasing power/intent.
-- High-value customers are not necessarily frequent buyers (avg orders ≈ 1), meaning revenue is driven by high
-- 		-ticket purchases, not loyalty.

-- CORE BUSINESS PROBLEM :
-- The business lacks a strong base of loyal, high-frequency customers.

-- STRATEGIC INSIGHTS :
-- Business is highly dependent on top-tier customers
-- Losing top 10% customers would significantly impact revenue
-- There is untapped potential in mid-tier segments (Segments 3–6). These customers exist in large numbers, but
-- 		have moderate spending, ideal for upselling.
-- Increasing order frequency is a bigger opportunity than increasing basket size.


-- ----------------
-- PAYMENT ANALYSIS
-- ----------------

-- Payment method breakdown.

with payment_summary as (
select
    payment_type,
    count(distinct order_id) as total_orders,
    round(sum(payment_value), 2) as total_revenue,
    round(avg(payment_installments), 1) as avg_installments
from payments
group by payment_type
),

totals as  (
select
    count(distinct order_id) as overall_orders,
    round(sum(payment_value), 2) as overall_revenue
from payments
)

select
	ps.*,
    round(ps.total_orders / t.overall_orders * 100, 2) as order_distribution,
    round(ps.total_revenue / t.overall_revenue * 100, 2) as revenue_distribution
from payment_summary ps
cross join totals t
order by total_orders desc;


-- Installment behaviour — do high-value orders use more installments?

select
    payment_installments,
    count(distinct p.order_id) as total_orders,
    round(avg(p.payment_value), 2) as avg_order_value
from payments p
join orders o on p.order_id = o.order_id
where o.order_status = 'delivered' and payment_type = 'credit_card'
group by payment_installments
order by payment_installments;


-- Revenue cross-check — payments vs orderitems.

with payment_totals as (
    select
        order_id,
        round(sum(payment_value), 2) as total_paid
    from payments
    group by order_id
)

select
    round(sum(oi.price + oi.freight_value), 2) as revenue_from_items,
    round(sum(pt.total_paid), 2) as revenue_from_payments,
    round(sum(pt.total_paid) - sum(oi.price + oi.freight_value), 2) as discrepancy
from orders o
join orderitems oi on o.order_id = oi.order_id
join payment_totals pt on o.order_id = pt.order_id
where o.order_status = 'delivered';

-- Note:
-- A discrepancy of R$4,356,530 exists between payment_value totals and
-- orderitems revenue. Discrepancy arises due to multiple payment records
-- per order (including vouchers and split payments), causing aggregation
-- differences. orderitems (price + freight_value) is used as the consistent
-- revenue definition throughout this analysis.

-- INSIGHTS :
-- Credit card is the dominant payment method, accounting for 76.94% of overall orders and 78.34% of total payment revenue.
-- Boleto is the second most used method contributing 19.90% of total orders, all paid upfront (avg installments = 1.0).
-- Vouchers, while low in order count (3866), are the likely source of the ~R$4.36M revenue discrepancy between payments
-- 		and orderitems tables, as they represent additional payment rows on existing orders.
-- Credit card is the only payment method involving installments, with an average of 3.5 
-- 		installments per transaction, further reinforcing its dominance in high-value purchases.
-- Higher-value orders tend to be financed through more installments (1 installment = R$95 vs 10 installments = R$410),
--   	suggesting customers use installments to afford larger purchases, not merely out of habit.
-- Installment counts above 10 have negligible order volumes and anomalous avg values - treated as outliers.

-- CORE BUSINESS PROBLEM :
-- The business has no visibility into how payment behaviour affects cash flow.
-- Revenue recorded at order time may not reflect actual cash received, especially for high-installment orders.

-- STRATEGIC INSIGHTS :
-- Boleto orders (~20% of orders) represent immediate full payment — prioritising boleto customers reduces cash flow risk.
-- Offering targeted installment plans (4–6 installments) for mid-value categories could unlock higher spend from price-
-- 		sensitive customers.
-- Voucher usage should be monitored closely — while it drives orders, it directly reduces net revenue and inflates
-- 		aggregated payment totals relative to product-level revenue.