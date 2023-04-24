
-- B. CREATE FUNCTION refreshing the summary table with a data transformation

CREATE OR REPLACE FUNCTION late_price()
	RETURNS TRIGGER AS $$
BEGIN
DELETE FROM summary;
INSERT INTO summary (
    SELECT 
        customer_id,
        first_name,
        email,
        rental_id,
        return_date,
        payment_id,
        amount,
        address_id,
        address,
        CASE WHEN return_date > '2015-05-25' THEN 1.00 END AS late_fee
    FROM detailed
    GROUP BY customer_id, first_name, email, rental_id, return_date, payment_id, amount, address_id, address
    ORDER BY customer_id DESC);
RETURN NEW;
END; $$ LANGUAGE plpgsql;

-- To view function
-- SELECT * FROM summary;
-- SELECT late_fee FROM summary;

$$

-- C. CREATE detailed table-

DROP TABLE IF EXISTS detailed;
CREATE TABLE detailed (
	customer_id integer,
	first_name varchar (45),
	last_name varchar (45),
	email varchar (90),
	rental_id integer,
	rental_date varchar (45),
	return_date numeric (12,2),
	payment_id integer,
	amount float,
	payment_date varchar (45),
	address_id integer,
	address varchar (50),
	postal_code integer,
	phone integer);
	
-- To view empty detailed table
-- SELECT * FROM detailed;

-- CREATE summary table

DROP TABLE IF EXISTS summary;
CREATE TABLE summary (
	customer_id integer,
	first_name varchar (45),
	email varchar(45),
	rental_id integer,
	return_date  ,
	payment_id integer,
	amount float,
	address_id integer,
	address varchar (45),
	late_fee numeric (5,2)
	);

-- To view empty summary table	
-- SELECT * FROM summary;

-- D. Extract raw data from sqlda database into detailed table

INSERT INTO detailed (
	customer_id,
	first_name,
	last_name,
	email,
	rental_id,
	rental_date,
	return_date,
	late_fee,
	payment_id,
	amount,
	payment_date,
	address_id
	address
	postal_code
	phone)
SELECT
	c.customer_id, c.first_name, c.last_name, c.email,
	r.rental_id, r.rental_date, r.return_date,
	p.payment_id, p.amount,
	a.address_id, a.address, a.postal_code, a.phone
FROM rental AS r
INNER JOIN payment AS p ON p.rental_ide = r.rental_id
INNER JOIN customer AS c ON p.customer_id = c.customer_id
INNER JOIN address AS a ON c.address_id = a.address_id;


-- To view contents of detailed table
-- SELECT * FROM detailed;

-- E. CREATE TRIGGER

CREATE TRIGGER summary_refresh
AFTER INSERT ON detailed
FOR EACH STATEMENT
EXECUTE PROCEDURE late_fee();


-- F. CREATE STORED PROCEDURE
-- To be automated to run on a daily basis, it will be ran at noon to see 
-- what will be late the next day
-- Use the external pgAgent application as a job scheduling tool

CREATE PROCEDURE refresh_reports()
LANGUAGE PLPGSQL
AS $$
BEGIN
DELETE FROM detailed;
INSERT INTO detailed (
	customer_id,
	first_name,
	last_name,
	email,
	rental_id,
	rental_date,
	return_date,
	late_fee,
	payment_id,
	amount,
	payment_date,
	address_id
	address
	postal_code
	phone)
SELECT
	c.customer_id, c.first_name, c.last_name, c.email,
	d.dealership_id, d.city,
	s.sales_amount,
	p.product_id, p.product_type, p.model, p.year
c.customer_id, c.first_name, c.last_name, c.email,
	r.rental_id, r.rental_date, r.return_date,
	p.payment_id, p.amount,
	a.address_id, a.address, a.postal_code, a.phone
FROM rental AS r
INNER JOIN payment AS p ON p.rental_ide = r.rental_id
INNER JOIN customer AS c ON p.customer_id = c.customer_id
INNER JOIN address AS a ON c.address_id = a.address_id;
END; $$;

-- To call stored procedure
-- CALL refresh_reports();

-- To view results
-- SELECT * FROM detailed;
-- SELECT * FROM summary;
