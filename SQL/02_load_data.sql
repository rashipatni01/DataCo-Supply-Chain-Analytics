-- Update the file paths below according to your local project location.


LOAD DATA LOCAL INFILE 'path/to/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    Customer_Id,
    Customer_Fname,
    Customer_Lname,
    Customer_Segment,
    Customer_City,
    Customer_State,
    Customer_Country,
    Customer_Zipcode
);

LOAD DATA LOCAL INFILE 'path/to/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    Product_Card_Id,
    Product_Name,
    Category_Name,
    Department_Name,
    Product_Price
);

LOAD DATA LOCAL INFILE 'path/to/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    Order_Id,
    Customer_Id,
    Order_Date,
    Shipping_Date,
    Shipping_Mode,
    Days_for_shipping_real,
    Days_for_shipment_scheduled,
    Delivery_Status,
    Late_delivery_risk,
    Market,
    Order_Region,
    Order_City,
    Order_State,
    Order_Country
);

LOAD DATA LOCAL INFILE 'path/to/order_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    Order_Item_Id,
    Order_Id,
    Product_Card_Id,
    Order_Item_Quantity,
    Sales,
    Order_Item_Product_Price,
    Order_Item_Discount,
    Order_Item_Discount_Rate,
    Order_Item_Total,
    Benefit_per_order,
    Order_Item_Profit_Ratio
);

