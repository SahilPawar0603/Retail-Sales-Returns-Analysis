/*
===============================================================
Retail Sales & Returns Analysis using SQL Server

Author      : Sahil Pawar
Database    : Project 2
Tools       : Microsoft SQL Server, SSMS
Purpose     : Reporting Layer for Power BI

Description:
This project analyzes retail sales and product return data
to evaluate sales performance, customer behavior, category
performance, and return patterns.

A reusable reporting layer was created using SQL Views,
business KPIs, aggregate functions, and window functions.

The resulting views are intended for Power BI dashboards
and business reporting.

===============================================================
*/





/*=============================================================
                REPORTING VIEWS
===============================================================

The following views form the analytical reporting layer
used throughout this project and in the Power BI dashboard.

Views Included

1. Product Performance
2. Category Performance
3. Customer Performance
4. Return Details
5. Product Return Analysis
6. Category Return Analysis
7. Return Reason Analysis

=============================================================*/



/*-------------------------------------------------------------
VIEW 1 : Product Performance

Purpose
-------
Provides product-level sales performance metrics including:

• Total Quantity Sold
• Total Revenue
• Total Profit
• Revenue Rank
• Profit Rank

Business Questions Answered
---------------------------
• Which products generate the highest revenue?
• Which products generate the highest profit?
• Which products sell the most units?

-------------------------------------------------------------*/

CREATE VIEW vw_product_performance AS

SELECT 
	p.product_id, 
	P.product_name, 
	c.category_name, 
	SUM(oi.quantity) AS total_quantity_sold , 
	SUM( oi.quantity*oi.price ) AS total_Revenue, 
	SUM(oi.quantity* (p.selling_price - p.cost_price)) AS total_Profit, 
	DENSE_RANK () over (
		ORDER BY SUM( oi.quantity*oi.price )DESC ) AS revenue_rank,
	DENSE_RANK() OVER(
		ORDER BY SUM(oi.quantity * (p.selling_price - p.cost_price)) DESC
) AS profit_rank

FROM order_items oi

JOIN products p
	ON oi.product_id = p.product_id

JOIN categories c
	ON p.category_id = c.category_id

JOIN orders o
	ON oi.order_id = o.order_id

WHERE o.order_status = 'Completed'

GROUP BY 
		p.product_id,
	    p.product_name, 
	    c.category_name




/*=============================================================
VIEW 2 : Category Performance
===============================================================

Purpose
-------
Provides category-level sales performance metrics including:

• Total Quantity Sold
• Total Revenue
• Total Profit
• Revenue Rank
• Profit Rank

Business Questions Answered
---------------------------
• Which categories generate the highest revenue?
• Which categories generate the highest profit?
• Which categories sell the highest quantity?

-------------------------------------------------------------*/

CREATE VIEW vw_category_performance AS

SELECT
    vpp.category_name,
    SUM(vpp.total_quantity_sold) AS total_quantity_sold,
    SUM(vpp.total_revenue) AS total_revenue,
    SUM(vpp.total_profit) AS total_profit,
    DENSE_RANK() OVER (
        ORDER BY SUM(vpp.total_revenue) DESC
    ) AS revenue_rank,
    DENSE_RANK() OVER (
        ORDER BY SUM(vpp.total_profit) DESC
    ) AS profit_rank

FROM vw_product_performance vpp

GROUP BY
    vpp.category_name;



/*=============================================================
VIEW 3 : Customer Performance
===============================================================

Purpose
-------
Provides customer-level sales performance metrics including:

• Total Orders
• Total Quantity Purchased
• Total Revenue
• Total Profit
• Revenue Rank
• Profit Rank

Business Questions Answered
---------------------------
• Which customers generate the highest revenue?
• Which customers generate the highest profit?
• Which customers purchase the most?
• Which customers place the most completed orders?

-------------------------------------------------------------*/


CREATE VIEW vw_customer_performance AS

SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_full_name, 
    COUNT(DISTINCT o.order_id) AS customer_total_orders,
    SUM(oi.quantity) AS customer_total_quantity_purchased,
    SUM(oi.quantity * oi.price) AS customer_total_revenue,
    SUM(oi.quantity * (p.selling_price - p.cost_price)) AS customer_total_profit,
    DENSE_RANK() OVER (
        ORDER BY SUM(oi.quantity * oi.price) DESC
    ) AS customer_revenue_rank,
    DENSE_RANK() OVER (
        ORDER BY SUM(oi.quantity * (p.selling_price - p.cost_price)) DESC
    ) AS customer_profit_rank

FROM customers c

JOIN orders o
    ON c.customer_id = o.customer_id

JOIN order_items oi
    ON o.order_id = oi.order_id

JOIN products p
    ON oi.product_id = p.product_id

WHERE o.order_status = 'Completed'

GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name;


/*=============================================================
VIEW 4 : Return Details
===============================================================

Purpose
-------
Provides detailed information for every returned product.

This view serves as the foundation for all return-related
analysis within the project.

Information Included
--------------------
• Customer Information
• Product Information
• Category Information
• Return Date
• Return Reason

Role in the Reporting Layer
---------------------------
This view acts as the base reporting layer for:

• Product Return Analysis
• Category Return Analysis
• Return Reason Analysis
-------------------------------------------------------------*/


CREATE VIEW vw_return_details AS

SELECT
    r.return_id,
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    p.product_id,
    p.product_name,
    ct.category_id,
    ct.category_name,
    r.return_date,
    r.return_reason

FROM returns r

JOIN orders o
    ON r.order_id = o.order_id

JOIN customers c
    ON o.customer_id = c.customer_id

JOIN order_items oi
    ON r.order_id = oi.order_id
   AND r.product_id = oi.product_id

JOIN products p
    ON oi.product_id = p.product_id

JOIN categories ct
    ON p.category_id = ct.category_id;



/*=============================================================
VIEW 5 : Product Return Analysis
===============================================================

Purpose
-------
Analyzes product-level return performance by integrating
sales performance with return information.

KPIs Included
-------------
• Total Quantity Sold
• Total Returns
• Return Rate
• Return Rank

Business Questions Answered
---------------------------
• Which products are returned the most?
• Which products have the highest return rate?
• Which products require quality or fulfillment improvements?

-------------------------------------------------------------*/
CREATE VIEW vw_product_return_analysis AS

SELECT
    vwpp.product_id,
    vwpp.product_name,
    vwpp.category_name,
    vwpp.total_quantity_sold,
    COUNT(*) AS total_returns,
    CAST((COUNT(vwrd.return_date) * 100.0) / vwpp.total_quantity_sold AS DECIMAL(10, 2)) AS return_rate,
    DENSE_RANK() OVER (
        ORDER BY COUNT(*) DESC
    ) AS return_rank
FROM vw_return_details vwrd
JOIN vw_product_performance vwpp
    ON vwrd.product_id = vwpp.product_id
GROUP BY
    vwpp.product_id, 
    vwpp.product_name,
    vwpp.category_name,
    vwpp.total_quantity_sold;


/*=============================================================
VIEW 6 : Category Return Analysis
===============================================================

Purpose
-------
Analyzes return performance across product categories.

KPIs Included
-------------
• Total Quantity Sold
• Total Returns
• Return Rate
• Return Rank

Business Questions Answered
---------------------------
• Which categories experience the highest number of returns?
• Which categories have the highest return rate?
• Which categories require the greatest operational attention?

-------------------------------------------------------------*/

CREATE VIEW vw_category_return_analysis AS

SELECT 
	category_name, 
	SUM(total_quantity_sold) total_quantity_sold_per_category,
	SUM(total_returns) total_returns_per_category,
CAST(
    SUM(total_returns) * 100.0
    /
    SUM(total_quantity_sold) AS DECIMAL (10,2)) AS return_rate_per_category,
DENSE_RANK() OVER (
    ORDER BY SUM(total_returns) DESC
) AS return_rank
FROM vw_product_return_analysis
GROUP BY category_name


/*=============================================================
VIEW 7 : Return Reason Analysis
===============================================================

Purpose
-------
Analyzes the reasons behind product returns to identify
the primary drivers of customer returns.

KPIs Included
-------------
• Total Returns
• Return Percentage
• Return Rank

Business Questions Answered
---------------------------
• What are the most common reasons for product returns?
• Which return reason contributes the highest percentage of returns?
• Where should the business focus to reduce future returns?

-------------------------------------------------------------*/

CREATE VIEW vw_return_reason_analysis AS

SELECT                            
	return_reason, 
	COUNT(*) total_returns,
	CAST(COUNT(*) * 100.0  / SUM(COUNT(*)) over() as decimal (10,2)) as return_percentage_of_total,
	DENSE_RANK() over (order by COUNT(*) desc) return_rank
from 
	returns 
group by 
	return_reason





/*=============================================================
END OF PROJECT

Reporting Views Created : 7
Business Questions Solved : 12+
Business KPIs Developed : 9

Core SQL Concepts Demonstrated
------------------------------
• INNER JOIN
• GROUP BY
• Aggregate Functions
• Window Functions (DENSE_RANK)
• Views
• Derived Metrics
• Business KPI Development
• Reporting Layer Design

This reporting layer serves as the data source for the
Power BI dashboard developed as part of this project.

Author : Sahil Pawar
=============================================================*/
