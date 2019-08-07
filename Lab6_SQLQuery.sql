CREATE DATABASE dennyw_Lab6
USE dennyw_Lab6

-- Create Tables -- 
CREATE TABLE tblCUSTOMER
(CustomerID INT IDENTITY(1,1) PRIMARY KEY
,CustomerFName VARCHAR(50) NOT NULL
,CustomerLName VARCHAR(50) NOT NULL
,DateOfBirth DATE NOT NULL)
GO

CREATE TABLE tblPRODUCT_TYPE
(ProductTypeID INT IDENTITY(1,1) PRIMARY KEY
,ProductTypeName VARCHAR(50) NOT NULL
,ProductTypeDescr VARCHAR(500) NULL)
GO

CREATE TABLE tblPRODUCT
(ProductID INT IDENTITY(1,1) PRIMARY KEY
,ProductName VARCHAR(50) NOT NULL
,ProductTypeID INT FOREIGN KEY REFERENCES tblPRODUCT_TYPE(ProductTypeID) NOT NULL
,ProductPrice DECIMAL(10,2) NOT NULL)
GO

CREATE TABLE tblORDER
(OrderID INT IDENTITY(1,1) PRIMARY KEY
,CustomerID INT FOREIGN KEY REFERENCES tblCUSTOMER(CustomerID) NOT NULL
,ProductID INT FOREIGN KEY REFERENCES tblPRODUCT(ProductID) NOT NULL
,OrderDate DATE NOT NULL
,Quantity INT NOT NULL)
GO

-- Insert sample data --
INSERT INTO tblPRODUCT_TYPE (ProductTypeName, ProductTypeDescr)
VALUES ('Food', 'Anything people eat'), ('Clothing', 'Anything people wear'), ('Furniture', 'Anything people sit on in their house')
GO

INSERT INTO tblPRODUCT (ProductName, ProductTypeID, ProductPrice)
VALUES ('Leather Sofa', 
(SELECT ProductTypeID 
FROM tblPRODUCT_TYPE 
WHERE ProductTypeName = 'Furniture'), 435.99),
('Blue Easy Chair', 
(SELECT ProductTypeID 
FROM tblPRODUCT_TYPE 
WHERE ProductTypeName = 'Furniture'), 135.99),
('Stand-Up 3-Bulb Lamp', 
(SELECT ProductTypeID 
FROM tblPRODUCT_TYPE 
WHERE ProductTypeName = 'Furniture'), 79.99),
('Leather Jacket', 
(SELECT ProductTypeID 
FROM tblPRODUCT_TYPE 
WHERE ProductTypeName = 'Clothing'), 685.99),
('Wool Socks', 
(SELECT ProductTypeID 
FROM tblPRODUCT_TYPE 
WHERE ProductTypeName = 'Clothing'), 5.99),
('Winter Ski Jacket', 
(SELECT ProductTypeID 
FROM tblPRODUCT_TYPE 
WHERE ProductTypeName = 'Clothing'), 185.99),
('Basketball Shoes', 
(SELECT ProductTypeID 
FROM tblPRODUCT_TYPE 
WHERE ProductTypeName = 'Clothing'), 88.99),
('Veggie Pizza', 
(SELECT ProductTypeID 
FROM tblPRODUCT_TYPE 
WHERE ProductTypeName = 'Food'), 15.99),
('Turkey Sandwich', 
(SELECT ProductTypeID 
FROM tblPRODUCT_TYPE 
WHERE ProductTypeName = 'Food'), 7.99),
('Ham Sandwich', 
(SELECT ProductTypeID 
FROM tblPRODUCT_TYPE 
WHERE ProductTypeName = 'Food'), 8.99)
GO

INSERT INTO tblCUSTOMER (CustomerFName, CustomerLName, DateOfBirth)
SELECT TOP 1000 CustomerFName, CustomerLName, DateOfBirth
FROM CUSTOMER_BUILD.dbo.tblCUSTOMER
GO

-- Create GetID Stored Procedures --
CREATE PROCEDURE uspGetCustID
@CustFName VARCHAR(50),
@CustLName VARCHAR(50),
@DOB VARCHAR(50),
@CustID INT OUTPUT
AS
SET @CustID = (SELECT CustomerID FROM tblCUSTOMER WHERE @CustFName = CustomerFName AND
                                                        @CustLName = CustomerLName AND
                                                        @DOB = DateOfBirth)
GO

CREATE PROCEDURE uspGetProdID
@ProdName VARCHAR(50),
@ProdPrice DECIMAL(10,2),
@ProdID INT OUTPUT
AS
SET @ProdID = (SELECT ProductID FROM tblPRODUCT WHERE @ProdName = ProductName AND
                                                      @ProdPrice = ProductPrice)
GO

-- Create Order Insert Stored Procedure -- 
CREATE PROCEDURE uspNewOrder
@Cust_Fname VARCHAR(50),
@Cust_Lname VARCHAR(50),
@Cust_DOB VARCHAR(50),
@Prod_Name VARCHAR(50),
@Prod_Price VARCHAR(50),
@OrdDate DATE,
@Quant INT
AS
DECLARE @C_ID INT, @P_ID INT

EXEC uspGetCustID
@CustFName = @Cust_Fname,
@CustLName = @Cust_Lname,
@DOB = @Cust_DOB,
@CustID = @C_ID OUTPUT

IF @C_ID IS NULL
    BEGIN
        RAISERROR('@C_ID is NULL and the following transaction will fail', 11, 1)
        RETURN
    END

EXEC uspGetProdID
@ProdName = @Prod_Name,
@ProdPrice = @Prod_Price,
@ProdID = @P_ID OUTPUT

IF @P_ID IS NULL
    BEGIN
        RAISERROR('@P_ID is NULL and the following transaction will fail', 11, 1)
        RETURN
    END

BEGIN TRAN T1
    INSERT INTO tblORDER (CustomerID, ProductID, OrderDate, Quantity)
    VALUES (@C_ID, @P_ID, @OrdDate, @Quant)
    IF @@ERROR <> 0
        ROLLBACK TRAN T1
    ELSE
        COMMIT TRAN T1
GO

-- Create Synthetic Transaction Stored Procedure -- 
CREATE PROCEDURE WRAPPER_uspNewOrder
@RUN INT
AS
DECLARE @Fname VARCHAR(50)
DECLARE @Lname VARCHAR(50)
DECLARE @Bdate DATE
DECLARE @Pname VARCHAR(50)
DECLARE @Pprice DECIMAL(10,2)
DECLARE @Odate DATE = (SELECT GetDate())
DECLARE @Oquantity INT

DECLARE @CustPK INT = (SELECT COUNT(*) FROM tblCUSTOMER)
DECLARE @ProdPK INT = (SELECT COUNT(*) FROM tblPRODUCT)

WHILE @RUN > 0
BEGIN
    SET @CustPK = (SELECT @CustPK * RAND())
    SET @ProdPK = (SELECT @ProdPK * RAND())
    IF @ProdPK < 1
    BEGIN
        SET @ProdPK = 2
    END
    IF @CustPK < 1
    BEGIN
        SET @CustPK = 2
    END
    SET @Fname = (SELECT CustomerFName FROM tblCUSTOMER WHERE CustomerID = @CustPK)
    SET @Lname = (SELECT CustomerLName FROM tblCUSTOMER WHERE CustomerID = @CustPK)
    SET @Bdate = (SELECT DateOfBirth FROM tblCUSTOMER WHERE CustomerID = @CustPK)
    SET @Pname = (SELECT ProductName FROM tblPRODUCT WHERE ProductID = @ProdPK)
    SET @Pprice = (SELECT ProductPrice FROM tblPRODUCT WHERE ProductID = @ProdPK)
    SET @Oquantity = (SELECT 7 * RAND())
    EXEC uspNewOrder
    @Cust_Fname = @Fname,
    @Cust_Lname = @Lname,
    @Cust_DOB = @Bdate,
    @Prod_Name = @Pname,
    @Prod_Price = @Pprice,
    @OrdDate = @Odate,
    @Quant = @Oquantity
    SET @RUN = @RUN - 1
END
GO

-- Testing the synthetic transaction/automated wrapper -- 
EXEC WRAPPER_uspNewOrder
@RUN = 100

SELECT * FROM tblCUSTOMER
SELECT * FROM tblPRODUCT
SELECT * FROM tblPRODUCT_TYPE
SELECT * FROM tblORDER

-- Clear Order Table and Reset Identity value to 0 -- 
DELETE FROM tblORDER
DBCC CHECKIDENT ('tblORDER', RESEED, 0);
GO