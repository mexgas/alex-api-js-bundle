/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/02/15
Description: Merge con los cambios de sorteos

Database: CCenterRia
Required version: 123.27

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
SET @versionfix = 13
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
	 ---------------- KR008000_Callkey_en_llamadas_manuales ----------------------------------------------------
		set @process = 'KR008000_Callkey_en_llamadas_manuales create table ccOdbc'
        set @sql = 'if not exists (select * from sys.tables where name = N''ccOdbc'')
        begin
            create table [dbo].[ccOdbc](
			[odbc_id] [SMALLINT] PRIMARY KEY IDENTITY(1,1) NOT NULL,
			[value] [VARCHAR](300) NULL,
			[description] [VARCHAR](600) NOT NULL,
			[status] [TINYINT] NULL,
			[detail] [VARCHAR](600) NULL,
			[tableName] [VARCHAR](300) NULL,
			[columnName] [VARCHAR](300) NULL,
			[columnPhone] [VARCHAR](300) NULL,
			[columnCallKey] [VARCHAR](300) NULL)
        end'
        EXEC(@sql)

		SET @process = 'KR008000_Callkey_en_llamadas_manuales add column to ccCamps table'
		set @sql = 'IF not exists (SELECT * FROM sys.columns WHERE name = N''odbc_id'' AND Object_ID = Object_ID(N''ccCamps''))
			BEGIN
				alter table ccCamps add odbc_id smallint null
			END'
		EXEC(@sql)

		set @process = 'KR008000_Callkey_en_llamadas_manuales Add Constraint FK_ccCamps_ccOdbc'
        set @sql = 'IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
            WHERE CONSTRAINT_NAME =''FK_ccCamps_ccOdbc'')
            BEGIN
				ALTER TABLE dbo.ccCamps DROP CONSTRAINT FK_ccCamps_ccOdbc
            END
			ALTER TABLE dbo.ccCamps ADD CONSTRAINT FK_ccCamps_ccOdbc FOREIGN KEY (odbc_id) REFERENCES dbo.ccOdbc(odbc_id)'

		EXEC(@sql)

		set @process = 'KR008000_Callkey_en_llamadas_manuales add setting 239'
        set @sql = 'IF NOT EXISTS(	SELECT cs.setting_id FROM dbo.ccSettings AS cs WHERE cs.setting_id = 239)
            BEGIN
				INSERT INTO dbo.ccSettings(setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate)
				VALUES(239, ''0'', ''Tipo de ODBC a utilizar'', 1, ''AGT'', ''Permite elegir el método de ODBC a utilizar en Agente Kolob. Valores(0,1,2). 0 = No configurado (valor default), 1 = Configuración de un ODBC, 2 = Configuración de más de un ODBC.'', 
				''ODBC type to use'', 1, ''^[0-2]$'')
            END'

		EXEC(@sql)

		set @process = 'KR008000_Callkey_en_llamadas_manuales Drop procedure ccsp_ODBCCampaign '
		 SET @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE type = ''P'' AND name = ''ccsp_ODBCCampaign'')
					BEGIN
                        DROP PROCEDURE ccsp_ODBCCampaign
                    END'
        EXEC(@sql)

			set @process = 'KR008000_Callkey_en_llamadas_manuales Create procedure ccsp_ODBCCampaign '
		 SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_ODBCCampaign]
						@campID SMALLINT
					AS
					BEGIN
					SET NOCOUNT ON;

					SELECT co.value, co.tableName, co.columnName,co.columnPhone,co.columnCallKey FROM dbo.ccCamps AS cc
					INNER JOIN dbo.ccOdbc AS co
					ON co.odbc_id = cc.odbc_id
					WHERE cc.cam_id = @campID AND co.status = 1;

					END'
        EXEC(@sql)

		SET @process = 'KR008000_Callkey_en_llamadas_manuales add column to ccoCallsOUT table'
		set @sql = 'IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''cal_odbc'' AND Object_ID = Object_ID(N''ccoCallsOUT''))
			BEGIN
				ALTER TABLE ccoCallsOUT ADD cal_odbc bit NOT NULL default(0)
			END'
		EXEC(@sql)

		SET @process = 'KR008000_Callkey_en_llamadas_manuales Alter procedure ccsp_AGENTInsertCallOut'
		set @sql = 'ALTER PROCEDURE [dbo].[ccsp_AGENTInsertCallOut]
		@cam_id smallint,
		@cal_Key varchar(40),
		@cal_Telefono varchar(30),
		@user_id int,
		@cal_extension varchar(7),
		@sData varchar(255) = '''', --HLAS para guardar notas de la llamada
		@existCallOut as int = 0,
		@callmode as smallint = 0,
		@odbc AS BIT = 0
		AS
		set 
		nocount on
		declare @fecha as datetime, @callout_id as int, @cal_id as int, @calloutMaxTime as int
		select @fecha=getdate()
		declare @dialPrefix integer
		select @dialPrefix = valor from ccSettings where setting_id = 202

		if @callmode = 1 begin
			INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension, cal_odbc) --''''Status 11=Iniciada
			select @existCallOut, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 0, @cal_extension, @odbc
			select @cal_id = scope_identity()

			insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
			select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo 
			from ccRIACampEspWG wg 
			where wg.tipo = 1 and wg.idcampesp =@cam_id

			select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
			select @existCallOut as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
		  return(0)
		end

		if @existCallOut=0  begin
			declare @prefijoMarcacion varchar(100) 
			set @prefijoMarcacion = ''''
			declare @LasCallKey varchar(20)
			set @LasCallKey = @cal_Key
			declare @settingCallKey as int
			select @settingCallKey = valor from ccSettings where setting_id = 194
	  
			if(@settingCallKey = 1) begin
				if (@cal_Key='''' or @cal_Key is null) begin   
					select top 1 @LasCallKey=cal_Key from ccoCallsOut where cam_id=@cam_id and cal_Inicio>=convert(datetime,getdate()) and cal_manual=0 order by cal_id desc
					set @cal_Key= @LasCallKey
				end
			end

			if @dialPrefix = 1 and len(@cal_telefono)>20
				begin
					set @prefijoMarcacion = LEFT(@cal_telefono ,len(@cal_telefono)-10)
					set @cal_telefono = RIGHT(@cal_telefono,10)		
				end
			else 
				begin
					set @prefijoMarcacion =''''			 
				end
		
			INSERT ccocallsoutsource (cal_key, cam_id, cal_telefono, cal_status, user_id, cal_fechaDial, dato1,dialPrefix)
			select @cal_Key, @cam_id, substring(@cal_Telefono, 1, 19), 6, @user_id, @fecha, @sData,@prefijoMarcacion
			select @callout_id = scope_identity()

			INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension, cal_odbc) --''''Status 11=Iniciada
			select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension, @odbc
			select @cal_id = scope_identity()

		
		 end

		else begin --@existCallOut<>0
			Update ccocallsoutsource set cam_id=@cam_id, cal_telefono=substring(@cal_Telefono, 1, 19), dato1=@sData where callout_id = @existCallOut	
			Update ccocallsout set cam_id=@cam_id, cal_telefono=@cal_Telefono where callout_id = @existCallOut
		
			set @callout_id = @existCallOut

			select top 1 @cal_id=cal_id from ccocallsout where callout_id = @callout_id order by cal_id desc
		
			if exists(select * from ccoLogDials where cal_id=@cal_id) begin
				INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension, cal_odbc) --''''Status 11=Iniciada
				select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension, @odbc
				select @cal_id = scope_identity()
			end
		 
		 end
		
		insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
		select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo 
		from dbo.ccRIACampEspWG wg 
		where wg.tipo = 1 and wg.idcampesp =@cam_id


		select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
		select @callout_id as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
		return(0)
	set nocount off'
		EXEC(@sql)

		SET @process = 'KR008000_Callkey_en_llamadas_manuales Alter function fn_getDialingMode '
		set @sql = 'ALTER function [dbo].[fn_getDialingMode](@call_id int, @TipoDialingMode tinyint, @logDial_id int, @cam_id int)
	returns nvarchar(9)
	as
	begin
		declare @valor nvarchar(9), @calif_id smallint, @califSub_id smallint, @cal_manual tinyint, @keepDial char(1), @cal_odbc bit
		set @keepDial=''0''

		-- En el caso de que no cuente con cal_id, se debe contar con logDial_id, por lo cual se busca el registro
		if @call_id is null
		 begin
			select top 1 @call_id=o.cal_id from ccoLogDials l with(nolock,index(PK_ccoLogDials)) join ccocallsout o with(nolock,index(IX_ccoCallsOut_2))
				on l.callout_id = o.callout_id and l.Puerto = o.cal_puerto
			where l.logDial_id = @logDial_id and l.fecha between convert(varchar(19), dateadd(minute, -5, o.cal_inicio), 121)
			and convert(varchar(19), dateadd(minute, 5, o.cal_inicio), 121)
			order by datediff(ss, l.fecha, o.cal_inicio) asc -- en caso de tener mas de uno, toma el que tenga menor diferencia en tiempo
		 end

		if @cam_id is null
		 begin
			select @calif_id=calif_id, @califSub_id=califSub_id, @cal_manual=cal_manual, @cam_id=cam_id, @cal_odbc = cal_odbc
			from ccocallsout O with(nolock,index(PK_ccoCallsOut))
			where O.cal_id = @call_id
		 end
		else
		 begin
			select @calif_id=calif_id, @califSub_id=califSub_id, @cal_manual=cal_manual, @cal_odbc = cal_odbc
			from ccocallsout O with(nolock,index(PK_ccoCallsOut))
			where O.cal_id = @call_id
		 end

		select @valor=isnull((select case when progDial=3 then ''100'' when progDial=2 then ''010'' when progDial=1 then ''001'' else ''000'' end + cast(iTipoDial as char(1)) + cast(abandonCallback as char(1))
		 + cast(excCallback as char(1)) from cccamps where cam_id=@cam_id), ''000000'')

		if ((select keepDial from ccTipoCalifOUT where calif_id = @calif_id)=1
		or (select keepDial from ccTipoCalifSubOUT where califSub_id = @califSub_id)=1)
			set @keepDial=''1''

		select @valor = @valor + @keepDial + case @cal_manual when 1 then ''10'' when 2 then ''01'' else ''00'' end
		
		  select @valor=substring(@valor, 1, 3) +
		  case @TipoDialingMode when 6 then ''1'' else substring(@valor, 4, 1) end + substring(@valor, 5, 2) +
		  case @TipoDialingMode when 3 then ''1'' else substring(@valor, 7, 1) end + substring(@valor, 8, 2)

		  -- Se obtiene el valor del bit en caso de que la llamada manual haya sido mediante ODBC
		  SET @valor = (CASE WHEN @cal_odbc = 1 THEN ''1'' ELSE ''0'' END)+SUBSTRING(@valor,2, LEN(@valor));
		  
	 return @valor
	end'
		EXEC(@sql)


	---------------- KR008000_Callkey_en_llamadas_manuales ----------------------------------------------------


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