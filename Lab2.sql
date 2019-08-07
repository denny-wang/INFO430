-- Create the database -- 
CREATE DATABASE INFO430_Lab2_dennyw

-- Connect to the database -- 
USE INFO430_Lab2_dennyw


--- Create Tables ---

-- Create the Customer Table -- 
CREATE TABLE tblCUSTOMER
(CustomerID INT IDENTITY(1,1) PRIMARY KEY
,CustFName VARCHAR(35) NOT NULL
,CustLName VARCHAR(35) NOT NULL
,CustDOB DATE NULL)
GO

-- Create the Product Type Table --
CREATE TABLE tblPRODUCT_TYPE
(ProdTypeID INT IDENTITY(1,1) PRIMARY KEY
,ProdTypeName VARCHAR(50) NOT NULL
,ProdTypeDescr VARCHAR(500) NULL)
GO

-- Create the Product Table --
CREATE TABLE tblPRODUCT 
(ProdID INT IDENTITY(1,1) PRIMARY KEY
,ProdName VARCHAR(50) NOT NULL
,ProdTypeID INT FOREIGN KEY REFERENCES tblPRODUCT_TYPE(ProdTypeID)
,Price NUMERIC(8,2) NOT NULL
,ProdDescr VARCHAR(500) NULL)
GO

-- Create the Employee Table --
CREATE TABLE tblEMPLOYEE 
(EmpID INT IDENTITY(1,1) PRIMARY KEY
,EmpFName VARCHAR(35) NOT NULL
,EmpLName VARCHAR(35) NOT NULL
,EmpDOB DATE NULL)
GO

-- Create the Order Table -- 
CREATE TABLE tblORDER 
(OrderID INT IDENTITY(1,1) PRIMARY KEY
,OrderDate DATE NOT NULL
,CustID INT FOREIGN KEY REFERENCES tblCUSTOMER(CustomerID) NOT NULL
,ProductID INT FOREIGN KEY REFERENCES tblPRODUCT(ProdID) NOT NULL
,EmpID INT FOREIGN KEY REFERENCES tblEMPLOYEE(EmpID) NOT NULL
,Quantity INT NOT NULL)
GO

--- Insert data into Tables ---

INSERT INTO tblCUSTOMER
VALUES ('John', 'Smith', '1-1-1992'), ('Sarah', 'Long', '4-13-1990'), ('Kane', 'Newman', '7-20-1985')
GO

INSERT INTO tblPRODUCT_TYPE
VALUES ('Noodle', ''), ('Rice', ''), ('Drinks', '')
GO

INSERT INTO tblPRODUCT
VALUES ('Chicken Chow Mein', (SELECT ProdTypeID FROM tblPRODUCT_TYPE WHERE ProdTypeName = 'Noodle'), 9.99, 'Stir fried noodles with chicken'),
       ('Chicken Fried Rice', (SELECT ProdTypeID FROM tblPRODUCT_TYPE WHERE ProdTypeName = 'Rice'), 8.99, 'Stir fried rice with chicken'),
       ('Water', (SELECT ProdTypeID FROM tblPRODUCT_TYPE WHERE ProdTypeName = 'Drinks'), 0.99, 'Bottled water')
GO

INSERT INTO tblEMPLOYEE
VALUES ('Kenny', 'Love', '1-8-1992'), ('Kyle', 'Wayne', '4-20-1969'), ('Lauren', 'Wu', '9-15-1995')
GO

-- Use a Stored Procedure to insert data in Order Table --
CREATE PROCEDURE pInsOrder 
(@CustFName VARCHAR(35)
,@CustLName VARCHAR(35)
,@CustDOB DATE
,@EmpFName VARCHAR(35)
,@EmpLName VARCHAR(35)
,@EmpDOB DATE
,@ProdName VARCHAR(50)
,@OrderDate DATE
,@Quantity INT)
AS
BEGIN
-- Set up variables to look-up the ID attribute in the Customer, Product, and Employee Tables
DECLARE @C_ID INT
DECLARE @P_ID INT
DECLARE @E_ID INT

-- Populate the variables with the corresponding ID and Error Handling for missing values
SET @C_ID = (SELECT CustomerID FROM tblCUSTOMER
             WHERE CustFName = @CustFName
             AND CustLName = @CustLName
             AND CustDOB = @CustDOB)

IF @C_ID IS NULL 
    BEGIN
        PRINT 'Wrong or Missing Customer'
        RAISERROR ('Cannot process and order without a real customer', 11, 1)
        RETURN
    END

SET @P_ID = (SELECT ProdID FROM tblPRODUCT
             WHERE ProdName = @ProdName)

IF @P_ID IS NULL 
    BEGIN
        PRINT 'Wrong or Missing Product'
        RAISERROR ('Cannot process and order without a real product', 11, 1)
        RETURN
    END

SET @E_ID = (SELECT EmpID FROM tblEMPLOYEE
             WHERE EmpFName = @EmpFName
             AND EmpLName = @EmpLName
             AND EmpDOB = @EmpDOB)

IF @E_ID IS NULL 
    BEGIN
        PRINT 'Wrong or Missing Employee'
        RAISERROR ('Cannot process and order without a real employee', 11, 1)
        RETURN
    END

-- Processes Insert --
BEGIN TRANSACTION G1
INSERT INTO tblORDER (OrderDate, CustID, ProductID, EmpID, Quantity)
VALUES (@OrderDate, @C_ID, @P_ID, @E_ID, @Quantity)
IF @@ERROR <> 0
    ROLLBACK TRANSACTION G1
ELSE 
    COMMIT TRANSACTION G1
END
GO

-- Populate Order Table using Stored Procedure --
EXECUTE pInsOrder
@CustFname = 'Sarah',
@CustLname = 'Long',
@CustDOB = '4-13-1990',
@EmpFName = 'Lauren',
@EmpLName = 'Wu',
@EmpDOB =  '9-15-1995',
@ProdName = 'Chicken Chow Mein',
@OrderDate = '2-14-2018',
@Quantity = 2

EXECUTE pInsOrder
@CustFname = 'John',
@CustLname = 'Smith',
@CustDOB = '1-1-1992',
@EmpFName = 'Lauren',
@EmpLName = 'Wu',
@EmpDOB =  '9-15-1995',
@ProdName = 'Water',
@OrderDate = '2-15-2018',
@Quantity = 4

EXECUTE pInsOrder
@CustFname = 'Kane',
@CustLname = 'Newman',
@CustDOB = '7-20-1985',
@EmpFName = 'Kenny',
@EmpLName = 'Love',
@EmpDOB =  '1-8-1992',
@ProdName = 'Chicken Fried Rice',
@OrderDate = '2-17-2018',
@Quantity = 1

-- View Tables -- 
SELECT * FROM tblCUSTOMER
SELECT * FROM tblPRODUCT_TYPE
SELECT * FROM tblPRODUCT
SELECT * FROM tblEMPLOYEE
SELECT * FROM tblORDER