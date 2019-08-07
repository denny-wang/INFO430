CREATE DATABASE dennyw_Lab7
USE dennyw_Lab7

-- Create Tables --
CREATE TABLE tblSTUDENT
(StudentID INT IDENTITY(1,1) PRIMARY KEY,
 StudentFName VARCHAR(50) NOT NULL,
 StudentLName VARCHAR(50) NOT NULL,
 StudentDOB DATE NOT NULL)
GO

CREATE TABLE tblBUILDING
(BuildingID INT IDENTITY(1,1) PRIMARY KEY,
 BuildingName VARCHAR(50) NOT NULL,
 BuildingDescr VARCHAR(500) NULL)
GO

CREATE TABLE tblUNIT
(UnitID INT IDENTITY(1,1) PRIMARY KEY,
 BuildingID INT FOREIGN KEY REFERENCES tblBUILDING (BuildingID) NOT NULL,
 UnitName VARCHAR(50) NOT NULL,
 UnitDescr VARCHAR(500) NULL)
GO

CREATE TABLE tblLEASE
(LeaseID INT IDENTITY(1,1) PRIMARY KEY,
 StudentID INT FOREIGN KEY REFERENCES tblSTUDENT (StudentID) NOT NULL,
 UnitID INT FOREIGN KEY REFERENCES tblUNIT (UnitID) NOT NULL,
 BeginDate DATE NOT NULL,
 MonthyPayment DECIMAL(10,2) NOT NULL,
 EndDate DATE NOT NULL)
GO

-- Populate tables with sample data --
INSERT INTO tblSTUDENT (StudentFName, StudentLName, StudentDOB)
VALUES ('John', 'Smith', '10-05-1995'), ('Sarah', 'Curran', '07-21-1997'), ('Dennis', 'Myers', '01-16-1994')
GO

INSERT INTO tblBUILDING (BuildingName, BuildingDescr)
VALUES ('Alder Hall', 'Located in West Campus'), ('Madrona Hall', 'Located in North Campus'), ('Stevens Court', 'Located in West Campus')
GO

INSERT INTO tblUNIT (BuildingID, UnitName, UnitDescr)
VALUES ((SELECT BuildingID FROM tblBUILDING WHERE BuildingName = 'Alder Hall'), '350', 'Third Floor'),
       ((SELECT BuildingID FROM tblBUILDING WHERE BuildingName = 'Madrona Hall'), '245', 'Second Floor'),
       ((SELECT BuildingID FROM tblBUILDING WHERE BuildingName = 'Stevens Court'), '405-A', 'Fourth Floor')
GO

-- Create GetIDs Stored Procedures --
CREATE PROCEDURE uspGetStudentID
@StuFName VARCHAR(50),
@StuLName VARCHAR(50),
@StuBirthDate DATE,
@StuID INT OUTPUT
AS
SET @StuID = (SELECT StudentID FROM tblSTUDENT WHERE StudentFName = @StuFName AND
                                                     StudentLName = @StuLName AND
                                                     StudentDOB = @StuBirthDate)
GO

CREATE PROCEDURE uspGetUnitID 
@UnName VARCHAR(50),
@UnID INT OUTPUT
AS
SET @UnID = (SELECT UnitID FROM tblUNIT WHERE UnitName = @UnName)
GO

-- Create Insert Stored Procedure -- 
CREATE PROCEDURE uspInsIntoLease
@S_FName VARCHAR(50),
@S_LName VARCHAR(50),
@S_BirthDate DATE,
@U_Name VARCHAR(50),
@BeginDate DATE,
@MonthlyPayment DECIMAL(10,2),
@EndDate DATE
AS
-- Include error-handling that terminates the processing before the transaction 
-- if the student is younger than 21 at the time of the Lease and the duration of the lease is greater than 1 year
IF @S_BirthDate > (SELECT GETDATE() - (365.25 * 21))
BEGIN
    IF (SELECT DATEDIFF(YEAR, @BeginDate, @EndDate)) > 1
        BEGIN
            RAISERROR('Student is younger than 21 and lease is greater than 1 year', 11, 1)
            RETURN
        END
END

DECLARE @S_ID INT, @U_ID INT

EXEC uspGetStudentID 
@StuFName = @S_FName,
@StuLName = @S_LName,
@StuBirthDate = @S_BirthDate,
@StuID = @S_ID OUTPUT

IF @S_ID IS NULL
BEGIN  
    RAISERROR('@S_ID cannot be NULL', 11, 1)
    RETURN
END

EXEC uspGetUnitID
@UnName = @U_Name,
@UnID = @U_ID OUTPUT

IF @U_ID IS NULL
BEGIN
    RAISERROR('@U_ID cannot be NULL', 11, 1)
    RETURN
END

BEGIN TRAN G1
    INSERT INTO tblLEASE (StudentID, UnitID, BeginDate, MonthyPayment, EndDate)
    VALUES (@S_ID, @U_ID, @BeginDate, @MonthlyPayment, @EndDate)
    IF @@ERROR <> 0
        ROLLBACK TRAN G1
    ELSE 
        COMMIT TRAN G1
GO