# 📦 E-Commerce Revenue & Customer Behavior Analytics (SQL Project)

This project performs an end-to-end analysis of an e-commerce business using **MySQL**.  
It explores revenue trends, customer behavior, retention, funnels, segmentation, and product affinity using the **Brazilian E-Commerce Public Dataset by Olist** (or a reduced clean version).

---

## 🎯 1. Business Objectives

The company wants to answer:

1. **How much revenue are we generating?**
2. **Which customer states contribute the most orders and revenue?**
3. **Which product categories generate the most revenue?**
4. **How effectively do customers move through our conversion funnel?**
5. **What is the retention behavior of customers over time?**
6. **What is the lifetime value (LTV) of our customers?**
7. **Which customer segments exist (RFM segmentation)?**
8. **Which products tend to be purchased together (product affinity)?**

---

## 📂 2. Dataset Description

The project uses the following tables:

| Table | Description |
|-------|-------------|
| customers | Customer demographics (city, state) |
| sellers | Seller information |
| products | Product catalog |
| orders | Order metadata |
| order_items | Order item-level price details |
| payments | Payment method & amount |
| reviews | Review scores |
| geolocation | Latitude/longitude details |

---

## 🛠 3. Tech Stack  
- **MySQL 8+**  
- **MySQL Workbench / CLI**  
- **SQL Views, Window Functions, CTEs, RFM Analysis**  

---

## 📘 4. How to Run the Project

1. Create the database:

```sql
CREATE DATABASE IF NOT EXISTS olist;
USE olist;
```


Import CSV files using MySQL Table Import Wizard
(customers, orders, order_items, products, sellers, payments, reviews, geolocation)

Run all queries from olist_analysis.sql.

## 📊 5. Project Sections & Insights
#### 5.1 Basic Exploration
      Total rows per table
      Orders over time
      Customer distribution by state
      Total revenue from delivered orders
 Key Insight: SP and RJ are the strongest markets.
#### 5.2 Sales & Revenue Analysis
      Monthly revenue trends
      Revenue by customer state
      Revenue by product category
      Repeat vs one-time customers
  Key Insight: ~25–35% customers are repeat buyers.

#### 5.3 Conversion Funnel
      Stages derived from existing relational activity:
      Total customers
      Customers who reach “add to cart” (appear in order_items)
      Customers who place orders
      Delivered orders
  Key Insight: The funnel narrows at the “order placed → delivered” stage.

#### 5.4 Customer Cohort Analysis
      Based on first delivered order month
      Measures retention across months
  Key Insight: Retention declines after 1st month, common in e-commerce.

#### 5.5 Customer Lifetime Value (LTV)
      Total spend per customer
      Average LTV by state
  Key Insight: Certain states exhibit 20–40% higher LTV.

#### 5.6 RFM Segmentation
      Uses Recency (R), Frequency (F), Monetary (M) window ranking
      Classifies customers into:
      Champions, Loyal, At Risk, Lost, Others
  Key Insight: Champions make up a small but highly valuable segment.

#### 5.7 Product Affinity (Market Basket Analysis)
      Identifies product pairs frequently purchased together
      Useful for recommendations and bundling
  Key Insight: Electronics + accessories frequently co-occur.

## 🧩 6. Folder Structure
``` sql ecommerce-sql-analysis/
│
├── README.md
├── olist_analysis.sql
│
└── data/
    ├── customers.csv
    ├── sellers.csv
    ├── products.csv
    ├── orders.csv
    ├── order_items.csv
    ├── payments.csv
    ├── reviews.csv
    └── geolocation.csv
```
## 🏁 7. Conclusion

#### This project provides a complete analytical view of an e-commerce business including:
      Revenue analysis
      Customer retention patterns
      LTV estimation
      Segmentation
      Conversion funnel
      Product co-purchase system

It demonstrates strong SQL proficiency suitable for data analyst/data science portfolios.

## 📧 Contact

If you liked the project or want to collaborate, feel free to connect!


