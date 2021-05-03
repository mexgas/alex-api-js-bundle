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

	set @process = 'CW-4990 modificar el sp ccsp_RIARegistryLists para obtener la variable list_id'
	set @sql = '
Alter Procedure [dbo].[ccsp_RIARegistryLists]
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


	set @process = 'CW-5157 Crear un nuevo setting para posicion de engines locales'
	set @sql = '
	if not exists(select * from ccsettings where setting_id=227)
	begin
		insert ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
		values (227,'''',''Posición de engine(s) locales'',1,''ADM'',''pbxId|IP de los engine(s) locales separados por comas y pipe 1|127.0.0.1:5060,2|127.0.0.2::5060. Corresponde a los engines para llamadas internas.'',''Local Engine location'',1,''^((([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}(25[0-5]|[01]?\d\d?|2[0-4]\d),?)+$'')

		update ccsettings set valor=(select valor from ccsettings where setting_id=143) where setting_id=227

		update ccsettings set descripcion=''Posición de engine(s) remotos'',detalle=''pbxId|IP de los engine(s) remotos separados por comas y pipe 1|127.0.0.1:5060,2|127.0.0.2::5060. Corresponde a los engines para llamadas remotas.'',description=''Remote Engine location'' where setting_id=143
	end'
	exec (@sql)

	set @process = 'CW-5157 Check if exist ccsp_DLRGetPBXInfo'	
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_DLRGetPBXInfo'')
            begin
          DROP PROCEDURE ccsp_DLRGetPBXInfo;
            end'
    EXEC(@sql)

	set @process = 'CW-5157 Crear SP para posicion de engines locales'
	set @sql = '
	CREATE procedure [dbo].[ccsp_DLRGetPBXInfo]
	@pbx_id int
	AS
	set nocount on

	declare @port varchar(5), @remotes varchar(300)
	select @port = valor from ccsettings where setting_id=119
	select @remotes = valor from ccsettings where setting_id=227
	select 
	case when charindex('':'',pbxIp)>0 then substring(pbxIp, 0, charindex('':'',pbxIp)) else pbxIp end pbxUri, 
	case when charindex('':'',pbxIp)>0 then substring(pbxIp, charindex('':'',pbxIp)+1, 5) else @port end port
	from
	(select
	substring(value,0,charindex(''|'',value)) pbxId,
	substring(value,charindex(''|'',value)+1,len(value)) pbxIp
	from dbo.fn_RIASplitDelimited(@remotes, '','')
	where cast(substring(value,0,charindex(''|'',value)) as int)=@pbx_id) x

	set nocount off'
	exec (@sql)

	set @process = 'CW-5140 Check if exists ccsp_GalateaAdminDispositions'	
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminDispositions'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminDispositions;
            end'
    EXEC(@sql)

	set @process = 'CW-5140 Create ccsp_GalateaAdminDispositions'	
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminDispositions]
@command int
AS
set nocount on

if @command=1 -- Load cctipoCalif
begin
  Select C.calif_id, C.Description, C.orden, C.canReprogram, cast(0 as bit) as contactOwner, 
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.EndConversation,0) conversationEnd
  from cctipoCalif C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 1
  where C.Calif_Status=1
  group by C.calif_id, C.Description, C.orden, C.canReprogram, C.EndConversation
  order by 2
  return(0)
end

If @command=2 -- Load cctipoCalifOUT
begin
  Select C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback,  
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.contactOwner,0) as contactOwner, 
  IsNull(C.finishPreview,0) as finishPreview
  from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
  where C.CalifOut_Status=1
  group by C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback, 
  C.contactOwner, C.finishPreview
  order by 2
  return(0)
end

set nocount off'
    EXEC(@sql)

	set @process = 'CW-5168 CW-5155 Check if exists ccsp_GalateaDispositionRelations'	
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaDispositionRelations'')
            begin
          DROP PROCEDURE ccsp_GalateaDispositionRelations;
            end'
    EXEC(@sql)

	set @process = 'CW-5168 CW-5155 Check if exists ccsp_GalateaAdminDispositionRelations'	
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminDispositionRelations'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminDispositionRelations;
            end'
    EXEC(@sql)
	
	set @process = 'CW-5168 CW-5155 Create ccsp_GalateaAdminDispositionRelations'	
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminDispositionRelations]
@command int,
@type tinyint = null, --0=In, 1=Out
@cam_id smallint = null,
@califIdLst varchar(8000) = null
AS
set nocount on
declare @sql as nvarchar(max)

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
If @command=2  --Asignar calificacion(es) a una campaña de entrada o salida
 begin 
	if @Type=0 
	begin	
		set @sql = ''declare @NotAssigned table(NotAssigned int); 
		declare @Assigned table(Assigned int);

		insert into @NotAssigned (NotAssigned)
		select calif_id from ccTipoCalif where CanReprogram=1 and calif_id in ('' + @califIdLst + '')
		and exists(select inbound_id from ccInbound where cam_id is null and Inbound_id= '' + cast(@cam_id as varchar(10)) + '')

		insert into ccCalifCamp(calif_id,cam_id,tipo) 
		select f.calif_id, e.inbound_id, 0 
		from ccInbound e, cctipoCalif f 
		where f.Calif_Status=1 and f.calif_id in ('' + @califIdLst + '') and f.calif_id not in (select NotAssigned from @NotAssigned)
		and Inbound_id = '' + cast(@cam_id as varchar(10)) + ''
		and not exists(
			select a.calif_id,c.inbound_id,0 from cctipoCalif a
			join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 0
			join ccInbound c on c.inbound_id = b.cam_id
			where f.calif_id = a.calif_id and e.inbound_id = c.inbound_id
			and c.Inbound_id = '' + cast(@cam_id as varchar(10)) + '')

		insert into @Assigned (Assigned)
		select calif_id from ccTipoCalif where calif_id in ('' + @califIdLst + '') and calif_id not in (select NotAssigned from @NotAssigned)

		declare @NotAssignedStr varchar(8000), @AssignedStr varchar(8000)
		SELECT @AssignedStr = COALESCE(@AssignedStr + '''','''', '''''''') + cast(Assigned as varchar(10)) from @Assigned
		select @NotAssignedStr = coalesce(@NotAssignedStr + '''','''', '''''''') + cast(NotAssigned as varchar(10)) from @NotAssigned

		select @AssignedStr [Assigned], @NotAssignedStr [NotAssigned]''
		execute sp_executesql @sql
	end
	else
	begin
		set @sql = ''insert into ccCalifCamp(calif_id,cam_id,tipo) 
		select f.calif_id, e.cam_id, 1 from ccCamps e, cctipoCalifOUT f where 
		f.CalifOut_Status=1 and f.calif_id in ('' + @califIdLst + '') and cam_id = '' + cast(@cam_id as varchar(10)) + ''
		and not exists(
		select a.calif_id,c.cam_id, 1 from cctipoCalifOUT a
		join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 1
		join ccCamps c on c.cam_id = b.cam_id
		where f.calif_id = a.calif_id and e.cam_id = c.cam_id
		and b.cam_id = '' + cast(@cam_id as varchar(10)) + '')''
		execute sp_executesql @sql
		update ccCamps set keepDial=dbo.fn_keepDial_Camps(@cam_id) where cam_id=@cam_id	
		return(0)
	end
 end
 If @command=3 -- Desasignar calificacion de campaña de entrada o salida
 begin
	delete ccCalifCamp where cam_id=@cam_id and tipo=@type and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	if @type=0 and not exists(select C.calif_id from ccCalifCamp C join ccTipoCalif T on C.calif_id = T.calif_id and T.CanReprogram=1 and C.Tipo=0 and C.cam_id=@cam_id)
	begin
		update ccInbound set cam_id=null where Inbound_id=@cam_id
	end

	update ccCamps set keepDial=dbo.fn_keepDial_Camps(@cam_id) where cam_id=@cam_id
	return(0)
 end

set nocount off'
    EXEC(@sql)

    	set @process = 'CW-5158 Check if exists ccsp_GalateaGetBlacklistImportStatus'	
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetBlacklistImportStatus'')
            begin
          DROP PROCEDURE ccsp_GalateaGetBlacklistImportStatus;
            end'
    EXEC(@sql)

    set @process = 'CW-5158 Create sp ccsp_GalateaGetBlacklistImportStatus'	
	set @sql = 'CREATE PROCEDURE ccsp_GalateaGetBlacklistImportStatus -- guiandose del sp ccsp_GalateaGetRecordsImportStatus(carga a campañas)
@action tinyint,
@loadID int = NULL

AS
declare @today datetime
select @today =convert(datetime, convert(varchar(11),getdate(),121),121)

SET nocount ON
if @action not IN (1,2)
	BEGIN
		raiserror(''ERROR. No se ingreso parametro de entrada'', 18, 1)
		return (0)
	END

if @action=1 -- Detalle general de carga de registros a listas Negras
BEGIN
     SELECT DISTINCT load_id as LoadId, camName as BlacklistName, cam_id as BlacklistId, pctg as ProgressPercentage , regsNotLoaded+regsBlocked as PhonesNotLoaded,
		regsLoaded as PhonesLoaded, state as LoadState, loadDate as StartLoadDate
        FROM ccRIALoading riaLoad
        WHERE 
        loadDate>=@today
        ORDER BY riaLoad.loadDate DESC
END

if @action=2 -- obtiene datos especificos de una carga a listas Negras a partir del id de carga
BEGIN
     SELECT DISTINCT load_id as LoadId, camName as BlacklistName, cam_id as BlacklistId, pctg as ProgressPercentage , regsNotLoaded+regsBlocked as PhonesNotLoaded,
		regsLoaded as PhonesLoaded, state as LoadState, loadDate as StartLoadDate
        FROM ccRIALoading riaLoad
        WHERE 
        load_id=@loadID
END'
    EXEC(@sql)


    set @process = 'CW-5158 Check if exists ccsp_GalateaValidateAccessMonitoringBlacklistLoads'	
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaValidateAccessMonitoringBlacklistLoads'')
            begin
          DROP PROCEDURE ccsp_GalateaValidateAccessMonitoringBlacklistLoads;
            end'
    EXEC(@sql)

    set @process = 'CW-5158 Create sp ccsp_GalateaValidateAccessMonitoringBlacklistLoads'	
	set @sql = 'CREATE PROCEDURE ccsp_GalateaValidateAccessMonitoringBlacklistLoads 
@userID smallint 
AS

if exists(SELECT User_id FROM ccUsers WHERE TipoUser_id IN(2,6) AND Status>0 AND User_id=@userID)
	SELECT 200 AS Result
ELSE
	SELECT -1 AS Result'
    EXEC(@sql)
	
	
	set @process = 'CW-4105 Se verifica si existe la funcion AsignaIDWS y si no se crea funcion para poder asignar el IDWG'
	set @sql = '
	IF EXISTS (select * from sys.all_objects where name = ''AsignaIDWS'')
	DROP FUNCTION AsignaIDWS;
	'
	exec (@sql)

	set @process = 'CW-4105 Se crea la funcion AsignaIDWS'
	set @sql = '
	CREATE FUNCTION AsignaIDWS (@ID INT, @TIPO INT)
	RETURNS VARCHAR (1000)
	AS
	BEGIN
	DECLARE @RES VARCHAR (1000)=''''
	DECLARE @TIDWG VARCHAR (5)
	DECLARE Cursor1 Cursor
		for SELECT IDWG from ccRIAWorkGroup_Calid WHERE User_id>0 AND cal_id=@ID AND tipo=@TIPO
	open Cursor1
	fetch Cursor1 INTO @TIDWG
	WHILE (@@FETCH_STATUS=0)
	BEGIN
	IF @RES=''''
				SET @RES=@TIDWG
			ELSE
				SET @RES=@RES+'',''+@TIDWG
	fetch Cursor1 INTO @TIDWG
	END
	close Cursor1
	Deallocate Cursor1
	return @RES
	END;
	'
	exec (@sql)

	set @process = 'CW-4105 Se verifica si existe el SP ccsp_AvrsSyncronization'
	set @sql = '
	IF EXISTS (select * from sys.all_objects where name = ''ccsp_AvrsSyncronization'')
	DROP PROCEDURE ccsp_AvrsSyncronization;
	'
	exec (@sql)


	set @process = 'CW-4105 Se implementa la funcion AsignaIDWG en el SP ccsp_AvrsSyncronization'
	set @sql = '
	CREATE PROCEDURE ccsp_AvrsSyncronization
	@action SMALLINT, 
	@maxRecordsToTransfer INT = 10, 
	@id INT = 0
	AS
	SET NOCOUNT ON

	IF @action = 1
	BEGIN
		DECLARE @countrId INT

		SET @countrId = 1

		SELECT @countrId = valor FROM ccSettings WHERE setting_id = 104

		(SELECT TOP (@maxRecordsToTransfer) call.cal_id, user_id, call.Inbound_id, call.calif_id, cast(cal_extension AS INT) AS cal_extension, cal_inicio, cal_ANI AS phone, 
		cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration, cal_key, 0 AS cal_manual, cal_puerto, call.dni_id, fvalida, 
		cal_whohung, isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id, 
		CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh, 
		dateadd(ss, cal_tDialog, cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, ccInbound.prefijo, 1 AS isCallRecord,isnull(dni.dni_numero,'''') as DNIS,dbo.AsignaIDWS (call.cal_id,avrs.tipo) AS IDWG
		FROM ccCallsIn AS call
		INNER JOIN ccInbound ON ccInbound.Inbound_id = call.Inbound_id
		INNER JOIN ccAVRSTransfer avrs ON call.cal_id = avrs.cal_id AND avrs.tipo = 0
		LEFT JOIN ccDNIS dni on dni.dni_id=call.dni_id
		LEFT JOIN (
			SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
			FROM ccLogTransfers
			WHERE tipo = 1
			GROUP BY cal_id, tipo
			) trans ON call.cal_id = trans.cal_id
		where call.User_id>0
		UNION
		
		SELECT TOP (@maxRecordsToTransfer) call.cal_id AS CallId, user_id AS UserId, call.cam_id AS camAcdId, cast(call.calif_id AS SMALLINT) AS califId, cast(cal_extension AS INT) AS extension, 
		cal_inicio, cal_telefono, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration, cal_key, cal_manual, cal_puerto, 0 AS dni_id, fvalida, 
		cal_whohung, isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id, 
		CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh, 
		dateadd(ss, cal_tDialog, cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, camps.prefijo, dbo.EnableCallRecord(camps.call_record, @countrId, cal_telefono) AS isCallRecord, '''' as DNIS,dbo.AsignaIDWS (call.cal_id,avrs.tipo)AS IDWG
		FROM ccoCallsOut AS call
		INNER JOIN ccCamps camps ON camps.cam_id = call.cam_id
		INNER JOIN ccAVRSTransfer avrs ON call.cal_id = avrs.cal_id AND avrs.tipo = 1
		LEFT JOIN (
			SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
			FROM ccLogTransfers
			WHERE tipo = 2
			GROUP BY cal_id, tipo
			) trans ON call.cal_id = trans.cal_id
	   where call.User_id>0)	
	END
	ELSE IF @action = 2
	BEGIN
		DELETE
		FROM ccAVRSTransfer
		WHERE id = @id
	END
	'
	exec (@sql)

	set @process = 'CW-5209 Se verifica si existe el SP ccsp_GalateaAdminBlackLFindNumber'
	set @sql = 'IF EXISTS (select * from sys.all_objects where name = ''ccsp_GalateaAdminBlackLFindNumber'')
		DROP PROCEDURE ccsp_GalateaAdminBlackLFindNumber;
	'
	exec (@sql)


	set @process = 'CW-5209 Se crea el sp ccsp_GalateaAdminBlackLFindNumber'
	set @sql = 'CREATE PROCEDURE ccsp_GalateaAdminBlackLFindNumber--guiandose del sp de xion ccsp_RIAFindNumber
@number varchar(10)

AS
	select distinct a1.idtipolista as BlackListId,tipolista as BlackListName from cclistanegra a1 
	inner join cctiposlistanegra a2 on (a1.idtipolista=a2.idtipolista) where telefono = @number'
	exec (@sql)
	


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
