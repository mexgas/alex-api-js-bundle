/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K053000

Database: CCenterRia
Required version: 125.37

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 37
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN
	BEGIN TRY

	---------------------------------------BEGIN Rodrigo Salazar---------------------------------------------------------
	SET @process = 'KR096001 ALTER TABLE ccTipoCalifOUT'
	SET @sql = '
		if exists(select * from sys.columns where name = ''description'' and object_id = OBJECT_ID(''ccTipoCalifOUT''))
		begin
			ALTER TABLE ccTipoCalifOUT ALTER COLUMN [description] varchar(150)
		end'
	EXEC(@sql)

	SET @process = 'KR096001 drop sp ccsp_GalateaAdminDispositions'
	SET @sql = '
		if exists(select * from sys.procedures where name = ''ccsp_GalateaAdminDispositions'')
		begin
			DROP PROCEDURE ccsp_GalateaAdminDispositions
		end'
	EXEC(@sql)

	SET @process = 'KR096001 create sp ccsp_GalateaAdminDispositions'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaAdminDispositions]
                @command int,
                @calif_id smallint = null,
                @califIdLst varchar(8000) = null,
                @description varchar(150)=null,
                @order tinyint=null,
                @canReprogram bit = null,
                @graphColor varchar(15) = null,
                @endConversation bit=null,
                @keepDial bit=null,
                @autoCB bit=null,
                @contactOwner bit=null,
                @finishPreview bit = 0,
                @allNumbersToBlacklist bit = 0,
    			@FinishRecordPreview bit = 0
                AS
                set nocount on
                declare @inserted table (ID smallint)

                if @command=1 -- Load Inbound Dispositions
                begin
                  Select C.calif_id, C.Description, C.orden, C.canReprogram, cast(0 as bit) as contactOwner, 
                  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.EndConversation,0) conversationEnd, graphColor
                  from cctipoCalif C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 1
                  where C.Calif_Status=1
                  group by C.calif_id, C.Description, C.orden, C.canReprogram, C.EndConversation, graphColor
                  order by 2
                  return(0)
                end

                If @command=2 -- Load Outbound Dispositions
                begin
                  Select C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback,  
                  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.contactOwner,0) as contactOwner, 
                  IsNull(C.finishPreview,0) as finishPreview, graphColor, allNumbersToBlacklist, ISNULL(C.FinishRecordPreview,0) as FinishRecordPreview
                  from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
                  where C.CalifOut_Status=1
                  group by C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback, 
                  C.contactOwner, C.finishPreview, graphColor, allNumbersToBlacklist, C.FinishRecordPreview
                  order by 2
                  return(0)
                end

                If @command=3 -- New ccTipoCalif
                begin
                  If exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@description)
                    begin
                      select cast(-1 as smallint) [result]  -- Disposition already exists
                      return(0)
                    end

                  If exists(select calif_id from ccTipoCalif where Calif_Status=0 and description=@description)
                  begin
                    select top 1 @calif_id = calif_id from ccTipoCalif where Calif_Status=0 and description=@description order by calif_id desc
                    update ccTipoCalif set orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), EndConversation=isnull(@endConversation,0), 
                    graphColor=isnull(@graphColor, ''1DB4E2''), Calif_Status=1
                    output inserted.calif_id into @inserted
                    where calif_id=@calif_id
                    select ID [result] from @inserted 
                    return(0)
                  end

                  insert into ccTipoCalif (calif_id, description, orden, CanReprogram, EndConversation , graphColor)
                  output inserted.calif_id into @inserted
                  select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), isnull(@canReprogram,0), isnull(@endConversation,0), isnull(@graphColor, ''1DB4E2'') from ccTipoCalif
                  select ID [result] from @inserted
                  return(0)
                end

                If @command=4 -- New ccTipoCalifOUT
                begin
                  If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=1 and description=@description)
                  begin
                  select cast(-1 as smallint) [result]  -- Disposition already exists
                  return(0)
                  end

                 If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description)
                 begin
                    select top 1 @calif_id = calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description order by calif_id desc
                    update ccTipoCalifOut set autoTime=0, orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), idTipoLista=0,
                    Califout_Status=1, keepDial=isnull(@keepDial,0), autocallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0), 
                    finishPreview=isnull(@finishPreview,0), graphColor=isnull(@graphColor, ''1DB4E2''), FinishRecordPreview = isnull(@FinishRecordPreview,0)
                    output inserted.calif_id into @inserted
                    where calif_id=@calif_id
                    select ID [result] from @inserted 
                    return(0)
                 end

                 insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram, keepDial, autocallback, contactOwner, finishPreview, graphColor, allNumbersToBlacklist,FinishRecordPreview)
                 output inserted.calif_id into @inserted
                 select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), 0, isnull(@canReprogram,0), isnull(@keepDial,0), 
                 isnull(@autoCB,0), isnull(@contactOwner,0), isnull(@finishPreview,0), isnull(@graphColor, ''1DB4E2''), ISNULL(@allNumbersToBlacklist,0), FinishRecordPreview = isnull(@FinishRecordPreview,0) from ccTipoCalifOut
                 select ID [result] from @inserted 
                 return(0)
                end
                If @command=5 -- Delete Inbound Dispositions
                begin
                    delete from ccCalifCamp where tipo=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
                    delete from cctipoSubCalifRel where tipoSubRel=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
                    update ccTipoCalif set Calif_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
                    return(0)
                end
                if @command=6 -- Delete Outbound Disposition
                begin
                    delete from ccCalifCamp where tipo=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
                    delete from cctipoSubCalifRel where tipoSubRel=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
                    update ccTipoCalifOUT set CalifOut_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
                    update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
                    return(0)
                end
                if @command=7 -- Update Inbound Disposition
                begin
                    if(exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@Description and calif_id<>@calif_id))
                    begin
                        select cast(-1 as smallint) [result]    -- Disposition already exists
                        return(0)
                    end

                    UPDATE ccTipoCalif set Description=isnull(@Description, Description), orden=isnull(@order, orden),
                    canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  
                    EndConversation=isnull(@endConversation,EndConversation)
                    output inserted.calif_id into @inserted
                    where calif_id=@calif_id

                    delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
                    tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

                    select ID [result] from @inserted
                    return(0)
                end
                if @command=8 -- Update Outbound Disposition
                begin
                    if(exists(select calif_id from ccTipoCalifOUT where CalifOut_Status=1 and Description=@description and calif_id<>@calif_id))
                    begin
                        select cast(-1 as smallint) [result]    -- Disposition already exists
                        return(0)
                    end

                    UPDATE ccTipoCalifOUT set Description=isnull(@Description, Description), Orden=isnull(@Order, Orden),
                    canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  keepDial=isnull(@keepDial,keepDial), 
                    autocallback = isnull(@autoCB,autocallback), contactOwner = isnull(@contactOwner,contactOwner), 
                    finishPreview = isnull(@finishPreview,finishPreview), allNumbersToBlacklist = isnull(@allNumbersToBlacklist, allNumbersToBlacklist),  FinishRecordPreview = isnull(@FinishRecordPreview,FinishRecordPreview)
                    output inserted.calif_id into @inserted
                    where calif_id=@calif_id

                    if @keepDial is not null
                    begin
                        update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
                    end

                    select ID [result] from @inserted
                    return(0) 
                    end

                set nocount off'
	EXEC(@sql)

	SET @process = 'KR096002 alter table ccTipoCalifSubOUT'
	SET @sql = '
		if exists(select * from sys.columns where name = ''califSubDesc'' and object_id = OBJECT_ID(''ccTipoCalifSubOUT''))
		begin
			ALTER TABLE ccTipoCalifSubOUT ALTER COLUMN califSubDesc varchar(150)
		end'
	EXEC(@sql)

	SET @process = 'KR096002 drop procedure ccsp_GalateaAdminSubdispositions'
	SET @sql = '
		if exists(select * from sys.procedures where name = ''ccsp_GalateaAdminSubdispositions'')
		begin
			DROP PROCEDURE ccsp_GalateaAdminSubdispositions
		end'
	EXEC(@sql)

	SET @process = 'KR096002 create procedure ccsp_GalateaAdminSubdispositions'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSubdispositions]
			@command int,
			@califSub_id smallint = null,
			@califSubIdLst varchar(max) = null,
			@califSubDesc varchar(150) = null,
			@order varchar(3) = null,
			@canReprogram bit = null,
			@endConversation bit=null,
			@keepDial bit=null,
			@autoCB bit=null,
			@contactOwner bit=null
			AS
			set nocount on
			declare @inserted table (ID smallint)

			if @command=1 -- Load Inbound Subdispositions
			begin
			  select califSub_id, IsNull(califSubDesc,'''') [califSubDesc], orden, canReprogram, 
			  IsNull(EndConversation,0) EndConversation
			  from ccTipoCalifSub
			  where califSub_Status = 1
			  order by 2
			  return(0)
			end

			If @command=2 -- Load Outbound Subdispositions
			begin
			  select califSub_id, IsNull(califSubDesc,'''') [califSubDesc],
			  IsNull(canReprogram, 0) [canReprogram],
			  IsNull(orden, 0) [orden],
			  IsNull(keepDial, 0) [keepDial],
			  IsNull(autoCallback, 0) [autoCallback],
			  IsNull(contactOwner, 0) [contactOwner]
			  from ccTipoCalifSubOut
			  where califSubOut_Status = 1
			  order by 2
			  return(0)
			end

			if @command=3   -- New Inbound Subdisposition
			begin
				if(exists(select califSub_id from ccTipoCalifSub where califSub_Status = 1 and califSubDesc=@califSubDesc))
				begin
					select cast(-1 as smallint) [result]    -- Subdisposition already exists
					return(0)
				end

				if(exists(select califSub_id from ccTipoCalifSub where califSub_Status=0 and califSubDesc=@califSubDesc))
				begin
					select top 1 @califSub_id = califSub_id from ccTipoCalifSub where califSub_Status=0 and califSubDesc=@califSubDesc order by califSub_id desc
					update ccTipoCalifSub set orden=isnull(@order,0), canReprogram=isnull(@canReprogram,0), EndConversation=isnull(@endConversation,0),
					califSub_Status=1
					output inserted.califSub_id into @inserted
					where califSub_id=@califSub_id
					select ID [result] from @inserted 
					return(0)
				end

				insert into ccTipoCalifSub (califSubDesc, orden, canReprogram, califSub_Status, EndConversation)
				select @califSubDesc, isnull(@order,0), isnull(@canReprogram,0), 1, isnull(@endConversation,0)
				select cast(SCOPE_IDENTITY() as smallint) [result]
				return(0)
			end

			if @command=4   -- New Outbound Subdisposition
			begin
				if(exists(select califSub_id from ccTipoCalifSubOUT where califSubOut_Status = 1 and califSubDesc=@califSubDesc))
				begin
					select cast(-1 as smallint) [result]    -- Subdisposition already exists
					return(0)
				end

				if(exists(select califSub_id from ccTipoCalifSubOUT where califSubOut_Status=0 and califSubDesc=@califSubDesc))
				begin
					select top 1 @califSub_id = califSub_id from ccTipoCalifSubOUT where califSubOut_Status=0 and califSubDesc=@califSubDesc order by califSub_id desc
					update ccTipoCalifSubOUT set orden=isnull(@order,0), canReprogram=isnull(@canReprogram,0),idTipoLista=0,
					califSubOut_Status=1, keepDial=isnull(@keepDial,0), autoCallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0)
					output inserted.califSub_id into @inserted
					where califSubDesc=@califSubDesc
					select ID [result] from @inserted 
					return(0)
				end

				insert into ccTipoCalifSubOUT (califSubDesc, orden, canReprogram, califSubOut_Status, keepDial, autoCallback, contactOwner)
				select @califSubDesc, isnull(@order,0), isnull(@canReprogram,0), 1, isnull(@keepDial,0), isnull(@autoCB,0), isnull(@contactOwner,0)
				select cast(SCOPE_IDENTITY() as smallint) [result]
				return(0)
			end

			if @command=5   -- Delete Inbound Subdisposition
			begin
				delete cctipoSubCalifRel where tipoSubRel=1 and califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSubIdLst, '',''))
				update cctipocalifSub set califSub_Status=0 where califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSubIdLst, '',''))
				return(0)
			end

			if @command=6   -- Delete Outbound Subdisposition
			begin
				delete cctipoSubCalifRel where tipoSubRel=0 and califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSubIdLst, '',''))
				update cctipocalifSubOUT set califSubOut_Status=0 where califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSubIdLst, '',''))
				update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
				return(0)
			end

			if @command=7   -- Update Inbound Subdisposition
			begin
				if(exists(select califSub_id from ccTipoCalifSub where califSub_Status=1 and califSubDesc=@califSubDesc and califSub_id<>@califSub_id))
				begin
					select cast(-1 as smallint) [result]    -- Subdisposition already exists
					return(0)
				end

				if @canReprogram=1
				begin
					if exists (select IB.Inbound_id from cctipoSubCalifRel CR join cctipoCalif TC on CR.calif_id = TC.calif_id and CR.tipoSubRel=1
					join ccCalifCamp CM on TC.calif_id = CM.calif_id and CM.tipo = 0 join ccInbound IB on CM.cam_id = IB.inbound_id 
					where califSub_id = @califSub_id and IB.cam_id is null)
					begin
						select cast(-2 as smallint) [result]    -- Cant reprogram, there is not assigned campaign
						return(0)
					end
				end

				update ccTipoCalifSub set califSubDesc=isnull(@califSubDesc, califSubDesc), orden=isnull(@order, orden), canReprogram=isnull(@canReprogram, canReprogram),
				EndConversation=isnull(@endConversation, EndConversation)
				output inserted.califSub_id into @inserted
				where califSub_id=@califSub_id

				delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
				tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

				select ID [result] from @inserted
				return(0) 
			end

			if @command=8   -- Update Outbound Subdisposition
			begin
            
				if(exists(select califSub_id from ccTipoCalifSubOUT where califSubOut_Status=1 and califSubDesc=@califSubDesc and califSub_id<>@califSub_id))
				begin
					select cast(-1 as smallint) [result]    -- Subdisposition already exists
					return(0)
				end

				update ccTipoCalifSubOUT set califSubDesc=isnull(@califSubDesc, califSubDesc), canReprogram=isnull(@canReprogram, canReprogram),
				orden=isnull(@order, orden), keepDial=isnull(@keepDial, keepDial), autoCallback=isnull(@autoCB, autoCallback), contactOwner=isnull(@contactOwner,contactOwner)
				output inserted.califSub_id into @inserted
				where califSub_id=@califSub_id
				update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)

				select ID [result] from @inserted
				return(0) 
			end


			set nocount off'
	EXEC(@sql)

	SET @process = 'KR096003 ALTER TABLE ccTipoCalif'
	SET @sql = '
		if exists(select * from sys.columns where name = ''Description'' and object_id = OBJECT_ID(''ccTipoCalif''))
		begin
			ALTER TABLE ccTipoCalif ALTER COLUMN [Description] varchar(150)
		end'
	EXEC(@sql)

	SET @process = 'KR096004 ALTER TABLE ccTipoCalifSub'
	SET @sql = '
		if exists(select * from sys.columns where name = ''califSubDesc'' and object_id = OBJECT_ID(''ccTipoCalifSub''))
		begin
			ALTER TABLE ccTipoCalifSub ALTER COLUMN califSubDesc varchar(150)
		end'
	EXEC(@sql)

	SET @process = 'KR096017 drop procedure ccsp_RIAADMGetCalifDayForced'
	SET @sql = '
		if exists(select * from sys.procedures where name = ''ccsp_RIAADMGetCalifDayForced'')
		begin
			DROP PROCEDURE ccsp_RIAADMGetCalifDayForced
		end'
	EXEC(@sql)

	SET @process = 'KR096017 create procedure ccsp_RIAADMGetCalifDayForced'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_RIAADMGetCalifDayForced]
        @type smallint,
        @cam_id smallint,
        @calif_id smallint = NULL,
        @isKolob BIT = 0
        AS 
        set nocount on
        create table #CalifTemp (id int identity,
        tipo integer, 
        Cam_id varchar(50), 
        Calificacion varchar(150), 
        subCalificacion varchar(150) null,
        calif_id smallint null,
        Total int,
        GraphColor varchar(15),
        IsSubDisp BIT)

        declare @today datetime
        set @today = convert(datetime, convert (varchar(11), getdate(), 101))
        --set @today =convert(datetime, convert (varchar(11), ''2015-10-01 17:50:20.470'', 101))

        -- Seleccion de idioma -- 
        declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
        select @nIdioma = case valor when 0 then ''Sin calificación'' WHEN 1 THEN ''No disposition''  else ''Sem classificação'' end
        from ccsettings where setting_id = 27 -- 0esp

        select @nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
        from ccsettings where setting_id = 27 -- 0 esp

        if @type=0 
        BEGIN
            insert into #CalifTemp 
            select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13
                    then case when description is not null 
                                then description 
                                else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
                                end
            else case when sll.descripcion is not null then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
            end end as Calificacion,
            case when count(co.califSub_id) > 0 then 1 else 0 end as Subcalificacion,co.calif_id as calif_id,count(*) cantidad,
            ISNULL(GraphColor,''1DB4E2'') GraphColor,
            CASE WHEN ISNULL(rel.calif_id, 0) = 0 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS IsSubDisp
            from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
            left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
            LEFT join cctipoSubCalifRel rel on rel.calif_id = ca.calif_id
            left join ccTipoCalifSubOUT tcsout on co.califSub_id = tcsout.califSub_id
            left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
            left join ccCamps ci on ci.cam_id = co.cam_id 
            where co.cal_inicio > @today
            and co.cam_id = @cam_id
            group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id,GraphColor, rel.calif_id
        END

        if @type=1 
        insert into #CalifTemp 
        select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
        else @nIdioma-- substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
        end as Calificacion,count(ci.califSub_id) as subCalificacion,ci.calif_id,count(*)  as total,
        ISNULL(GraphColor,''1DB4E2'') GraphColor,
        0 as IsSubDisp
        from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) 
        left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
        left join ccInbound cci on cci.inbound_id = ci.inbound_id 
        where ci.cal_inicio > @today
        and ci.inbound_id = @cam_id
        and statuscall_id = 13 
        group by description, cci.inbound_id,ci.califSub_id,ci.calif_id,GraphColor

        -- Se corrigio suma de totales -- 
        Alter table #CalifTemp add iTotal4Campaign int null

        if (select valor from ccSettings where setting_id = 78) = 0
        update #CalifTemp set iTotal4Campaign = 0

        else    
        update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign 
        from (select cam_id, sum(A.Total) iTotal4Campaign
        from #CalifTemp A group by cam_id) t join #CalifTemp c
        on t.cam_id = c.cam_id

        if @type=1 
        BEGIN
            IF(@isKolob = 1)
            BEGIN
                select tipo as Type, cast(cam_id as varchar) as CampId, calificacion as Calification, cast(subCalificacion as varchar) as SubCalificationQuantity, cast(calif_id as smallint) as CalificationId, sum( total ) as Total, GraphColor from (
                select 1 as tipo, inboundId as Cam_id, case when description is not null then description 
                    else @nIdioma --substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
                    end as Calificacion,0 as subCalificacion ,a.disposition as calif_id, COUNT(disposition) as Total,ISNULL(GraphColor,''1DB4E2'') GraphColor--,0 as iTotal4Campaign
                from ccriachats a left join ccTipoCalif b 
                on a.disposition=b.calif_id 
                where a.chatDate > @today
                and a.inboundId = @cam_id
                group by inboundId, Description, GraphColor, a.disposition
                union all
        
        
                select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
                then calificacion 
                else @nIdioma --substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
                end as Calificacion,
                case when count(subCalificacion) > 0 then 1 else 0 end subCalificacion,calif_id,sum(Total) as Total, ISNULL(GraphColor,''1DB4E2'') GraphColor  --iTotal4Campaign -- para ver total por campaña
                from #CalifTemp 
                group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
                then calificacion 
                else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
                end, Cam_id,calif_id, iTotal4Campaign, GraphColor
                )  as a group by tipo, cam_id, calificacion,subCalificacion,calif_id,GraphColor   order by tipo,cam_id 
            END
            ELSE
            BEGIN
                select tipo as Type, cast(cam_id as varchar) as CampId, calificacion as Calification, cast(subCalificacion as varchar) as SubCalificationQuantity, cast(calif_id as smallint) as CalificationId, sum( total ) as Total, GraphColor from (
                select 1 as tipo, inboundId as Cam_id, case when description is not null then description 
                    else @nIdioma --substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
                    end as Calificacion,0 as subCalificacion ,0 as calif_id,count(disposition) as Total,ISNULL(GraphColor,''1DB4E2'') GraphColor--,0 as iTotal4Campaign
                from ccriachats a left join ccTipoCalif b 
                on a.disposition=b.calif_id 
                where a.chatDate > @today
                and a.inboundId = @cam_id
                group by inboundId, Description, GraphColor
        
                union all
        
        
                select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
                then calificacion 
                else @nIdioma --substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
                end as Calificacion,
                case when count(subCalificacion) > 0 then 1 else 0 end subCalificacion,calif_id,sum(Total) as Total, ISNULL(GraphColor,''1DB4E2'') GraphColor  --iTotal4Campaign -- para ver total por campaña
                from #CalifTemp 
                group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
                then calificacion 
                else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
                end, Cam_id,calif_id, iTotal4Campaign, GraphColor
            )  as a group by tipo, cam_id, calificacion,subCalificacion,calif_id,GraphColor order by tipo,cam_id 
            END
        END
            
        if @type=0 

        select tipo as Type,Cam_id as CampId,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
        then calificacion 
        else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
        end as Calification,subCalificacion as SubCalificationQuantity, calif_id as CalificationId,sum(Total) as Total, ISNULL(GraphColor,''1DB4E2'') GraphColor -- , iTotal4Campaign -- para ver total por campaña
        ,IsSubDisp
        from #CalifTemp 
        group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
        then calificacion 
        else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
        end, Cam_id,subCalificacion, calif_id, iTotal4Campaign, GraphColor, IsSubDisp



        if @type = 3 begin -----entrada acd''s
            select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
            else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
            end as Calificacion,isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(*) as totales 
            from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
            left join ccInbound cci on cci.inbound_id = ci.inbound_id 
            left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
            where ci.cal_inicio > @today
            and ci.inbound_id = @cam_id
            and statuscall_id = 13 
            and ci.calif_id = @calif_id
            group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id 
        end

        if @type = 4 begin --salida campañas
                select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13 
                    then case when description is not null 
                                then description 
                                else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
                                end
            else case when sll.descripcion is not null 
            then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
            end end as Calificacion,isnull(cso.califSubDesc,@nIdiomaSub) ,count(*) cantidad 
            from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
            left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
            left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id
            left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
            left join ccCamps ci on ci.cam_id = co.cam_id 
            where co.cal_inicio > @today
            and co.cam_id = @cam_id
            group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc
        end 
     

        drop table #CalifTemp 
        set nocount off'
	EXEC(@sql)

	SET @process = 'KR096029 drop procedure ccspAgent_GetLastCalls'
	SET @sql = '
		if exists(select * from sys.procedures where name = ''ccspAgent_GetLastCalls'')
        begin
            DROP PROCEDURE ccspAgent_GetLastCalls
        end'
	EXEC(@sql)

	SET @process = 'KR096029 create procedure ccspAgent_GetLastCalls'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id INT
            AS
             SET NOCOUNT ON;
             DECLARE @lastCallAgt TABLE(id           INT NOT NULL
                                      , tipo         VARCHAR(10) NOT NULL
                                      , Hora         DATETIME NOT NULL --VARCHAR(19) NOT NULL, 
                                      , Telefono     VARCHAR(55) NOT NULL
                                      , EspCamp      VARCHAR(55) NOT NULL
                                      , Calificacion VARCHAR(150)
                                      , Duracion     VARCHAR(10) NOT NULL
                                      , CallBack     DATETIME
                                      , cal_key      VARCHAR(40)
                                      , IDCampEsp    SMALLINT NOT NULL
                                      , prefijo      VARCHAR(255) NULL
                                      , GraphicID    INT
                                      , CamManualMode INT
                                      , SelectRotativeANI INT
                                      , PRIMARY KEY(id)
             );

             DECLARE @pais TINYINT;
             DECLARE @maxHours SMALLINT;
             DECLARE @topRows INT;
             DECLARE @setting VARCHAR(6);
             DECLARE @hidePhone BIT;
             DECLARE @dateStart DATETIME;

             SET @hidePhone = 1;

             SELECT @setting = valor FROM ccSettings WHERE setting_id = 255;

             SET @maxHours = CAST(SUBSTRING(@setting, 1, (SELECT PATINDEX(''%|%'', @setting)) - 1) AS SMALLINT);
             SET @topRows = CAST(SUBSTRING(@setting, (SELECT PATINDEX(''%|%'', @setting)) + 1, LEN(@setting)) AS INT);

             IF @maxHours = 0
             BEGIN
                 SELECT Id
                      , tipo
                      , (CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) AS Hora
                      , Telefono
                      , EspCamp
                      , Calificacion
                      , CallBack
                      , Duracion
                      , '''' AS CallBack
                      , cal_key
                      , IDCampEsp
                      , prefijo
                      , GraphicID
                      , SelectRotativeANI
                      , @hidePhone AS HidePhone FROM @lastCallAgt;

                 RETURN 0;
             END;

             SELECT @pais = valor FROM ccSettings WHERE setting_id = 104;

             SELECT @hidePhone = CASE WHEN valor = ''0''
                                 THEN 0 ELSE 1
                                 END FROM ccSettings WHERE setting_id = 223;

             IF @topRows = 0
             BEGIN
                 SET @topRows = 10000;
             END;

             SET @dateStart = DATEADD(hh, -@maxHours, GETDATE());

             WITH timeTransfer
                  AS (SELECT cal_id
                           , tipo
                           , SUM(tAntesXfer) AS tAntesXfer
                           , SUM(tDespuesXfer) AS tDespuesXfer FROM ccLogTransfers
                      WHERE fechaFin > @dateStart
                      GROUP BY cal_id
                             , tipo)

                  INSERT INTO @lastCallAgt
                         ---Insert OUT
                         SELECT TOP (@topRows) c.cal_id AS id
                                             , ''OUT'' AS Tipo
                                             , cal_inicio
                                             , cal_telefono AS Telefono
                                             , cam_descripcion AS EspCamp
                                             , ISNULL(cal.Description, '''') AS Calificacion
                                             , CONVERT(VARCHAR(8), DATEADD(ss, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0
                                                                                                        THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
                                                                                                        END, 0), 114) AS Duracion
                                             , cal_fcallback AS CallBack
                                             , cal_key
                                             , c.cam_id AS IDCampEsp
                                             , ISNULL(ccCamps.prefijo, '''') Prefijo
                                             , graph.graphic_id GraphicID
                                             , cam_ModoManual as CamManualMode 
                                             , ISNULL(selectRotativeANI, 0) as SelectRotativeANI FROM ccoCallsOut c
                                                                               INNER JOIN ccCamps ON ccCamps.cam_id = c.cam_id
                                                                               LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = c.cam_id
                                                                               LEFT JOIN ccTipoCalifOut cal ON c.calif_id = cal.calif_id
                                                                               LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
                                                                                                           AND t.tipo = 2
                         WHERE user_id = @user_id
                               AND cal_inicio > @dateStart
                         UNION
                         --- IN
                         SELECT TOP (@topRows) c.cal_id AS id
                                             , ''IN'' AS Tipo
                                             , cal_inicio
                                             , cal_ani AS Telefono
                                             , descripcion AS EspCamp
                                             , ISNULL(cal.Description, '''') AS Calificacion
                                             , CONVERT(VARCHAR(14), DATEADD(second, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0
                                                                                                             THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
                                                                                                             END, 0), 108) Duracion
                                             , NULL AS CallBack
                                             , cal_key
                                             , c.inbound_id AS IDCampEsp
                                             , ISNULL(ccInbound.prefijo, '''') Prefijo
                                             , graph.graphic_id GraphicID
                                             , '''' as CamManualMode 
                                             , 0 as SelectRotativeANI FROM ccCallsIn c WITH (NOLOCK INDEX(IX_ccCallsIn_4))
                                                                               JOIN ccRIAInboundGraph graph ON graph.Inbound_id = c.Inbound_id
                                                                               INNER JOIN ccInbound ON ccInbound.Inbound_id = c.Inbound_id
                                                                               LEFT JOIN ccTipoCalif cal ON c.calif_id = cal.calif_id
                                                                               LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
                                                                                                           AND t.tipo = 1
                         WHERE user_id = @user_id
                               AND cal_inicio > @dateStart;

             SELECT Id
                  , tipo
                  , CASE WHEN @pais = 4
                    THEN(CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) ELSE(CONVERT(VARCHAR(10), Hora, 103) + '' '' + CONVERT(VARCHAR(8), Hora, 14))
                    END AS Hora
                  , Telefono
                  , EspCamp
                  , Calificacion
                  , ISNULL(CONVERT(VARCHAR(16), CallBack, 121), '''') AS CallBack
                  , Duracion
                  , CallBack
                  , cal_key
                  , IDCampEsp
                  , prefijo
                  , GraphicID
                  , @hidePhone AS HidePhone 
                  , CamManualMode 
                  , SelectRotativeANI FROM @lastCallAgt
             ORDER BY hora DESC;
             SET NOCOUNT OFF;'
	EXEC(@sql)



	---------------------------------------END Rodrigo Salazar-----------------------------------------------------------
	
	/* End script release */
	/* Upgrade database version (first and the last number of setting 77) */
	EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
	EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

	COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END