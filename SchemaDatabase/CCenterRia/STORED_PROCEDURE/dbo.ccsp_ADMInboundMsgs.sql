CREATE PROCEDURE ccsp_ADMInboundMsgs
@Inbound_id smallint,
@msg_id smallint,
@orden smallint,
@Tipo tinyint -- 1=ALTA, 2=Modificacion, 3=Borrar
AS
declare @Descripcion varchar(40)
declare @idioma as bit

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

	select @Descripcion=Upper(msgFile) from ccMsgFiles where msg_id=@msg_id
	if ( @Tipo=1 )
	begin
		if ( select count(*) from ccInboundMsgs where Inbound_id = @Inbound_id and msg_id=@msg_id and orden=@orden
		) > 0
			if @idioma = 1
			select 0, 'Message Already Assigned'
			else
			select 0, 'Mensaje ya Asignado'
		else
		begin
			Insert ccInboundMsgs ( Msg_id, Inbound_id, orden  ) Values ( @msg_id, @Inbound_id, @orden )
			if @idioma = 1
			select -1, 'Message: ' + @Descripcion + ' Assigned to the Specialty OK'
			else
			select -1, 'Mensaje: ' + @Descripcion + ' Asignado en la Especialidad OK'
		end
	end
	if ( @Tipo=3 )
	begin
		Delete ccInboundMsgs where Inbound_id = @Inbound_id and msg_id=@msg_id and orden=@orden
		if @idioma = 1
		select -1, 'Message: ' + @Descripcion + ' Removed from the Specialty'
		else
		select -1, 'Mensaje: ' + @Descripcion + ' Removido de la Especialidad'
	end