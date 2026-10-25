/*
===============================================================================
  Script:      Create Data Warehouse Database and Schemas
  Description: Creates the DataWarehouse database and its Bronze, Silver, and
               Gold schemas if they do not already exist.
  Database:    Microsoft SQL Server
===============================================================================
  Purpose:
      Set up the initial structure of the data warehouse using a Medallion
      Architecture.

  Schemas:
      bronze  - Stores raw data from source systems (ERP and CRM).
      silver  - Stores cleaned, validated, and transformed data.
      gold    - Stores business-ready data for analytics and reporting.

  Notes:
      - Creates the database only if it does not exist.
      - Creates each schema only if it does not exist.
      - Can be executed multiple times without recreating existing objects.
      - Existing data and objects are preserved.

===============================================================================
*/

USE master;
GO

-- Create the database if it does not exist
IF DB_ID(N'DataWarehouse') IS NULL
BEGIN
    CREATE DATABASE DataWarehouse;
END;
GO

USE DataWarehouse;
GO

-- Create the Bronze schema if it does not exist
IF SCHEMA_ID(N'bronze') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA bronze');
END;
GO

-- Create the Silver schema if it does not exist
IF SCHEMA_ID(N'silver') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA silver');
END;
GO

-- Create the Gold schema if it does not exist
IF SCHEMA_ID(N'gold') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA gold');
END;
GO
