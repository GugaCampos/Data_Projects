-- THE AIM OF THIS PROJECT IS TO CLEAN DATA FROM A DATASET AND MAKE IT USABLE FOR ANALYSIS --

select *
from NashVille_Housing

--Objectives:
	--1. Standardize Date Format--
	--2. Populate Propery Address data--
	--3. Breaking out Address into Individual Columns (Address, City, State)--
	--4. Change Y and N to Yes and No in 'Sold as Vacant' field --
	--5. Remove Duplicates --
	--6. Delete Unused Columns --

--1--

SELECT SaleDate, convert(date,SaleDate)
from NashVille_Housing

UPDATE NashVille_Housing
SET SaleDate = CONVERT(DATE,SALEDATE)
	
ALTER TABLE NashVille_Housing
ADD SaleDateConverted DATE;

UPDATE NashVille_Housing
SET SaleDateConverted = CONVERT(DATE,SALEDATE)

SELECT SaleDateConverted
FROM NashVille_Housing

--2--

SELECT *
from NashVille_Housing
--WHERE PropertyAddress is null
order by ParcelID

SELECT nh.ParcelID, nh.PropertyAddress, nh2.ParcelID, nh2.PropertyAddress, isnull(nh.PropertyAddress, nh2.PropertyAddress)
from NashVille_Housing AS NH
JOIN  NashVille_Housing AS NH2
	ON NH.ParcelID = NH2.ParcelID
	AND NH.[UniqueID ] <> NH2.[UniqueID]
where nh.PropertyAddress is null

UPDATE nh
SET PropertyAddress = isnull(nh.PropertyAddress, nh2.PropertyAddress)
from NashVille_Housing AS NH
JOIN  NashVille_Housing AS NH2
	ON NH.ParcelID = NH2.ParcelID
	AND NH.[UniqueID ] <> NH2.[UniqueID]
where nh.PropertyAddress is null

--3--
SELECT PropertyAddress
from NashVille_Housing
--WHERE PropertyAddress is null
--order by ParcelID

SELECT 
SUBSTRING(PropertyAddress,1, charindex(',',PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress, charindex(',',PropertyAddress)+1, len(PropertyAddress)) as Address
from NashVille_Housing

ALTER TABLE NashVille_Housing
ADD Property_Split_Address nvarchar(255);

UPDATE NashVille_Housing
SET Property_Split_Address = SUBSTRING(PropertyAddress,1, charindex(',',PropertyAddress)-1)

ALTER TABLE NashVille_Housing
ADD City_Split_Address nvarchar(255);

UPDATE NashVille_Housing
SET City_Split_Address = SUBSTRING(PropertyAddress, charindex(',',PropertyAddress)+1, len(PropertyAddress)) 

select *
from NashVille_Housing

select
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
from NashVille_Housing



ALTER TABLE NashVille_Housing
ADD Owner_Street nvarchar(255);

UPDATE NashVille_Housing
SET Owner_Street =  PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE NashVille_Housing
ADD Owner_City nvarchar(255);

UPDATE NashVille_Housing
SET Owner_City =  PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE NashVille_Housing
ADD Owner_State nvarchar(255);

UPDATE NashVille_Housing
SET Owner_State =  PARSENAME(REPLACE(OwnerAddress,',','.'),1)


select *
from NashVille_Housing


--4--

SELECT DISTINCT(SoldAsVacant), count(SoldAsVacant)
FROM NashVille_Housing
group by SoldAsVacant
order by 2

select SoldAsVacant,
case
	when soldasvacant = 'Y' then 'Yes'
	WHEN SOLDASVACANT = 'N' THEN 'No'
	ELSE Soldasvacant
END
	from NashVille_Housing

UPDATE NashVille_Housing
SET SoldAsVacant = case
	when soldasvacant = 'Y' then 'Yes'
	WHEN SOLDASVACANT = 'N' THEN 'No'
	ELSE Soldasvacant
END


--5-- 

WITH CTE_DUPLICATES_REMOVAL AS
(
SELECT *, 
ROW_NUMBER() OVER (Partition BY ParcelID,
								PropertyAddress,
								SalePrice,
								SaleDate,
								LegalReference
								order by UNIQUEID) as ROW_NUM
FROM NashVille_Housing
)
SELECT *
FROM CTE_DUPLICATES_REMOVAL
WHERE ROW_NUM > 1


--6--

SELECT *
FROM NashVille_Housing

alter table NashVille_Housing
DROP COLUMN SaleDate, OwnerAddress, TaxDistrict, PropertyAddress


--END OF PROJECT --