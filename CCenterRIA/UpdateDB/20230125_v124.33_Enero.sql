/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124.25

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
SET @version = 124 --**********actualizar a 123 sin fix
SET @versionfix = 33
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

	SET @process = 'DEV3-208 DROP PROCEDURE ccsp_GalateaUnavailableByAdmin'
	SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaUnavailableByAdmin'')
		BEGIN
			DROP PROCEDURE ccsp_GalateaUnavailableByAdmin;
		END'
	EXEC(@sql)

	SET @process = 'DEV3-208 CREATE PROCEDURE ccsp_GalateaUnavailableByAdmin'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaUnavailableByAdmin]
@Command int,
@User_id smallint = null,
@Action bit=1,
@NR_ids varchar(max) = ''''
AS
SET NOCOUNT ON

IF @Command = 1
BEGIN
	select snr.TipoNotReady_id
	from ccTipoNotReady t
	inner join ccSupervisor_NotReady snr on t.TipoNotReady_id = snr.TipoNotReady_id
	inner join ccUsers u on snr.user_id = u.user_id
	inner join ccRiaNotReadyGraph nrg on t.TipoNotReady_id = nrg.TipoNotReady_id
	inner join ccRiaGraphics g on nrg.graphic_id = g.graphic_id
	where t.TipoNotReady_id > 0 and t.StatusTipoNotReady = 1 and snr.user_id = @User_id
	return(0)
END

IF @Command = 2
BEGIN
	declare @NRTemp table (id int primary key not null)

	insert into @NRTemp
	select value from dbo.fn_RIASplitDelimited (@NR_ids, '','')

	if @Action=0
	begin
		delete from ccSupervisor_NotReady where user_id = @User_id and TipoNotReady_id in (select id from @NRTemp)
	end
	else
	begin
		insert ccSupervisor_NotReady 
		select @User_id , tiponotready_id
		from ccTipoNotReady
		where TipoNotReady_id in (select id from @NRTemp)
		and cast(@User_id as varchar(10)) + ''|'' + cast(TipoNotReady_id as varchar(10))
		not in (select cast(user_id as varchar(10)) + ''|'' + cast(TipoNotReady_id as varchar(10)) 
		from ccSupervisor_NotReady)
	end
	return(0)
END

SET NOCOUNT OFF'
	EXEC(@sql)	

	SET @process = 'DEV3-208 DROP PROCEDURE ccsp_GalateaUnavailableStates'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaUnavailableStates'')
            begin
				DROP PROCEDURE ccsp_GalateaUnavailableStates;
            end'
    EXEC(@sql)

    set @process = 'DEV3-208 CREATE PROCEDURE ccsp_GalateaUnavailableStates'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaUnavailableStates]
@NotReady_id smallint = null,
@Description varchar(30)='''',
@Acc_Time int = null,
@Intervals int = null,
@Pass_Supv tinyint = null,
@NextStatus int = null,
@Frame smallint = null,
@Type varchar(1)='''',
@IsSupv int = null,
@NotReady_ids varchar(max)=''''
AS
set nocount on
DECLARE @sql nvarchar(4000), @graph nvarchar(1000), @id smallint, @newGraph smallint

	if @Type = 1 -- LOAD
		begin
			SELECT distinct a1.TipoNotReady_id as NotReady_Id, a1.Descripcion as Description, a1.Time_Acum as Acc_Time, a1.Time_xEv as Intervals, 
			cast(a1.Pas_Sup as bit) Pass_Supv, a1.NextStatus, frame as Frame, cast(a1.IsSup as bit) IsSupv
			FROM ccTipoNotReady a1 
			inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
			inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
			where a1.StatusTipoNotReady=1
			order by 2
		end

	If @Type=2 -- INSERT
	 begin
		if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Description)
		 begin		
			select -1
			return(0)
		 end
		if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=0 and Descripcion=@Description)
			begin		
				select @id=TipoNotReady_id from ccTipoNotReady where Descripcion=@Description
				update ccTipoNotReady set 
				Time_acum=@Acc_Time,
				Time_xEv=@Intervals,
				Pas_Sup=@Pass_Supv,
				NextStatus=@NextStatus,
				IsSup=@IsSupv,
				StatusTipoNotReady=1
				where Descripcion=@Description
				If not exists(select frame from ccRIAGraphics where frame = @Frame and type_id = 4)
					Begin
						insert into ccRIAGraphics (frame, type_id) select @Frame,4
					End
			
				insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @Frame and type_id = 4
				select cast(@id as int)
				return(0)		
			end
		If not exists(select frame from ccRIAGraphics where frame = @Frame and type_id = 4)
		 Begin
			insert into ccRIAGraphics (frame, type_id) select @Frame,4
		 End

		insert ccTipoNotReady (Descripcion, Time_Acum, Time_xEv, Pas_Sup, NextStatus, IsSup, StatusTipoNotReady) 
		select @Description, @Acc_Time, @Intervals, @Pass_Supv, @NextStatus, @IsSupv,1
		select @id=SCOPE_IDENTITY()
		insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @Frame and type_id = 4
		select cast(@id as int)
	 end

	If @Type=3 -- DELETE
	 begin
		 declare @NDs_Ids table (id int primary key not null)

		if @NotReady_id is null
		 begin
			insert into @NDs_Ids
			select value from dbo.fn_RIASplitDelimited (@NotReady_ids, '','')
		 end
		else
		 begin
			insert into @NDs_Ids
			select @NotReady_id
		 end

		exec ccsp_AdminNotready 3,0,@NotReady_id,0, @NotReady_ids
		delete ccRIANotReadyGraph where tipoNotReady_id in (select id from @NDs_Ids)
		update ccTipoNotReady set StatusTipoNotReady=0 where tipoNotReady_id in (select id from @NDs_Ids)
		update ccTipoNotReady set NextStatus=-1 where NextStatus in (select id from @NDs_Ids)
	
		select cast(id as smallint) NotReady_Id, 0 as Related from @NDs_Ids
	 end

	if(@Type=4) --UPDATE
	 begin

		if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Description and TipoNotReady_id not in (@NotReady_id))
		 begin		
			select -1
			return(0)
		 end

		update ccTipoNotReady set 
		 Descripcion=case @Description when '''' then Descripcion else @Description end,
		 Time_Acum=ISNULL(@Acc_Time,Time_Acum),
		 Time_xEv=ISNULL(@Intervals,Time_xEv),
		 Pas_Sup=ISNULL(@Pass_Supv,Pas_Sup), 
		 NextStatus=ISNULL(@NextStatus,NextStatus), 
		 IsSup=ISNULL(@IsSupv,IsSup)
		where TipoNotReady_id=@NotReady_id

		IF ISNULL(@Frame,'''') not in('''')
		 BEGIN
			If not exists (select frame from ccRIAGraphics where frame = @Frame and type_id = 4)
			 begin
				insert into ccRIAGraphics (frame, type_id) select @Frame,4
			 end

			select @graph = graphic_id from ccRIAGraphics where frame = @Frame and type_id = 4
			update ccRIANotReadyGraph set graphic_id=cast(@graph as smallint) where TipoNotReady_id=cast(@NotReady_id as tinyint)
		 END
		 select 1
	 end

	if @Type = 5
	 begin
		select cast(NextStatus as smallint) NotReady_Id, cast(TipoNotReady_id as int) Related
		from ccTipoNotReady 
		where StatusTipoNotReady=1 and NextStatus in (select value from dbo.fn_RIASplitDelimited (@NotReady_ids, '',''))
	 end

set nocount off'
    EXEC(@sql)
	
	




		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
