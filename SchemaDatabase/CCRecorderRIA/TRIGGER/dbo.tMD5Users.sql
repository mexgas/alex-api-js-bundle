Create TRIGGER [dbo].[tMD5Users] ON [dbo].[TREC_AGENTE]
FOR INSERT, UPDATE
AS
if (substring(COLUMNS_UPDATED(),1,1) & 64) > 0 begin
	update trec_agente set age_password = dbo.md5(i.age_password)
	from trec_agente u inner join inserted i
	on u.age_id = i.age_id
	where len(i.age_password) <> 32 AND len(dbo.md5(i.age_password)) = 32
end