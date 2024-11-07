SELECT * FROM books;

SELECT * FROM branch;

SELECT * FROM members;

SELECT * FROM employees;

SELECT * FROM issued_status;

SELECT * FROM return_status;



--- PROJECT TASKS 

--Task 1. Create a New Book Record 
-- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co

INSERT INTO books values('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co');


-- Task 2: Update an Existing Member's Address

UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';


--Task 3: Delete a Record from the Issued Status

DELETE FROM issued_status
WHERE issued_id = 'IS121';

--Task 4: Retrieve All Books Issued by a Specific Employee

SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';


-- Task 5: List Members Who Have Issued More Than One Book

SELECT issued_member_id, COUNT(issued_member_id)
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(issued_id) > 1;


--Task 6: Create Summary Tables: 
--Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**

CREATE TABLE issued_book_summary 
AS
SELECT b.isbn, b.book_title, COUNT(ist.issued_id) AS issued_count
FROM books as b
LEFT JOIN issued_status as ist -- Left JOIn used to know the count of each book
ON b.isbn = ist.issued_book_isbn
GROUP BY b.isbn, b.book_title;



-- Task 7. Retrieve All Books in a Specific Category:

SELECT * FROM books
WHERE category = 'Classic';


-- Task 8: Find Total Rental Income by Category:

SELECT b.category, COUNT(ist.issued_book_isbn) AS issued_book_count, 
SUM(b.rental_price) AS rental_income
FROM books b
JOIN issued_status ist
ON b.isbn = ist.issued_book_isbn
GROUP BY b.category
ORDER BY issued_book_count DESC;


-- Task 9 : List Members Who Registered in the Last 180 Days:

SELECT * FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days';

-- Task 10 : List Employees with Their Branch Manager's Name and their branch details:

SELECT e1.emp_id, e1.emp_name, e1.emp_position, e1.salary,
b.*, e2.emp_name as manager
FROM employees e1
JOIN branch b 
ON e1.branch_id = b.branch_id
JOIN employees e2
ON e2.emp_id = b.manager_id;

-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold:

CREATE TABLE expensive_books 
AS
SELECT * FROM books
WHERE rental_price > 7.00;


-- Task 12: Retrieve the List of Books Not Yet Returned

SELECT * FROM issued_status ist
LEFT JOIN return_status rs
ON ist.issued_id = rs.issued_id
WHERE rs.return_id IS NULL;


-- Task 13: Identify Members with Overdue Books  (assume a 30-day return period). 
-- Display the member's_id, member's name, book title, issue date, and days overdue.

SELECT * FROM members;
SELECT * FROM issued_status;
SELECT * FROM return_status;

SELECT m.member_id, m.member_name, ist.issued_book_name, ist.issued_date, CURRENT_DATE - ist.issued_date as DAYS_OVERDUE
FROM members m
JOIN issued_status ist
ON m.member_id = ist.issued_member_id
LEFT JOIN return_status rs
ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL
AND (CURRENT_DATE - ist.issued_date) > 210; -- HERE we can assume any no. of days I have taken 200



-- Task 14: Write a query to update the status of books in the books table to "Yes" when they are returned 
-- (based on entries in the return_status table).
SELECT * FROM books;
SELECT * FROM issued_status;
SELECT * FROM return_status;

CREATE OR REPLACE PROCEDURE
return_books (p_return_id VARCHAR(30), p_issued_id VARCHAR(25))
LANGUAGE plpgsql
AS
$$

	DECLARE 
		v_book_isbn VARCHAR(50);
		v_book_name VARCHAR(100);
	
	BEGIN
		SELECT issued_book_isbn issued_book_name
		INTO v_book_isbn, v_book_name
		FROM issued_status
		WHERE issued_id = p_issued_id;
	
		INSERT INTO return_status (return_id, issued_id, return_book_name, return_date, return_book_isbn)
		VALUES
		(p_return_id, p_issued_id, v_book_name, CURRENT_DATE, v_book_isbn);
	
		UPDATE books
		SET status = 'yes'
		WHERE isbn = v_book_isbn;
END;
$$

CALL return_books('RS148', 'IS140');



-- Task 15 : Create a query that generates a performance report for each branch, showing the number of books issued, 
-- the number of books returned, and the total revenue generated from book rentals.

SELECT * FROM branch;
SELECT * FROM members;
SELECT * FROM employees;
SELECT * FROM books;
SELECT * FROM issued_status;
SELECT * FROM return_status;


SELECT b.branch_id, 
	b.manager_id,
	COUNT(ist.issued_book_isbn) as no_books_issued,
	COUNT(rs.return_id) as no_of_books_returned,
	SUM(bk.rental_price) as TOTAL_REVENUE
FROM branch b 
JOIN employees e 
ON b.branch_id =  e.branch_id
JOIN 
issued_status ist
ON e.emp_id = ist.issued_emp_id
LEFT JOIN 
return_status rs
ON ist.issued_id = rs.issued_id
JOIN 
books bk 
ON ist.issued_book_isbn = bk.isbn
GROUP BY b.branch_id;


-- Task 16 : Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have
-- issued at least one book in the last 2 months.
SELECT * FROM members;
SELECT * FROM books;
SELECT * FROM issued_status;
SELECT * FROM return_status;


CREATE TABLE active_members
AS
SELECT m.member_id,m.member_name, MAX(ist.issued_date) as last_book_issue_date, 
(CURRENT_DATE - MAX(ist.issued_date)) AS Days_not_active
FROM members m
JOIN issued_status ist
ON m.member_id = ist.issued_member_id
GROUP BY m.member_id
HAVING (CURRENT_DATE - MAX(ist.issued_date)) > 210;



-- Task 17 : Write a query to find the top 3 employees who have processed the most book issues.
-- Display the employee name, number of books processed, and their branch.
SELECT * FROM employees;
SELECT * FROM branch;
SELECT * FROM issued_status;

SELECT ist.issued_emp_id, COUNT(ist.issued_id) as total_books_issued,
e.emp_name,
b.branch_id
FROM issued_status ist
JOIN employees e
ON ist.issued_emp_id = e.emp_id
JOIN branch b
ON e.branch_id = b.branch_id
GROUP BY ist.issued_emp_id, e.emp_name, b.branch_id
ORDER BY total_books_issued DESC
LIMIT 3;



-- Task 18 : Write a query to identify members who have issued books more than twice with the status "damaged" in the books
-- table. Display the member name, book title, and the number of times they've issued damaged books.
SELECT * FROM members;
SELECT * FROM books;
SELECT * FROM issued_status;


-- Task 19 : Stored Procedure

CREATE OR REPLACE PROCEDURE 
issue_books(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(30),p_issued_book_name VARCHAR(50), p_issued_book_isbn VARCHAR(30), p_issued_emp_id VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
	v_status VARCHAR(10);

BEGIN
	SELECT status
	INTO v_status
	FROM books 
	WHERE isbn = p_issued_book_isbn;

	IF v_status = 'yes' THEN

	INSERT INTO issued_status (issued_id, issued_member_id, issued_book_name, issued_date, issued_book_isbn, issued_emp_id)
	VALUES
	(p_issued_id, p_issued_member_id, p_issued_book_name, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);

	UPDATE books
	SET status = 'no'
	WHERE isbn = p_issued_book_isbn;

	RAISE NOTICE 'Book record added successfully for book isbn : %', p_issued_book_isbn;

	ELSE
	RAISE NOTICE 'Sorry!! The requested book is currently unavailable ';

	END IF;
END;

$$

978-0-375-41398-8
The Diary of a Young Girl

CALL issue_books('IS141','C108','Animal Farm','978-0-330-25864-8','E104');
CALL issue_books('IS142','C108','The Diary of a Young Girl','978-0-375-41398-8','E104');

-- Task 20 : CTAS
SELECT * FROM members;
SELECT * FROM books;
SELECT * FROM issued_status;
SELECT * FROM return_status;

CREATE TABLE fine_info 
AS
SELECT ist.issued_member_id, COUNT(ist.issued_id) as no_books_not_returned,
MAX(ist.issued_date) as issued_date,
(CURRENT_DATE - MAX(ist.issued_date)) as days_book_not_returned,
CASE
WHEN (CURRENT_DATE - MAX(ist.issued_date)) > 210 THEN (CURRENT_DATE - MAX(ist.issued_date))*0.5  ELSE 0 END AS Total_fine
FROM issued_status ist
LEFT JOIN return_status rs
ON ist.issued_id = rs.issued_id
WHERE rs.return_id IS NULL
GROUP BY ist.issued_member_id;
