# SSIS Project

## Overview
This directory contains the SQL Server Integration Services (SSIS) project used to create and load the Olist data warehouse.

## Project Files
- `Olist_capstone_project.sln` - Visual Studio solution.
- `Olist_capstone_project.dtproj` - SSIS project definition.
- `Olist_SSIS_dwh.dtsx` - Main ETL package.
- `MATOMELA.conmgr` - OLE DB connection manager.
- `Project.params` - Project parameters.
- `Olist_capstone_project.database` - Project deployment configuration.

## ETL Workflow
The main package performs the following operations:

1. Creates the `olist_dwh` database if it does not exist.
2. Creates the Bronze schema.
3. Truncates and reloads nine Bronze tables from the source CSV files.
4. Creates the Silver schema.
5. Loads transformed and deduplicated geolocation data into Silver.
6. Creates the Gold schema.
7. Creates the ETL schema for batch logging.

The Silver validation scripts and Gold dimension and fact loading scripts are maintained separately under the `sql` directory.

## Requirements
- Microsoft SQL Server.
- SQL Server Integration Services.
- SQL Server Data Tools (SSDT) with SSIS project support.
- Access to the Olist source CSV files.
- A configured SQL Server connection manager.

## Running the Project
1. Open `Olist_capstone_project.sln` in Visual Studio.
2. Review the `MATOMELA` connection manager and update its server connection for the target environment.
3. Confirm that the source CSV file paths are correctly configured.
4. Ensure the SQL Server instance is available.
5. Execute the `Olist_SSIS_dwh.dtsx` package.

## Important
Connection settings and source file paths may need to be adjusted when moving the project to another computer.
