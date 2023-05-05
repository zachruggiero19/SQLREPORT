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
        return_date,
        amount :: varchar (8),
	CASE 
	WHEN return_date < '2005-06-20 00:00:00'::timestamp THEN TRUE ELSE FALSE END AS late_fee
    FROM detailed
    GROUP BY customer_id, first_name, email, return_date, amount, late_fee
    ORDER BY customer_id DESC);
RETURN NEW;
END; $$ LANGUAGE plpgsql;


-- C. CREATE detailed table-

DROP TABLE IF EXISTS detailed;
CREATE TABLE detailed (
	customer_id integer,
	first_name varchar (45),
	last_name varchar (45),
	email varchar (90),
	rental_id integer,
	rental_date timestamp without time zone,
	return_date timestamp without time zone,
	payment_id integer,
	amount float,
	payment_date varchar (45));
	
-- To view empty detailed table
-- SELECT * FROM detailed;

-- CREATE summary table

DROP TABLE IF EXISTS summary;
CREATE TABLE summary (
	customer_id integer,
	first_name varchar (45),
	email varchar(45),
	return_date timestamp without time zone,
	amount float,
	late_fee boolean
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
	payment_id,
	amount,
	payment_date
	)
	
SELECT
	c.customer_id, c.first_name, c.last_name, c.email,
	r.rental_id, r.rental_date, r.return_date,
	p.payment_id, p.amount, p.payment_date
FROM rental AS r
INNER JOIN payment AS p ON p.rental_id = r.rental_id
INNER JOIN customer AS c ON p.customer_id = c.customer_id
WHERE return_date >= '2005-06-20 00:00:00'
AND return_date <= '2005-06-23 00:00:00'

-- To view contents of detailed table
-- SELECT * FROM detailed;

-- E. CREATE TRIGGER

CREATE TRIGGER summary_refresh
AFTER INSERT ON detailed
FOR EACH STATEMENT
EXECUTE PROCEDURE late_price();


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
	payment_id,
	amount,
	payment_date)
SELECT
	c.customer_id, c.first_name, c.last_name, c.email,
	r.rental_id, r.rental_date, r.return_date,
	p.payment_id, p.amount, p.payment_date
FROM rental AS r
INNER JOIN payment AS p ON p.rental_id = r.rental_id
INNER JOIN customer AS c ON p.customer_id = c.customer_id
WHERE return_date >= '2005-06-20 00:00:00'
AND return_date <= '2005-06-23 00:00:00';

END; $$;

-- To call stored procedure
-- CALL refresh_reports();

-- To view results
-- SELECT * FROM detailed;
-- SELECT * FROM summary;

