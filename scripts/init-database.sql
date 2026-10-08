-- Delete databases if they already exist
DROP DATABASE IF EXISTS  DataWarehouse;
DROP DATABASE IF EXISTS bronze;
DROP DATABASE IF EXISTS silver;
DROP DATABASE IF EXISTS gold;

-- Create Data Warehouse
CREATE DATABASE DataWarehouse;

--Create Medallion Architecture Layers 
CREATE DATABASE bronze;
CREATE DATABASE silver;
CREATE DATABASE gold;
