-- 1. Write the stored procedure to populate one row in PLANE_MAINTENANCE table using the following:
-- a) Nested stored procedures to obtain FKs PlaneID and MaintenanceID
-- b) Error-handling for any required values that are NULL
-- c) Explicit transaction

CREATE PROCEDURE uspGetPlaneID
@Pname VARCHAR(50),
@PID INT OUTPUT
AS
SET @PID = (SELECT PlaneID FROM tblPLANE WHERE PlaneName = @PName)
GO

CREATE PROCEDURE uspGetMaintenanceID
@Mname VARCHAR(50),
@MID INT OUTPUT
AS
SET @MID = (SELECT MaintenanceID FROM tblMAINTENANCE WHERE MaintenanceName = @Mname)
GO

CREATE PROCEDURE uspInsIntoPlaneMaintenance
@P_name VARCHAR(50),
@M_name VARCHAR(50),
@PlaneMaintDate DATE
AS

IF @P_name IS NULL OR @M_name IS NULL
BEGIN
    RAISERROR('Parameters cannot be NULL', 11, 1)
    RETURN
END

DECLARE @P_ID INT, @M_ID INT

EXEC uspGetPlaneID
@Pname = @P_name,
@PID = @P_ID OUTPUT

IF @P_ID IS NULL
BEGIN
    RAISERROR('@P_ID cannot be NULL', 11, 1)
    RETURN
END

EXEC uspGetMaintenanceID
@Mname = @M_name,
@MID = @M_ID OUTPUT

IF @M_ID IS NULL
BEGIN
    RAISERROR('@M_ID cannot be NULL', 11, 1)
    RETURN
END

BEGIN TRAN G1
    INSERT INTO tblPLANE_MAINTENANCE (PlaneID, MaintenanceID, PlaneMaintDate)
    VALUES (@P_ID, @M_ID, @PlaneMaintDate)
    IF @@ERROR <> 0 
        ROLLBACK TRAN G1
    ELSE 
        COMMIT TRAN G1
GO

-- 2. Write the SQL code to create a computed column to track the total number of bookings for each customer
CREATE FUNCTION fn_TotalBookingsForCustomer(@PK INT)
RETURNS INT
AS
BEGIN
    DECLARE @Ret INT = (
        SELECT COUNT(BookingID) 
        FROM tblCUSTOMER C 
        JOIN tblBOOKING B ON C.CustomerID = B.CustomerID
        WHERE C.CustomerID = @PK
    )
    RETURN @Ret
END
GO

ALTER TABLE tblCUSTOMER 
ADD TotalBookings AS (dbo.fn_TotalBookingsForCustomer(CustomerID))
GO

-- 3. Write the SQL code to enforce the following business rule:
-- "No employee younger than 21 may be scheduled on a flight as crew chief"
CREATE FUNCTION fn_NoEmployeeUnder21CrewChief()
RETURNS INT
AS
BEGIN  
    DECLARE @Ret INT = 0
    IF EXISTS (SELECT *
               FROM tblEMPLOYEE E 
               JOIN tblFLIGHT_EMPLOYEE FE ON E.EmployeeID = FE.EmployeeID
               JOIN tblROLE R ON FE.RoleID = R.RoleID
               WHERE E.EmployeeDOB > (SELECT GETDATE() - (365.25 * 21))
               AND R.RoleName = 'crew chief')
    BEGIN
        SET @Ret = 1
    END
    RETURN @Ret
END
GO

ALTER TABLE tblFLIGHT_EMPLOYEE
ADD CONSTRAINT CK_NoEmployeeUnder21CrewChief
CHECK (dbo.fn_NoEmployeeUnder21CrewChief() = 0)
GO

-- 4. Write the SQL code to determine which customers meet all four of the following conditions:
-- a) have had at least 3 flights arriving into SEATAC airport since May 4, 2011
-- b) have had no more than 7 flights departing from Seoul/Inchon since November 12, 2010 
-- c) have booked flights with more than $10,750 in fares in 2017
-- d) have booking fees of less than $3,300 for 'excessive luggage' between June and September 2014 
WITH CTE_A (CustomerID, Fname, Lname, NumOfFlights)
AS
(SELECT C.CustomerID, C.CustomerFname, C.CustomerLname, COUNT(*) AS NumOfFlights
 FROM tblCUSTOMER C 
 JOIN tblBOOKING B ON C.CustomerID = B.CustomerID
 JOIN tblFLIGHT F ON B.FlightID = F.FlightID
 JOIN tblAIRPORT A ON F.ArrivalAirportID = A.AirportID
 WHERE A.AirportName = 'SEATAC' AND F.ScheduledArrival > '5/4/2011'
 GROUP BY C.CustomerID, C.CustomerFname, C.CustomerLname
 HAVING COUNT(*) >= 3),
CTE_B (CustomerID, Fname, Lname, NumOfFlights)
AS
(SELECT C.CustomerID, C.CustomerFname, C.CustomerLname, COUNT(*) AS NumOfFlights
 FROM tblCUSTOMER C
 JOIN tblBOOKING B ON C.CustomerID = B.CustomerID
 JOIN tblFLIGHT F ON B.FlightID = F.FlightID
 JOIN tblAIRPORT A ON F.DepartAirportID = A.AirportID
 JOIN tblCITY CI ON A.CityID = CI.CityID
 WHERE CI.CityName = 'Seoul' AND CI.CityName = 'Inchon' AND F.ScheduledDepart > '11/12/2010'
 GROUP BY C.CustomerID, C.CustomerFname, C.CustomerLname
 HAVING COUNT(*) <= 7),
CTE_C (CustomerID , Fname, Lname, TotalFares)
AS
(SELECT C.CustomerID, C.CustomerFname, C.CustomerLname, SUM(Fare) AS TotalFares
 FROM tblCUSTOMER C 
 JOIN tblBOOKING B ON C.CustomerID = B.CustomerID
 JOIN tblFLIGHT F ON B.FlightID = F.FlightID
 WHERE F.ScheduledDepart BETWEEN '1/1/2017' AND '12/31/2017'
 GROUP BY C.CustomerID, C.CustomerFname, C.CustomerLname
 HAVING SUM(Fare) > 10750),
CTE_D (CustomerID, Fname, Lname, TotalFees)
AS
(SELECT C.CustomerID, C.CustomerFname, C.CustomerLname, SUM(FeeAmount) AS TotalFees
 FROM tblCUSTOMER C 
 JOIN tblBOOKING B ON C.CustomerID = B.CustomerID
 JOIN tblBOOKING_FEE BF ON B.BookingID = BF.BookingID
 JOIN tblFEE F ON BF.FeeID = F.FeeID
 JOIN tblFEE_TYPE FT ON F.FeeTypeID = FT.FeeTypeID
 WHERE FT.FeeTypeName = 'excessive luggage' AND B.BookDateTime BETWEEN '6/1/2014' AND '9/31/2014'
 GROUP BY C.CustomerID, CustomerFname, CustomerLname
 HAVING SUM(FeeAmount) < 3300)

SELECT CustomerID, CustomerFname, CustomerLname, NumOfFlights, TotalFares, TotalFees
FROM CTE_A A 
JOIN CTE_B B ON A.CustomerID = B.CustomerID
JOIN CTE_C C ON B.CustomerID = C.CustomerID
JOIN CTE_D D ON C.CustomerID = D.CustomerID
GO

-- 5. Write the SQL code to enforce the following business rule:
-- "Pilots under 35 years old cannot fly into North American airports more than 21 times in any given year."
CREATE FUNCTION fn_PilotsUnder35NoMoreThan21IntoNA()
RETURNS INT
AS
BEGIN
    DECLARE @Ret INT = 0
    IF EXISTS (SELECT * FROM tblFLIGHT F
               JOIN tblFLIGHT_EMPLOYEE FE ON F.FlightID = FE.FlightID
               JOIN tblROLE R ON FE.RoleID = R.RoleID
               JOIN tblEMPLOYEE E ON FE.EmployeeID = E.EmployeeID 
               JOIN tblAIRPORT A ON F.DepartAirportID = A.AirportID
               JOIN tblCITY C ON A.CityID = C.CityID 
               JOIN tblCOUNTRY CO ON C.CountyID = CO.CountyID
               JOIN tblREGION R ON CO.RegionID = R.RegionID
               WHERE R.RoleName = 'Pilot' AND R.RegionName = 'North America'
               AND E.EmployeeDOB > (SELECT GETDATE() - (365.25 * 35))
               AND COUNT(F.FlightID) > 21)
               -- Not sure how to count by year --
    BEGIN
        SET @Ret = 1
    END
    RETURN @Ret
END
GO

ALTER TABLE tblFLIGHT_EMPLOYEE
ADD CONSTRAINT CK_PilotsUnder35NoMoreThan21IntoNA
CHECK (dbo.fn_PilotsUnder35NoMoreThan21IntoNA() = 0)
GO

-- 6. Write the SQL code to divide customers into quartiles by the number of total flights booked in the past 9 years. 
SELECT C.CustomerID, C.CustomerFname, C.CustomerLname, NTILES(5) OVER (ORDER BY COUNT(*))
FROM tblCUSTOMER C 
JOIN tblBOOKING B ON C.CustomerID = B.CustomerID
WHERE BookDateTime > (SELECT GETDATE() - (365.25 * 9))
GROUP BY C.CustomerID, C.CustomerFname, C.CustomerLname