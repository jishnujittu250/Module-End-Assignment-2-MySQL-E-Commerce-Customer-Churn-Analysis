USE ecomm;

-- =========================================================
-- E-COMMERCE CUSTOMER CHURN ANALYSIS
-- Assignment 2 - SQL Answers
-- Run the source database script first, then run this file.
-- =========================================================

-- 1. DATA CLEANING
-- Impute missing values with rounded mean.

SELECT ROUND(AVG(WarehouseToHome)) INTO @mean_WarehouseToHome
FROM customer_churn;
UPDATE customer_churn
SET WarehouseToHome = @mean_WarehouseToHome
WHERE WarehouseToHome IS NULL;

SELECT ROUND(AVG(HourSpendOnApp)) INTO @mean_HourSpendOnApp
FROM customer_churn;
UPDATE customer_churn
SET HourSpendOnApp = @mean_HourSpendOnApp
WHERE HourSpendOnApp IS NULL;

SELECT ROUND(AVG(OrderAmountHikeFromlastYear)) INTO @mean_OrderAmountHike
FROM customer_churn;
UPDATE customer_churn
SET OrderAmountHikeFromlastYear = @mean_OrderAmountHike
WHERE OrderAmountHikeFromlastYear IS NULL;

SELECT ROUND(AVG(DaySinceLastOrder)) INTO @mean_DaySinceLastOrder
FROM customer_churn;
UPDATE customer_churn
SET DaySinceLastOrder = @mean_DaySinceLastOrder
WHERE DaySinceLastOrder IS NULL;


-- Impute missing values with mode.

SELECT Tenure INTO @mode_Tenure
FROM customer_churn
WHERE Tenure IS NOT NULL
GROUP BY Tenure
ORDER BY COUNT(*) DESC, Tenure
LIMIT 1;
UPDATE customer_churn
SET Tenure = @mode_Tenure
WHERE Tenure IS NULL;

SELECT CouponUsed INTO @mode_CouponUsed
FROM customer_churn
WHERE CouponUsed IS NOT NULL
GROUP BY CouponUsed
ORDER BY COUNT(*) DESC, CouponUsed
LIMIT 1;
UPDATE customer_churn
SET CouponUsed = @mode_CouponUsed
WHERE CouponUsed IS NULL;

SELECT OrderCount INTO @mode_OrderCount
FROM customer_churn
WHERE OrderCount IS NOT NULL
GROUP BY OrderCount
ORDER BY COUNT(*) DESC, OrderCount
LIMIT 1;
UPDATE customer_churn
SET OrderCount = @mode_OrderCount
WHERE OrderCount IS NULL;


-- Remove WarehouseToHome outliers greater than 100.
DELETE FROM customer_churn
WHERE WarehouseToHome > 100;


-- Standardize inconsistent values.
UPDATE customer_churn
SET PreferredLoginDevice = 'Mobile Phone'
WHERE PreferredLoginDevice = 'Phone';

UPDATE customer_churn
SET PreferedOrderCat = 'Mobile Phone'
WHERE PreferedOrderCat = 'Mobile';

UPDATE customer_churn
SET PreferredPaymentMode = 'Cash on Delivery'
WHERE PreferredPaymentMode = 'COD';

UPDATE customer_churn
SET PreferredPaymentMode = 'Credit Card'
WHERE PreferredPaymentMode = 'CC';


-- 2. DATA TRANSFORMATION
ALTER TABLE customer_churn
CHANGE COLUMN PreferedOrderCat PreferredOrderCat VARCHAR(20);

ALTER TABLE customer_churn
CHANGE COLUMN HourSpendOnApp HoursSpentOnApp INT;

ALTER TABLE customer_churn
ADD COLUMN ComplaintReceived VARCHAR(3),
ADD COLUMN ChurnStatus VARCHAR(10);

UPDATE customer_churn
SET ComplaintReceived =
    CASE WHEN Complain = 1 THEN 'Yes' ELSE 'No' END,
    ChurnStatus =
    CASE WHEN Churn = 1 THEN 'Churned' ELSE 'Active' END;

ALTER TABLE customer_churn
DROP COLUMN Churn,
DROP COLUMN Complain;


-- 3. DATA EXPLORATION AND ANALYSIS

-- 3.1 Count of churned and active customers.
SELECT ChurnStatus, COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY ChurnStatus;


-- 3.2 Average tenure and total cashback of churned customers.
SELECT
    AVG(Tenure) AS AverageTenure,
    SUM(CashbackAmount) AS TotalCashbackAmount
FROM customer_churn
WHERE ChurnStatus = 'Churned';


-- 3.3 Percentage of churned customers who complained.
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN ComplaintReceived = 'Yes' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS PercentageOfChurnedCustomersWhoComplained
FROM customer_churn
WHERE ChurnStatus = 'Churned';


-- 3.4 City tier with the highest number of churned customers
--     whose preferred order category is Laptop & Accessory.
SELECT CityTier, COUNT(*) AS ChurnedCustomerCount
FROM customer_churn
WHERE ChurnStatus = 'Churned'
  AND PreferredOrderCat = 'Laptop & Accessory'
GROUP BY CityTier
ORDER BY ChurnedCustomerCount DESC
LIMIT 1;


-- 3.5 Most preferred payment mode among active customers.
SELECT PreferredPaymentMode, COUNT(*) AS CustomerCount
FROM customer_churn
WHERE ChurnStatus = 'Active'
GROUP BY PreferredPaymentMode
ORDER BY CustomerCount DESC
LIMIT 1;


-- 3.6 Total order amount hike for single customers
--     who prefer mobile phones for ordering.
SELECT SUM(OrderAmountHikeFromlastYear) AS TotalOrderAmountHike
FROM customer_churn
WHERE MaritalStatus = 'Single'
  AND PreferredOrderCat = 'Mobile Phone';


-- 3.7 Average number of devices registered by customers
--     whose preferred payment mode is UPI.
SELECT AVG(NumberOfDeviceRegistered) AS AverageDevicesRegistered
FROM customer_churn
WHERE PreferredPaymentMode = 'UPI';


-- 3.8 City tier with the highest number of customers.
SELECT CityTier, COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY CityTier
ORDER BY CustomerCount DESC
LIMIT 1;


-- 3.9 Gender that utilized the highest number of coupons.
SELECT Gender, SUM(CouponUsed) AS TotalCouponsUsed
FROM customer_churn
GROUP BY Gender
ORDER BY TotalCouponsUsed DESC
LIMIT 1;


-- 3.10 Number of customers and maximum app hours
--      in each preferred order category.
SELECT
    PreferredOrderCat,
    COUNT(*) AS CustomerCount,
    MAX(HoursSpentOnApp) AS MaximumHoursSpentOnApp
FROM customer_churn
GROUP BY PreferredOrderCat;


-- 3.11 Total order count for customers who prefer Credit Card
--      and have the maximum satisfaction score.
SELECT SUM(OrderCount) AS TotalOrderCount
FROM customer_churn
WHERE PreferredPaymentMode = 'Credit Card'
  AND SatisfactionScore = (
      SELECT MAX(SatisfactionScore)
      FROM customer_churn
  );


-- 3.12 Average satisfaction score of customers who complained.
SELECT AVG(SatisfactionScore) AS AverageSatisfactionScore
FROM customer_churn
WHERE ComplaintReceived = 'Yes';


-- 3.13 Preferred order categories among customers who used
--      more than 5 coupons.
SELECT DISTINCT PreferredOrderCat
FROM customer_churn
WHERE CouponUsed > 5;


-- 3.14 Top 3 preferred order categories with the highest
--      average cashback amount.
SELECT
    PreferredOrderCat,
    AVG(CashbackAmount) AS AverageCashbackAmount
FROM customer_churn
GROUP BY PreferredOrderCat
ORDER BY AverageCashbackAmount DESC
LIMIT 3;


-- 3.15 Preferred payment modes for groups whose average tenure
--      is 10 months and whose total order count is greater than 500.
SELECT
    PreferredPaymentMode,
    AVG(Tenure) AS AverageTenure,
    SUM(OrderCount) AS TotalOrderCount
FROM customer_churn
GROUP BY PreferredPaymentMode
HAVING AVG(Tenure) = 10
   AND SUM(OrderCount) > 500;


-- 3.16 Categorize customers by WarehouseToHome distance
--      and show churn-status breakdown for each category.
SELECT
    CASE
        WHEN WarehouseToHome <= 5 THEN 'Very Close Distance'
        WHEN WarehouseToHome <= 10 THEN 'Close Distance'
        WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
        ELSE 'Far Distance'
    END AS DistanceCategory,
    ChurnStatus,
    COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY DistanceCategory, ChurnStatus
ORDER BY
    CASE DistanceCategory
        WHEN 'Very Close Distance' THEN 1
        WHEN 'Close Distance' THEN 2
        WHEN 'Moderate Distance' THEN 3
        ELSE 4
    END,
    ChurnStatus;


-- 3.17 Order details of married customers in City Tier 1
--      whose order count is above the overall average.
SELECT *
FROM customer_churn
WHERE MaritalStatus = 'Married'
  AND CityTier = 1
  AND OrderCount > (
      SELECT AVG(OrderCount)
      FROM customer_churn
  );


-- 3.18(a) Create customer_returns table and insert the given records.
CREATE TABLE IF NOT EXISTS customer_returns (
    ReturnID INT PRIMARY KEY,
    CustomerID INT,
    ReturnDate DATE,
    RefundAmount DECIMAL(10,2)
);

INSERT INTO customer_returns (ReturnID, CustomerID, ReturnDate, RefundAmount)
VALUES
    (1001, 50022, '2023-01-01', 2130),
    (1002, 50316, '2023-01-23', 2000),
    (1003, 51099, '2023-02-14', 2290),
    (1004, 52321, '2023-03-08', 2510),
    (1005, 52928, '2023-03-20', 3000),
    (1006, 53749, '2023-04-17', 1740),
    (1007, 54206, '2023-04-21', 3250),
    (1008, 54838, '2023-04-30', 1990)
ON DUPLICATE KEY UPDATE
    CustomerID = VALUES(CustomerID),
    ReturnDate = VALUES(ReturnDate),
    RefundAmount = VALUES(RefundAmount);


-- 3.18(b) Return details with customer details for customers
--         who churned and made complaints.
SELECT
    cr.ReturnID,
    cr.CustomerID,
    cr.ReturnDate,
    cr.RefundAmount,
    cc.* 
FROM customer_returns AS cr
INNER JOIN customer_churn AS cc
    ON cr.CustomerID = cc.CustomerID
WHERE cc.ChurnStatus = 'Churned'
  AND cc.ComplaintReceived = 'Yes';
