
CREATE DATABASE CreditCard;

USE CreditCard; 

SELECT * FROM dbo.CC_transactions;

--COUNT NUMBER OF ROWS 
SELECT COUNT(*) AS total_rows FROM DBO.CC_transactions; --26052 rows

----COUNT NUMBER OF COLUMNS
SELECT COUNT(*) AS column_count
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CC_transactions'; -- 7

select min(Date), max(Date) from CCT; -- 10-2013 to 05-2015 -- we have 19 months of data

--FINDING THE DUPLICATES
--CREATE A DUPLICATE TABLE

SELECT * INTO CCT  
FROM dbo.CC_transactions;  

WITH CTE AS(
SELECT *,
ROW_NUMBER() OVER (PARTITION BY CITY,DATE,CARD_TYPE,EXP_TYPE,GENDER,AMOUNT ORDER BY CITY )AS RN
FROM CCT  )
DELETE FROM CTE WHERE RN > 1;  --TO DELETE RECORDS WHERE YOU FIND DUPLICATES

--OR YOU CAN ALSO USE 
SELECT CITY,DATE,CARD_TYPE,EXP_TYPE,GENDER,AMOUNT, COUNT(*) AS duplicate_count
FROM CCT
GROUP BY CITY,DATE,CARD_TYPE,EXP_TYPE,GENDER,AMOUNT  -- Include all columns
HAVING COUNT(*) > 1;

--no duplicate record found

--Overview of Spending Patterns
--What is the total number of transactions and the cumulative amount spent across all cities?

select * from CCT;

select 
	City
	, count(1) as TXN_no
	,sum(Amount) as City_wise_Amount
from CCT
group by City
order by City_wise_Amount desc;

/* There are 986 cities in the data set, highest transcations spend are made in Mumbai,Bengaluru,A'bad and Delhi.*/

--a function to find card type transactions in the selected City.
-- Declare the scalar variable
DECLARE @city NVARCHAR(100);  -- Specify an appropriate data type and size

-- Set the value of the variable
SET @city = 'Achalpur, India';


select 
	City
	, count(1) as TXN_no
	,Card_type
	,sum(Amount) as City_wise_Amount
from CCT
where City = @city
group by City,Card_type
order by city,City_wise_Amount desc;


--Average Transaction Value: What is the average amount spent per transaction? - 156411 in amount

ALTER TABLE CCT
ALTER COLUMN Amount BIGINT;

select 
	sum(Amount)/count(1) as avg_amt_per_transaction
from CCT;

--considering all the transanctions, on an avg, 156411 is spent 

select 
	City
	,sum(Amount)/count(1) as avg_amt_per_transaction_city
	,count(1) as no_of_trans  ,
	sum(case when Gender  = 'F' then 1 end) as Female_transactions,
	sum(case when Gender  = 'M' then 1 end) as Male_transactions
from CCT
group by City 
order by no_of_trans desc,avg_amt_per_transaction_city desc;

--highest avg transaction is seen in bengaluru with 3552 transactions.
--when we splitting transaction, it is seen that female have more number of transactions as compared to male in the metro cities.

--how many cities have female transactions more the male transactions?

with male_female_trans as 

(select
	City
	,count(1) as no_of_trans
	,sum(case when Gender  = 'F' then 1 end) as Female_transactions
	,sum(case when Gender  = 'M' then 1 end) as Male_transactions
from CCT
group by City)
select
	sum(case when Female_transactions > Male_transactions then 1 end) as female_male,
	sum(case when Female_transactions < Male_transactions then 1 end) as male_female
from male_female_trans;

--377 cities have female transactions more than male

--Do people spend more on weekdays or weekends? How does transaction volume and average spending compare between the two?

with cte as(
select 
City,
sum(case when DATEPART(WEEKDAY, Date) IN (1, 7) then 1 end) as weekend_trans,
sum(case when DATEPART(WEEKDAY, Date) IN (2,3,4,5,6) then 1 end) as weekday_trans,
sum(case when DATEPART(WEEKDAY, Date) IN (1, 7) then Amount end) as weekend_trans_amt,
sum(case when DATEPART(WEEKDAY, Date) IN (2,3,4,5,6) then Amount end) as weekday_trans_amt
from CCT 
group by City)
select * from cte where weekend_trans_amt>weekday_trans_amt;

--there are around 160 cities where  week end trans >weed day trans

--card type split by gender

SELECT
	Card_Type
	,sum(case when Gender = 'F' then 1 end) as female
	,sum(case when Gender = 'M' then 1 end) as male
FROM CCT
GROUP BY Card_Type

--in all the Card types, females hold more than males.


SELECT
	Card_Type
	,sum(case when year(Date) = 2014 and Month(Date) = 01 then 1  end) as '2014-01'
	,sum(case when year(Date) = 2014 and Month(Date) = 02 then 1  end) as '2014-02'
	,sum(case when year(Date) = 2014 and Month(Date) = 03 then 1  end) as '2014-03'
	,sum(case when year(Date) = 2014 and Month(Date) = 04 then 1  end) as '2014-04'
	,sum(case when year(Date) = 2014 and Month(Date) = 05 then 1  end) as '2014-05'
	,sum(case when year(Date) = 2014 and Month(Date) = 06 then 1  end) as '2014-06'
FROM CCT
GROUP BY Card_Type
 
 --no specifc seen month on month basis

ALTER TABLE CC_transactions  
DROP COLUMN [index];

--Mumbai, Bengaluru,A'bad,Delhi and kolkata are top 5 cities with highest spends
select * from CC_transactions;

ALTER TABLE CC_transactions
ALTER COLUMN Amount BIGINT;

WITH city_wise_sales AS (
    SELECT City, SUM(Amount) AS city_Amount
    FROM CC_transactions
    GROUP BY City
)
SELECT top 5 *,
       SUM(city_Amount) OVER () AS total_amount,
	   1.0*city_Amount/(SUM(city_Amount) OVER ()) as percent_total
FROM city_wise_sales
order by city_Amount desc;

-- highest spend by month in the year 2014 for each card type - Aug'14 has the highest spend
with monthly_yearly_amount as(
select year(Date) as years, MONTH(Date) as months,Card_Type, sum(Amount) as month_cardType_amt
from CC_transactions
where year(Date) = '2014'
group by year(Date), MONTH(Date), Card_Type
)

select *,
sum(month_cardType_amt) over( partition by years, months ) as total_amount
from monthly_yearly_amount
order by total_amount desc;

--comsidering all the years, Jan'2015 had highest overall spend.
select top 1
	year(Date) as years, MONTH(Date) as months, CONCAT(year(Date),'-',format(MONTH(Date),'00')) as year_month, sum(Amount)  as monthly_amount
	from CC_transactions
	group by year(Date), MONTH(Date)
	order by monthly_amount desc;

--Jan'15 spend split by card type

SELECT
    YEAR(Date) AS years, 
    MONTH(Date) AS months, 
    CONCAT(YEAR(Date), '-', FORMAT(MONTH(Date), '00')) AS year_month,
    Card_type, 
    SUM(Amount) AS monthly_amount
FROM CC_transactions
WHERE CONCAT(YEAR(Date), '-', FORMAT(MONTH(Date), '00')) = 
(
    SELECT TOP 1 
        CONCAT(YEAR(Date), '-', FORMAT(MONTH(Date), '00')) 
    FROM CC_transactions
    GROUP BY YEAR(Date), MONTH(Date)
    ORDER BY SUM(Amount) DESC
)
GROUP BY YEAR(Date), MONTH(Date), Card_type
ORDER BY monthly_amount DESC;

-- the transaction details for each card type when it reaches a cumulative of 1000000 total spends

EXEC SP_RENAME 'CCT.[index]', 'TXN_ID', 'COLUMN';
SELECT * FROM CCT;

with running_amount as(
SELECT
	Card_type
	,Date
	,sum(Amount) over (Partition by Card_type order by Date ASC,TXN_ID) as cumulative_amount
FROM CCT),

ranks as (
select *,
row_number() over (partition by Card_type order by cumulative_amount ) as ranks
from running_amount where cumulative_amount >= 1000000)

select * from ranks where ranks = 1;


--4- Dhamtari had lowest percentage spend for gold card type out of total spends on gold.

WITH city_cardtype_amount AS (
    SELECT
        Card_type, 
        City, 
        SUM(Amount) AS city_cardtype_amount
    FROM CCT
    WHERE Card_type = 'Gold'
    GROUP BY Card_type, City
)
SELECT *, 
       SUM(city_cardtype_amount) OVER () AS total_gold_amount,
       1.0 *city_cardtype_amount / SUM(city_cardtype_amount) OVER () AS percent_total
FROM city_cardtype_amount
ORDER BY percent_total ASC;

--5- query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel).

select * from CCT;

with expenses as
(select City,Exp_Type,sum(Amount) as total_amt
from CCT
group by City,Exp_Type
) ,

ranking as(
select * ,
ROW_NUMBER() over (partition by City order by total_amt asc) as rn_min,
ROW_NUMBER() over (partition by City order by total_amt desc) as rn_max
from expenses)

select City,
max(case when rn_min = 1 then Exp_Type end)  as leastexp,
max(case when rn_max = 1 then Exp_Type end)  as mostexp
from ranking
group by City

--percentage contribution of spends by females for each expense type.

with expd as (
select Exp_Type,Gender,Sum(Amount) as tot_Amount
from CCT
group by Exp_Type,Gender
)

select *,
sum(tot_Amount) over (Partition by Exp_Type) as exp_total,
1.0*tot_Amount/(sum(tot_Amount) over (Partition by Exp_Type)) as perc_total
from expd;

select Exp_Type,
sum(case when Gender = 'F' then Amount else 0 end)*1.0/sum(Amount) as percentage_female
from CCT
group by Exp_Type
order by percentage_female desc;

--Applied row by row before aggregation (inside aggregates).

-- Gold card - travel combination saw highest month over month growth in Jan-2014.

with montly_amount as(
select	 
	 CONCAT(year(Date),'-',format(MONTH(Date),'00')) as year_month
	,CONCAT(Card_Type,'-',Exp_Type) as Card_type
	,sum(Amount) as total_amount
from CCT
group by CONCAT(year(Date),'-',format(MONTH(Date),'00')),CONCAT(Card_Type,'-',Exp_Type)
),
perc_cange as
(select *,
	lag(total_amount) over (partition by Card_type order by year_month asc) as previous_month_sales
	,1.0* (total_amount - (lag(total_amount) over (partition by Card_type order by year_month asc)))/(lag(total_amount) over (partition by Card_type order by year_month asc)) as change_p
from montly_amount)

select * from perc_cange where year_month = '2014-01'
order by change_p desc;


--8- during weekends, Sonepur had highest total spend to total no of transcations ratio 

select top 1 City , sum(Amount)*1.0/count(1) as ratio
from CCT
where datepart(weekday,Date) in (1,7)
--where datename(weekday,transaction_date) in ('Saturday','Sunday')
group by City
order by ratio desc;

-- Surat took least number of days to reach its 500th transaction after the first transaction in that city 

with cte as (
SELECT 
	City, Date, 
	ROW_NUMBER() OVER (PARTITION BY City ORDER BY Date asc) rn_min,
	ROW_NUMBER() OVER (PARTITION BY City ORDER BY Date desc) rn_max
FROM CCT)
select top 1 City,
	min(case when rn_min =1 then [Date] end) as First_transaction,
	min(case when rn_max =500 then [Date] end) as Last_transaction,
	DATEDIFF(DAY, 
        MIN(CASE WHEN rn_min = 1 THEN Date END), 
        MIN(CASE WHEN rn_max = 500 THEN Date END)
    ) AS Transaction_Days_Difference
from cte
group by City
having
	MIN(CASE WHEN rn_min = 1 THEN Date END) is not null  
	 and MIN(CASE WHEN rn_max = 500 THEN Date END) is not null
order by Transaction_Days_Difference asc;


--Overview of Spending Patterns
--What is the total number of transactions and the cumulative amount spent across all cities?

select * from CCT;

select City, count(1) as TXN_no,sum(Amount) as City_wise_Amount
from CCT
group by City
order by City_wise_Amount desc;

/* there are 986 cities in the data set, highest transcations spend are made in Mumbai,Bengaluru,A'bad and Delhi.*/

-- Declare the scalar variable
DECLARE @city NVARCHAR(100);  -- Specify an appropriate data type and size

-- Set the value of the variable
SET @city = 'Achalpur, India';


select City, count(1) as TXN_no,Card_type,sum(Amount) as City_wise_Amount
from CCT
where City = @city
group by City,Card_type
order by city,City_wise_Amount desc;


--Average Transaction Value: What is the average amount spent per transaction?

ALTER TABLE CCT
ALTER COLUMN Amount BIGINT;

select sum(Amount)/count(1) as avg_amt_per_transaction
from CCT;

--considering all the transanctions, on an avg, 156411 is spent 

select City,sum(Amount)/count(1) as avg_amt_per_transaction_city, count(1) as no_of_trans  ,
sum(case when Gender  = 'F' then 1 end) as Female_transactions,
sum(case when Gender  = 'M' then 1 end) as Male_transactions
from CCT
group by City 
order by no_of_trans desc,avg_amt_per_transaction_city desc;

--highest avg transaction is seen in bengaluru with 3552 transactions.
--when we splitting transaction, it is seen that female have more number of transactions as compared to male in the metro cities.

--how many cities have female transactions more the male transactions?

with male_female_trans as 

(select
	City
	,count(1) as no_of_trans
	,sum(case when Gender  = 'F' then 1 end) as Female_transactions
	,sum(case when Gender  = 'M' then 1 end) as Male_transactions
from CCT
group by City)
select
sum(case when Female_transactions > Male_transactions then 1 end) as female_male,
sum(case when Female_transactions < Male_transactions then 1 end) as male_female
from male_female_trans;

--377 cities have female transaction more than male

--Do people spend more on weekdays or weekends? How does transaction volume and average spending compare between the two?

with cte as(
select 
City,
sum(case when DATEPART(WEEKDAY, Date) IN (1, 7) then 1 end) as weekend_trans,
sum(case when DATEPART(WEEKDAY, Date) IN (2,3,4,5,6) then 1 end) as weekday_trans,
sum(case when DATEPART(WEEKDAY, Date) IN (1, 7) then Amount end) as weekend_trans_amt,
sum(case when DATEPART(WEEKDAY, Date) IN (2,3,4,5,6) then Amount end) as weekday_trans_amt
from CCT 
group by City)
select * from cte where weekend_trans_amt>weekday_trans_amt;

--there are around 160 cities where  week end trans >weed day trans



















