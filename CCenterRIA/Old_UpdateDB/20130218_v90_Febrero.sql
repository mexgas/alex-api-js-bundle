/*
Autor: Raymundo Gonzalez
Fecha: 2013/02/18
Descripcion: 	
	Se modifica la tabla cccampsagente para cambiar tipo de dato de la columna user_id
	Se modifica la tabla ccocallsout para cambiar tipo de dato de la columna cal_extension
	Se inserta el setting 127 para activar o desactivar cambio en calculo de formula de nivel de servicio
	Se modifica el SP ccsp_RIAGetAveTimeEspec para modificar la formula de nivel de servicio
	Se crea el SP ccsp_GetAgentListAndRestrictions para devolver restricciones de llamada a WS
	Se crea la tabla ccCamEspAgentStatus para guardar las campañas a gestionar
	Se crea el SP ccAgentStatus para controlar las campañas a gestionar
	Se modifica el SP ccsp_RIAStartStopCamp para iniciar o detener campañas desde WS
	Se inserta registro en ccRIALog_Module para tipificar movimientos realizados desde WS
	Se actualiza la tabla ccRIALog_Operation para correcion de descripcion en eñ registro
	Se quitan valores nulos de ccCmaps.id_anilist
	
Version requerida: 89
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '90'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

		set @process = 'iii - Create Index'
		set @Sql='IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[ccCampsAgente]'') AND name = N''iii'')
DROP INDEX [iii] ON [dbo].[ccCampsAgente] WITH ( ONLINE = OFF )

ALTER TABLE cccampsagente 
ALTER COLUMN user_id smallint

CREATE NONCLUSTERED INDEX [iii] ON [dbo].[ccCampsAgente] 
(
	[user_id] ASC,
	[cam_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]'
	
	EXEC(@Sql)

		set @process = 'ccocallsout - Alter Table'
		set @Sql='ALTER TABLE ccocallsout 
ALTER COLUMN cal_extension varchar(15)'
	
	EXEC(@Sql)
	
		set @process = 'ccsettings - Insert'
		set @sql='insert into ccsettings values(127,0,''activa el cambio de formula de nivel de servicio'',1,''ADM'',''se utiliza para cambiar la formaula de NS,0 = para formula original, 1 = para formula de pentafon'',''Change the arithmetic operation of Service level'',0)'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_RIAGetAveTimeEspec - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAGetAveTimeEspec]
@CveCamp int
AS

declare @fechaI as datetime, @fechaF as datetime
declare @Dlgs as int
declare @DlgsAveTime as int
declare @Que as int
declare @QueueAveTime as int
declare @CallsLost as int
declare @SL1 as int
declare @SL2 as int
declare @answ_tres as smallint
declare @abnd_tres as smallint

declare @nanswer as smallint
declare @nno_answer as smallint
declare @nlost as smallint
declare @nabnd as smallint
declare @ntimeout as smallint
declare @noverflow as smallint
declare @nno_agent as smallint
declare @total as int
declare @setting as tinyint

declare @dia as varchar(11)

declare @tresRing as smallint
declare @tresDialog as smallint
declare @tresDelayIn as smallint

exec @tresRing = ccspConfigTresRing
exec @tresDialog = ccspConfigTresDialog
exec @tresDelayIn = ccspConfigtresDelayIn

--select @dia = ''2003/01/22'' --, @CveCamp=5
select @dia=CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))

select @fechaI = convert(datetime, @dia, 101)
select @fechaF = dateadd( d, 1, @fechaI )
select @setting = valor from ccsettings where setting_id = 127

SELECT 
@Dlgs = count(case when statuscall_id = 13 then 1 else null end), 
@DlgsAveTime = ISNULL(sum( case when statuscall_id = 13 then cal_tDialog + cal_tNotas else null end), 0),

@Que = count(case when cal_que> 0 then 1 else null end), 
@QueueAveTime = ISNULL(sum( case when cal_que > 0 then cal_tWait else null end), 0),

@CallsLost= isnull(COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer IS NULL))  THEN 1 ELSE NULL END), 0), -- ODC

@abnd_tres = COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer IS NULL)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),
@answ_tres =  case when @setting = 0 then COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END) else Count(case when (statuscall_id = 13 and (cal_twait + cal_txfer + cal_tring<@tresDelayIn)) then 1 else null end) end,

@SL1 = case when @setting = 0 then @abnd_tres + @answ_tres else @answ_tres end,

@nanswer = COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),
@nno_answer = COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END),
@nlost = COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),
@nabnd = COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer IS NULL))THEN 1 ELSE NULL END),
@ntimeout = COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),
@noverflow = COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),
@nno_agent = COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),
@total = count(*),

@SL2 = case when @setting = 0 then @nanswer + @nno_answer + @nlost + @nabnd + @ntimeout + @noverflow + @nno_agent else @total end
FROM ccCallsIN
WHERE cal_Inicio between @fechaI AND @fechaF
AND Inbound_id = @CveCamp

select 	''ID''=@CveCamp, ''DlgsAveTime''=@DlgsAveTime/ (@Dlgs+1),  ''QueueAveTime''=@QueueAveTime / (@Que +1),
	''SL'' = case when @SL2 > 0 then 100 * @SL1 / @SL2 else 0 end, ''sl2'' = case when @setting = 0 then case when (@nanswer + @nno_answer + @nlost + @nabnd + @ntimeout + @noverflow + @nno_agent) > 0 then 100 * (@abnd_tres + @answ_tres) / (@nanswer + @nno_answer + @nlost + @nabnd + @ntimeout + @noverflow + @nno_agent) else 0 end else case when @total > 0 then 100 * @answ_tres/@total else 0 end end'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_GetAgentListAndRestrictions - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_GetAgentListAndRestrictions] @areaId int = 0
AS

DECLARE @assistedTransfer int

select @assistedTransfer = valor
from ccsettings
where setting_id = 76

if @areaId = 0
	begin
		select user_id,login,nombres,apellidopaterno,apellidomaterno,sexo,password,
		cast(dialMask & 1 as int) as ''Restringe celular'', cast( (dialMask & 2) /2 as int) as ''Restringe ld'', 
		cast((dialMask & 4) / 4 as int) as ''Restringe local'', cast( xfermask as int) as ''Recibe transferencia'', 
		cast(XferAgents as tinyint) XferAgents, @assistedTransfer as assistedTransfer
		from ccusers 
		where status = 1 
		and tipoUser_id = 1
	end
else
	begin
		select user_id,login,nombres,apellidopaterno,apellidomaterno,sexo,password,
		cast(dialMask & 1 as int) as ''Restringe celular'', cast( (dialMask & 2) /2 as int) as ''Restringe ld'', 
		cast((dialMask & 4) / 4 as int) as ''Restringe local'', cast( xfermask as int) as ''Recibe transferencia'', 
		cast(XferAgents as tinyint) XferAgent, @assistedTransfer as assistedTransfer
		from ccusers 
		where status = 1 
		and tipoUser_id = 1
		and IDArea = @areaId
	end'
	
	EXEC(@Sql)
	
		set @process = 'ccCamEspAgentStatus - Create Table'
		set @Sql='CREATE TABLE [dbo].[ccCamEspAgentStatus](
	[id] [smallint] NOT NULL,
	[type] [bit] NOT NULL,
	[amount] [smallint] NULL CONSTRAINT [DF_ccCamEspAgentStatus_amount]  DEFAULT ((0)),
 CONSTRAINT [PK_ccCamEspAgentStatus] PRIMARY KEY CLUSTERED 
(
	[id] ASC,
	[type] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]'
	
	EXEC(@Sql)
	
		set @process = 'ccAgentStatus - Create Procedure'
		set @Sql='create PROCEDURE [dbo].[ccAgentStatus]
@tipo as tinyint,
@cam as smallint=0,
@inOut as bit=false,
@amount as smallint=0
AS
if @tipo = 0
begin
	select id, [type] from ccCamEspAgentStatus
end
--carga las relaciones de campañas
if @tipo = 1
begin
select cA.user_id,cA.cam_id as id, cA.idWG from cccampsagente cA, ccCamEspAgentStatus CES where cA.cam_id = CES.id and CES.type = 1
end
--carga las relaciones de especialidad
if @tipo = 2
begin
select iA.user_id,iA.inbound_id as id, iA.idWG from ccInboundAgentes iA, ccCamEspAgentStatus CES where iA.inbound_id = CES.id and CES.type = 0
end
--actualiza informacion
if @tipo = 3
begin
update ccCamEspAgentStatus set amount= @amount where id = @cam and type = @inOut
end'
			
	EXEC(@Sql)
	
		set @process = 'ccsp_RIAStartStopCamp - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAStartStopCamp]
@User int,
@Type tinyint,
@Cam_Id int
AS

declare @sql nvarchar(1000)

if( @Type=1)
	begin
		select cam_id, cam_descripcion, cast(cam_procesando as int) as cam_procesando from ccCamps
		where cam_id in (select cam_id from ccSupervisorCam 
		where user_id = @User and tipo = 1) 
		order by cam_procesando DESC, cam_descripcion
	end

if( @Type=2)
	begin
		if NOT EXISTS (select cam_id from ccCamps where cam_id = @cam_id)
		begin
			select -1
		end
		select cast(cam_procesando as int) as cam_procesando from ccCamps
		where cam_id = @cam_id
	end'
			
	EXEC(@Sql)
	
		set @process = 'ccRIALog_Module - Insert'
		set @Sql='INSERT INTO ccRIALog_Module VALUES (53, ''WEBSERVICE|WEBSERVICE'')'
			
	EXEC(@Sql)
	
		set @process = 'ccRIALog_Operation - Update'
		set @Sql='UPDATE ccRIALog_Operation SET descripcion = ''ACTUALIZAR SUBCALIFICACION|UPDATE SUBDISPOSITION'' WHERE operationType = 147'
					
	EXEC(@Sql)

		set @process = 'ccCamps - Update'
		set @Sql='update ccCamps set id_anilist = 0 where id_anilist is null'
					
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
