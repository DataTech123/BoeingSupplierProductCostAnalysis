EXEC sp_execute_external_script
  @language = N'Python',
  @script = N'
import pandas as pd
import numpy as np
 
df_purchaseproduct = InputDataSet
df_purchaseproduct["OrderDate"] = pd.to_datetime(df_purchaseproduct["OrderDate"])

start_year = 2018
end_year = 2023
vendor_names = [ "Honeywell Aerospace", "PPG Aerospace"]

df_selectedvendor = df_purchaseproduct[
    (df_purchaseproduct["VendorName"].isin(vendor_names)) &
    (df_purchaseproduct["OrderDate"].dt.year >= start_year) &
    (df_purchaseproduct["OrderDate"].dt.year <= end_year)]

# Calculate a total price and convert dollar sign format
total_prices = df_selectedvendor.groupby("VendorName")["TotalPrice"].sum().reset_index()
total_prices["TotalPrice"] = total_prices["TotalPrice"].apply(lambda x: "${:,.2f}".format(x))

df_output = pd.merge( total_prices, 
    df_selectedvendor[["VendorName", "OrderDate", "PurchaseReceipt", "StockQuantity", "ItemName", "WarehouseName"]].drop_duplicates(),on="VendorName")
OutputDataSet = df_output',

@input_data_1 = N'
 SELECT 
        pp.PurchaseOrderID, pp.VendorID, v.VendorName, pp.ItemName, pp.OrderDate, pp.QuantityOrdered, 
        CAST(pp.TotalPrice AS FLOAT) AS TotalPrice, pp.PurchaseReceipt, w.StockQuantity, w.WarehouseName
FROM PurchaseProduct pp
INNER JOIN Vendor v 
	 ON pp.VendorID = v.VendorID
INNER JOIN Warehouse w ON pp.ItemName = w.ItemName
WHERE v.VendorName IN (''Honeywell Aerospace'', ''PPG Aerospace'') 
      AND YEAR(pp.OrderDate) BETWEEN 2018 AND 2023;
',
  @output_data_1_name = N'OutputDataSet'
WITH RESULT SETS (
  ( VendorName NVARCHAR(100),
    TotalPrice NVARCHAR(100),
    OrderDate DATE,
    PurchaseReceipt NVARCHAR(100),
    StockQuantity INT,
    ItemName NVARCHAR(100),
    WarehouseName NVARCHAR(100))
);
