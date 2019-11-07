CREATE PROCEDURE ccsp_ADMCampDialers
@cam_id smallint,
@dialer_id smallint,
@Tipo tinyint -- 1=ALTA, 2=Modificacion, 3=Borrar
AS
declare @Descripcion varchar(40)
declare @idioma as bit

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

	select @Descripcion=Upper(Descripcion) from ccoDialers where dialer_id=@dialer_id
	if ( @Tipo=1 )
	begin
		if ( select count(*) from ccoDialerCamp where cam_id = @cam_id and dialer_id=@dialer_id
		) > 0	
			if @idioma = 1
			select 0, 'Dialer Already Assigned'
			else
			select 0, 'Dialer ya Asignado'
		else
		begin
			Insert ccoDialerCamp ( dialer_id, cam_id  ) Values ( @dialer_id, @cam_id)
			if @idioma = 1
			select -1, 'Dialer: ' + @Descripcion + ' Assigned to the Campaign OK'
			else
			select -1, 'Dialer: ' + @Descripcion + ' Asignado en la Campaa OK'
		end
	end
	if ( @Tipo=3 )
	begin
		Delete ccoDialerCamp where cam_id = @cam_id and dialer_id=@dialer_id
		if @idioma = 1
		select -1, 'Dialer: ' + @Descripcion + ' Removed from Campaign'
		else
		select -1, 'Dialer: ' + @Descripcion + ' Removido de la Campaa'
	end