CREATE DATABASE dataco_supply_chain;

USE dataco_supply_chain;

CREATE TABLE customers (
    Customer_Id INT PRIMARY KEY,
    Customer_Fname VARCHAR(100),
    Customer_Lname VARCHAR(100),
    Customer_Segment VARCHAR(50),
    Customer_City VARCHAR(100),
    Customer_State VARCHAR(100),
    Customer_Country VARCHAR(100),
    Customer_Zipcode VARCHAR(20)
);

CREATE TABLE products (
    Product_Card_Id INT PRIMARY KEY,
    Product_Name VARCHAR(255),
    Category_Name VARCHAR(100),
    Department_Name VARCHAR(100),
    Product_Price DECIMAL(10,2)
);

CREATE TABLE orders (
    Order_Id INT PRIMARY KEY,
    Customer_Id INT,
    Order_Date DATETIME,
    Shipping_Date DATETIME,
    Shipping_Mode VARCHAR(50),
    Days_for_shipping_real INT,
    Days_for_shipment_scheduled INT,
    Delivery_Status VARCHAR(50),
    Late_delivery_risk TINYINT,
    Market VARCHAR(50),
    Order_Region VARCHAR(100),
    Order_City VARCHAR(100),
    Order_State VARCHAR(100),
    Order_Country VARCHAR(100),

    FOREIGN KEY (Customer_Id)
        REFERENCES customers(Customer_Id)
);

CREATE TABLE order_items (
    Order_Item_Id INT PRIMARY KEY,
    Order_Id INT,
    Product_Card_Id INT,

    Order_Item_Quantity INT,
    Sales DECIMAL(12,2),
    Order_Item_Product_Price DECIMAL(10,2),
    Order_Item_Discount DECIMAL(12,2),
    Order_Item_Discount_Rate DECIMAL(6,4),
    Order_Item_Total DECIMAL(12,2),

    Benefit_per_order DECIMAL(12,2),
    Order_Item_Profit_Ratio DECIMAL(8,4),

    FOREIGN KEY (Order_Id)
        REFERENCES orders(Order_Id),

    FOREIGN KEY (Product_Card_Id)
        REFERENCES products(Product_Card_Id)
);