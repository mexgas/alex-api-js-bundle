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

	/**---------------------------------- BEGIN K035002 ----------------------------------------------------------*/
	SET @process = 'K035002-Listado de agentes-Cambiar a ND delete procedure ccsp_RIACATNotReadyTypes'
	SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RIACATNotReadyTypes'')
		BEGIN
			DROP PROCEDURE ccsp_RIACATNotReadyTypes;
		END';
	EXEC(@sql);

	SET @process = 'K035002-Listado de agentes-Cambiar a ND create procedure ccsp_RIACATNotReadyTypes'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_RIACATNotReadyTypes]
		@TipoNotReady_id varchar(5)='',
		@Descripcion varchar(30)='',
		@Time_Acum varchar(10)='',
		@Time_xEv varchar(5)='',
		@Pas_Sup varchar(2)='',
		@NextStatus varchar(5)='',
		@graphic_id varchar(5)='',
		@Type varchar(1)='',
		@IsSup int = null,
		@super_id as int = null
		AS
		set nocount on
		DECLARE @sql nvarchar(4000), @graph nvarchar(1000), @id smallint, @newGraph smallint

		if @Type=0
		 begin
			SELECT TipoNotReady_id, Descripcion FROM ccTipoNotReady WITH(NOLOCK) WHERE StatusTipoNotReady=1
			return(0)
		 end

		if @Type=6 -- LOAD by setting
		 begin
			select @Type = valor from ccSettings where setting_id = 87

			if @Type = 4 begin
				SELECT a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
				FROM ccTipoNotReady a1 
				inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
				inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
				inner join ccsupervisor_notready snd on (a1.tiponotready_id = snd.tiponotready_id and snd.user_id = @super_id)
				where a1.TipoNotReady_id > 0 
				and a1.IsSup = case @Type when 1 then (select valor from ccSettings where setting_id = 28)
				when 2 then a1.IsSup when 4 then a1.issup else 1 end and a1.StatusTipoNotReady=1
			end
			else begin
				SELECT a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
				FROM ccTipoNotReady a1 
				inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
				inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
				where a1.TipoNotReady_id > 0 
				and a1.IsSup = case @Type when 1 then (select valor from ccSettings where setting_id = 28)
				when 2 then a1.IsSup when 4 then a1.issup else 1 end and a1.StatusTipoNotReady=1
			end
			return(0)
		 end

		if @Type=1 -- LOAD
		 begin
			declare @NotReadybyCampACD int
			select @NotReadybyCampACD = valor from ccsettings where setting_id = 135
	
			if (@NotReadybyCampACD = 0)
			begin
				SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
				FROM ccTipoNotReady a1 
				inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
				inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
				where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
			end
			else if (@NotReadybyCampACD = 1)
				begin
					SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
					FROM ccTipoNotReady a1 
					inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
					inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
					inner join ccUnavailableRelation a4 on (idunavailable = a1.tiponotready_id)
					where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
					and a4.idCampACD in (select distinct(cam_id) from ccSupervisorCam where user_id = @super_id)
					AND a4.type = 0
					union
					SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
					FROM ccTipoNotReady a1 
					inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
					inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
					inner join ccUnavailableRelation a4 on (idunavailable = a1.tiponotready_id)
					where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
					and a4.idCampACD in (select distinct(cam_id) from ccSupervisorCam where user_id = @super_id)
					AND a4.type = 1
				end
			return(0)
		 end

		If @Type=2 -- INSERT
		 begin
			if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Descripcion)
			 begin		
				select 1
				return(0)
			 end
			if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=0 and Descripcion=@Descripcion)
				begin		
					select @id=TipoNotReady_id from ccTipoNotReady where Descripcion=@Descripcion
					update ccTipoNotReady set 
					Time_acum=@Time_Acum,
					Time_xEv=@Time_xEv,
					Pas_Sup=@Pas_Sup,
					NextStatus=@NextStatus,
					IsSup=@IsSup,
					StatusTipoNotReady=1
					where Descripcion=@Descripcion
					If not exists(select frame from ccRIAGraphics where frame = @graphic_id and type_id = 4)
						Begin
							insert into ccRIAGraphics (frame, type_id) select @graphic_id,4
						End
			
					insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @graphic_id and type_id = 4
					return(0)		
				end
			If not exists(select frame from ccRIAGraphics where frame = @graphic_id and type_id = 4)
			 Begin
				insert into ccRIAGraphics (frame, type_id) select @graphic_id,4
			 End

			insert ccTipoNotReady (Descripcion, Time_Acum, Time_xEv, Pas_Sup, NextStatus, IsSup,StatusTipoNotReady) 
			select @Descripcion, @Time_Acum, @Time_xEv, @Pas_Sup, @NextStatus, @IsSup,1
			select @id=SCOPE_IDENTITY()
			insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @graphic_id and type_id = 4
			return(0)
		 end

		If @Type=3 -- DELETE
		 begin
			exec ccsp_AdminNotready 3,0,@TipoNotReady_id,0
			delete ccRIANotReadyGraph where tipoNotReady_id = @TipoNotReady_id
			update ccTipoNotReady set StatusTipoNotReady=0 where tipoNotReady_id = @TipoNotReady_id
		 end

		if(@Type=4) --UPDATE
		 begin

			if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Descripcion)
			 begin		
				select @Descripcion=''
			 end

			update ccTipoNotReady set 
			 Descripcion=case @Descripcion when '' then Descripcion else @Descripcion end,
			 Time_Acum=case @Time_Acum when '' then Time_Acum else @Time_Acum end,
			 Time_xEv=case @Time_xEv when '' then Time_xEv else @Time_xEv end,
			 Pas_Sup=case @Pas_Sup when '' then Pas_Sup else @Pas_Sup end,
			 NextStatus=case @NextStatus when '' then NextStatus else @NextStatus end,
			 IsSup=ISNULL(@IsSup,IsSup)
			where TipoNotReady_id=@TipoNotReady_id

			IF ISNULL(@graphic_id,'') not in('')
			 BEGIN
				If not exists (select frame from ccRIAGraphics where frame = @graphic_id and type_id = 4)
				 begin
					insert into ccRIAGraphics (frame, type_id) select @graphic_id,4
				 end

				select @graph = graphic_id from ccRIAGraphics where frame = @graphic_id and type_id = 4
				update ccRIANotReadyGraph set graphic_id=cast(@graph as smallint) where TipoNotReady_id=cast(@TipoNotReady_id as tinyint)
			 END
			return(0)
		 end

		if @Type = 7 -- LOAD
			begin
				SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
				FROM ccTipoNotReady a1 
				inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
				inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
				where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
				return(0)
			end

		if @Type = 8 -- Check admin permission
			begin
				select @Type = valor from ccSettings where setting_id = 87

				if @Type = 4 begin
					SELECT CAST( count(snd.TipoNotReady_id) AS BIT) AS hasPermission
					FROM ccTipoNotReady a1 
					inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
					inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
					inner join ccsupervisor_notready snd on (a1.tiponotready_id = snd.tiponotready_id and snd.user_id = @super_id)
					where a1.TipoNotReady_id = @TipoNotReady_id 
					and a1.IsSup = case @Type when 1 then (select valor from ccSettings where setting_id = 28)
					when 2 then a1.IsSup when 4 then a1.issup else 1 end and a1.StatusTipoNotReady=1
				end
				else begin
					SELECT CAST(1 AS bit) AS  hasPermission
				end
			end
			set nocount off';

	EXEC(@sql);	

	/**---------------------------------- END K035002 MARCO CHAGOLLA ----------------------------------------------------------*/
	
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
