CREATE PROCEDURE ccspExportBasexRiaXml @path VARCHAR(MAX) --Path Not Contener espacios
AS
BEGIN
	DECLARE @fileName VARCHAR(MAX)
	DECLARE @sqlStr VARCHAR(1000)
	DECLARE @sqlCmd VARCHAR(1000)
	DECLARE @baseXName VARCHAR(255)

	IF len(@path) = 0
	BEGIN
		RAISERROR ('The @path can not be empty', 16, 1);
	END
	ELSE IF CHARINDEX(' ', @path) > 0
	BEGIN
		RAISERROR ('The export @path must not have spaces', 16, 1);
	END

	IF CHARINDEX('\', @path, len(@path) - 1) = 0
	BEGIN
		SET @path = @path + '\'
	END

	WHILE EXISTS (
			SELECT *
			FROM RiaRecnodeBasexBackup
			WHERE STATUS = 0
			)
	BEGIN
		SELECT TOP 1 @baseXName = Xname
		FROM RiaRecnodeBasexBackup
		WHERE STATUS = 0

		SET @fileName = '"' + @path + @baseXName + '.xml"'

		SELECT @fileName, @baseXName

		SET @sqlStr = '"SELECT top 1 ''<root> ''+ CHAR(10) +replace(convert(varchar(MAX), nodes,0),''/>'',''/>''+CHAR(10)) +''</root>'' FROM ' + DB_NAME() + '..RiaRecnodeBasexBackup WHERE STATUS = 0"'
		SET @sqlCmd = 'bcp ' + @sqlStr + ' queryout ' + @fileName + ' -S -w -T'

		EXEC xp_cmdshell @sqlCmd

		UPDATE RiaRecnodeBasexBackup
		SET STATUS = 1
		WHERE Xname = @baseXName
	END
END