/*
Autor: Raymundo Gonzalez
Fecha: 2013/07/26
Descripcion:
	Se crea el SP ccsp_RIANotReadyEsp para configuracion de NotReady por Campaña y Especialidad

Version requerida: 96
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '97'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

		set @process = 'ccsp_RIANotReadyEsp - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_RIANotReadyEsp]
@Type smallint,
@Type2 smallint,
@IDArea smallint=0,
@CamEspID smallint,
@User_id smallint,
@InOut_Id smallint,
@InsertNotReady_id varchar(1000),
@DeleteNotReady_id varchar(1000)
AS
set nocount on


If @Type=1 --get camps
 begin
	SELECT a1.cam_id, a1.cam_descripcion, a3.frame,CASE a1.CallsBySurvey WHEN 0 THEN 0 ELSE 1 END as ''CallsBySurvey''  FROM ccCamps a1
	inner join ccRIACampsGraph a2 on(a1.cam_id=a2.cam_id)
	inner join ccRIAGraphics a3 on(a2.graphic_id=a3.graphic_id)
	where isnull(IDArea, -1) = case 
	when @IDArea = 0 then -1
	when (select login from ccusers where user_id = @User_id) = ''root'' then isnull(IDArea, -1)
	else @IDArea end
	order by 2
	return(0)
 end

If @Type=2 --get ACDGroups
 begin
	SELECT a1.Inbound_id, descripcion, a2.graphic_id, a3.frame from ccInbound a1
	inner join ccRIAInboundGraph a2 on(a1.Inbound_id=a2.Inbound_id)
	inner join ccRIAGraphics a3 on(a2.graphic_id=a3.graphic_id)
	where isnull(a1.IDArea, -1) = case when @IDArea=0 then -1
	when (select login from ccusers where user_id = @User_id) = ''root'' then isnull(a1.IDArea, -1)
	else @IDArea end
	order by 2
	return(0)
 end

IF @Type=3 --query
 begin
	If(@Type2=0) --ACDGroup
	 begin
		select c.Inbound_id, c.Descripcion as c_Descripcion, nr.TipoNotReady_id, nr.Descripcion as nr_Descripcion, nr.Time_Acum, nr.Time_xEv
	 	from ccInbound c
		inner join ccTipoNotReadyInbound nri on c.Inbound_id = nri.Inbound_id
	 	inner join ccTipoNotReady nr on nr.TipoNotReady_id = nri.TipoNotReady_id
	 	where c.inbound_id=@CamEspID
		and status=1
		ORDER BY 4
	 end

	If(@Type2=1) --Camp
	 begin
	  	select c.Cam_id, c.Cam_descripcion as c_Descripcion, nr.TipoNotReady_id, nr.Descripcion as nr_Descripcion, nr.Time_Acum, nr.Time_xEv
	 	from ccCamps c
		inner join ccTipoNotReadyCamps nrc on c.Cam_id = nrc.Cam_id
	 	inner join ccTipoNotReady nr on nr.TipoNotReady_id = nrc.TipoNotReady_id
	 	where c.cam_id=@CamEspID
		ORDER BY 4
	 end
 end

If @Type=4
 begin
	if exists(select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id)
	and (select login from ccUsers where user_id=@User_id)<>''root''
		select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id
	else
		select * from ccRIACAT_Areas where StatusArea=1 order by AreaName
	return(0)
 end

declare @sql as nvarchar(1000), @nIDArea as varchar(10)

if @Type=5 --Insert NotReadys
 begin
	If @Type2=3
	 begin
		If exists(select inbound_id from ccTipoNotReadyInbound where inbound_id=@CamEspID and TipoNotReady_id=@InsertNotReady_id)
			select 2
		else
			insert ccTipoNotReadyInbound(inbound_id, TipoNotReady_id) select @CamEspID, @InsertNotReady_id
		return(0)
	 end

	If @Type2=2
	 begin
		If exists(select cam_id from ccTipoNotReadyCamps where cam_id=@CamEspID and TipoNotReady_id=@InsertNotReady_id)
			select 2
		else
			insert ccTipoNotReadyCamps(cam_id, TipoNotReady_id) select top 1 @CamEspID, @InsertNotReady_id
		return(0)
	 end

	If @Type2<>1
		return(0)

	If @InOut_Id=0 --ACD
	 begin
		If @IDArea=0
		 begin
			set @sql=''insert ccTipoNotReadyInbound
			select distinct a.inbound_id, b.TipoNotReady_id from ccInbound a, ccTipoNotReady b where
			b.TipoNotReady_id in(''+@InsertNotReady_id+'')
			and not exists(select c.inbound_id, e.TipoNotReady_id from ccTipoNotReadyInbound c
			join ccTipoNotReady e on e.TipoNotReady_id=c.TipoNotReady_id
			join ccInbound d on d.inbound_id=c.inbound_id and IDArea is null
			where c.inbound_id=a.inbound_id and b.TipoNotReady_id=e.TipoNotReady_id)
			and a.inbound_id in(select x.inbound_id from ccInbound x where IDArea is null)''
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql=''insert ccTipoNotReadyInbound select distinct a.inbound_id, b.TipoNotReady_id 
		from ccInbound a, ccTipoNotReady b where b.TipoNotReady_id in(''+@InsertNotReady_id+'')
		and not exists(select c.inbound_id, e.TipoNotReady_id from ccTipoNotReadyInbound c
		join ccTipoNotReady e on e.TipoNotReady_id=c.TipoNotReady_id
		join ccInbound d on d.inbound_id=c.inbound_id and IDArea=''+@nIDArea+
		'' where c.inbound_id=a.inbound_id and b.TipoNotReady_id=e.TipoNotReady_id)
		and a.inbound_id in(select x.inbound_id from ccInbound x where IDArea=''+@nIDArea+'')''
		execute sp_executesql @sql
		return(0)
	 end

	If @InOut_Id=1 --Camp
	 begin
		If @IDArea=0
		 begin
			set @sql=''insert ccTipoNotReadyCamps
			select distinct a.cam_id, b.TipoNotReady_id from ccCamps a, ccTipoNotReady b where
			b.TipoNotReady_id in(''+@InsertNotReady_id+'')
			and not exists(select c.cam_id, e.TipoNotReady_id from ccTipoNotReadyCamps c
			join ccTipoNotReady e on e.TipoNotReady_id=c.TipoNotReady_id
			join ccCamps d on d.cam_id=c.cam_id and IDArea is null
			where c.cam_id=a.cam_id and b.TipoNotReady_id=e.TipoNotReady_id)
			and a.cam_id in(select x.cam_id from ccCamps x where IDArea is null)''
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql=''insert ccTipoNotReadyCamps select distinct a.cam_id, b.TipoNotReady_id
		from ccCamps a, ccTipoNotReady b where b.TipoNotReady_id in(''+@InsertNotReady_id+'')
		and not exists(select c.cam_id, e.TipoNotReady_id from ccTipoNotReadyCamps c
		join ccTipoNotReady e on e.TipoNotReady_id=c.TipoNotReady_id
		join ccCamps d on d.cam_id=c.cam_id and IDArea=''+@nIDArea+
		'' where c.cam_id=a.cam_id and b.TipoNotReady_id=e.TipoNotReady_id)
		and a.cam_id in(select x.cam_id from ccCamps x where IDArea=''+@nIDArea+'')''
		execute sp_executesql @sql
		return(0)
	 end
 end

If @Type=6 --Delete NotReadys
 begin
	If @Type2=3
	 begin
		delete ccTipoNotReadyInbound where inbound_id=@CamEspID	and TipoNotReady_id=@DeleteNotReady_id
		return(0)
	 end

	If @Type2=2
	 begin
		delete ccTipoNotReadyCamps where cam_id=@CamEspID and TipoNotReady_id=@DeleteNotReady_id
		return(0)
	 end

	If @Type2<>1
		return(0)

	If @InOut_Id=0 --ACD
	 begin
		If @IDArea=0
		 begin
			set @sql=''delete ccTipoNotReadyInbound where inbound_id in(select inbound_id from 
			ccInbound where IDArea is null) and TipoNotReady_id in(''+@DeleteNotReady_id+'')''
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql=''delete ccTipoNotReadyInbound where inbound_id in(select inbound_id from 
		ccInbound where IDArea=''+@nIDArea+'') and TipoNotReady_id in(''+@DeleteNotReady_id+'')''
		execute sp_executesql @sql
		return(0)
	 end

	If @InOut_Id=1 --Camp
	 begin
		If @IDArea=0
		 begin
			set @sql=''delete ccTipoNotReadyCamps
			where cam_id in(select cam_id from ccCamps where IDArea is null)
			and TipoNotReady_id in(''+@DeleteNotReady_id+'')''
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql=''delete ccTipoNotReadyCamps
		where cam_id in(select cam_id from ccCamps where IDArea=''+@nIDArea+'')
		and TipoNotReady_id in(''+@DeleteNotReady_id+'')''
		execute sp_executesql @sql
		return(0)
	 end
 end

return(0)
set nocount off'
		
	EXEC(@Sql)
	
	------------------ fin SCRIPT @Sql ------------------
	--		Generamos nueva version
			exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
