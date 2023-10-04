/*
Cleaning Data in SQL Queries
*/

USE [PortfolioProject]
GO

--Fetch TOP 100 record from NashvilleHousing
SELECT TOP 100 * 
FROM NashvilleHousing 

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format(Because Timestamp value is recorded as 00:00:00.000)

SELECT SaleDate, CAST(SaleDate AS Date) AS SaleDateConverted  --Can also use CONVERT("Date", SaleDate) to format Date
FROM NashvilleHousing 


-- Adding new column SaleDateConverted and updating it with SaleDate in Date format
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date

UPDATE NashvilleHousing
SET SaleDateConverted = CAST(SaleDate AS Date)


--------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data if it is null

SELECT *
FROM NashvilleHousing 
--Where PropertyAddress is null
ORDER BY ParcelID 

/*
See UniqueID 38077 and 43076. Both Having same ParcelID 025 07 0 031.00, So PropertyAddress for both should be same, in 2nd record it is null.
So we can update the 2nd record's null PropertyAddress with 1st record PropertyAddress
*/

SELECT NH1.ParcelID AS NH1ParcelId, NH1.PropertyAddress AS NH1PropertyAddress, 
	NH2.ParcelID AS NH2ParcelId, NH2.PropertyAddress AS NH2PropertyAddress, 
	ISNULL(NH1.PropertyAddress, NH2.PropertyAddress) AS UpdatedNH1PropertyAddress
FROM NashvilleHousing NH1
JOIN NashvilleHousing NH2
ON NH1.ParcelID = NH2.ParcelID
AND NH1.[UniqueID ] <> NH2.[UniqueID ]
WHERE NH1.PropertyAddress IS NULL


-- Populating the NULL PropertyAddress to correct value with the same Parcel ID's address but different UniqueID

UPDATE NH1
SET PropertyAddress = ISNULL(NH1.PropertyAddress, NH2.PropertyAddress)
FROM NashvilleHousing NH1
JOIN NashvilleHousing NH2
ON NH1.ParcelID = NH2.ParcelID
AND NH1.[UniqueID ] <> NH2.[UniqueID ]
WHERE NH1.PropertyAddress IS NULL


SELECT *
FROM NashvilleHousing 
--Where PropertyAddress is null
--WHERE [UniqueID ] in (38077,43076)
ORDER BY ParcelID 

--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (HouseNo, Street, City)

-- Splitting PropertyAddress

SELECT PropertyAddress, 
SUBSTRING("PropertyAddress", 1, CHARINDEX(',', PropertyAddress)-1) AS PropertySplitAddress,  --Splitting the 1st part before comma as address
SUBSTRING("PropertyAddress", CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS PropertySplitCity  --Splitting the last part after comma as City
FROM NashvilleHousing 


ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255), PropertySplitCity NVARCHAR(255)


UPDATE NashvilleHousing
SET 
PropertySplitAddress = SUBSTRING("PropertyAddress", 1, CHARINDEX(',', PropertyAddress)-1),
PropertySplitCity = SUBSTRING("PropertyAddress", CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))


-- Splitting OwnerAddress


SELECT OwnerAddress, 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address,  --Parsing with occurence of . from end
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
FROM NashvilleHousing 


ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255), OwnerSplitCity NVARCHAR(255), OwnerSplitState NVARCHAR(255)


UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


--------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2 DESC


SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant END AS NewSoldAsVacant
FROM NashvilleHousing


-- Updating the SoldAsVacant with 'Yes' for 'Y' and 'No' for 'N'
UPDATE NashvilleHousing
SET SoldAsVacant = CASE 
					WHEN SoldAsVacant = 'Y' THEN 'Yes'
					WHEN SoldAsVacant = 'N' THEN 'No'
					ELSE SoldAsVacant
					END


-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

--Storing all the duplicate records in a temporary table and not performing hard delete on the original table

DROP TABLE IF EXISTS #duplicateRecords
--CREATE TABLE #duplicateRecords
--(
--UniqueID float,
--ParcelID NVARCHAR(255),
--PropertyAddress NVARCHAR(255),
--SalePrice FLOAT,
--SaleDate DATETIME,
--LegalReference NVARCHAR(255),
--Row_num INT
--)


WITH RowNumCTE (UniqueID, ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference, row_num) AS
(
SELECT UniqueID, ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) AS 'row_num'

FROM NashvilleHousing
)
--INSERT INTO #DuplicateRecords (UniqueID, ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference, Row_num) 
SELECT * INTO #DuplicateRecords FROM
(
SELECT UniqueID, ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference, Row_num  FROM RowNumCTE
WHERE row_num > 1
--ORDER BY ParcelID
) AS TEMP
ORDER BY ParcelID

SELECT * FROM #DuplicateRecords ORDER BY ParcelID
SELECT * FROM NashvilleHousing WHERE ParcelID='081 10 0 313.00' -- Checking the duplicate record for a single ParcelID

---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

Select *
From NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate, PropertyAddress, OwnerAddress

---------------------------------------------------------------------------------------------------------

--Update missing values in OwnerName, TaxDistrict column

UPDATE NashvilleHousing
SET
OwnerName = 'Not available'
WHERE OwnerName is NULL

UPDATE NashvilleHousing
SET
TaxDistrict = 'Not available'
WHERE TaxDistrict is NULL

---------------------------------------------------------------------------------------------------------
