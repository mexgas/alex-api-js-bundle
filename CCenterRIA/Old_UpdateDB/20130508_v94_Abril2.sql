/*
Autor: Raymundo Gonzalez
Fecha: 2013/05/08
Descripcion:
	Se agrega campo onLine a la tabla ccUsers
	Se actualiza campo online con '0' de la tabla ccUsers
	Se modifica el setting 124 de grabadora (bLoadSettings) para que sea cargado al inicio de la interfaz del administrador
	Se modifica la funcion xmlAppend para cambiar tipo de dato de smallint a int de la variable @indx
	Se modifica el SP ccsp_IVRChecaInboundHorario para agregar funcionalidad de desborde a una especialidad
	Se modifica el SP ccsp_RIAADMChecaLogin para indicar cuando un administrador esta conectado
	Se modifica el SP ccsp_RIAGetRelsSupsAgent para devolver la lista de administradores conectados
	Se cambia el tipo de dato de smallint a int del campo load_id de la tabla ccRIALoading
	Se cambia el tipo de dato de smallint a int del campo load_id de la tabla ccRIALogPhones
	Se creal el SP ccsp_RIACleanLoadingTable para mantener solo la información de un mes en la tabla ccRIALoading
	Se modifica el SP ccsp_RIALogPhones para cambiar el tipo de dato de la variable @load_id de smallint a int
	Se modifica el SP ccsp_RIAADMLoadSettings para devolver el id del pais
	Se crean los indices IX_ccLogAgentesDia_5 y IX_ccLogAgentesNotReady_4 para optimizacion
	Se modifica el SP ccsp_SaveStatusAgent para optimización
	
Version requerida: 93
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '94'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
	---------------- inicio SCRIPT @Sql ----------------
	
		set @process = 'ccSettings - Update'
		set @Sql='Update ccSettings set bLoadSettings = 1 where setting_id = 124'
						
	EXEC(@Sql)

		set @process = 'ccusers - Alter Table'
		set @Sql='alter table ccusers add [onLine] [bit] default 0'
						
	EXEC(@Sql)
	
		set @process = 'ccusers - Update'
		set @Sql='update ccusers set onLine = 0'
						
	EXEC(@Sql)

		set @process = 'xmlAppend - Alter Function'
		set @Sql='ALTER function [dbo].[xmlAppend] (@xml xml, @add varchar(max), @betweenNode varchar(255)) -- Si se agrega se metera la cadena en el nodo
returns xml
as
begin
declare @xml1 varchar(max), @indx int
set @xml1 = cast(@xml as varchar(max))

if @xml is null
 begin
	return @xml
 end

else if @betweenNode is null
 begin 
	return cast(isnull(@xml1,'''')+ isnull(@add, '''') as xml)
 end

else if @add is null
 begin
	return @xml
 end

else
 begin
	set @indx = charindex(@betweenNode, @xml1, 1)
	select @xml1 = replace(@xml1, @betweenNode, '''')
	select @xml1=substring(@xml1, 1, @indx-1) + 
		replace(@betweenNode, ''/'', '''') + @add + replace(replace(@betweenNode, ''/'', ''''), ''<'', ''</'') + 
		substring(@xml1, @indx, len(@xml1))

	set @xml = cast(@xml1 as xml)
 end
 
return @xml
end'
						
	EXEC(@Sql)
	
		set @process = 'ccsp_IVRChecaInboundHorario - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_IVRChecaInboundHorario]
@inbound_id int
AS
set nocount on
declare @fecha datetime
declare @dia smallint
declare @hora smallint
declare @minuto smallint
declare @Cuantos smallint
declare @bnocturno smallint
declare @tel_noct varchar(14)
declare @tel_maxqueue varchar(14)
declare @tel_maxwait varchar(14)
declare @tel_outservice varchar(14)
declare @tHoldCall int
declare @OutOFService tinyint
declare @Active tinyint
declare @stopRecording bit

	SET DATEFIRST 1

	select @fecha =  getdate()
	select @dia = datepart(dw,@fecha), @hora = datepart(hh,@fecha), @minuto = datepart(mi,@fecha)
	if ( @dia=1 )	--LUNES
	begin
		select @Cuantos = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND LUNES = 1
		AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
		AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
	end
	if @dia=2	--MARTES
	begin
		select @Cuantos = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND MARTES = 1
		AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
		AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
	end
	if @dia=3	--MIERCOLES
	begin
		select @Cuantos = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND MIERCOLES = 1
		AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
		AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
	end
	if @dia=4	--JUEVES
	begin
		select @Cuantos = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND JUEVES = 1
		AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
		AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
	end
	if @dia=5	--VIERNES
	begin
		select @Cuantos = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND VIERNES = 1
		AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
		AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
	end
	if @dia=6	--SABADO
	begin
		select @Cuantos = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND SABADO = 1
		AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
		AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
	end
	if @dia=7	--DOMINGO
	begin
		select @Cuantos = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND DOMINGO = 1
		AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
		AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
	end
	--- Para ver si esta Activa la Especialidad
	select @Active = count(*)
	from ccInbound
	where Inbound_id = @inbound_id
	and Status =1
	--- Para ver si esta en Operacion o No esta Campaa
	select @OutOFService = count(*)
	from ccInbound
	where Inbound_id = @inbound_id
	and standby = 0
	IF ( @OutOFService =1 AND @Active=1 and (select valor from ccsettings where setting_id = 4) = 1)
	BEGIN
--			SI ESTA EN SERVICO
		select  @tHoldCall = tMaxWaitCall, @bnocturno =bnocturno, @stopRecording=stopRecording,
			@tel_noct=tel_noct, @tel_maxqueue=tel_maxqueue, @tel_maxwait=tel_maxwait, @tel_outservice=tel_outservice
			from ccInbound I
			Where I.Inbound_id = @inbound_id
	END
	ELSE
	BEGIN
		IF ( @OutOFService = 0 and (select valor from ccsettings where setting_id = 4) = 1)
		BEGIN -- ESPECIALIDAD NO ACTIVA
			select @Cuantos= -1, @tHoldCall =0, @bnocturno ='''', @tel_noct ='''', @tel_maxqueue='''', @tel_maxwait='''', @tel_outservice=''''
			--from ccInbound
			--Where Inbound_id = @inbound_id
		END
		IF ( @Active = 0 )
		BEGIN -- ESPECIALIDAD FUERA DE SERVICIO TEMPORAL
			select @Cuantos= -2, @tHoldCall =0, @bnocturno ='''', @tel_noct ='''', @tel_maxqueue='''', @tel_maxwait='''', @tel_outservice=tel_outservice
			from ccInbound
			Where Inbound_id = @inbound_id
		END 
	END
	SET DATEFIRST 7

	if charindex(''|'',@tel_maxwait) <> 0 begin
		select @tel_maxwait = ''ACD''+[value] from dbo.fn_RIASplitDelimited(@tel_maxwait,''|'') where ID = 2
	end

	if charindex(''|'',@tel_maxqueue) <> 0 begin
		select @tel_maxqueue = ''ACD''+[value] from dbo.fn_RIASplitDelimited(@tel_maxqueue,''|'') where ID = 2
	end

	select ''Cuantos''=@Cuantos, ''tHoldCall''=@tHoldCall, ''bNocturno''=1, ''tel_MaxWait''=@tel_maxwait, ''tel_MaxQueue''=@tel_maxqueue, ''tel_Noct''=@tel_noct, ''tel_outservice''=@tel_outservice, ''stopRecording''=@stopRecording
set nocount off'
						
	EXEC(@Sql)
	
		set @process = 'ccsp_RIAADMChecaLogin - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAADMChecaLogin]
@Login varchar(12) = '''',
@Password varchar(40) = '''',
@PasswordLwC varchar(40) = null,
@adminId int = 0
as
set nocount on

if @adminId <> 0
	begin
		update ccUsers set onLine = 0 where User_id = @adminId
		return(0)
	end

declare @UserID smallint
select @UserID=User_id from ccUsers Where Login=@Login AND TipoUser_id in(2,6) and status>0


if not exists (select Login from ccUsers Where User_id=@UserID 
AND(Password=@Password OR Password = dbo.md5(@password) OR dbo.md5(Password)=@Password
OR Password=@PasswordLwC OR Password = dbo.md5(@PasswordLwC) OR dbo.md5(Password)=@PasswordLwC))
 begin
	SELECT case when @UserID is null then 0 else 1 end ''LoginOK'', 0 ''PswdOK'', 0 ''UserID'', 0 ''Nombre'', 0 ''ADMServer'', 0 ''AreaId''
	return(0)
 end

update ccUsers set Password=isnull(@PasswordLwC, Password) Where User_id=@UserID and Password<>@PasswordLwC

update ccUsers set onLine = 1 where User_id = @UserID

Select 1 ''LoginOK'', 1 ''PswdOK'', User_id ''UserID'', 
 Nombres +'' ''+ isnull(ApellidoPaterno,'''') +'' ''+isnull(ApellidoMaterno,'''') ''Nombre'', 
 (SELECT valor FROM ccSettings WHERE setting_id=8) ''ADMServer'', isnull(IDArea,0) ''AreaId''
From ccUsers Where User_id=@UserID
return(0)
set nocount off'
						
	EXEC(@Sql)
	
		set @process = 'ccsp_RIAGetRelsSupsAgent - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAGetRelsSupsAgent]

AS

--Relaciones Sup-Agt de acuerdo a WorkGroups
select distinct a1.user_id as agt, a5.user_id as sup, a5.login
from ccusers a1 
inner join ccriaworkgroupusers a2 on (a1.user_id=a2.user_id and tipouser_id=1)
inner join (select a3.user_id, a4.IDWG, a3.login  
			from ccusers a3 
			inner join ccriaworkgroupusers a4 on (a3.user_id = a4.user_id and (tipouser_id = 2 or tipouser_id = 6) and a3.onLine = 1)
			) a5 
			on (a2.IDWG = a5.IDWG)
where a5.user_id not in (select User_id from ccRIAUsr_AdminPermissions where per_id = 4) -- Excluye sólo monitoreo
order by a1.user_id, a5.user_id'
						
	EXEC(@Sql)
	
		set @process = 'ccRIALoading - Alter Table(1)'
		set @Sql='alter table ccRIALoading drop constraint PK_ccRIALoading'
						
	EXEC(@Sql)
	
		set @process = 'ccRIALoading - Alter Table(2)'
		set @Sql='ALTER TABLE ccRIALoading
  ALTER COLUMN load_id int'
						
	EXEC(@Sql)
	
		set @process = 'ccRIALoading - Alter Table(3)'
		set @Sql='ALTER TABLE dbo.ccRIALoading ADD CONSTRAINT
	PK_ccRIALoading PRIMARY KEY CLUSTERED 
	(
	load_id
	) WITH( PAD_INDEX = OFF, FILLFACTOR = 100, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
						
	EXEC(@Sql)
	
		set @process = 'ccRIALogPhones - Alter Table'
		set @Sql='ALTER TABLE ccRIALogPhones
  ALTER COLUMN load_id int'
								
	EXEC(@Sql)
	
		set @process = 'ccsp_RIACleanLoadingTable - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_RIACleanLoadingTable]
AS
BEGIN

	delete from ccrialoading
	where loadDate < convert (datetime, convert (varchar(11), dateadd(mm,-1,getDate())))

END'
								
	EXEC(@Sql)
	
		set @process = 'ccsp_RIALogPhones - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_RIALogPhones]
@load_id int,
@Type smallint,
@GenCSV bit = 1-- 0:100 / 1:todos
as
set nocount on

declare @CaseType varchar(2000), @sql varchar(4000), @nType char(5)
select @CaseType = '''', @nType = right(''0000''+cast(@Type as varchar(5)), 5)

if @nType like ''%____1%''
	select @CaseType = @CaseType + '' or isnull(telefono, '''''''') = '''''''' and tipoMov = 0 ''

if @nType like ''%___1_%''
	select @CaseType = @CaseType + '' or isnull(telefono, '''''''') <> '''''''' and tipoMov = 0 ''

if @nType like ''%__1__%''
	select @CaseType = @CaseType + '' or isnull(telefono, '''''''') = '''''''' and tipoMov = 1 ''

if @nType like ''%_1___%''
	select @CaseType = @CaseType + '' or isnull(telefono, '''''''') <> '''''''' and tipoMov = 1 ''

if @nType like ''%1____%''
	select @CaseType = @CaseType + '' or isnull(telefono, '''''''') = '''''''' and tipoMov = 2 ''

if @CaseType = '''' and @nType <> 0
	return(0)

set @sql = ''select '' + case @GenCSV when 0 then ''top 100 '' else '''' end 
	+ ''load_id, cal_key, telefono, tipoMov, motivo 
	from ccRIALogPhones where load_id = '' 
	+ cast(@load_id as varchar(10)) + 
	case when @CaseType <> '''' then '' and ('' + substring(@CaseType, 5, len(@CaseType)) + '')'' else '''' end

exec(@sql)
return(0)

set nocount off'
								
	EXEC(@Sql)
	
		set @process = 'ccsp_RIAADMLoadSettings - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAADMLoadSettings]
@setting_id as tinyint = 0,
@type as tinyint = null,
@ip_admin as varchar(15)=''''
AS

declare @bremlog as tinyint
set nocount on
if @type is null
 begin
	select @bremlog = case when ip = @ip_admin then 1 else 0 end from ccriaremotelog where ip = @ip_admin
	IF @setting_id=0
 		select setting_id, valor, isnull(@bremlog,0) ip_host from ccsettings where Status=''1'' and bLoadSettings = 1 order by setting_id
	ELSE
		select setting_id, valor, isnull(@bremlog,0) ip_host from ccsettings where Status=''1'' and setting_id  = @setting_id
	return(0)
 end

if @type=1 -- Settings de paises
 begin
	select CtyCode, minPhoneLength, maxPhoneLength, CtyID from ccRIACat_Country
	where CtyID in (select valor from ccSettings where setting_id=104)
	return(0)
 end

set nocount off'
								
	EXEC(@Sql)

		set @process = 'Indexes - Create Index'
		set @Sql='CREATE NONCLUSTERED INDEX [IX_ccLogAgentesDia_5] ON [dbo].[ccLogAgentesDia] 
(
	[IdCampEsp] ASC,
	[user_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_ccLogAgentesNotReady_4] ON [dbo].[ccLogAgentesNotReady] 
(
	[IdCampEsp] ASC,
	[user_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]'
	
	EXEC(@Sql)

		set @process = 'ccsp_SaveStatusAgent - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]
@User_id smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady tinyint,
@tStatus smallint,
@TipoCall  tinyint,
@Camp smallint
AS
declare @Fecha4 datetime
set @Fecha4 = getdate()

if @TipoCall > 0
	set @TipoCall = @TipoCall - 1

if (@User_id > 0 )
begin
	if (@TipoStatusAge_id=4) -- 4 = Dialogo
	 begin
		declare @tStatus3 int, @Fecha3 datetime
		select top 1 @tStatus3=tstatus, @Fecha3=fecha from ccLogAgentesDia where TipoStatusAge_id=3 and user_id=@User_id order by fecha desc
		insert into ccLogAgentesDia_Dialog
		select @User_id, cam_id, datediff(ms, dateadd(ss, -@tStatus3, @Fecha3), dateadd(ss, -@tStatus, @Fecha4)), @tStatus3, @Fecha3, @tStatus, @Fecha4
		from cccampsagente where user_id = @User_id
	 end

	INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo )
	VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall )

	if ( @TipoStatusAge_id = 2 )   -- 2 = No Disponible
	begin
		INSERT ccLogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha, IdCampEsp, Tipo )
			VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4, @Camp, @TipoCall )

		---Para Agente RIA: OAYC
		INSERT ccRIALogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha )
			VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4 )			
	end

	-- Actualiza para reporte de tiempos especiales (Boan)
	if @Camp > 0
		begin
			if exists (select * from ccLogAgentesDia with(index(IX_ccLogAgentesDia_5),nolock)
						where IdCampEsp = 0 and user_id = @User_id)
				begin
					update ccLogAgentesDia with(rowlock)
					set IdCampEsp = @Camp, Tipo = @TipoCall
					where IdCampEsp = 0
					and user_id = @User_id
				end
			
			if exists (select * from ccLogAgentesNotReady with(index(IX_ccLogAgentesNotReady_4),nolock)
						where IdCampEsp = 0 and user_id = @User_id)
				begin
					update ccLogAgentesNotReady with(rowlock)
					set IdCampEsp = @Camp, Tipo = @TipoCall
					where IdCampEsp = 0
					and user_id = @User_id
				end
		end
end'
	
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
