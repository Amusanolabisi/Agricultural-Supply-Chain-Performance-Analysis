CREATE DATABASE agricsupplychain;
USE agricsupplychain;
CREATE TABLE agric_supply_chain (
    record_id VARCHAR(50),
    farmer_id VARCHAR(50),
    crop VARCHAR(50),
    state VARCHAR(50),
    lga VARCHAR(100),
    harvest_date DATE,
    season VARCHAR(30),
    quantity_harvested_kg DECIMAL(12,2),
    post_harvest_loss_pct DECIMAL(5,2),
    quantity_sold_kg DECIMAL(12,2),
    farm_gate_price_per_kg DECIMAL(12,2),
    market_price_per_kg DECIMAL(12,2),
    gross_revenue_ngn DECIMAL(15,2),
    transport_mode VARCHAR(50),
    transport_cost_ngn DECIMAL(12,2),
    destination_market VARCHAR(100),
    days_to_market INT,
    storage_type VARCHAR(50),
    fertilizer_used VARCHAR(10),
    irrigation_used VARCHAR(10),
    cooperative_member VARCHAR(10)
);
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/agric_supply_chain.csv'
INTO TABLE agric_supply_chain
FIELDS TERMINATED BY ','
IGNORE 1 LINES;

-- Calculate total revenue and average post-harvest loss for each crop
-- Sort crops by highest average loss percentage
SELECT crop,
SUM(gross_revenue_ngn) AS total_revenue,
AVG(post_harvest_loss_pct) AS avg_post_harvest_loss_pct
FROM agric_supply_chain
GROUP BY crop
ORDER BY avg_post_harvest_loss_pct DESC;


-- Evaluate state performance based on revenue, average margin, and  average losses
SELECT state,
SUM(gross_revenue_ngn) AS total_revenue,
AVG(market_price_per_kg - farm_gate_price_per_kg) AS avg_margin,
AVG(post_harvest_loss_pct) AS avg_loss
FROM agric_supply_chain
GROUP BY state
ORDER BY total_revenue DESC;


-- Compare average market price and loss rate between cooperative and non-cooperative farmers
SELECT cooperative_member,
AVG(market_price_per_kg) AS avg_price,
AVG(post_harvest_loss_pct) AS avg_loss
FROM agric_supply_chain
GROUP BY cooperative_member;


-- Identify 5 most profitable crop and state combinations
SELECT crop, state,
SUM(gross_revenue_ngn - transport_cost_ngn) AS profit
FROM agric_supply_chain
GROUP BY crop, state
ORDER BY profit DESC
LIMIT 5;


-- Measure transportation efficiency by transport mode as a percentage of total revenue
SELECT transport_mode,
SUM(transport_cost_ngn) AS total_transport_cost,
SUM(gross_revenue_ngn) AS total_revenue,
ROUND((SUM(transport_cost_ngn)/ SUM(gross_revenue_ngn)*100),2) AS transport_cost_pct
FROM agric_supply_chain
GROUP BY transport_mode
ORDER BY transport_cost_pct;

-- Compare average farm-gate and market prices across months for each crop
SELECT crop,
YEAR(harvest_date) AS year,
MONTH(harvest_date) AS month,
AVG(farm_gate_price_per_kg) AS avg_farm_gate_price,
AVG(market_price_per_kg) AS avg_market_price
FROM agric_supply_chain
GROUP BY crop, YEAR(harvest_date), MONTH(harvest_date)
ORDER BY year, month;

-- Count farmers with severe post-harvest losses and determine their average revenue
SELECT COUNT(DISTINCT farmer_id) AS affected_farmers,
AVG(gross_revenue_ngn) AS avg_revenue_impact
FROM agric_supply_chain
WHERE post_harvest_loss_pct > 20;

SELECT storage_type,
AVG(post_harvest_loss_pct) AS avg_loss_pct,
AVG(gross_revenue_ngn) AS avg_revenue
FROM agric_supply_chain
GROUP BY storage_type
ORDER BY avg_loss_pct;


-- Analyze market performance using total revenue and sales volume
SELECT destination_market,
SUM(gross_revenue_ngn) AS total_revenue,
SUM(quantity_sold_kg) AS total_volume_sold
FROM agric_supply_chain
GROUP BY destination_market
ORDER BY total_revenue DESC;

-- Calculate net profit margin for each crop and rank crops from most to least profitable
SELECT crop,
ROUND((SUM(gross_revenue_ngn - transport_cost_ngn) / SUM(gross_revenue_ngn)) * 100,2) AS net_profit_margin_pct,
RANK() OVER (ORDER BY (SUM(gross_revenue_ngn - transport_cost_ngn) / SUM(gross_revenue_ngn)) DESC) AS crop_rank
FROM agric_supply_chain
GROUP BY crop;