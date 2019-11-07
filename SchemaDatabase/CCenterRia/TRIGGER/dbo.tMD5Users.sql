CREATE TRIGGER [dbo].[tMD5Users] ON [dbo].[ccUsers]
FOR INSERT, UPDATE
NOT for Replication
AS
if (substring(COLUMNS_UPDATED(),1,1) & 64) > 0 
 begin
	if (select len(password) from inserted) = 33 and (select ascii(right(password, 1)) from inserted) = 126
	 begin	
	 	update ccUsers set password = left(i.password, 32)
		from ccUsers u inner join inserted i on u.user_id = i.user_id
		where len(i.password) = 33
	 end
	 
	else
	 begin
		update ccUsers set password = dbo.md5(i.password)
		from ccUsers u inner join inserted i on u.user_id = i.user_id
		where len(i.password) <> 32 AND len(dbo.md5(i.password)) = 32
	 end
 end