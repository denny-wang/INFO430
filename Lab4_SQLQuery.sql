CREATE DATABASE dennyw_Lab4
GO

USE dennyw_Lab4
GO

USE Group2_Lab4
GO


CREATE TABLE tblCUSTOMER 
(CustID INT IDENTITY(1,1) PRIMARY KEY
,FName VARCHAR(255) NOT NULL
,LName VARCHAR(255) NOT NULL
,BirthDate DATE
,StreetAddress VARCHAR(255)
,City VARCHAR(255)
,State VARCHAR(255)
,Zip INT)
GO

CREATE TABLE tblORDER
(OrderID INT IDENTITY(1,1) PRIMARY KEY
,OrderDate DATE NOT NULL
,CustID INT FOREIGN KEY REFERENCES tblCUSTOMER(CustID) NOT NULL
,OrderTotal DECIMAL(10,2) NOT NULL)
GO

CREATE TABLE tblPRODUCT
(ProductID INT IDENTITY(1,1) PRIMARY KEY
,ProductName VARCHAR(255) NOT NULL
,Price DECIMAL(10,2) NOT NULL
,ProductDescr VARCHAR(255))
GO

CREATE TABLE tblCART
(CartID INT IDENTITY(1,1) PRIMARY KEY
,CustID INT FOREIGN KEY REFERENCES tblCUSTOMER(CustID) NOT NULL
,ProductID INT FOREIGN KEY REFERENCES tblPRODUCT(ProductID) NOT NULL
,Quantity INT)
GO

CREATE TABLE tblLINE_ITEM
(OrderProductID INT IDENTITY(1,1) PRIMARY KEY
,OrderID INT FOREIGN KEY REFERENCES tblORDER(OrderID) NOT NULL
,ProductID INT FOREIGN KEY REFERENCES tblPRODUCT(ProductID) NOT NULL
,Qty INT
,PriceExtended DECIMAL(10,2))
GO

-- 1) Populate tblCART with a stored procedure; parameters are going to be Fname, Lname, BirthDate, ProductName, Quantity and Date. -- 

CREATE PROCEDURE uspInsIntoCart
@Fname VARCHAR(255),
@Lname VARCHAR(255),
@BirthDate DATE,
@ProductName VARCHAR(255),
@Quantity INT,
@Date DATE
AS
DECLARE @C_ID INT, @P_ID INT
SET @C_ID = (SELECT CustID FROM tblCUSTOMER
             WHERE Fname = @Fname
             AND LName = @Lname
             AND BirthDate = @BirthDate)
SET @P_ID = (SELECT ProductID FROM tblPRODUCT
             WHERE ProductName = @ProductName)
BEGIN TRAN T1 
INSERT INTO tblCART(CustID, ProductID, Quantity)
VALUES (@C_ID, @P_ID, @Quantity)
IF @@ERROR <> 0 
    ROLLBACK TRAN T1
ELSE
    COMMIT TRAN T1
GO

-- 2) Write two stored procedures to get the required foreign key values in tblORDER (CustID and ProdID) -- 
CREATE PROCEDURE sp_getCustID
@Fname_RC varchar(255),
@Lname_RC varchar(255),
@BirthDate_RC date,
@StreetAddress_RC varchar(255),
@City_RC varchar(255),
@State_RC varchar(255),
@Zip_RC int,
@CustID int output
AS
IF (@Fname_RC IS NULL OR
    @Lname_RC IS NULL OR
    @BirthDate_RC IS NULL OR
    @StreetAddress_RC IS NULL OR
    @City_RC IS NULL OR
    @State_RC IS NULL OR
    @Zip_RC IS NULL)
		BEGIN
		    PRINT 'Customer Parameters Missing'
		    RAISERROR ('Cannot process without a customer parameters', 11,1)
		    RETURN
		END
SET @CustID=(SELECT CustID FROM tblCUSTOMER
	WHERE Fname=@Fname_RC
	AND Lname=@Lname_RC
    AND BirthDate=@BirthDate_RC
    AND StreetAddress=@StreetAddress_RC
    AND City=@City_RC
    AND State=@State_RC
    AND Zip=@Zip_RC)
GO

CREATE PROCEDURE sp_getProdID
@ProductName_RC varchar(255),
@Price_RC decimal(10,2),
@ProdID int output
AS
IF (@ProductName_RC IS NULL OR
    @Price_RC IS NULL)
		BEGIN
		    PRINT 'Product Parameters Missing'
		    RAISERROR ('Cannot process without a product parameters', 11,1)
		    RETURN
		END
SET @ProdID = (SELECT ProductID FROM tblPRODUCT
	          WHERE ProductName=@ProductName_RC
	          AND Price=@Price_RC)
GO

-- 3) Write the SQL stored procedure to process the contents of tblCART based on a customer first name, last name and BirthDate.  --
CREATE PROC uspCart
@FN varchar(30), 
@LN varchar(30),
@BD Date, 
@PN varchar(30),  
@Q INT
AS
Begin
  DECLARE @CustID INT 
  DECLARE @ProdID INT
  
SET @CustID = (SELECT CustID FROM tblCUSTOMER
		WHERE Fname = @FN
		AND Lname = @LN
		AND BirthDate = @BD) 

IF @CustID IS NULL
		BEGIN
		PRINT 'Customer is not specified.'
		RAISERROR ('Cannot process without a real customer', 11,1)
		RETURN
		END

SET @ProdID = (SELECT ProductID FROM tblPRODUCT
		WHERE ProductName = @PN)

IF @ProdID IS NULL
		BEGIN
		PRINT 'Product is not specified.'
		RAISERROR ('Cannot process without a real product', 11,1)
		RETURN
		END

BEGIN TRAN G1
INSERT INTO tblCART (CustID, ProductID, Quantity)
VALUES (@CustID, @ProdID, @Q)
IF @@ERROR <> 0
	ROLLBACK TRAN G1
ELSE
	COMMIT TRAN G1
END
