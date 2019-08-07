USE MovieDB

-- What is the shortest movie? --
SELECT TOP 1 movieTitle, movieRuntime
FROM tblMovie 
WHERE movieRuntime IS NOT NULL
ORDER BY movieRuntime ASC
GO

-- What is the movie with the most number of votes? --
SELECT TOP 1 movieTitle, movieVoteCount
FROM tblMovie
ORDER BY movieVoteCount DESC
GO

-- Which movie made the most net profit? --
SELECT TOP 1 movieTitle, (movieRevenue - movieBudget) AS Profit
FROM tblMovie
ORDER BY (movieRevenue - movieBudget) DESC
GO

-- Which movie lost the most money? --
SELECT TOP 1 movieTitle, (movieRevenue - movieBudget) AS [Money Lost]
FROM tblMovie
WHERE movieRevenue > 0
ORDER BY (movieRevenue - movieBudget) ASC

-- How many movies were made in the 80’s? --
SELECT COUNT(movieReleaseDate) AS [Number of Movies]
FROM tblMovie
WHERE movieReleaseDate BETWEEN '1980-01-01' AND '1989-12-31'
GO

-- What is the most popular movie released in the year 1980? -- 
SELECT TOP 1 movieTitle, moviePopularity
FROM tblMovie
WHERE movieReleaseDate LIKE '1980%'
ORDER BY moviePopularity DESC
GO

-- How long was the longest movie made before 1900? --
SELECT TOP 1 movieTitle, movieRuntime
FROM tblMovie
WHERE movieReleaseDate < '1900-01-01'
ORDER BY movieRuntime DESC
GO

-- Which language has the shortest movie? --
SELECT TOP 1 languageName, movieTitle
FROM tblMovie AS M JOIN tblLanguage as L
ON M.languageID = L.languageID
WHERE movieRuntime IS NOT NULL
ORDER BY movieRuntime ASC
GO

-- Which collection has the highest total popularity? --
SELECT TOP 1 collectionName, SUM(moviePopularity) AS totalPopularity
FROM tblMovie AS M JOIN tblCollection as C
ON M.collectionID = C.collectionID
WHERE moviePopularity IS NOT NULL
GROUP BY collectionName
ORDER BY totalPopularity DESC
GO 

-- Which language has the most movies in production or post-production? --
SELECT TOP 1 L.languageName, COUNT(L.languageName) AS [Number of Movies]
FROM tblMovie AS M JOIN tblLanguage as L
ON M.languageID = L.languageID
JOIN tblStatus AS S ON M.statusID = S.statusID
WHERE S.statusName = 'In Production' OR S.statusName = 'Post Production'
GROUP BY L.languageName
ORDER BY [Number of Movies] DESC
GO

-- What was the most expensive movie that ended up getting canceled? --
SELECT TOP 1 movieTitle, movieBudget, statusName
FROM tblMovie AS M JOIN tblLanguage as L
ON M.languageID = L.languageID
JOIN tblStatus AS S ON M.statusID = S.statusID
WHERE S.statusName = 'Canceled'
ORDER BY movieBudget DESC
GO

-- How many collections have movies that are in production for the language French (FR) --
SELECT L.languageCode, S.statusName, COUNT(C.collectionID) AS [Number of Collections]
FROM tblMovie AS M JOIN tblCollection as C
ON M.collectionID = C.collectionID
JOIN tblStatus AS S ON M.statusID = S.statusID
JOIN tblLanguage AS L ON M.languageID = L.languageID
WHERE S.statusName = 'In Production' AND L.languageCode = 'fr'
GROUP BY L.languageCode, S.statusName
GO

-- List the top ten rated movies that have received more than 5000 votes --
SELECT TOP 10 movieTitle, movieVoteAverage, movieVoteCount
FROM tblMovie
WHERE movieVoteCount > 5000
ORDER BY movieVoteAverage DESC
GO

-- Which collection has the most movies associated with it? --
SELECT TOP 1 collectionName, COUNT(movieTitle) AS [Number of Movies]
FROM tblMovie AS M JOIN tblCollection as C
ON M.collectionID = C.collectionID
GROUP BY collectionName
ORDER BY [Number of Movies] DESC
GO 

-- What is the collection with the longest total duration? --
SELECT TOP 1 collectionName, SUM(movieRuntime) AS [Total Duration]
FROM tblMovie AS M JOIN tblCollection as C
ON M.collectionID = C.collectionID
GROUP BY collectionName
ORDER BY [Total Duration] DESC
GO 

-- Which collection has made the most net profit? --
SELECT TOP 1 collectionName, SUM(movieRevenue - movieBudget) AS [Net Profit]
FROM tblMovie AS M JOIN tblCollection as C
ON M.collectionID = C.collectionID
GROUP BY collectionName
ORDER BY [Net Profit] DESC
GO 

-- List the top 100 movies by their duration from longest to shortest --
SELECT TOP 100 movieTitle, movieRuntime 
FROM tblMovie
ORDER BY movieRuntime DESC
GO

-- Which languages have more than 25,000 movies associated with them? --
SELECT languageCode, languageName, COUNT(movieID) AS [Number of Movies]
FROM tblMovie AS M JOIN tblLanguage AS L
ON M.languageID = L.languageID
GROUP BY languageCode, languageName
HAVING COUNT(movieID) > 25000
GO

-- Which collections had all their movies made in the 80’s? --
SELECT collectionName, COUNT(movieTitle) AS [Number of Movies Made in the 80s]
FROM tblMovie AS M JOIN tblCollection AS C
ON M.collectionID = C.collectionID
WHERE movieReleaseDate BETWEEN '1980-01-01' AND '1989-12-31'
GROUP BY collectionName
GO

-- In the language that has the most number of movies in the database, how many movies start with “The”? (You may not hard-code a language) --
SELECT TOP 1 languageCode
, languageName
, COUNT(movieID) AS [Number of Movies]
, COUNT(CASE WHEN movieTitle LIKE 'The%' THEN 1 ELSE NULL END) AS [Number of Movies that start with "The"]
FROM tblMovie AS M JOIN tblLanguage AS L
ON M.languageID = L.languageID
GROUP BY languageCode, languageName
ORDER BY [Number of Movies] DESC
