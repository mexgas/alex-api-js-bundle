CREATE PROCEDURE [dbo].[ccsp_RIAServerIP]
					AS
					Select valor,DATABASEPROPERTYEX('CCenterRia', 'Collation') AS DBCollation from ccSettings where setting_id = 67