USE dataco_supply_chain;

-- =====================================================
-- 1. OVERALL BUSINESS KPIs
-- =====================================================

SELECT
    COUNT(DISTINCT o.Order_Id) AS total_orders,
    SUM(oi.Order_Item_Quantity) AS total_quantity,
    ROUND(SUM(oi.Sales), 2) AS total_sales,
    ROUND(SUM(oi.Benefit_per_order), 2) AS total_profit,
    ROUND(
        SUM(oi.Benefit_per_order) / SUM(oi.Sales) * 100,
        2
    ) AS profit_margin_percent,
    ROUND(
        SUM(oi.Sales) / COUNT(DISTINCT o.Order_Id),
        2
    ) AS average_order_value
FROM orders o
JOIN order_items oi
    ON o.Order_Id = oi.Order_Id;

-- =====================================================
-- 2. YEAR-OVER-YEAR SALES, PROFIT & ORDER GROWTH
-- =====================================================

WITH yearly_metrics AS (
    SELECT
        YEAR(o.Order_Date) AS order_year,
        COUNT(DISTINCT o.Order_Id) AS total_orders,
        SUM(oi.Sales) AS total_sales,
        SUM(oi.Benefit_per_order) AS total_profit
    FROM orders o
    JOIN order_items oi
        ON o.Order_Id = oi.Order_Id
    GROUP BY YEAR(o.Order_Date)
)

SELECT
    order_year,
    total_orders,
    ROUND(total_sales, 2) AS total_sales,
    ROUND(total_profit, 2) AS total_profit,

    ROUND(
        (total_sales - LAG(total_sales) OVER (ORDER BY order_year))
        / LAG(total_sales) OVER (ORDER BY order_year) * 100,
        2
    ) AS sales_growth_percent,

    ROUND(
        (total_profit - LAG(total_profit) OVER (ORDER BY order_year))
        / LAG(total_profit) OVER (ORDER BY order_year) * 100,
        2
    ) AS profit_growth_percent,

    ROUND(
        (total_orders - LAG(total_orders) OVER (ORDER BY order_year))
        / LAG(total_orders) OVER (ORDER BY order_year) * 100,
        2
    ) AS order_growth_percent

FROM yearly_metrics
ORDER BY order_year;

-- =====================================================
-- 3. MONTHLY SALES TRENDS
-- =====================================================

SELECT
    DATE_FORMAT(o.Order_Date, '%Y-%m') AS order_month,
    COUNT(DISTINCT o.Order_Id) AS total_orders,
    SUM(oi.Order_Item_Quantity) AS total_quantity,
    ROUND(SUM(oi.Sales), 2) AS total_sales,
    ROUND(SUM(oi.Benefit_per_order), 2) AS total_profit
FROM orders o
JOIN order_items oi
    ON o.Order_Id = oi.Order_Id
GROUP BY DATE_FORMAT(o.Order_Date, '%Y-%m')
ORDER BY order_month;

-- =====================================================
-- 4. SALES & ORDERS BY MARKET
-- =====================================================

SELECT
    o.Market,
    COUNT(DISTINCT o.Order_Id) AS total_orders,
    SUM(oi.Order_Item_Quantity) AS total_quantity,
    ROUND(SUM(oi.Sales), 2) AS total_sales,
    ROUND(SUM(oi.Benefit_per_order), 2) AS total_profit,
    ROUND(
        SUM(oi.Benefit_per_order) / SUM(oi.Sales) * 100,
        2
    ) AS profit_margin_percent
FROM orders o
JOIN order_items oi
    ON o.Order_Id = oi.Order_Id
GROUP BY o.Market
ORDER BY total_sales DESC;

-- =====================================================
-- 5. SALES & PROFIT BY ORDER REGION
-- =====================================================

SELECT
    o.Order_Region,
    COUNT(DISTINCT o.Order_Id) AS total_orders,
    SUM(oi.Order_Item_Quantity) AS total_quantity,
    ROUND(SUM(oi.Sales), 2) AS total_sales,
    ROUND(SUM(oi.Benefit_per_order), 2) AS total_profit,
    ROUND(
        SUM(oi.Benefit_per_order) / SUM(oi.Sales) * 100,
        2
    ) AS profit_margin_percent
FROM orders o
JOIN order_items oi
    ON o.Order_Id = oi.Order_Id
GROUP BY o.Order_Region
ORDER BY total_sales DESC;

-- =====================================================
-- 6. LATE DELIVERY RATE BY SHIPPING MODE
-- =====================================================

SELECT
    o.Shipping_Mode,
    COUNT(DISTINCT o.Order_Id) AS total_orders,
    SUM(o.Late_delivery_risk) AS late_orders,
    ROUND(
        SUM(o.Late_delivery_risk) / COUNT(DISTINCT o.Order_Id) * 100,
        2
    ) AS late_delivery_rate_percent,

    ROUND(
        AVG(o.Days_for_shipping_real),
        2
    ) AS avg_actual_shipping_days,

    ROUND(
        AVG(o.Days_for_shipment_scheduled),
        2
    ) AS avg_scheduled_shipping_days

FROM orders o
GROUP BY o.Shipping_Mode
ORDER BY late_delivery_rate_percent DESC;

-- =====================================================
-- 7. CUSTOMER REPEAT-PURCHASE ANALYSIS
-- =====================================================

WITH customer_orders AS (
    SELECT
        Customer_Id,
        COUNT(DISTINCT Order_Id) AS order_count
    FROM orders
    GROUP BY Customer_Id
),

customer_segments AS (
    SELECT
        Customer_Id,
        order_count,
        CASE
            WHEN order_count = 1 THEN 'One-time'
            WHEN order_count BETWEEN 2 AND 3 THEN 'Repeat'
            ELSE 'Loyal'
        END AS purchase_type
    FROM customer_orders
),

customer_value AS (
    SELECT
        cs.Customer_Id,
        cs.purchase_type,
        cs.order_count,
        SUM(oi.Sales) AS total_sales,
        SUM(oi.Benefit_per_order) AS total_profit
    FROM customer_segments cs
    JOIN orders o
        ON cs.Customer_Id = o.Customer_Id
    JOIN order_items oi
        ON o.Order_Id = oi.Order_Id
    GROUP BY
        cs.Customer_Id,
        cs.purchase_type,
        cs.order_count
)

SELECT
    purchase_type,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_percent,
    ROUND(AVG(order_count), 2) AS avg_orders_per_customer,
    ROUND(SUM(total_sales), 2) AS total_sales,
    ROUND(SUM(total_profit), 2) AS total_profit,
    ROUND(
        SUM(total_profit) / SUM(total_sales) * 100,
        2
    ) AS profit_margin_percent
FROM customer_value
GROUP BY purchase_type
ORDER BY
    CASE purchase_type
        WHEN 'Loyal' THEN 1
        WHEN 'Repeat' THEN 2
        WHEN 'One-time' THEN 3
    END; 

-- =====================================================
-- 8. TOP PRODUCT IN EACH CATEGORY
-- =====================================================

WITH product_sales AS (
    SELECT
        p.Category_Name,
        p.Product_Name,
        ROUND(SUM(oi.Sales), 2) AS total_sales
    FROM products p
    JOIN order_items oi
        ON p.Product_Card_Id = oi.Product_Card_Id
    GROUP BY
        p.Category_Name,
        p.Product_Name
)

SELECT
    Category_Name,
    Product_Name,
    total_sales
FROM (
    SELECT
        Category_Name,
        Product_Name,
        total_sales,
        RANK() OVER (
            PARTITION BY Category_Name
            ORDER BY total_sales DESC
        ) AS product_rank
    FROM product_sales
) ranked_products
WHERE product_rank = 1
ORDER BY total_sales DESC;

-- =====================================================
-- 9. HIGH-FREQUENCY CUSTOMER SUMMARY
-- =====================================================

SELECT
    COUNT(*) AS customers_with_more_than_5_orders,
    MAX(order_count) AS maximum_orders_by_customer
FROM (
    SELECT
        Customer_Id,
        COUNT(DISTINCT Order_Id) AS order_count
    FROM orders
    GROUP BY Customer_Id
    HAVING COUNT(DISTINCT Order_Id) > 5
) AS customer_orders;

-- =====================================================
-- 10. PRODUCT CUSTOMER REACH
-- =====================================================

SELECT
    p.Product_Name,
    COUNT(DISTINCT oi.Order_Id) AS total_orders,
    COUNT(DISTINCT o.Customer_Id) AS unique_customers
FROM products p
JOIN order_items oi
    ON p.Product_Card_Id = oi.Product_Card_Id
JOIN orders o
    ON oi.Order_Id = o.Order_Id
GROUP BY
    p.Product_Card_Id,
    p.Product_Name
ORDER BY unique_customers DESC
LIMIT 10;

-- =====================================================
-- 11. SINGLE-ITEM VS MULTI-ITEM ORDERS
-- =====================================================

SELECT
    CASE
        WHEN item_count = 1 THEN 'Single-item order'
        ELSE 'Multi-item order'
    END AS order_type,
    COUNT(*) AS order_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_percent
FROM (
    SELECT
        Order_Id,
        COUNT(*) AS item_count
    FROM order_items
    GROUP BY Order_Id
) AS order_summary
GROUP BY
    CASE
        WHEN item_count = 1 THEN 'Single-item order'
        ELSE 'Multi-item order'
    END
ORDER BY order_count DESC;

-- =====================================================
-- 12. ORDER SIZE BY CUSTOMER SEGMENT
-- =====================================================

SELECT
    c.Customer_Segment,
    COUNT(DISTINCT o.Order_Id) AS total_orders,
    ROUND(
        SUM(oi.Order_Item_Quantity) /
        COUNT(DISTINCT o.Order_Id),
        2
    ) AS avg_items_per_order,
    ROUND(
        SUM(oi.Sales) /
        COUNT(DISTINCT o.Order_Id),
        2
    ) AS avg_order_value
FROM customers c
JOIN orders o
    ON c.Customer_Id = o.Customer_Id
JOIN order_items oi
    ON o.Order_Id = oi.Order_Id
GROUP BY c.Customer_Segment
ORDER BY avg_order_value DESC;

-- =====================================================
-- 13. LATE DELIVERY RATE BY MARKET
-- =====================================================

SELECT
    Market,
    COUNT(DISTINCT Order_Id) AS total_orders,
    SUM(Late_delivery_risk) AS late_orders,
    ROUND(
        SUM(Late_delivery_risk) * 100.0 / COUNT(DISTINCT Order_Id),
        2
    ) AS late_delivery_rate_percent
FROM orders
GROUP BY Market
ORDER BY late_delivery_rate_percent DESC;

-- =====================================================
-- 14. AVERAGE SHIPPING DELAY BY MARKET
-- =====================================================

SELECT
    Market,
    COUNT(DISTINCT Order_Id) AS total_orders,
    ROUND(AVG(Days_for_shipping_real), 2) AS avg_actual_shipping_days,
    ROUND(AVG(Days_for_shipment_scheduled), 2) AS avg_scheduled_shipping_days,
    ROUND(
        AVG(Days_for_shipping_real - Days_for_shipment_scheduled),
        2
    ) AS avg_shipping_delay_days
FROM orders
GROUP BY Market
ORDER BY avg_shipping_delay_days DESC;

-- =====================================================
-- 15. LATE DELIVERY RATE BY CUSTOMER SEGMENT
-- =====================================================

SELECT
    c.Customer_Segment,
    COUNT(DISTINCT o.Order_Id) AS total_orders,
    SUM(o.Late_delivery_risk) AS late_orders,
    ROUND(
        SUM(o.Late_delivery_risk) * 100.0
        / COUNT(DISTINCT o.Order_Id),
        2
    ) AS late_delivery_rate_percent
FROM customers c
JOIN orders o
    ON c.Customer_Id = o.Customer_Id
GROUP BY c.Customer_Segment
ORDER BY late_delivery_rate_percent DESC;

-- =====================================================
-- 16. REPEAT CUSTOMERS BY CUSTOMER SEGMENT
-- =====================================================

SELECT
    c.Customer_Segment,
    COUNT(DISTINCT c.Customer_Id) AS total_customers,
    COUNT(DISTINCT CASE
        WHEN customer_orders.order_count > 1
        THEN c.Customer_Id
    END) AS repeat_customers,
    ROUND(
        COUNT(DISTINCT CASE
            WHEN customer_orders.order_count > 1
            THEN c.Customer_Id
        END) * 100.0
        / COUNT(DISTINCT c.Customer_Id),
        2
    ) AS repeat_customer_rate_percent
FROM customers c
JOIN (
    SELECT
        Customer_Id,
        COUNT(DISTINCT Order_Id) AS order_count
    FROM orders
    GROUP BY Customer_Id
) AS customer_orders
    ON c.Customer_Id = customer_orders.Customer_Id
GROUP BY c.Customer_Segment
ORDER BY repeat_customer_rate_percent DESC;

-- =====================================================
-- 17. AVERAGE ORDER VALUE BY CUSTOMER SEGMENT
-- =====================================================

SELECT
    c.Customer_Segment,
    COUNT(DISTINCT o.Order_Id) AS total_orders,
    ROUND(
        SUM(oi.Sales) / COUNT(DISTINCT o.Order_Id),
        2
    ) AS average_order_value,
    ROUND(
        SUM(oi.Order_Item_Quantity) / COUNT(DISTINCT o.Order_Id),
        2
    ) AS average_items_per_order
FROM customers c
JOIN orders o
    ON c.Customer_Id = o.Customer_Id
JOIN order_items oi
    ON o.Order_Id = oi.Order_Id
GROUP BY c.Customer_Segment
ORDER BY average_order_value DESC;

-- =====================================================
-- 18. ORDER COMPOSITION BY CUSTOMER SEGMENT
-- =====================================================

SELECT
    c.Customer_Segment,
    CASE
        WHEN item_count = 1 THEN 'Single-item'
        ELSE 'Multi-item'
    END AS order_type,
    COUNT(*) AS order_count
FROM customers c
JOIN orders o
    ON c.Customer_Id = o.Customer_Id
JOIN (
    SELECT
        Order_Id,
        COUNT(*) AS item_count
    FROM order_items
    GROUP BY Order_Id
) AS order_items_count
    ON o.Order_Id = order_items_count.Order_Id
GROUP BY
    c.Customer_Segment,
    CASE
        WHEN item_count = 1 THEN 'Single-item'
        ELSE 'Multi-item'
    END
ORDER BY
    c.Customer_Segment,
    order_count DESC;

-- =====================================================
-- 19. CUSTOMER VALUE BY CUSTOMER SEGMENT
-- =====================================================

SELECT
    c.Customer_Segment,
    COUNT(DISTINCT c.Customer_Id) AS total_customers,
    ROUND(SUM(oi.Sales), 2) AS total_sales,
    ROUND(SUM(oi.Benefit_per_order), 2) AS total_profit,
    ROUND(
        SUM(oi.Sales) / COUNT(DISTINCT c.Customer_Id),
        2
    ) AS sales_per_customer,
    ROUND(
        SUM(oi.Benefit_per_order) / COUNT(DISTINCT c.Customer_Id),
        2
    ) AS profit_per_customer
FROM customers c
JOIN orders o
    ON c.Customer_Id = o.Customer_Id
JOIN order_items oi
    ON o.Order_Id = oi.Order_Id
GROUP BY c.Customer_Segment
ORDER BY sales_per_customer DESC;

-- =====================================================
-- 20. TOP CUSTOMERS BY SALES
-- =====================================================

SELECT
    c.Customer_Id,
    CONCAT(c.Customer_Fname, ' ', c.Customer_Lname) AS customer_name,
    c.Customer_Segment,
    COUNT(DISTINCT o.Order_Id) AS total_orders,
    ROUND(SUM(oi.Sales), 2) AS total_sales,
    ROUND(SUM(oi.Benefit_per_order), 2) AS total_profit
FROM customers c
JOIN orders o
    ON c.Customer_Id = o.Customer_Id
JOIN order_items oi
    ON o.Order_Id = oi.Order_Id
GROUP BY
    c.Customer_Id,
    c.Customer_Fname,
    c.Customer_Lname,
    c.Customer_Segment
ORDER BY total_sales DESC
LIMIT 10;

-- =====================================================
-- 21. PRODUCTS WITH THE WIDEST CUSTOMER REACH
-- =====================================================

SELECT
    p.Product_Name,
    p.Category_Name,
    COUNT(DISTINCT o.Customer_Id) AS unique_customers,
    COUNT(DISTINCT o.Order_Id) AS total_orders,
    ROUND(SUM(oi.Sales), 2) AS total_sales
FROM products p
JOIN order_items oi
    ON p.Product_Card_Id = oi.Product_Card_Id
JOIN orders o
    ON oi.Order_Id = o.Order_Id
GROUP BY
    p.Product_Card_Id,
    p.Product_Name,
    p.Category_Name
ORDER BY unique_customers DESC
LIMIT 10;

-- =====================================================
-- 22. PRODUCT PROFITABILITY
-- =====================================================

SELECT
    p.Product_Name,
    p.Category_Name,
    ROUND(SUM(oi.Sales), 2) AS total_sales,
    ROUND(SUM(oi.Benefit_per_order), 2) AS total_profit,
    ROUND(
        SUM(oi.Benefit_per_order) / SUM(oi.Sales) * 100,
        2
    ) AS profit_margin_percent
FROM products p
JOIN order_items oi
    ON p.Product_Card_Id = oi.Product_Card_Id
GROUP BY
    p.Product_Card_Id,
    p.Product_Name,
    p.Category_Name
HAVING SUM(oi.Sales) > 0
ORDER BY profit_margin_percent ASC
LIMIT 10;

-- =====================================================
-- 23. SHIPPING PERFORMANCE BY CUSTOMER SEGMENT
-- =====================================================

SELECT
    c.Customer_Segment,
    COUNT(DISTINCT o.Order_Id) AS total_orders,
    ROUND(AVG(o.Days_for_shipping_real), 2) AS avg_actual_shipping_days,
    ROUND(AVG(o.Days_for_shipment_scheduled), 2) AS avg_scheduled_shipping_days,
    ROUND(
        AVG(
            o.Days_for_shipping_real
            - o.Days_for_shipment_scheduled
        ),
        2
    ) AS avg_shipping_delay_days
FROM customers c
JOIN orders o
    ON c.Customer_Id = o.Customer_Id
GROUP BY c.Customer_Segment
ORDER BY avg_shipping_delay_days DESC;

-- =====================================================
-- 24. PRODUCT CATEGORY PERFORMANCE BY ORDER REGION
-- =====================================================

SELECT
    o.Order_Region,
    p.Category_Name,
    COUNT(DISTINCT o.Order_Id) AS total_orders,
    ROUND(SUM(oi.Sales), 2) AS total_sales,
    ROUND(SUM(oi.Benefit_per_order), 2) AS total_profit
FROM orders o
JOIN order_items oi
    ON o.Order_Id = oi.Order_Id
JOIN products p
    ON oi.Product_Card_Id = p.Product_Card_Id
GROUP BY
    o.Order_Region,
    p.Category_Name
ORDER BY
    o.Order_Region,
    total_sales DESC;

-- =====================================================
-- 25. MONTHLY SALES BY CUSTOMER SEGMENT
-- =====================================================

SELECT
    DATE_FORMAT(o.Order_Date, '%Y-%m') AS order_month,
    c.Customer_Segment,
    COUNT(DISTINCT o.Order_Id) AS total_orders,
    ROUND(SUM(oi.Sales), 2) AS total_sales
FROM customers c
JOIN orders o
    ON c.Customer_Id = o.Customer_Id
JOIN order_items oi
    ON o.Order_Id = oi.Order_Id
GROUP BY
    DATE_FORMAT(o.Order_Date, '%Y-%m'),
    c.Customer_Segment
ORDER BY
    order_month,
    c.Customer_Segment;

-- =====================================================
-- 26. REPEAT PURCHASE RATE BY MARKET
-- =====================================================

SELECT
    o.Market,
    COUNT(DISTINCT o.Customer_Id) AS total_customers,
    COUNT(DISTINCT CASE
        WHEN customer_orders.order_count > 1
        THEN o.Customer_Id
    END) AS repeat_customers,
    ROUND(
        COUNT(DISTINCT CASE
            WHEN customer_orders.order_count > 1
            THEN o.Customer_Id
        END) * 100.0
        / COUNT(DISTINCT o.Customer_Id),
        2
    ) AS repeat_customer_rate_percent
FROM orders o
JOIN (
    SELECT
        Customer_Id,
        COUNT(DISTINCT Order_Id) AS order_count
    FROM orders
    GROUP BY Customer_Id
) AS customer_orders
    ON o.Customer_Id = customer_orders.Customer_Id
GROUP BY o.Market
ORDER BY repeat_customer_rate_percent DESC;

-- =====================================================
-- 27. ORDER VOLUME BY DAY OF WEEK
-- =====================================================

SELECT
    DAYNAME(Order_Date) AS day_of_week,
    COUNT(DISTINCT Order_Id) AS total_orders,
    SUM(
        CASE
            WHEN Late_delivery_risk = 1 THEN 1
            ELSE 0
        END
    ) AS late_orders,
    ROUND(
        SUM(
            CASE
                WHEN Late_delivery_risk = 1 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(DISTINCT Order_Id),
        2
    ) AS late_delivery_rate_percent
FROM orders
GROUP BY
    DAYOFWEEK(Order_Date),
    DAYNAME(Order_Date)
ORDER BY DAYOFWEEK(Order_Date);

-- =====================================================
-- 28. TOP CITIES BY SALES
-- =====================================================

SELECT
    o.Order_City,
    COUNT(DISTINCT o.Order_Id) AS total_orders,
    ROUND(SUM(oi.Sales), 2) AS total_sales,
    ROUND(SUM(oi.Benefit_per_order), 2) AS total_profit
FROM orders o
JOIN order_items oi
    ON o.Order_Id = oi.Order_Id
GROUP BY o.Order_City
ORDER BY total_sales DESC
LIMIT 15;

-- =====================================================
-- 29. CUSTOMER DENSITY BY CITY
-- =====================================================

SELECT
    o.Order_City,
    COUNT(DISTINCT o.Customer_Id) AS unique_customers,
    COUNT(DISTINCT o.Order_Id) AS total_orders,
    ROUND(
        COUNT(DISTINCT o.Order_Id) * 1.0
        / COUNT(DISTINCT o.Customer_Id),
        2
    ) AS orders_per_customer
FROM orders o
GROUP BY o.Order_City
HAVING COUNT(DISTINCT o.Customer_Id) >= 100
ORDER BY orders_per_customer DESC
LIMIT 15;

-- =====================================================
-- 30. LATE DELIVERY RATE BY CITY
-- =====================================================

SELECT
    Order_City,
    COUNT(DISTINCT Order_Id) AS total_orders,
    SUM(Late_delivery_risk) AS late_orders,
    ROUND(
        SUM(Late_delivery_risk) * 100.0
        / COUNT(DISTINCT Order_Id),
        2
    ) AS late_delivery_rate_percent
FROM orders
GROUP BY Order_City
HAVING COUNT(DISTINCT Order_Id) >= 100
ORDER BY late_delivery_rate_percent DESC
LIMIT 15;


-- =====================================================
-- 31. HIGH-SALES CITIES WITH HIGH DELIVERY RISK
-- =====================================================

WITH city_sales AS (
    SELECT
        o.Order_City,
        COUNT(DISTINCT o.Order_Id) AS total_orders,
        ROUND(SUM(oi.Sales), 2) AS total_sales
    FROM orders o
    JOIN order_items oi
        ON o.Order_Id = oi.Order_Id
    GROUP BY o.Order_City
),

city_delivery AS (
    SELECT
        Order_City,
        ROUND(
            SUM(Late_delivery_risk) * 100.0
            / COUNT(DISTINCT Order_Id),
            2
        ) AS late_delivery_rate_percent
    FROM orders
    GROUP BY Order_City
)

SELECT
    cs.Order_City,
    cs.total_orders,
    cs.total_sales,
    cd.late_delivery_rate_percent
FROM city_sales cs
JOIN city_delivery cd
    ON cs.Order_City = cd.Order_City
WHERE cs.total_orders >= 300
  AND cd.late_delivery_rate_percent >= 55
ORDER BY cs.total_sales DESC;

-- =====================================================
-- 32. SHIPPING PERFORMANCE BY MARKET AND MODE
-- =====================================================

SELECT
    Market,
    Shipping_Mode,
    COUNT(DISTINCT Order_Id) AS total_orders,
    SUM(Late_delivery_risk) AS late_orders,
    ROUND(
        SUM(Late_delivery_risk) * 100.0
        / COUNT(DISTINCT Order_Id),
        2
    ) AS late_delivery_rate_percent
FROM orders
GROUP BY
    Market,
    Shipping_Mode
HAVING COUNT(DISTINCT Order_Id) >= 100
ORDER BY
    late_delivery_rate_percent DESC;

-- =====================================================
-- 33. ACTUAL VS SCHEDULED SHIPPING TIME BY MODE
-- =====================================================

SELECT
    Shipping_Mode,
    COUNT(DISTINCT Order_Id) AS total_orders,
    ROUND(AVG(Days_for_shipping_real), 2) AS avg_actual_days,
    ROUND(AVG(Days_for_shipment_scheduled), 2) AS avg_scheduled_days,
    ROUND(
        AVG(Days_for_shipping_real - Days_for_shipment_scheduled),
        2
    ) AS avg_delay_days
FROM orders
GROUP BY Shipping_Mode
ORDER BY avg_delay_days DESC;

-- =====================================================
-- 34. SHIPPING DELAY BY MARKET
-- =====================================================

SELECT
    Market,
    COUNT(DISTINCT Order_Id) AS total_orders,
    ROUND(AVG(Days_for_shipping_real), 2) AS avg_actual_days,
    ROUND(AVG(Days_for_shipment_scheduled), 2) AS avg_scheduled_days,
    ROUND(
        AVG(
            Days_for_shipping_real
            - Days_for_shipment_scheduled
        ),
        2
    ) AS avg_delay_days
FROM orders
GROUP BY Market
ORDER BY avg_delay_days DESC;

-- =====================================================
-- 35. WORST SHIPPING MODE WITHIN EACH MARKET
-- =====================================================

WITH mode_performance AS (
    SELECT
        Market,
        Shipping_Mode,
        COUNT(DISTINCT Order_Id) AS total_orders,
        SUM(Late_delivery_risk) AS late_orders,
        ROUND(
            SUM(Late_delivery_risk) * 100.0
            / COUNT(DISTINCT Order_Id),
            2
        ) AS late_delivery_rate_percent
    FROM orders
    GROUP BY
        Market,
        Shipping_Mode
),
ranked_modes AS (
    SELECT
        Market,
        Shipping_Mode,
        total_orders,
        late_orders,
        late_delivery_rate_percent,
        RANK() OVER (
            PARTITION BY Market
            ORDER BY late_delivery_rate_percent DESC
        ) AS mode_rank
    FROM mode_performance
)
SELECT
    Market,
    Shipping_Mode,
    total_orders,
    late_orders,
    late_delivery_rate_percent
FROM ranked_modes
WHERE mode_rank = 1
ORDER BY late_delivery_rate_percent DESC;

-- =====================================================
-- 36. SALES & PROFIT BY DELIVERY RISK
-- =====================================================

WITH order_financials AS (
    SELECT
        Order_Id,
        SUM(Sales) AS total_sales,
        SUM(Benefit_per_order) AS total_profit
    FROM order_items
    GROUP BY Order_Id
)
SELECT
    CASE
        WHEN o.Late_delivery_risk = 1 THEN 'Late-risk'
        ELSE 'Not late-risk'
    END AS delivery_status,
    COUNT(DISTINCT o.Order_Id) AS total_orders,
    ROUND(SUM(f.total_sales), 2) AS total_sales,
    ROUND(SUM(f.total_profit), 2) AS total_profit,
    ROUND(
        SUM(f.total_sales) / COUNT(DISTINCT o.Order_Id),
        2
    ) AS average_order_value,
    ROUND(
        SUM(f.total_profit) / COUNT(DISTINCT o.Order_Id),
        2
    ) AS profit_per_order
FROM orders o
JOIN order_financials f
    ON o.Order_Id = f.Order_Id
GROUP BY
    CASE
        WHEN o.Late_delivery_risk = 1 THEN 'Late-risk'
        ELSE 'Not late-risk'
    END
ORDER BY total_sales DESC;

-- =====================================================
-- 37. PROFIT MARGIN BY DELIVERY RISK
-- =====================================================

SELECT
    CASE
        WHEN o.Late_delivery_risk = 1 THEN 'Late-risk'
        ELSE 'Not late-risk'
    END AS delivery_status,
    COUNT(DISTINCT o.Order_Id) AS total_orders,
    ROUND(SUM(oi.Sales), 2) AS total_sales,
    ROUND(SUM(oi.Benefit_per_order), 2) AS total_profit,
    ROUND(
        SUM(oi.Benefit_per_order)
        / SUM(oi.Sales) * 100,
        2
    ) AS profit_margin_percent
FROM orders o
JOIN order_items oi
    ON o.Order_Id = oi.Order_Id
GROUP BY
    CASE
        WHEN o.Late_delivery_risk = 1 THEN 'Late-risk'
        ELSE 'Not late-risk'
    END
ORDER BY profit_margin_percent DESC;

-- =====================================================
-- 38. LOWEST-MARGIN PRODUCTS
-- =====================================================

SELECT
    p.Product_Name,
    p.Category_Name,
    ROUND(SUM(oi.Sales), 2) AS total_sales,
    ROUND(SUM(oi.Benefit_per_order), 2) AS total_profit,
    ROUND(
        SUM(oi.Benefit_per_order)
        / NULLIF(SUM(oi.Sales), 0) * 100,
        2
    ) AS profit_margin_percent
FROM products p
JOIN order_items oi
    ON p.Product_Card_Id = oi.Product_Card_Id
GROUP BY
    p.Product_Card_Id,
    p.Product_Name,
    p.Category_Name
HAVING SUM(oi.Sales) > 0
ORDER BY
    profit_margin_percent ASC
LIMIT 10;

-- =====================================================
-- 39. TOP PRODUCTS BY TOTAL PROFIT
-- =====================================================

SELECT
    p.Product_Name,
    p.Category_Name,
    ROUND(SUM(oi.Sales), 2) AS total_sales,
    ROUND(SUM(oi.Benefit_per_order), 2) AS total_profit,
    ROUND(
        SUM(oi.Benefit_per_order)
        / NULLIF(SUM(oi.Sales), 0) * 100,
        2
    ) AS profit_margin_percent
FROM products p
JOIN order_items oi
    ON p.Product_Card_Id = oi.Product_Card_Id
GROUP BY
    p.Product_Card_Id,
    p.Product_Name,
    p.Category_Name
ORDER BY total_profit DESC
LIMIT 10;