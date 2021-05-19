CREATE PROCEDURE[dbo].[ccsp_CreateDynamicTable] @Template_id INT,
					@Name VARCHAR(20)
				AS
				SET NOCOUNT ON;


				DECLARE @SQL VARCHAR(MAX) = ''
				DECLARE @colnames VARCHAR(1000)

				IF NOT EXISTS(
					SELECT *
					FROM sys.tables WHERE name = @Name
				)
				BEGIN

				SELECT @colnames = coalesce(@colnames + ',', '') + i + +' VARCHAR(255)'
				FROM Components_per_Template
				WHERE Template_id = @Template_id
				AND Component_id != 7

				SET @SQL = 'Create Table dbo.' + @Name + ' (Record_id int IDENTITY(1,1) NOT NULL primary key, Call_key nVarchar(40),Date datetime,' + @colnames + ');
				CREATE INDEX idx_callkey ON ' + @Name + '(Call_key);
				CREATE INDEX idx_date ON ' + @Name + '(Date);
				'

				EXEC(@SQL);

				UPDATE Templates
				SET EditStatus = 0
				WHERE Template_id = @Template_id
				END
				ELSE
				BEGIN
				SELECT - 1
				END