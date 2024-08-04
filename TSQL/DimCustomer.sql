-- This fetches necessary data about customer from source DB
WITH People AS (
SELECT A.BusinessEntityID, AddressID AddressKey, PersonType,Title, FirstName, MiddleName, LastName, PhoneNumber, EmailAddress
FROM Person.Person A
LEFT JOIN Person.PersonPhone B ON A.BusinessEntityID = B.BusinessEntityID
LEFT JOIN Person.EmailAddress C ON A.BusinessEntityID = C.BusinessEntityID 
LEFT JOIN Person.BusinessEntityAddress C1 ON A.BusinessEntityID = C1.BusinessEntityID),

Addresses AS (
SELECT AddressID, PostalCode, AddressLine1 Street, City, E.Name StateProvince, F.Name CountryRegion, E.TerritoryID
FROM Person.Address D, Person.StateProvince E, Person.CountryRegion F
WHERE 
	D.StateProvinceID = E.StateProvinceID
	AND E.CountryRegionCode = F.CountryRegionCode)

SELECT People.*, PostalCode, Street, City, StateProvince, CountryRegion, TerritoryID
FROM People 
LEFT JOIN Addresses ON People.AddressKey = Addresses.AddressID