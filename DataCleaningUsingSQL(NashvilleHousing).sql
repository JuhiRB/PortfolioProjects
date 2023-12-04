
-- Cleaning Data 

SELECT *
FROM Project_Housing..Nashville_Housing

-- Standardizing SaleDate

ALTER TABLE Project_Housing..Nashville_Housing
ADD SaleDateConverted DATE;

UPDATE Project_Housing..Nashville_Housing
SET SaleDateConverted = CONVERT(DATE,SaleDate)


SELECT SaleDateConverted
FROM Project_Housing..Nashville_Housing

-- Populate Property Address

SELECT N1.ParcelID, N1.PropertyAddress,N2.ParcelID, N2.PropertyAddress
FROM Project_Housing..Nashville_Housing N1 JOIN Project_Housing..Nashville_Housing N2
ON N1.ParcelID = N2.ParcelID AND N1.[UniqueID ] <> N2.[UniqueID ]
WHERE N1.PropertyAddress IS NULL

UPDATE N1
SET N1.PropertyAddress = ISNULL(N1.PropertyAddress,N2.PropertyAddress)
FROM Project_Housing..Nashville_Housing N1 JOIN Project_Housing..Nashville_Housing N2
ON N1.ParcelID = N2.ParcelID AND N1.[UniqueID ] <> N2.[UniqueID ]
WHERE N1.PropertyAddress IS NULL

--Breaking out Address into Individual Columns(Address,City,State)

SELECT PropertyAddress
FROM Project_Housing..Nashville_Housing

SELECT 
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) AS Address ,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) AS City
FROM Project_Housing..Nashville_Housing

ALTER TABLE Project_Housing..Nashville_Housing
ADD SplitAddress NVARCHAR(255);

UPDATE Project_Housing..Nashville_Housing
SET SplitAddress= SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE Project_Housing..Nashville_Housing
ADD SplitCity NVARCHAR(255);

UPDATE Project_Housing..Nashville_Housing
SET SplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))

--Breaking out Owner's Address into Individual Columns(Address,City,State)

SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.'),3) AS OwnerSplitAddress,
PARSENAME(REPLACE(OwnerAddress,',','.'),2) AS OwnerSplitCity,
PARSENAME(REPLACE(OwnerAddress,',','.'),1) AS OwnerSplitState
FROM Project_Housing..Nashville_Housing

ALTER TABLE Project_Housing..Nashville_Housing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE Project_Housing..Nashville_Housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE Project_Housing..Nashville_Housing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE Project_Housing..Nashville_Housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE Project_Housing..Nashville_Housing
ADD OwnerSplitState NVARCHAR(255);

UPDATE Project_Housing..Nashville_Housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

--Changing Y and N to Yes and No (to have uniformity)

SELECT DISTINCT(SoldAsVacant)
FROM Project_Housing..Nashville_Housing

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM Project_Housing..Nashville_Housing 

UPDATE Project_Housing..Nashville_Housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END

--Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
	ORDER BY UniqueID
	) row_num
FROM Project_Housing..Nashville_Housing
)

DELETE
FROM RowNumCTE
WHERE row_num > 1
/*
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY ParcelID
*/

--Deleting Unused Columns

ALTER TABLE  Project_Housing..Nashville_Housing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict, SaleDate
