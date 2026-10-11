-- E-Commerce Inventory Management System
-- MySQL 8.0+
CREATE DATABASE IF NOT EXISTS ecommerce_inventory;
USE ecommerce_inventory;

SET FOREIGN_KEY_CHECKS=0;
DROP VIEW IF EXISTS low_stock_products;
DROP VIEW IF EXISTS product_inventory;
DROP VIEW IF EXISTS order_summary;
DROP VIEW IF EXISTS sales_by_product;
DROP TRIGGER IF EXISTS trg_order_item_after_insert;
DROP TRIGGER IF EXISTS trg_order_item_after_delete;
DROP PROCEDURE IF EXISTS add_stock;
DROP PROCEDURE IF EXISTS place_order_item;
DROP PROCEDURE IF EXISTS search_products;
DROP TABLE IF EXISTS stock_movements;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS categories;
SET FOREIGN_KEY_CHECKS=1;

CREATE TABLE categories (
 category_id INT AUTO_INCREMENT PRIMARY KEY,
 category_name VARCHAR(100) NOT NULL UNIQUE,
 description VARCHAR(255)
);

CREATE TABLE suppliers (
 supplier_id INT AUTO_INCREMENT PRIMARY KEY,
 supplier_name VARCHAR(150) NOT NULL,
 contact_person VARCHAR(100),
 email VARCHAR(150) UNIQUE,
 phone VARCHAR(20),
 city VARCHAR(100),
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
 product_id INT AUTO_INCREMENT PRIMARY KEY,
 product_name VARCHAR(150) NOT NULL,
 sku VARCHAR(50) NOT NULL UNIQUE,
 category_id INT NOT NULL,
 supplier_id INT NULL,
 unit_price DECIMAL(10,2) NOT NULL,
 stock_quantity INT NOT NULL DEFAULT 0,
 reorder_level INT NOT NULL DEFAULT 5,
 is_active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 CONSTRAINT chk_product_price CHECK (unit_price >= 0),
 CONSTRAINT chk_product_stock CHECK (stock_quantity >= 0),
 CONSTRAINT chk_reorder_level CHECK (reorder_level >= 0),
 FOREIGN KEY (category_id) REFERENCES categories(category_id),
 FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) ON DELETE SET NULL
);

CREATE TABLE customers (
 customer_id INT AUTO_INCREMENT PRIMARY KEY,
 first_name VARCHAR(100) NOT NULL,
 last_name VARCHAR(100) NOT NULL,
 email VARCHAR(150) NOT NULL UNIQUE,
 phone VARCHAR(20),
 address VARCHAR(255),
 city VARCHAR(100),
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
 order_id INT AUTO_INCREMENT PRIMARY KEY,
 customer_id INT NOT NULL,
 order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 order_status ENUM('Pending','Processing','Shipped','Delivered','Cancelled')
   NOT NULL DEFAULT 'Pending',
 total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
 CONSTRAINT chk_order_total CHECK (total_amount >= 0),
 FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
 order_item_id INT AUTO_INCREMENT PRIMARY KEY,
 order_id INT NOT NULL,
 product_id INT NOT NULL,
 quantity INT NOT NULL,
 unit_price DECIMAL(10,2) NOT NULL,
 line_total DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
 CONSTRAINT chk_item_quantity CHECK (quantity > 0),
 CONSTRAINT chk_item_price CHECK (unit_price >= 0),
 FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
 FOREIGN KEY (product_id) REFERENCES products(product_id),
 UNIQUE KEY uq_order_product (order_id, product_id)
);

CREATE TABLE stock_movements (
 movement_id INT AUTO_INCREMENT PRIMARY KEY,
 product_id INT NOT NULL,
 quantity_change INT NOT NULL,
 movement_type ENUM('Stock In','Sale','Return','Adjustment') NOT NULL,
 notes VARCHAR(255),
 movement_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (product_id) REFERENCES products(product_id)
);

INSERT INTO categories(category_name,description) VALUES
('Electronics','Electronic devices and accessories'),
('Clothing','Clothing and fashion products'),
('Books','Printed books and study materials'),
('Home & Kitchen','Home and kitchen products');

INSERT INTO suppliers(supplier_name,contact_person,email,phone,city) VALUES
('Tech World Supplies','Ravi Kumar','contact@techworld.example','9876501001','Hyderabad'),
('Fashion Hub','Priya Sharma','sales@fashionhub.example','9876501002','Bengaluru'),
('Book Point Distributors','Arun Das','orders@bookpoint.example','9876501003','Chennai');

INSERT INTO products(product_name,sku,category_id,supplier_id,unit_price,stock_quantity,reorder_level) VALUES
('Wireless Mouse','ELEC-001',1,1,599.00,40,10),
('USB Keyboard','ELEC-002',1,1,899.00,25,8),
('Bluetooth Headphones','ELEC-003',1,1,1499.00,6,8),
('Cotton T-Shirt','CLTH-001',2,2,499.00,50,12),
('Denim Jeans','CLTH-002',2,2,1299.00,4,10),
('SQL for Beginners','BOOK-001',3,3,350.00,30,5),
('Java Programming Guide','BOOK-002',3,3,650.00,15,5),
('Water Bottle','HOME-001',4,NULL,199.00,3,6);

INSERT INTO customers(first_name,last_name,email,phone,address,city) VALUES
('Amit','Verma','amit.verma@example.com','9000000001','12 Lake Road','Hyderabad'),
('Sneha','Reddy','sneha.reddy@example.com','9000000002','24 Park Street','Vijayawada'),
('Rahul','Patel','rahul.patel@example.com','9000000003','8 Market Road','Bengaluru');

INSERT INTO orders(customer_id,order_date,order_status) VALUES
(1,'2026-09-10 10:30:00','Delivered'),
(2,'2026-09-15 14:00:00','Processing'),
(3,'2026-09-20 16:15:00','Pending');

DELIMITER $$
CREATE TRIGGER trg_order_item_after_insert
AFTER INSERT ON order_items FOR EACH ROW
BEGIN
 UPDATE products SET stock_quantity=stock_quantity-NEW.quantity
 WHERE product_id=NEW.product_id;
 UPDATE orders SET total_amount=total_amount+NEW.line_total
 WHERE order_id=NEW.order_id;
 INSERT INTO stock_movements(product_id,quantity_change,movement_type,notes)
 VALUES(NEW.product_id,-NEW.quantity,'Sale',CONCAT('Order ID: ',NEW.order_id));
END$$

CREATE TRIGGER trg_order_item_after_delete
AFTER DELETE ON order_items FOR EACH ROW
BEGIN
 UPDATE products SET stock_quantity=stock_quantity+OLD.quantity
 WHERE product_id=OLD.product_id;
 UPDATE orders SET total_amount=GREATEST(0,total_amount-OLD.line_total)
 WHERE order_id=OLD.order_id;
 INSERT INTO stock_movements(product_id,quantity_change,movement_type,notes)
 VALUES(OLD.product_id,OLD.quantity,'Return',CONCAT('Removed from order ID: ',OLD.order_id));
END$$
DELIMITER ;

INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES
(1,1,2,599.00),(1,6,1,350.00),(2,2,1,899.00),(2,4,2,499.00),(3,7,1,650.00);

CREATE INDEX idx_products_name ON products(product_name);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_orders_customer_date ON orders(customer_id,order_date);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_stock_movements_date ON stock_movements(movement_date);

CREATE VIEW product_inventory AS
SELECT p.product_id,p.product_name,p.sku,c.category_name,s.supplier_name,
 p.unit_price,p.stock_quantity,p.reorder_level,
 CASE WHEN p.stock_quantity=0 THEN 'Out of Stock'
      WHEN p.stock_quantity<=p.reorder_level THEN 'Low Stock'
      ELSE 'In Stock' END AS stock_status
FROM products p JOIN categories c ON p.category_id=c.category_id
LEFT JOIN suppliers s ON p.supplier_id=s.supplier_id
WHERE p.is_active=TRUE;

CREATE VIEW low_stock_products AS
SELECT * FROM product_inventory WHERE stock_quantity<=reorder_level;

CREATE VIEW order_summary AS
SELECT o.order_id,o.order_date,o.order_status,c.customer_id,
 CONCAT(c.first_name,' ',c.last_name) AS customer_name,c.email,o.total_amount
FROM orders o JOIN customers c ON o.customer_id=c.customer_id;

CREATE VIEW sales_by_product AS
SELECT p.product_id,p.product_name,
 COALESCE(SUM(CASE WHEN o.order_status<>'Cancelled' THEN oi.quantity ELSE 0 END),0) AS units_sold,
 COALESCE(SUM(CASE WHEN o.order_status<>'Cancelled' THEN oi.line_total ELSE 0 END),0.00) AS total_sales
FROM products p
LEFT JOIN order_items oi ON p.product_id=oi.product_id
LEFT JOIN orders o ON oi.order_id=o.order_id
GROUP BY p.product_id,p.product_name;

DELIMITER $$
CREATE PROCEDURE add_stock(IN p_product_id INT, IN p_quantity INT, IN p_notes VARCHAR(255))
BEGIN
 IF p_quantity<=0 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Quantity must be greater than zero';
 ELSEIF NOT EXISTS(SELECT 1 FROM products WHERE product_id=p_product_id) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Product does not exist';
 ELSE
  UPDATE products SET stock_quantity=stock_quantity+p_quantity WHERE product_id=p_product_id;
  INSERT INTO stock_movements(product_id,quantity_change,movement_type,notes)
  VALUES(p_product_id,p_quantity,'Stock In',p_notes);
 END IF;
END$$

CREATE PROCEDURE place_order_item(IN p_order_id INT, IN p_product_id INT, IN p_quantity INT)
BEGIN
 DECLARE v_price DECIMAL(10,2);
 DECLARE v_stock INT DEFAULT NULL;
 DECLARE v_status VARCHAR(20) DEFAULT NULL;

 IF p_quantity<=0 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Quantity must be greater than zero';
 END IF;

 SELECT unit_price,stock_quantity INTO v_price,v_stock
 FROM products WHERE product_id=p_product_id AND is_active=TRUE;

 IF v_stock IS NULL THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Product not found or inactive';
 END IF;
 IF v_stock<p_quantity THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Not enough stock available';
 END IF;

 SELECT order_status INTO v_status FROM orders WHERE order_id=p_order_id;
 IF v_status IS NULL THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Order not found';
 ELSEIF v_status='Cancelled' THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Cannot add items to a cancelled order';
 END IF;

 INSERT INTO order_items(order_id,product_id,quantity,unit_price)
 VALUES(p_order_id,p_product_id,p_quantity,v_price);
END$$

CREATE PROCEDURE search_products(IN p_keyword VARCHAR(150))
BEGIN
 SELECT product_id,product_name,sku,unit_price,stock_quantity
 FROM products
 WHERE is_active=TRUE AND product_name LIKE CONCAT('%',p_keyword,'%')
 ORDER BY product_name;
END$$
DELIMITER ;

-- Example queries: run individually after importing this script.
-- SELECT * FROM product_inventory;
-- SELECT * FROM low_stock_products;
-- SELECT * FROM order_summary ORDER BY order_date DESC;
-- SELECT * FROM sales_by_product ORDER BY total_sales DESC;
-- SELECT SUM(unit_price*stock_quantity) AS inventory_value FROM products;
-- SELECT c.category_name,COUNT(p.product_id) AS product_count
-- FROM categories c LEFT JOIN products p ON c.category_id=p.category_id
-- GROUP BY c.category_id,c.category_name;
-- SELECT * FROM stock_movements ORDER BY movement_date DESC;
-- CALL search_products('Java');
-- CALL add_stock(1,10,'Restock from supplier');
-- CALL place_order_item(3,1,1);
