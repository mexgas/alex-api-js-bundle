CREATE TRIGGER [dbo].[trigHashPhone] ON [dbo].[ccListaNegra]
FOR INSERT
AS
SET NOCOUNT ON
begin	
	update A set A.Hashtel= dbo.hashPhone(B.telefono) from ccListaNegra A
	inner join INSERTED B on  A.idtipolista=B.idtipolista and A.telefono=B.telefono 

end