/*INICIANDO BANCO DE DADOS*/
USE dannys_diner


/*CRIANDO As tabelas e inserindo os dados */

CREATE TABLE SALES (
	CUSTOMER_ID VARCHAR(1),
	ORDER_DATE DATE,
	PRODUCT_ID INTEGER
)
GO

INSERT INTO SALES
  ("CUSTOMER_ID", "ORDER_DATE", "PRODUCT_ID")
VALUES
  ('A', '2021-01-01', '1'),  ('A', '2021-01-01', '2'),  ('A', '2021-01-07', '2'),  ('A', '2021-01-10', '3'),  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),  ('B', '2021-01-01', '2'),  ('B', '2021-01-02', '2'),  ('B', '2021-01-04', '1'),  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),  ('B', '2021-02-01', '3'),  ('C', '2021-01-01', '3'),  ('C', '2021-01-01', '3'),  ('C', '2021-01-07', '3')
GO

CREATE TABLE MEMBERS (
	CUSTOMER_ID VARCHAR(1),
	JOIN_DATE DATE
)
GO

INSERT INTO MEMBERS
  ("CUSTOMER_ID", "JOIN_DATE")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09')
GO

CREATE TABLE MENU (
	PRODUCT_ID VARCHAR(1),
	PRODUCT_NAME VARCHAR(5),
	PRICE INTEGER
)
GO

INSERT INTO MENU
  ("PRODUCT_ID", "PRODUCT_NAME", "PRICE")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12')
GO



/*What is the total amount each customer spent at the restaurant?*/

SELECT S.CUSTOMER_ID, SUM(PRICE) AS "SPENT($)"
FROM SALES  S
INNER JOIN MENU
ON S.PRODUCT_ID = MENU.PRODUCT_ID
GROUP BY S.CUSTOMER_ID
GO

/*How many days has each customer visited the restaurant?*/
SELECT CUSTOMER_ID, APPROX_COUNT_DISTINCT(ORDER_DATE)
FROM SALES
GROUP BY CUSTOMER_ID
ORDER BY 1
GO

/*What was the first item from the menu purchased by each customer?*/
WITH SALES_CTE AS (
	SELECT CUSTOMER_ID, PRODUCT_NAME, ORDER_DATE,
		DENSE_RANK() OVER(PARTITION BY CUSTOMER_ID ORDER BY ORDER_DATE) AS "RANKING"
	FROM SALES S
		INNER JOIN MENU MN
			ON S.PRODUCT_ID = MN.PRODUCT_ID
)
SELECT CUSTOMER_ID, PRODUCT_NAME
FROM SALES_CTE
WHERE RANKING = 1
GROUP BY CUSTOMER_ID, PRODUCT_NAME

/*What is the most purchased item on the menu and how many times was it purchased by all customers?*/

SELECT TOP 1 M.PRODUCT_NAME, COUNT (S.PRODUCT_ID) AS "TIMES"
FROM SALES S
INNER JOIN MENU M
ON S.PRODUCT_ID = M.PRODUCT_ID
GROUP BY M.PRODUCT_NAME
ORDER BY TIMES DESC
GO

/*Which item was the most popular for each customer?*/

WITH SALES_CTE AS (
	SELECT S.CUSTOMER_ID, MN.PRODUCT_NAME, COUNT(*) AS "PEDIDOS",
		DENSE_RANK() OVER(PARTITION BY CUSTOMER_ID ORDER BY COUNT(*) DESC) AS "RANKING"
	FROM SALES S
		INNER JOIN MENU MN
			ON S.PRODUCT_ID = MN.PRODUCT_ID
	GROUP BY S.CUSTOMER_ID, MN.PRODUCT_NAME
)
SELECT CUSTOMER_ID, PRODUCT_NAME, PEDIDOS
FROM SALES_CTE
WHERE RANKING = 1


/*Which item was purchased first by the customer after they became a member?*/

WITH SALES_CTE AS (
	SELECT S.CUSTOMER_ID, MN.PRODUCT_NAME, S.ORDER_DATE, M.JOIN_DATE,
		DENSE_RANK() OVER(PARTITION BY S.CUSTOMER_ID ORDER BY ORDER_DATE) AS "RANKING"
	FROM SALES S
		INNER JOIN MENU MN
			ON S.PRODUCT_ID = MN.PRODUCT_ID
		INNER JOIN MEMBERS M
			ON S.CUSTOMER_ID = M.CUSTOMER_ID
	WHERE S.ORDER_DATE > M.JOIN_DATE
)
SELECT CUSTOMER_ID, PRODUCT_NAME
FROM SALES_CTE
WHERE RANKING = 1


/*Which item was purchased just before the customer became a member?*/

WITH SALES_CTE AS (
	SELECT S.CUSTOMER_ID, MN.PRODUCT_NAME, S.ORDER_DATE, M.JOIN_DATE,
		DENSE_RANK() OVER(PARTITION BY S.CUSTOMER_ID ORDER BY ORDER_DATE DESC) AS "RANKING"
	FROM SALES S
		INNER JOIN MENU MN
			ON S.PRODUCT_ID = MN.PRODUCT_ID
		INNER JOIN MEMBERS M
			ON S.CUSTOMER_ID = M.CUSTOMER_ID
	WHERE S.ORDER_DATE < M.JOIN_DATE
)
SELECT CUSTOMER_ID, PRODUCT_NAME
FROM SALES_CTE
WHERE RANKING = 1

/*What is the total items and amount spent for each member before they became a member*/

SELECT 
	S.CUSTOMER_ID, 
	COUNT(S.PRODUCT_ID) AS "ITEMS", SUM(MN.PRICE) AS "SPENT"
FROM MEMBERS M
LEFT JOIN SALES S
ON M.CUSTOMER_ID = S.CUSTOMER_ID 
AND M.JOIN_DATE > S.ORDER_DATE  
LEFT JOIN MENU MN
ON S.PRODUCT_ID = MN.PRODUCT_ID
GROUP BY S.CUSTOMER_ID
GO

/*If each $1 spent equates to 10 points and sushi has a 2x points multiplier
	- how many points would each customer have?*/

SELECT
	S.CUSTOMER_ID,
	SUM(PRICE * 10 * (CASE WHEN MN.PRODUCT_NAME LIKE 'SUSHI' THEN 2 ELSE 1 END)) AS "POINTS"
FROM MENU MN
LEFT JOIN SALES S
ON MN.PRODUCT_ID = S.PRODUCT_ID
GROUP BY S.CUSTOMER_ID

/*In the first week after a customer joins the program (including their join date) 
they earn 2x points on all items, not just sushi - 
how many points do customer A and B have at the end of January?*/

SELECT
	S.CUSTOMER_ID,
	SUM(
		CASE 
			WHEN S.ORDER_DATE BETWEEN M.JOIN_DATE AND DATEADD(DAY,6,M.JOIN_DATE) 
				THEN PRICE * 10 * 2
			WHEN MN.PRODUCT_NAME LIKE 'SUSHI' 
				THEN PRICE * 10 * 2
			ELSE PRICE *10 
		END) AS "POINTS"
FROM SALES S
	INNER JOIN MENU MN
		ON S.PRODUCT_ID = MN.PRODUCT_ID
	INNER JOIN MEMBERS M
		ON S.CUSTOMER_ID = M.CUSTOMER_ID
WHERE S.ORDER_DATE < '2021-02-01'
GROUP BY S.CUSTOMER_ID
GO

/*Join All The Things*/

CREATE VIEW STATUS_MEMBER AS
SELECT 
	S.CUSTOMER_ID, S.ORDER_DATE,
	MN.PRODUCT_NAME, MN.PRICE,(
	CASE 
		WHEN M.JOIN_DATE <= S.ORDER_DATE THEN 'Y'
		ELSE 'N'
	END) AS "MEMBER"
FROM SALES S
JOIN MENU MN
ON S.PRODUCT_ID = MN.PRODUCT_ID
LEFT JOIN MEMBERS M
ON S.CUSTOMER_ID = M.CUSTOMER_ID
GO

SELECT * FROM STATUS_MEMBER
GO

/*Rank All The Things
Here we need to create a view. A view is a virtual table. 
A view does not save the table data. It saves the query 
so that you do not need to rewrite it every time you need
to retrieve data. You can view it like a normal table while
in the background the saved query is called. An important advantage 
of the view is that when the source table(s) updates, 
the view also updates to show us the most recent changes.
*/

SELECT *,
	(CASE
		WHEN MEMBER = 'N' THEN NULL
		ELSE RANK() OVER(
			PARTITION BY  CUSTOMER_ID, MEMBER 
			ORDER BY ORDER_DATE)
	END) AS "RANKING"
FROM STATUS_MEMBER