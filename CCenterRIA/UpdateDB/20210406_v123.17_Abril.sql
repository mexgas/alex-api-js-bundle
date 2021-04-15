/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/04/06
Description:

Database: CCenterRia
Required version: 123.14

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
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 17
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



	set @process = 'CW-4990 Agregar nueva columna a tabla ccRIALoading'
	set @sql = 'if not exists (select * from sys.columns where name = N''list_id'' and Object_ID = Object_ID(N''ccRIALoading''))
    begin
        ALTER TABLE ccRIALoading 
		ADD list_id int
    end'
	exec (@sql)


	set @process = 'CW-4990 Verificar si existe el ccsp_RIARegistryLists'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIARegistryLists'')
            begin
          DROP PROCEDURE ccsp_RIARegistryLists;
            end'
    EXEC(@sql)

	set @process = 'CW-4990 modificar el sp ccsp_RIARegistryLists para obtener la variable list_id'
	set @sql = '
		Create Procedure [dbo].[ccsp_RIARegistryLists]
		@action tinyint = 0, 
		@list_id int = 0,
		@cam_id smallint = 0,
		@name varchar(80) = '''',
		@status tinyint = 0,
		@sequence smallint = 0,
		@load_id int = 0
		AS

		--Status lista 0: inactiva, 1:pausa, 2:procesar

		--Insert
		IF @action = 1 begin

			IF @cam_id <> 0 begin
				select @sequence = isnull(max( sequence ),0) from ccRIARegistryLists where cam_id = @cam_id
				set @sequence = @sequence + 1
				Insert into ccRIARegistryLists(cam_id,name,status,sequence) values (@cam_id, @name, 2, @sequence)
				select max(list_id) from ccRIARegistryLists
			end
		end

		--Update sequence
		IF @action = 2 begin
			
			declare @oldSeq as int
			select @oldSeq = sequence, @cam_id = cam_id from ccRIARegistryLists where list_id = @list_id

			if @oldSeq <> @sequence begin
				
				if @oldSeq > @sequence begin
					update ccRIARegistryLists set sequence = sequence + 1 where cam_id = @cam_id and sequence >= @sequence and sequence < @oldSeq
				end

				if @oldSeq < @sequence begin
					update ccRIARegistryLists set sequence = sequence - 1 where cam_id = @cam_id and sequence <= @sequence and sequence > @oldSeq
				end

				update ccRIARegistryLists set sequence = @sequence where list_id = @list_id

			end

		end

		--Change status
		IF @action = 3 begin
			
			update ccRIARegistryLists set status = @status where list_id = @list_id

		end

		-- lista campañas y listas de registros
		IF @action = 4 begin
			select a.cam_id, b.cam_descripcion, count(list_id) as NoListas, c.graphic_id as Frame from ccRIARegistryLists a 
			left join cccamps b on a.cam_id = b.cam_id
			left join ccRIACampsGraph c on a.cam_id = c.cam_id
			where b.cam_activo = 1 and a.cam_id in ( select distinct(cam_id) from ccRIARegistryLists ) 
			group by a.cam_id,b.cam_descripcion,c.graphic_id order by a.cam_id asc

		end

		-- listas de registros y no. registros
		IF @action = 5 
		begin
			select a.list_id,a.name,count(b.list_id) as NoRegistros,a.sequence   
			from ccRIARegistryLists a with(index(IX_ccRIARegistryLists_1),nolock) 
			left join ccocallsoutsource b with(index(IX_ccoCallsOutSource_13),nolock) 
			on b.cam_id = @cam_id and a.list_id = b.list_id 
			where a.status > 0 and a.cam_id = @cam_id and status > 0 
			group by a.list_id,a.name,a.sequence 
			order by a.sequence
		end

		-- borrar lista
		IF @action = 6 begin

			select @cam_id = cam_id from ccRIARegistryLists where list_id = @list_id
			select @sequence = max(sequence) from ccRIARegistryLists where cam_id = @cam_id
			exec ccsp_RIARegistryLists @action = 3, @status = 0, @list_id = @list_id
			exec ccsp_RIARegistryLists @action = 2, @sequence = @sequence, @list_id = @list_id

		end

		-- Detalle de numero de registros
		IF @action = 7 begin

			declare @total as int

			select @total = count(*) from ccocallsoutsource where list_id = @list_id
			select @total = (@total - count(*)) from ccoworkingtable where list_id = @list_id

			if exists(select list_id from ccoWorkingTable where list_id = @list_id) begin
				select @status = status from ccRIARegistryLists where list_id = @list_id
				select @list_id as list_id,cam_id, @status as status,
					count(case cal_status when 0 then 1 else null end) as New,
					count(case cal_status when 1 then 1 else null end) as CB,
					count(case cal_status when 2 then 1 else null end) as Pro, 
					@total as Fin
				from ccoWorkingTable where list_id = @list_id group by cam_id
			end
			ELSE begin
				select list_id, cam_id, status, 
				0 as New,
				0 as CB,
				0 as Pro,
				0 as Fin
				from ccRIARegistryLists where list_id = @list_id
			end


		end

		-- Cambia de nombre a la lista
		IF @action = 8 begin
			
			update ccRIARegistryLists set name = @name where list_id = @list_id

		end

		-- Borra listas sin registros y reordena las listas
		IF @action = 9 begin

			Create table #TempRegs(
				list_id int,
				[name] varchar(100),
				NoRegistros int,
				sequence int)

			insert into #TempRegs 
				select a.list_id,a.name,count(b.list_id) as NoRegistros,a.sequence 
				from ccRIARegistryLists a with(index(IX_ccRIARegistryLists_1),nolock)
				left join ccocallsoutsource b with(index(IX_ccoCallsOutSource_14),nolock)
				on a.list_id = b.list_id
				where a.status > 0 and a.cam_id = @cam_id and status > 0 
				group by a.list_id,a.name,a.sequence,a.status order by a.sequence

			while ( exists( select list_id from #TempRegs where NoRegistros = 0 ) ) begin
				declare @listToDelete as int
				select top 1 @listToDelete = list_id from #TempRegs where NoRegistros = 0
				exec ccsp_RIARegistryLists @action = 6, @list_id = @listToDelete
				delete from #TempRegs where list_id =  @listToDelete
			end

			drop table #TempRegs
			
			select @sequence=min(sequence) from ccRIARegistryLists where  cam_id = @cam_id and status = 0 

			select @list_id= list_id from ccRIARegistryLists where sequence =(
			select  max(sequence) as sequence from ccRIARegistryLists where  cam_id = @cam_id and status > 0 ) and cam_id = @cam_id
			update ccRIALoading set list_id = @list_id where load_id=@load_id
			exec ccsp_RIARegistryLists @action=2,@list_id=@list_id,@sequence=@sequence

			end'
	exec (@sql)






	set @process = 'CW-5100 Crear un nuevo setting para timeout de ventana de error'
	set @sql = '
	if not exists( select * from ccSettings where setting_id = 226)
	begin
		insert into ccSettings (setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate) 
		values (226, 10000, ''Tiempo de timeout para la ventana de error al cargar la informacion'', 1, ''AGT'', ''Tiempo en segundos que tardara en mostrarse la ventana de error al cargar la informacion cuando se solicita un catalogo en el agente y este no carga debido a una desconexion de red'', ''Time of timeout for the error window when loading the information'', 1, ''.*'')
	end'
	exec (@sql)

	set @process = 'CW-5082 Se actualiza el detalle del setting por que se agrego una opcion nueva'
	set @sql = '
	update ccsettings set detalle=''setting para ocultar el telefono en el agente (0 lo muestra, -1 lo oculta, > 0 Es el numero de digitos que se mostraran de derecha a izquierda )'', description=''Setting to hide telephone number, 0 Show the number, -1 Hide the number, >0 Number of digits that will be show from right to left'', validate=''*'' where setting_id=223
	'
	exec (@sql)

	set @process = 'CW-4870 se quita el sp ccsp_GalateaGetCampsNvosCB si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetCampsNvosCB'')
            begin
          DROP PROCEDURE ccsp_GalateaGetCampsNvosCB;
            end'
        EXEC(@sql)

	set @process = 'CW-4870 se crea sp ccsp_GalateaGetCampsNvosCB'
	set @sql = ' CREATE PROCEDURE [dbo].[ccsp_GalateaGetCampsNvosCB]
@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
@regval int =0, @tcpa int=0
as
set nocount on

declare @TipoJobs as int, @isExecOutbound bit

set @isExecOutbound= case when @regval=0 then 0 else 1 end

-- Actualiza todas las camps
if @Tipo in (1,2) begin

	declare @id AS INTEGER

	CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)
	CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,dateUpdate datetime)

	create table #temccocallsoutsource (cam_id int,Pend  int)

	create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

	if @cam_id = 0 begin
		if @user_id > 0 and not exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
			insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
			select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
			from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
			where user_id = @user_id and tipo = 1
		end
		else begin
			insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
			select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
			from ccCamps cam (nolock)
		end
	end
	else begin
		if @Tipo = 2
			insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
			select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
			from ccCamps cam with(nolock) 
			where cam.cam_id = @cam_id
		else
			if @user_id > 0 and not exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
				insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
				select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
				from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
				where user_id = @user_id and tipo = 1
			end
			else begin
				insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
				select cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
				from ccCamps cam (nolock) 
				where cam_activo=1 
			end
	end



	insert into  #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,dateUpdate)
	select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0,max(dateUpdate) from(
	select A.*,dateUpdate from #Tcamps A
	left join ccCampsNvosCB B (nolock) on A.cam_id=B.id
	where datediff(ss,B.dateUpdate,getdate())> case @tcpa when 1 then 1 else 5 end or B.dateUpdate is null)X
	group by cam_id


	
	if (select count(*) from #Tcamps2)>0 begin

		insert into #temccocallsoutsource(cam_id,Pend)
		SELECT ccos.cam_id, count(ccos.cam_id) as Pend
		FROM ccocallsoutsource ccos with(index(IX_ccoCallsOutSource_17),nolock)
		join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
		WHERE cal_status in(0, 7)
		GROUP BY ccos.cam_id

		insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
		SELECT A.cam_id,
		count(case cal_status when 0 then 1 else null end) as New,
		count(case cal_status when 1 then 1 else null end) as Cb,
		count(case cal_status when 2 then 1 else null end) as Pro,
		count(case cal_status when 3 then 1 else null end) as Fin
		FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
		join #Tcamps2 B on A.cam_id = B.cam_id
		GROUP BY A.cam_id	

	
		if (@regval = 0 and @cam_id >0 and @Tipo =2) or @tcpa = 1 begin
		update #Tcamps2 set status =1,cantidad=0  where cam_id = @cam_id
		end
		else begin
			While exists(select * from #Tcamps2 where status = 0 and ( datediff(ss,dateUpdate,getdate())>60 or dateUpdate is null))  Begin
				set rowcount 1
				select @id = cam_id,@TipoJobs=cam_tipojobs from #Tcamps2 where status = 0 order by cam_id
				set rowcount 0
				EXEC @regval = ccsp_OUTGetNewJobs @id,2,0
				update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @id
			end
		end

		declare @TotalNew table(
				cam_id int primary key,
				OverallTotalNew int 
			)
		

		begin Tran updateccCampsNvosCB

			insert into @TotalNew
			select CampNvosCB.id,isnull(CampNvosCB.OverallTotalNew,CampNvosCB.new)  from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
			where CampNvosCB.id = tcamp.cam_id

			delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
			where CampNvosCB.id = tcamp.cam_id

			INSERT into ccCampsNvosCB 
			SELECT cams.cam_id, cams.cam_descripcion,
			isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb,
			isNull(cs.Pend,0) as pend,
			isNull(wt.Pro,0) as pro,
			isNull(cams.procesando,0) cam_procesando,
			isNull(cams.cam_tipojobs,0) cam_tipojobs,
			isNull(wt.Fin,0) Fin,
			isNull(cams.cantidad,0) cantidad,
			getdate(),
			isnull(T.OverallTotalNew,0)  as OverallTotalNew
			FROM #Tcamps2 cams with(nolock)
			LEFT JOIN #temWorkinTable  wt on cams.cam_id = wt.cam_id
			LEFT JOIN #temccocallsoutsource cs on cams.cam_id = cs.cam_id
			LEFT JOIN @TotalNew  T on T.cam_id = cams.cam_id

		COMMIT TRAN updateccCampsNvosCB
	end

	if @isExecOutbound = 0 begin

	if @Tipo = 2 begin
		-- devuelve resultado de la taba, solo las camps del usuario
		SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, cc.cam_procesando as st, res.job, res.Fin, 
		isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial,cc.aggressionFactor, OverallTotalNew
		FROM #Tcamps tcam
		left join  ccCampsNvosCB res (nolock) on tcam.cam_id  = res.id
		LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
		inner join cccamps cc (nolock) on res.id=cc.cam_id
	end
	else 
		SELECT id, campaña, new, cb, pro, pen,cc.cam_procesando as st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial,
		cc.aggressionFactor, OverallTotalNew
		FROM ccCampsNvosCB res (nolock)
		LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
		inner join cccamps cc (nolock) on res.id=cc.cam_id
		WHERE res.id = @cam_id
	end

	drop table #Tcamps
	drop table #Tcamps2
	drop table #temccocallsoutsource
	drop table #temWorkinTable

	return(0)

end

set nocount off'
	exec (@sql)
	
	 set @process = 'CW-5008 Valida si existe campo DialingMode en ccUsers'
		set @sql = 'IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccUsers'' AND COLUMN_NAME = ''DialingMode'')
				Begin
				ALTER TABLE ccUsers 
				ADD DialingMode bit NOT NULL
				CONSTRAINT DF_ccUsers_DialingMode DEFAULT 0
				WITH VALUES
				End'
        EXEC(@sql)

set @process = 'CW-5008 se quita el sp ccsp_GalateaADMPermisos si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaADMPermisos'')
            begin
          DROP PROCEDURE ccsp_GalateaADMPermisos;
            end'
        EXEC(@sql)


	set @process = 'CW-5008 se crea sp ccsp_GalateaADMPermisos'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaADMPermisos]
@users_id varchar(255),
@Type int, -- 1.- cambia permiso, 2.- obtiene lista de permisos
@Permit int, -- 1.- Permiso de marcacion
@Value int --Valor para permiso tipo de marcacion
AS
set nocount on

If @Type = 1 --1 Update Permission DialingMode
 begin
	 if @permit = 1 --DialingMode/PreviewPro
	 begin
		 if @Value = 0
		 begin
	   			UPDATE ccUsers SET DialingMode = @Value
				where user_id in (select value from dbo.fn_RIASplitDelimited(@users_id, '',''))
				return(0)
		 end
		 if @Value = 1
		 begin
	   			UPDATE ccUsers SET  DialingMode = @Value
				where user_id in (select value from dbo.fn_RIASplitDelimited(@users_id, '',''))
				return(0)
		 end
		 if @Value = 2
		 begin
	   			UPDATE ccUsers SET AllowChangeDialingMode = 1
				where user_id in (select value from dbo.fn_RIASplitDelimited(@users_id, '',''))
				return(0)
		 end
		 if @Value = 3
		 begin
	   			UPDATE ccUsers SET AllowChangeDialingMode = 0
				where user_id in (select value from dbo.fn_RIASplitDelimited(@users_id, '',''))
				return(0)
		 end
	end
 end

if @Type = 2 --Get Permission
begin
	return(0)
end

set nocount off

'
	exec (@sql)
	
	set @process = 'CW-5060 Check if exist ccsp_GalateaDispositionRelations'	
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaDispositionRelations'')
            begin
          DROP PROCEDURE ccsp_GalateaDispositionRelations;
            end'
    EXEC(@sql)

	set @process = 'CW-5060 Create sp ccsp_GalateaDispositionRelations'	
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaDispositionRelations]
@command int
AS
set nocount on
If @command = 1
begin
	select 
		cast (0 as int) [type], 
		i.inbound_id as cam_id, 
		c.calif_id 
	from ccInbound i inner join ccCalifCamp c on i.inbound_id = c.cam_id and c.tipo = 0
	inner join ccTipoCalif t on c.calif_id = t.calif_id
	UNION
	select 
		cast (1 as int) [type], 
		o.cam_id, 
		c.calif_id 
	from ccCamps o inner join ccCalifCamp c on o.cam_id = c.cam_id and c.tipo = 1
	inner join ccTipoCalifOUT co on c.calif_id = co.calif_id
	order by [type], cam_id, calif_id
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
