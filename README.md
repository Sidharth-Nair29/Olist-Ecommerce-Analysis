# Olist-Ecommerce-Analysis

## Overview
This project analyzes the Brazilian E-Commerce Public Dataset by Olist to uncover 
actionable business insights related to sales performance, product category 
intelligence, customer behaviour, and revenue distribution. The analysis simulates 
a real-world business intelligence workflow — from raw data to a structured SQL 
analysis layer to an executive dashboard.

---

## Business Problem
Olist is a Brazilian e-commerce platform that connects merchants to customers across 
multiple marketplaces. Despite strong order volumes, the business faces key challenges:

- **Retention problem** — the vast majority of customers make only one purchase, 
  making the business heavily dependent on continuous new customer acquisition.
- **Revenue concentration** — a small proportion of customers drive a 
  disproportionate share of total revenue, creating significant business risk.
- **Product inefficiency** — not all product categories contribute meaningfully 
  to revenue, with many operating at low volume and low value simultaneously.

The goal of this project is to quantify these problems, segment customers and 
products systematically, and generate data-driven strategic recommendations.

---

## Dataset
- **Source**: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- **Tables used**: `orders`, `order_items`, `customers`, `products`, `payments`
- **Period covered**: September 2016 — August 2018
- **Volume**: ~100,000 orders, ~96,000 unique customers

---

## Tools Used
| Tool | Purpose |
|------|---------|
| Python (Pandas) | Data cleaning and preprocessing |
| MySQL Workbench | Exploratory and analytical SQL queries |
| Power BI | Interactive dashboard and data visualization |

---

## Methodology

### 1. Data Cleaning (Python / Pandas)
- Handled missing values in product category names
- Removed duplicate records
- Standardised data types and date formats
- Validated referential integrity across tables before loading into MySQL

### 2. SQL Analysis (MySQL)
Structured into five analytical sections:

- **Sales Overview** — KPIs including total revenue, delivery rate, AOV, and 
  monthly trend analysis
- **Product Analysis** — Multi-dimensional category segmentation using NTILE 
  window functions across revenue, volume, and average item value, producing a 
  9-class segmentation matrix
- **Customer Analysis** — One-time vs repeat customer classification with revenue 
  contribution comparison
- **Revenue Distribution** — NTILE(10) customer segmentation with cumulative 
  revenue analysis revealing Pareto-like concentration
- **Payment Analysis** — Payment method breakdown, installment behaviour 
  correlation, and revenue integrity cross-check between two tables

### 3. Dashboard (Power BI)
4-page interactive dashboard built on top of pre-aggregated SQL query results:
- Sales Overview
- Product Category Segmentation and Analysis
- Customer Base Analysis
- Revenue Distribution

---

## Key Findings

**Sales**
- Total revenue of R$15.42M across 96K delivered orders (Sep 2016 — Aug 2018)
- 97.02% delivery rate indicating strong operational efficiency
- Peak revenue in November 2017 (R$1.15M) driven by Black Friday demand
- Consistent growth through 2017, plateauing in mid-2018

**Product**
- `beleza_saude` (health & beauty) is the highest revenue category at R$14.12M
- 5 categories classified as Star Category — high revenue, volume, and value simultaneously
- Several Premium Niche categories show high average value but low volume — 
  indicating untapped growth potential through targeted marketing

**Customer**
- 97% of customers are one-time buyers — severe retention problem
- Repeat customers generate 2x more revenue per customer than one-time buyers
- Increasing repeat rate from 3% to 10% could significantly boost revenue without 
  additional acquisition spend

**Revenue Distribution**
- Top 10% of customers (VIP) contribute ~38% of total revenue
- Top 30% of customers generate ~64% of revenue
- Average order value gap between top and bottom segments: R$601 vs R$31
- Average orders ≈ 1 across all segments — retention problem confirmed across 
  every value tier, not just low-value customers

**Payment**
- Credit card dominates at 76.94% of orders with avg 3.5 installments
- Higher installment counts strongly correlate with higher order values 
  (1 installment = R$95 vs 10 installments = R$410)
- R$4.36M discrepancy identified between payment table totals and orderitems 
  revenue — investigated and attributed to voucher and split payment rows

---

## Strategic Recommendations
- **Loyalty programs** to convert one-time buyers into repeat customers
- **Retargeting campaigns** focused on customers with single high-value purchases
- **Upselling strategies** targeting mid-value customer segments (largest volume, 
  most room to grow)
- **Protect VIP customers** — losing the top 10% would directly impact 38% of revenue
- **Targeted installment plans** (4–6 installments) for mid-value product categories 
  to unlock higher spend from price-sensitive customers
- **Monitor voucher usage** — while driving orders, vouchers reduce net revenue

---

## Dashboard Preview
![Sales Overview]( <img width="508" height="288" alt="image" src="https://github.com/user-attachments/assets/b1335987-8885-48cb-9d43-5f7faca1ec74" /> )
![Product Analysis](<img width="506" height="286" alt="image" src="https://github.com/user-attachments/assets/16750395-5d10-4db8-ae49-694a18bd8e86" />)
![Customer Analysis](<img width="506" height="286" alt="image" src="https://github.com/user-attachments/assets/cc82d017-ad34-4054-a653-18241b2014b3" />)
![Revenue Distribution](<img width="509" height="286" alt="image" src="https://github.com/user-attachments/assets/8366e1dd-3da4-4d67-9109-2fc41fb5d25f" />)
