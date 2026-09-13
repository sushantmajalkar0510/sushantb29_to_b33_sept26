create table officedata_bronze
(
   employee_id int,
   employee_name varchar(30),
   department varchar(30),
   state varchar(20),
   salary int,
   age int,
   bonus int,
   updated_at DATETIME default GETDATE()
);

CREATE TABLE officedata_silver
(
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(30),
    department VARCHAR(30),
    state VARCHAR(20),
    salary INT,
    age INT,
    bonus INT,
    updated_at DATETIME
);



INSERT INTO officedata_bronze
(employee_id, employee_name, department, state, salary, age, bonus)
VALUES
(1,'John','IT','Texas',70000,30,5000),
(2,'David','HR','California',60000,35,4000),
(3,'Sarah','Finance','New York',80000,32,7000);
	

select * from officedata_bronze
select * from officedata_silver



CREATE OR ALTER PROCEDURE sp_load_officedata_scd1_update_insert

AS
BEGIN

SET NOCOUNT ON;
------------------------------------------------
-- UPDATE EXISTING RECORDS
------------------------------------------------

UPDATE TARGET

SET

TARGET.employee_name = SOURCE.employee_name,
TARGET.department    = SOURCE.department,
TARGET.state         = SOURCE.state,
TARGET.salary        = SOURCE.salary,
TARGET.age           = SOURCE.age,
TARGET.bonus         = SOURCE.bonus,
TARGET.updated_at    = GETDATE()

FROM officedata_silver TARGET


INNER JOIN officedata_bronze SOURCE


ON TARGET.employee_id = SOURCE.employee_id;



------------------------------------------------
-- INSERT NEW RECORDS
------------------------------------------------


INSERT INTO officedata_silver
(
    employee_id,
    employee_name,
    department,
    state,
    salary,
    age,
    bonus,
    updated_at
)
SELECT
SOURCE.employee_id,
SOURCE.employee_name,
SOURCE.department,
SOURCE.state,
SOURCE.salary,
SOURCE.age,
SOURCE.bonus,
GETDATE() FROM officedata_bronze SOURCE
WHERE NOT EXISTS
(
SELECT 1 FROM officedata_silver TARGET WHERE TARGET.employee_id = SOURCE.employee_id
);

END;

INSERT INTO officedata_bronze
(employee_id, employee_name, department, state, salary, age, bonus)
VALUES
(4,'Sushant','HR','Mumbai',80000,32,7000);

update officedata_bronze set department='IT' where employee_id = 2;


DROP TABLE officedata_bronze

execute sp_load_officedata_scd1_update_insert


CREATE TABLE officedata_silver_scd2 (
    surrogate_key INT IDENTITY(1,1) PRIMARY KEY,
    employee_id int,
    employee_name varchar(30),
    department varchar(30),
    state varchar(20),
    salary int,
    age int,
    bonus int,
    start_date DATETIME,
    end_date DATETIME,
    is_current BIT
);



CREATE OR ALTER PROCEDURE sp_load_officedata_scd2_update_insert

AS
BEGIN

SET NOCOUNT ON;

------------------------------------------------
-- STEP 1
-- CLOSE OLD RECORD
------------------------------------------------
UPDATE TARGET
SET
TARGET.end_date = GETDATE(),
TARGET.is_current = 0
FROM officedata_silver_scd2 TARGET
INNER JOIN officedata_bronze SOURCE
ON TARGET.employee_id = SOURCE.employee_id
AND TARGET.is_current = 1
WHERE
(
TARGET.employee_name <> SOURCE.employee_name
OR TARGET.department <> SOURCE.department
OR TARGET.state <> SOURCE.state
OR TARGET.salary <> SOURCE.salary
OR TARGET.age <> SOURCE.age
OR TARGET.bonus <> SOURCE.bonus
);



------------------------------------------------
-- STEP 2
-- INSERT NEW VERSION
------------------------------------------------


INSERT INTO officedata_silver_scd2
(
employee_id,
employee_name,
department,
state,
salary,
age,
bonus,
start_date,
end_date,
is_current
)

SELECT
SOURCE.employee_id,
SOURCE.employee_name,
SOURCE.department,
SOURCE.state,
SOURCE.salary,
SOURCE.age,
SOURCE.bonus,
GETDATE(),
NULL,
1
FROM officedata_bronze SOURCE WHERE NOT EXISTS
(
SELECT 1 FROM officedata_silver_scd2 TARGET
WHERE TARGET.employee_id = SOURCE.employee_id
AND TARGET.is_current = 1
);

END;

execute sp_load_officedata_scd2_update_insert;


INSERT INTO officedata_bronze
(employee_id, employee_name, department, state, salary, age, bonus)
VALUES
(5,'Shreya','IT','Mumbai',80000,32,7000);

update officedata_bronze set department='HR' where employee_id = 2;



select * from officedata_bronze
select * from officedata_silver_scd2



CREATE OR ALTER PROCEDURE sp_load_officedata_scd2_merge

AS
BEGIN

SET NOCOUNT ON;

------------------------------------------------
-- STEP 1
-- Expire Existing Records
------------------------------------------------

MERGE officedata_silver_scd2 AS TARGET
USING officedata_bronze AS SOURCE
ON TARGET.employee_id = SOURCE.employee_id
AND TARGET.is_current = 1
WHEN MATCHED AND
(
TARGET.employee_name <> SOURCE.employee_name
OR TARGET.department <> SOURCE.department
OR TARGET.state <> SOURCE.state
OR TARGET.salary <> SOURCE.salary
OR TARGET.age <> SOURCE.age
OR TARGET.bonus <> SOURCE.bonus
)

THEN
UPDATE SET
TARGET.end_date = GETDATE(),
TARGET.is_current = 0;

------------------------------------------------
-- STEP 2
-- Insert New Version
------------------------------------------------

INSERT INTO officedata_silver_scd2
(
employee_id,
employee_name,
department,
state,
salary,
age,
bonus,
start_date,
end_date,
is_current
)
SELECT
B.employee_id,
B.employee_name,
B.department,
B.state,
B.salary,
B.age,
B.bonus,
GETDATE(),
NULL,
1
FROM officedata_bronze B
LEFT JOIN officedata_silver_scd2 S
ON B.employee_id=S.employee_id
AND S.is_current=1
WHERE S.employee_id IS NULL;
END;

execute sp_load_officedata_scd2_merge;


INSERT INTO officedata_bronze
(employee_id, employee_name, department, state, salary, age, bonus)
VALUES
(6,'Sukhesh','HR','Mumbai',80000,32,7000);

update officedata_bronze set department='IT' where employee_id = 2;



select * from officedata_bronze
select * from officedata_silver_scd2


CREATE OR ALTER PROCEDURE sp_load_officedata_scd1_merge

AS
BEGIN

SET NOCOUNT ON;

MERGE officedata_silver AS TARGET

USING officedata_bronze AS SOURCE

ON TARGET.employee_id = SOURCE.employee_id

WHEN MATCHED THEN

UPDATE SET

TARGET.employee_name = SOURCE.employee_name,
TARGET.department    = SOURCE.department,
TARGET.state         = SOURCE.state,
TARGET.salary        = SOURCE.salary,
TARGET.age           = SOURCE.age,
TARGET.bonus         = SOURCE.bonus,
TARGET.updated_at    = GETDATE()

WHEN NOT MATCHED BY TARGET THEN

INSERT
(
employee_id,
employee_name,
department,
state,
salary,
age,
bonus,
updated_at
)

VALUES
(
SOURCE.employee_id,
SOURCE.employee_name,
SOURCE.department,
SOURCE.state,
SOURCE.salary,
SOURCE.age,
SOURCE.bonus,
GETDATE()
);

END;

execute sp_load_officedata_scd1_merge;

INSERT INTO officedata_bronze
(employee_id, employee_name, department, state, salary, age, bonus)
VALUES
(7,'Devika','IT','Mumbai',80000,32,7000);

update officedata_bronze set department='IT' where employee_id = 2;



select * from officedata_bronze
select * from officedata_silver
