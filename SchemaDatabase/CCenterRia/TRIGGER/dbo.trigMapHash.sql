CREATE TRIGGER [dbo].[trigMapHash] ON [dbo].[ccSIPCodeMap]
			FOR INSERT,UPDATE
			AS
			SET NOCOUNT ON
			BEGIN

				update ccSIPCodeMap set 
				hash=UPPER(SUBSTRING(master.dbo.fn_varbintohexstr(HashBytes('MD5', rtrim(ltrim(map.carrier))+'|'+cast(map.resultCode as varchar(5)))), 3, 32))
				from ccSIPCodeMap map 
				inner join inserted i on map.id=i.id

			END