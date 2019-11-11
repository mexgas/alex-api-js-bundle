CREATE TRIGGER [dbo].[trigPosicionEspecialidad] ON [dbo].[ccLogLogin]
	FOR INSERT
	AS
	insert into ccPosicionEspecialidad(Inbound_id,User_id,Tipo,Fecha)
		select c.inbound_id,i.user_id,i.TipoMov,getdate()
		from inserted i
		inner join ccinboundagentes c (nolock)
		on	c.user_id = i.user_id
		
		
	insert into ccPosicionCamps(cam_id,User_id,Tipo,Fecha)
		select c.cam_id,i.user_id,i.TipoMov,getdate()
		from inserted i
		inner join cccampsagente c (nolock)
		on	c.user_id = i.user_id