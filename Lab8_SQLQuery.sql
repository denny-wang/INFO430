USE UNIVERSITY
GO

-- 1) RANK() + PARTITION
-- * Write the SQL to determine the 300 students with the lowest GPA (all students/classes) during years 1975 -1981 partitioned by StudentPermState.

-- CTE -- 
WITH CTE_300_Students_Lowest_GPA_1975_1981 (StudentID, StudentFname, StudentLname, StudentGPA, [State])
AS
(SELECT TOP 300 S.StudentID, S.StudentFname, S.StudentLname, SUM(CO.Credits * CL.Grade) / SUM(CO.Credits) AS [StudentGPA], S.StudentPermState
FROM tblSTUDENT S
JOIN tblCLASS_LIST CL ON S.StudentID = CL.StudentID
JOIN tblCLASS C ON CL.ClassID = C.ClassID
JOIN tblCOURSE CO ON C.CourseID = CO.CourseID
WHERE C.[YEAR] BETWEEN 1975 AND 1981
GROUP BY S.StudentID, S.StudentFname, S.StudentLname, S.StudentPermState
ORDER BY [StudentGPA])
SELECT StudentID, StudentFname, StudentLname, StudentGPA, RANK() OVER (PARTITION BY [State] ORDER BY StudentGPA) AS Ranking FROM CTE_300_Students_Lowest_GPA_1975_1981
GO

-- Table variable --
DECLARE @TableVar TABLE (
    StudentID INT NOT NULL,
    StudentFname VARCHAR(30) NOT NULL,
    StudentLname VARCHAR(30) NOT NULL,
    StudentGPA NUMERIC(3,2) NOT NULL
)
INSERT INTO @TableVar(StudentID, StudentFname, StudentLname, StudentGPA)
SELECT TOP 300 S.StudentID, S.StudentFname, S.StudentLname, SUM(CO.Credits * CL.Grade) / SUM(CO.Credits) AS [StudentGPA]
FROM tblSTUDENT S
JOIN tblCLASS_LIST CL ON S.StudentID = CL.StudentID
JOIN tblCLASS C ON CL.ClassID = C.ClassID
JOIN tblCOURSE CO ON C.CourseID = CO.CourseID
WHERE C.[YEAR] BETWEEN 1975 AND 1981
GROUP BY S.StudentID, S.StudentFname, S.StudentLname, S.StudentPermState
ORDER BY [StudentGPA]

SELECT T.StudentID, T.StudentFname, T.StudentLname, T.StudentGPA, RANK() OVER (PARTITION BY S.StudentPermState ORDER BY StudentGPA) AS Ranking
FROM @TableVar T JOIN tblSTUDENT S ON T.StudentID = S.StudentID
GO

-- #temp -- 
SELECT TOP 300 S.StudentID, S.StudentFname, S.StudentLname, SUM(CO.Credits * CL.Grade) / SUM(CO.Credits) AS [StudentGPA], RANK() OVER (PARTITION BY S.StudentPermState ORDER BY SUM(CO.Credits * CL.Grade) / SUM(CO.Credits)) AS Ranking
INTO #Temp1
FROM tblSTUDENT S
JOIN tblCLASS_LIST CL ON S.StudentID = CL.StudentID
JOIN tblCLASS C ON CL.ClassID = C.ClassID
JOIN tblCOURSE CO ON C.CourseID = CO.CourseID
WHERE C.[YEAR] BETWEEN 1975 AND 1981
GROUP BY S.StudentID, S.StudentFname, S.StudentLname, S.StudentPermState
ORDER BY [StudentGPA]
SELECT * FROM #Temp1
GO

-- 2) DENSE_RANK()
-- * Write the SQL to determine the 26th highest GPA during the 1970's for all business classes

-- CTE -- 
WITH CTE_26th_GPA_1970_Business (StudentID, StudentFname, StudentLname, StudentGPA, Ranking)
AS
(SELECT S.StudentID, S.StudentFname, S.StudentLname, SUM(CO.Credits * CL.Grade) / SUM(CO.Credits) AS [StudentGPA], DENSE_RANK() OVER (ORDER BY SUM(CO.Credits * CL.Grade) / SUM(CO.Credits) DESC) AS Ranking
FROM tblSTUDENT S
JOIN tblCLASS_LIST CL ON S.StudentID = CL.StudentID
JOIN tblCLASS C ON CL.ClassID = C.ClassID
JOIN tblCOURSE CO ON C.CourseID = CO.CourseID
JOIN tblDEPARTMENT D ON CO.DeptID = D.DeptID
JOIN tblCOLLEGE COL ON D.CollegeID = COL.CollegeID
WHERE C.[YEAR] BETWEEN 1970 and 1979 AND COL.CollegeName = 'Business (Foster)'
GROUP BY S.StudentID, S.StudentFname, S.StudentLname)
SELECT StudentID, StudentFname, StudentLname, StudentGPA, Ranking FROM CTE_26th_GPA_1970_Business
WHERE Ranking = 26
GO

-- Table variable --
DECLARE @TableVar TABLE (
    StudentID INT NOT NULL,
    StudentFname VARCHAR(30) NOT NULL,
    StudentLname VARCHAR(30) NOT NULL,
    StudentGPA NUMERIC(3,2) NOT NULL,
    Ranking INT NOT NULL
)

INSERT INTO @TableVar(StudentID, StudentFname, StudentLname, StudentGPA, Ranking)
SELECT S.StudentID, S.StudentFname, S.StudentLname, SUM(CO.Credits * CL.Grade) / SUM(CO.Credits) AS [StudentGPA], DENSE_RANK() OVER (ORDER BY SUM(CO.Credits * CL.Grade) / SUM(CO.Credits) DESC) AS Ranking
FROM tblSTUDENT S
JOIN tblCLASS_LIST CL ON S.StudentID = CL.StudentID
JOIN tblCLASS C ON CL.ClassID = C.ClassID
JOIN tblCOURSE CO ON C.CourseID = CO.CourseID
JOIN tblDEPARTMENT D ON CO.DeptID = D.DeptID
JOIN tblCOLLEGE COL ON D.CollegeID = COL.CollegeID
WHERE C.[YEAR] BETWEEN 1970 and 1979 AND COL.CollegeName = 'Business (Foster)'
GROUP BY S.StudentID, S.StudentFname, S.StudentLname

SELECT T.StudentID, T.StudentFname, T.StudentLname, T.StudentGPA, T.Ranking
FROM @TableVar T JOIN tblSTUDENT S ON T.StudentID = S.StudentID
WHERE T.Ranking = 26
GO

-- #temp --
SELECT S.StudentID, S.StudentFname, S.StudentLname, SUM(CO.Credits * CL.Grade) / SUM(CO.Credits) AS [StudentGPA], DENSE_RANK() OVER (ORDER BY SUM(CO.Credits * CL.Grade) / SUM(CO.Credits) DESC) AS Ranking
INTO #Temp2
FROM tblSTUDENT S
JOIN tblCLASS_LIST CL ON S.StudentID = CL.StudentID
JOIN tblCLASS C ON CL.ClassID = C.ClassID
JOIN tblCOURSE CO ON C.CourseID = CO.CourseID
JOIN tblDEPARTMENT D ON CO.DeptID = D.DeptID
JOIN tblCOLLEGE COL ON D.CollegeID = COL.CollegeID
WHERE C.[YEAR] BETWEEN 1970 and 1979 AND COL.CollegeName = 'Business (Foster)'
GROUP BY S.StudentID, S.StudentFname, S.StudentLname
SELECT * FROM #Temp2 WHERE #Temp2.Ranking = 26
GO


-- 3) NTILE
-- * Write the SQL to divide ALL students into 100 groups based on GPA for Arts & Sciences classes during 1980's

-- CTE -- 
WITH CTE_Group_GPA_Arts_And_Sci_1980 (StudentID, StudentFname, StudentLname, StudentGPA, Ranking)
AS
(SELECT S.StudentID, S.StudentFname, S.StudentLname, SUM(CO.Credits * CL.Grade) / SUM(CO.Credits) AS [StudentGPA], NTILE(100) OVER (ORDER BY SUM(CO.Credits * CL.Grade) / SUM(CO.Credits) DESC) AS Ranking
FROM tblSTUDENT S
JOIN tblCLASS_LIST CL ON S.StudentID = CL.StudentID
JOIN tblCLASS C ON CL.ClassID = C.ClassID
JOIN tblCOURSE CO ON C.CourseID = CO.CourseID
JOIN tblDEPARTMENT D ON CO.DeptID = D.DeptID
JOIN tblCOLLEGE COL ON D.CollegeID = COL.CollegeID
WHERE C.[YEAR] BETWEEN 1980 and 1989 AND COL.CollegeName = 'Arts and Sciences'
GROUP BY S.StudentID, S.StudentFname, S.StudentLname)
SELECT StudentID, StudentFname, StudentLname, StudentGPA, Ranking FROM CTE_Group_GPA_Arts_And_Sci_1980
GO

-- Table variable --
DECLARE @TableVar TABLE (
    StudentID INT NOT NULL,
    StudentFname VARCHAR(30) NOT NULL,
    StudentLname VARCHAR(30) NOT NULL,
    StudentGPA NUMERIC(3,2) NOT NULL,
    Ranking INT NOT NULL
)

INSERT INTO @TableVar(StudentID, StudentFname, StudentLname, StudentGPA, Ranking)
SELECT S.StudentID, S.StudentFname, S.StudentLname, SUM(CO.Credits * CL.Grade) / SUM(CO.Credits) AS [StudentGPA], NTILE(100) OVER (ORDER BY SUM(CO.Credits * CL.Grade) / SUM(CO.Credits) DESC) AS Ranking
FROM tblSTUDENT S
JOIN tblCLASS_LIST CL ON S.StudentID = CL.StudentID
JOIN tblCLASS C ON CL.ClassID = C.ClassID
JOIN tblCOURSE CO ON C.CourseID = CO.CourseID
JOIN tblDEPARTMENT D ON CO.DeptID = D.DeptID
JOIN tblCOLLEGE COL ON D.CollegeID = COL.CollegeID
WHERE C.[YEAR] BETWEEN 1980 and 1989 AND COL.CollegeName = 'Arts and Sciences'
GROUP BY S.StudentID, S.StudentFname, S.StudentLname

SELECT T.StudentID, T.StudentFname, T.StudentLname, T.StudentGPA, T.Ranking
FROM @TableVar T JOIN tblSTUDENT S ON T.StudentID = S.StudentID
GO

-- #temp -- 
SELECT S.StudentID, S.StudentFname, S.StudentLname, SUM(CO.Credits * CL.Grade) / SUM(CO.Credits) AS [StudentGPA], NTILE(100) OVER (ORDER BY SUM(CO.Credits * CL.Grade) / SUM(CO.Credits) DESC) AS Ranking
INTO #Temp3
FROM tblSTUDENT S
JOIN tblCLASS_LIST CL ON S.StudentID = CL.StudentID
JOIN tblCLASS C ON CL.ClassID = C.ClassID
JOIN tblCOURSE CO ON C.CourseID = CO.CourseID
JOIN tblDEPARTMENT D ON CO.DeptID = D.DeptID
JOIN tblCOLLEGE COL ON D.CollegeID = COL.CollegeID
WHERE C.[YEAR] BETWEEN 1980 and 1989 AND COL.CollegeName = 'Arts and Sciences'
GROUP BY S.StudentID, S.StudentFname, S.StudentLname
SELECT * FROM #Temp3