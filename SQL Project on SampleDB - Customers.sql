-- PROCESS 1 -> Data Exploration

-- Checking table structure and column data types
EXEC sp_help 'customers'
SELECT * FROM customers
ORDER BY id ASC

-- Count total number of records
SELECT COUNT(*) FROM customers

-- Identify unique values (gender, state, town, postcode)
SELECT DISTINCT
	gender,
	[state],
	town,
	postcode
FROM customers

-- Analyse distribution of categorical fields (gender, state, spam)

-- Most spammed gender category
SELECT gender, COUNT(spam) [MostSpammedGender]
FROM customers
GROUP BY gender
ORDER BY [MostSpammedGender] DESC

-- Most gender by state
SELECT gender, COUNT([state]) [MostGenderByState]
FROM customers
GROUP BY gender
ORDER BY [MostGenderByState] DESC

-- Count of genders per state
SELECT 
    [state],
    COUNT(CASE WHEN gender = 'F' THEN 1 END) AS Female_Count,
    COUNT(CASE WHEN gender = 'M' THEN 1 END) AS Male_Count,
    COUNT(CASE WHEN gender IS NULL OR gender = 'U' THEN 1 END) AS Unknown_Count
FROM customers
GROUP BY [state]
ORDER BY Female_Count DESC

-- Most spammed state
SELECT [state], COUNT(spam) [MostSpammedState]
FROM customers
GROUP BY [state]
ORDER BY [MostSpammedState] DESC

-- Identifying missing/null values across all columns
SELECT * FROM customers
WHERE
	id IS NULL
	OR
	email IS NULL
	OR
	familyname IS NULL
	OR
	givenname IS NULL
	OR 
	gender IS NULL
	OR
	street IS NULL
	OR 
	town IS NULL
	OR
	[state] IS NULL
	OR
	postcode IS NULL
	OR 
	dob IS NULL
	OR
	phone IS NULL
	OR
	spam IS NULL
	OR
	height IS NULL
	OR 
	registered IS NULL
ORDER BY id ASC

-- Analyse numerical fields (height, age derived from dob)

-- Each Customer's Age
SELECT 
	CONCAT(givenname, ' ', familyname) [FullName], 
	DATEPART(YEAR, GETDATE()) - DATEPART(YEAR, dob) [Customer's Age]
FROM customers
ORDER BY [Customer's Age] DESC

-- AVG age of customers
SELECT AVG(DATEPART(YEAR, GETDATE()) - DATEPART(YEAR, dob)) [AverageAgeofCustomers]
FROM customers

-- AVG height 
SELECT ROUND(AVG(height), 2) [AVG Height]
FROM customers

-- Age by State
SELECT MAX(DATEPART(YEAR, dob)) [EarliestDOB], MIN(DATEPART(YEAR, dob)) [LatestDOB]
FROM customers -- To find the range of customers age

SELECT 
	[state],
	COUNT(CASE WHEN (DATEPART(YEAR, GETDATE()) - DATEPART(YEAR, dob)) >= 20 AND (DATEPART(YEAR, GETDATE()) - DATEPART(YEAR, dob)) <= 40 THEN 1 END) [Within 20 - 40],
	COUNT(CASE WHEN (DATEPART(YEAR, GETDATE()) - DATEPART(YEAR, dob)) > 40 AND (DATEPART(YEAR, GETDATE()) - DATEPART(YEAR, dob)) <= 60 THEN 1 END) [Within 41 - 60],
	COUNT(CASE WHEN (DATEPART(YEAR, GETDATE()) - DATEPART(YEAR, dob)) > 60 AND (DATEPART(YEAR, GETDATE()) - DATEPART(YEAR, dob)) <= 80 THEN 1 END) [Within 61 - 80],
	COUNT(CASE WHEN dob IS NULL THEN 1 END) AS Unknown_Count
FROM customers
GROUP BY [state]
ORDER BY [Within 20 - 40] DESC
-- After reviewing this, I discovered that using the DATEDIFF function would be best for this. 

-- Height by state
SELECT MAX(height) [MaxHeight], MIN(height) [MinHeight]
FROM customers -- To find the range of customers height

SELECT
	[state],
	COUNT(CASE WHEN height >= 142 AND height <= 162 THEN 1 END) [HeightWithin 142 to 162],
	COUNT(CASE WHEN height > 162 AND height <= 182 THEN 1 END) [HeightWithin 162 to 182],
	COUNT(CASE WHEN height > 182 AND height <= 202 THEN 1 END) [HeightWithin 182 to 202]
FROM customers
GROUP BY [state]
ORDER BY [HeightWithin 142 to 162] DESC

-- Checking chronological logic(if the registered date happened before dob)
SELECT
	COUNT(CASE WHEN DATEPART(YEAR, registered) - DATEPART(YEAR, dob) < 0 THEN 1 END) [Diff_In_Reg_and_Dob]
FROM customers
WHERE dob IS NOT NULL AND registered IS NOT NULL

-- Checking frequency distribution (customers, state/town)

-- Checking customers by state
SELECT 
	[state],
	COUNT(givenname) [MostCustomers/State]
FROM customers
GROUP BY [state]
ORDER BY COUNT(givenname) DESC

-- Checking customers by town
SELECT
	town,
	COUNT(givenname) [MostCustomers/Town]
FROM customers
GROUP BY town
ORDER BY COUNT(givenname) DESC

-- Checking consistency of text fields (case sensitivity, spelling)

UPDATE customers
SET gender = UPPER(gender)

-- Validate logical ranges (dob)

SELECT givenname, dob
FROM customers
WHERE DATEPART(YEAR, dob) > DATEPART(YEAR, GETDATE())


-- PROCESS 2 -> Data Cleaning

-- Handling of Null Values
UPDATE customers
SET gender = 'U'
WHERE gender IS NULL
-- This column only accept 1 character. U represents UNKNOWN

UPDATE customers
SET street = 'Unkown'
WHERE street IS NULL
-- Mistakenly Updated it to 'Unkown' instead of 'Unknown'

UPDATE customers
SET town = 'Unkown'
WHERE town IS NULL
-- Mistakenly Updated it to 'Unkown' instead of 'Unknown'

UPDATE customers
SET [state] = 'UNK'
WHERE [state] IS NULL

UPDATE customers
SET dob = ''
WHERE dob IS NULL

/* 
1. The state column only accepts 3 characters, hence the UNK. 
UNK represents unkown

2. The Postcode column will be left with it's NULLs
because post code is a very important data.

3. The dob column NULLS will be left also.

4. The phone column will be left with it's NULLs
because phone is a very important data.
*/

UPDATE customers
SET spam = 0
WHERE spam IS NULL

UPDATE customers
SET height = 0
WHERE height IS NULL

-- Checking for duplicates
SELECT COUNT(*) [Occurence]
FROM customers
GROUP BY [id]
      ,[email]
      ,[familyname]
      ,[givenname]
      ,[gender]
      ,[street]
      ,[town]
      ,[state]
      ,[postcode]
      ,[dob]
      ,[phone]
      ,[spam]
      ,[height]
      ,[registered]
HAVING COUNT(*) > 1

-- Standardising text formats (familyname, givenname, and town)

-- Case Consistency
UPDATE customers
SET familyname = UPPER(LEFT(familyname, 1)) + LOWER(SUBSTRING(familyname, 2, LEN(familyname)))

UPDATE customers
SET givenname = UPPER(LEFT(givenname, 1)) + LOWER(SUBSTRING(givenname, 2, LEN(givenname)))

UPDATE customers
SET town = UPPER(LEFT(town, 1)) + LOWER(SUBSTRING(town, 2, LEN(town)))

-- Finding spaces (trimming) in text
SELECT familyname
FROM customers
WHERE familyname != TRIM(familyname)

SELECT givenname
FROM customers
WHERE givenname != TRIM(givenname)

SELECT town
FROM customers
WHERE town != TRIM(town)

SELECT [state]
FROM customers
WHERE [state] != TRIM([state])

-- Validating email formats
SELECT * FROM customers
WHERE email NOT LIKE '%@%'

SELECT * FROM customers
WHERE 
	email NOT LIKE '%.com' 
	AND 
	email NOT LIKE '%.net'
	AND
	email NOT LIKE '%.org'

-- Validating phone numbers
SELECT * FROM customers
WHERE phone LIKE '%-%'

-- Fix inconsistent gender values
SELECT
	familyname,
	givenname,
	CASE
		WHEN gender IN ('M', 'm', '	Male', 'male') THEN 'M'
		WHEN gender IN ('F', 'f', 'Female', 'female') THEN 'F'
		WHEN gender IN ('U', 'u', 'Null') OR gender IS NULL THEN 'U'
	END [CleanedGender]
FROM customers


-- PROCESS 3 -> Data Analysis & Business Key Problems & Answers

/*
QUESTIONS

Q1. How many customers are in the database?
Q2. How many unique email addresses are registered?
Q3. What is the gender distribution of customers?
Q4. How many customers are marked as spam?
Q5. What is the average age of customers?
Q6. What is the distribution of customers by state?
Q7. Which state has the highest number of customers?
Q8. How many customers registered over time (by day/month)?
Q9. What is the average height by gender?
Q10. Are there customers with missing critical information (email, name, gender)?
Q11. How many customers share the same postcode?
Q12. What is the distribution of customers by town?
Q13. Which customers have invalid or missing phone numbers?
Q14. What is the age distribution across different states?
Q15. Are there duplicate customer records based on email?
*/

-- ANSWERS

-- Q1. How many customers are in the database?
SELECT COUNT(*) [TotalCustomers]
FROM customers

-- Q2. How many unique email addresses are registered?
SELECT COUNT(DISTINCT email) [UniqueEmails]
FROM customers

-- Q3. What is the gender distribution of customers?
SELECT 
	COUNT(CASE WHEN gender = 'M' THEN 1 END) [Total Male Customers],
	COUNT(CASE WHEN gender = 'F' THEN 1 END) [Total Female Customers],
	COUNT(CASE WHEN gender = 'U' THEN 1 END) [Total Unknown Customers]
FROM customers
ORDER BY [Total Male Customers] DESC

-- Q4. How many customers are marked as spam?
SELECT COUNT(*) [Spam Customers]
FROM customers
WHERE spam = 1

-- Q5. What is the average age of customers?
SELECT
	AVG(DATEPART(YEAR, GETDATE()) - DATEPART(YEAR, dob)) [AVG Age of Customers]
FROM customers

-- Q6. What is the distribution of customers by state?
SELECT
	[state],
	COUNT(*) [Customers By State]
FROM customers
GROUP BY [state]
ORDER BY [Customers By State] DESC

-- Q7. Which state has the highest number of customers?
SELECT TOP 1
	[state],
	COUNT(*) [Highest State]
FROM customers
GROUP BY [state]
ORDER BY [Highest State] DESC

-- Q8. How many customers registered over time (by day/month)?
SELECT
	DATENAME(MONTH, registered) [Month Of Registration],
	COUNT(*) [Registered Customers by Month]
FROM customers
GROUP BY DATENAME(MONTH, registered)
ORDER BY [Registered Customers by Month] DESC

-- Q9. What is the average height by gender?
SELECT
	gender,
	ROUND(AVG(height), 2) [AVG Height]
FROM customers
GROUP BY gender
ORDER BY [AVG Height]

-- Q10. Are there customers with missing critical information?
SELECT * FROM customers
WHERE NULL IN (id, email, familyname, givenname, gender, street, town, [state], postcode, dob, phone, spam, height, registered)

-- Q11. How many customers share the same postcode?
SELECT COUNT(DISTINCT postcode) [Same Postcode]
FROM customers
GROUP BY postcode
HAVING COUNT(DISTINCT postcode) > 1

-- Q12. What is the distribution of customers by town?
SELECT
	town,
	COUNT(givenname) [Customers by Town]
FROM customers
GROUP BY town
ORDER BY [Customers by Town] DESC

-- Q13. Which customers have invalid or missing phone numbers?
SELECT
	givenname [Customers With No Number]
FROM customers
WHERE phone IS NULL

-- Q14. What is the age distribution across different states?
SELECT
	[state],
	COUNT(DATEPART(YEAR, dob)) [Age Distribution]
FROM customers
GROUP BY [state]
ORDER BY [Age Distribution] DESC

-- Q15. Are there duplicate customer records based on email?
SELECT COUNT(email) [Duplicate Record]
FROM customers
GROUP BY email
HAVING COUNT(email) > 1
ORDER BY [Duplicate Record] DESC

-- End of Project

SELECT * FROM customers
ORDER BY id ASC