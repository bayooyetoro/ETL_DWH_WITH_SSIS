SELECT 
    SalesOrderNumber, CustomerID, ProductID, SalesPersonID, 
    TerritoryID, OrderQty, CurrencyRateID, UnitPrice, UnitPriceDiscount,
    LineTotal, OrderDate, DueDate, ShipDate, OnlineOrderFlag
FROM 
    Sales.SalesOrderDetail AS SOD
LEFT JOIN 
    Sales.SalesOrderHeader AS SOH ON SOD.SalesOrderID = SOH.SalesOrderID