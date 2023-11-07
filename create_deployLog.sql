IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'dp_deployLog')
BEGIN
	CREATE TABLE dbo.dp_deployLog (
		uniqueId int identity(1,1),
		dbName varchar(100),
		loadId int,
		deployDate datetime2(7),
		version varchar(5)
	)
END