# E-Commerce Inventory Management System

A MySQL database project for managing products, categories, suppliers, customers, orders, and inventory stock movements. This project is suitable for SQL practice, internship work, and a beginner portfolio.

## Features

- Manage product categories and suppliers
- Store product details, SKU, price, current stock, and reorder level
- Store customer details and customer orders
- Track order items and calculate line totals
- Automatically update stock and order totals when order items are inserted or deleted
- Record stock movement history
- Identify low-stock and out-of-stock products
- Search products using a stored procedure
- Add stock using a stored procedure
- View inventory, order summaries, and product sales through SQL views
- Use primary keys, foreign keys, constraints, indexes, joins, views, triggers, and stored procedures

## Repository Structure

```text
E-Commerce-Inventory-Schema/
├── README.md
├── ecommerce_inventory.sql


The screenshots folder is optional. Add screenshots from MySQL Workbench or your SQL client if you want to show the database and query outputs.

## Requirements

- MySQL 8.0 or later
- MySQL Workbench or another MySQL client

## How to Run

1. Download or clone this repository.
2. Open `ecommerce_inventory.sql` in MySQL Workbench.
3. Execute the script.
4. The script creates and selects the `ecommerce_inventory` database, creates the tables and database objects, and inserts sample data.
5. Run the example queries at the bottom of the SQL file individually to explore the results.

**Important:** The script drops and recreates project tables and views with the same names. Do not run it against an existing database containing data you need to keep.

## Database Tables

| Table | Purpose |
|---|---|
| `categories` | Product category information |
| `suppliers` | Supplier contact information |
| `products` | Product details, price, stock, and reorder level |
| `customers` | Customer contact information |
| `orders` | Customer order status and total |
| `order_items` | Products and quantities included in each order |
| `stock_movements` | History of stock additions and reductions |

## Views

- `product_inventory` — products with category, supplier, and stock status
- `low_stock_products` — products at or below their reorder level
- `order_summary` — orders with customer details
- `sales_by_product` — units sold and sales totals by product

## Stored Procedures

```sql
CALL search_products('Java');
CALL add_stock(1, 10, 'Restock from supplier');
CALL place_order_item(3, 1, 1);
```

These are example calls. The sample product and order IDs are created by the SQL script; check the database before using them after making changes.

## Example Queries

```sql
-- List inventory
SELECT * FROM product_inventory;

-- Find low-stock products
SELECT * FROM low_stock_products;

-- View customer orders
SELECT * FROM order_summary ORDER BY order_date DESC;

-- View sales by product
SELECT * FROM sales_by_product ORDER BY total_sales DESC;

-- Calculate the current inventory value
SELECT SUM(unit_price * stock_quantity) AS inventory_value
FROM products;
```

## Concepts Demonstrated

- DDL: `CREATE`, `ALTER`-style schema design, `DROP`
- DML: `INSERT`, `UPDATE`, `DELETE`
- DQL: `SELECT`, filtering, sorting, grouping, and joins
- Primary and foreign keys
- `UNIQUE`, `CHECK`, and default constraints
- Indexes and generated columns
- Views, triggers, and stored procedures
- Inventory tracking and basic sales reporting

## Possible Future Improvements

- Add a payment and shipment tracking module
- Add user roles for administrators and staff
- Create a Java or web frontend connected through JDBC
- Add reports by date range and category
- Add transaction handling and concurrency protection for stock updates
- Add automated tests for inventory and order workflows

## Author

**Sunil Behera**  
B.Tech — Computer Science Engineering

---

This project is intended for learning and demonstration. Sample customers and supplier email addresses use example domains and are not real contact details.
