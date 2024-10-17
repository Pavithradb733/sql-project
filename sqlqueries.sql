CREATE DATABASE IF NOT EXISTS WALMART_SALES;

CREATE TABLE if not exists SALES(
    invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    tax_pct FLOAT NOT NULL,
    total DECIMAL(12, 4) NOT NULL,
    date DATETIME NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_pct FLOAT(11,9),
    gross_income DECIMAL(12, 4),
    rating FLOAT
);
select * from sales;

-- --------------------------------------------------------------------------------------------------------
-- ------------------------------Feature Engineering------------------------------------------------------
SELECT CASE WHEN TIME(TIME) between '06:00:00' AND '12:00:00' THEN 'MORNING'
		    WHEN TIME(TIME) BETWEEN '12:00:00' AND '17:00:00' THEN 'AFTERNOON'
            WHEN TIME(TIME) BETWEEN '17:00:00' AND '21:00:00' THEN 'EVENING'
            ELSE 'NIGHT'
            END AS 'TIME_OF_DATE'
            FROM SALES;
ALTER TABLE SALES
ADD COLUMN TIME_OF_DAY VARCHAR(20);

UPDATE SALES
SET TIME_OF_DAY = (CASE WHEN TIME(TIME) between '06:00:00' AND '12:00:00' THEN 'MORNING'
		    WHEN TIME(TIME) BETWEEN '12:00:00' AND '17:00:00' THEN 'AFTERNOON'
            WHEN TIME(TIME) BETWEEN '17:00:00' AND '21:00:00' THEN 'EVENING'
            ELSE 'NIGHT'
            END);
SET SQL_SAFE_UPDATES = 0;

-- DAYNAME-----------------------------
SELECT DATE,LEFT(dayname(DATE),3) FROM SALES;
ALTER TABLE SALES
ADD COLUMN DAY_NAME VARCHAR(10);

UPDATE SALES
SET DAY_NAME = LEFT(dayname(DATE),3);
-- MONTHNAME-------------------------------------
SELECT date,left(monthname(DATE),3) FROM SALES;
ALTER TABLE SALES
ADD COLUMN MONTH_NAME VARCHAR(10);

UPDATE SALES
SET MONTH_NAME = left(monthname(DATE),3);

-- ----------------------------------------------------------------------------------------------
-- EXPLORATORY DATA ANALYSIS--------------------------------------------------------------------
-- GENERIC QUESTIONS-------
-- How many unique cities does the data have?
SELECT COUNT(DISTINCT CITY) FROM SALES;

-- In which city is each branch?
SELECT DISTINCT BRANCH,CITY FROM SALES;

-- PRODUCT-----------------------
-- How many unique product lines does the data have?
SELECT COUNT(DISTINCT PRODUCT_LINE) FROM SALES;

-- What is the most common payment method?
SELECT PAYMENT,COUNT(PAYMENT) FROM SALES GROUP BY PAYMENT ORDER BY COUNT(PAYMENT) DESC LIMIT 1;

-- What is the most selling product line?
SELECT PRODUCT_LINE ,SUM(QUANTITY) FROM SALES GROUP BY PRODUCT_LINE ORDER BY SUM(QUANTITY) DESC;

-- What is the total revenue by month?
SELECT MONTH(DATE),SUM(TOTAL) FROM SALES GROUP BY MONTH(DATE);

-- What month had the largest COGS?
SELECT MONTH_NAME,SUM(COGS) FROM SALES GROUP BY MONTH_NAME ORDER BY SUM(COGS) DESC;

-- What product line had the largest revenue?
SELECT PRODUCT_LINE ,SUM(TOTAL) FROM SALES GROUP BY PRODUCT_LINE ORDER BY SUM(TOTAL) DESC;

-- What is the city with the largest revenue?
SELECT CITY ,SUM(TOTAL) FROM SALES GROUP BY CITY ORDER BY SUM(TOTAL) DESC;

-- What product line had the largest VAT?
SELECT PRODUCT_LINE,MAX(TAX_PCT) FROM SALES GROUP BY PRODUCT_LINE ORDER BY MAX(TAX_PCT) DESC;

-- Fetch each product line and add a column to those product line showing 
-- "Good", "Bad". Good if its greater than average sales
SELECT AVG(QUANTITY) FROM SALES;

WITH CTC AS(
SELECT PRODUCT_LINE,SUM(QUANTITY)/COUNT(QUANTITY) AS AVERAGE FROM SALES GROUP BY PRODUCT_LINE)
SELECT PRODUCT_LINE,AVERAGE,CASE WHEN AVERAGE>=(SELECT AVG(QUANTITY) FROM SALES) THEN 'GOOD'
						WHEN AVERAGE<(SELECT AVG(QUANTITY) FROM SALES) THEN 'BAD'
					END AS STATUS 
 FROM CTC;
 
 -- Which branch sold more products than average product sold?
 WITH CTC AS(
SELECT BRANCH,SUM(QUANTITY)/COUNT(QUANTITY) AS AVERAGE FROM SALES GROUP BY BRANCH)
SELECT BRANCH FROM CTC WHERE AVERAGE>(SELECT AVG(QUANTITY) FROM SALES);

-- What is the most common product line by gender?
WITH CTC AS(
SELECT PRODUCT_LINE,COUNT(PRODUCT_LINE) AS CNT,GENDER FROM SALES GROUP BY GENDER,PRODUCT_LINE 
ORDER BY CNT DESC),
CTC1 AS(
SELECT CTC.* ,RANK() OVER(PARTITION BY GENDER ORDER BY CNT DESC) AS RNK FROM CTC)
SELECT PRODUCT_LINE,GENDER FROM CTC1 WHERE RNK=1;

-- What is the average rating of each product line?
SELECT PRODUCT_LINE,ROUND(AVG(RATING),2) AS AVRG FROM SALES GROUP BY PRODUCT_LINE ORDER BY AVRG DESC;

-- ---------------------------------------------------------------------------------------------------
-- ---------------------------SALES--------------------------------------------------
-- Number of sales made in each time of the day per weekday?
WITH CTC AS(
SELECT DAY_NAME,TIME_OF_DAY,SUM(QUANTITY) AS QTY FROM SALES GROUP BY TIME_OF_DAY,DAY_NAME 
ORDER BY QTY DESC)
SELECT DAY_NAME,
SUM(CASE WHEN TIME_OF_DAY = 'MORNING' THEN QTY END) AS 'MORNING',
SUM(CASE WHEN TIME_OF_DAY = 'AFTERNOON' THEN QTY END) AS 'AFTERNOON',
SUM(CASE WHEN TIME_OF_DAY = 'EVENING' THEN QTY END) AS 'EVENING'
FROM CTC GROUP BY DAY_NAME;

-- Which of the customer types brings the most revenue?
SELECT CUSTOMER_TYPE,SUM(TOTAL) AS TOTAL FROM SALES GROUP BY CUSTOMER_TYPE ORDER BY TOTAL DESC;

-- Which city has the largest tax percent/ VAT (Value Added Tax)?
SELECT CITY,SUM(TAX_PCT) AS TOTAL FROM SALES GROUP BY CITY ORDER BY TOTAL DESC;

-- Which customer type pays the most in VAT?
SELECT CUSTOMER_TYPE,SUM(TAX_PCT) AS TOTAL FROM SALES GROUP BY CUSTOMER_TYPE ORDER BY TOTAL DESC;

-- ---------------------------------------------------------------------------------------
-- ------------------------------CUSTOMER--------------------------------------
-- How many unique customer types does the data have?
SELECT COUNT(DISTINCT CUSTOMER_TYPE) FROM SALES;

-- How many unique payment methods does the data have?
SELECT COUNT(DISTINCT PAYMENT) FROM SALES;

-- What is the most common customer type?
SELECT CUSTOMER_TYPE,COUNT(*) AS CNT  FROM SALES GROUP BY CUSTOMER_TYPE;

-- Which customer type buys the most?
SELECT CUSTOMER_TYPE,SUM(TOTAL) AS CNT  FROM SALES GROUP BY CUSTOMER_TYPE ORDER BY CNT DESC;

-- What is the gender of most of the customers?
SELECT GENDER,COUNT(*) FROM SALES GROUP BY GENDER;

-- What is the gender distribution per branch?
WITH CTC AS(
SELECT BRANCH,GENDER,COUNT(GENDER) AS CNT FROM SALES GROUP BY BRANCH,GENDER)
SELECT BRANCH,
SUM(CASE WHEN GENDER = 'MALE' THEN CNT END) AS 'MALE',
SUM(CASE WHEN GENDER = 'FEMALE' THEN CNT END) AS 'FEMALE'
FROM CTC GROUP BY BRANCH;

-- Which time of the day do customers give most ratings?
SELECT TIME_OF_DAY,AVG(RATING) AS RATING FROM SALES GROUP BY TIME_OF_DAY ORDER BY RATING DESC;

-- Which time of the day do customers give most ratings per branch?
WITH CTC AS(
SELECT BRANCH,TIME_OF_DAY,AVG(RATING) AS RATING FROM SALES GROUP BY BRANCH,TIME_OF_DAY 
ORDER BY RATING DESC)
SELECT BRANCH,
avg(CASE WHEN TIME_OF_DAY = 'MORNING' THEN RATING END) AS 'MORNING',
avg(CASE WHEN TIME_OF_DAY = 'AFTERNOON' THEN RATING END) AS 'AFTERNOON',
avg(CASE WHEN TIME_OF_DAY = 'EVENING' THEN RATING END) AS 'EVENING'
FROM CTC GROUP BY BRANCH;

-- Which day fo the week has the best avg ratings?
SELECT DAY_NAME,AVG(RATING) AS RATING FROM SALES GROUP BY DAY_NAME ORDER BY RATING DESC;

-- Which day of the week has the best average ratings per branch?
WITH CTC AS(
SELECT BRANCH,DAY_NAME,AVG(RATING) AS RATING FROM SALES GROUP BY BRANCH,DAY_NAME ORDER BY RATING DESC)
SELECT DAY_NAME,
avg(CASE WHEN BRANCH='A' THEN RATING END) AS 'A',
avg(CASE WHEN BRANCH='B' THEN RATING END) AS 'B',
avg(CASE WHEN BRANCH='C' THEN RATING END) AS 'C'
FROM CTC GROUP BY DAY_NAME;



SELECT * FROM SALES;

