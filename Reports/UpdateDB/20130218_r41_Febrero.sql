/*
Autor: Raymundo Gonzalez
Fecha: 2013/02/18
Descripcion: 
	Se modifica la tabla cccampsagente para cambiar tipo de dato de la columna user_id
	Se modifica la tabla ccocallsout para cambiar tipo de dato de la columna cal_extension
	Se crea el SP cc_InboundMetrics para nuevo reporte en Pentafon
	
Version requerida: 40
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '41'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------
		
		set @process = 'usuario - Create Index'
		set @Sql='IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[ccCampsAgente]'') AND name = N''usuario'')
DROP INDEX [usuario] ON [dbo].[ccCampsAgente] WITH ( ONLINE = OFF )

ALTER TABLE cccampsagente 
ALTER COLUMN user_id smallint

CREATE NONCLUSTERED INDEX [usuario] ON [dbo].[ccCampsAgente] 
(
	[user_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]'

	EXEC(@Sql)

		set @process = 'ccocallsout - Alter Table'
		set @Sql='ALTER TABLE ccocallsout 
ALTER COLUMN cal_extension varchar(15)'

	EXEC(@Sql)

		set @process = 'cc_InboundMetrics - Create Procedure'
		set @Sql='CREATE procedure [dbo].[cc_InboundMetrics]
@fecIni as datetime,
@fecFin as datetime,
@acds as varchar(2000)=''''
as

DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint
declare @RtnValue table (Id int identity(1,1), Value nvarchar(100))

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

if @acds = ''''
begin
insert into @RtnValue select inbound_id from ccinbound
end
else
begin
	While (Charindex('','',@acds)>0)
	 Begin 
		Insert Into @RtnValue (value)
		Select Value = ltrim(rtrim(Substring(@acds,1,Charindex('','',@acds)-1)))
 
		Set @acds = Substring(@acds,Charindex('','',@acds)+len('',''),len(@acds))
	 End 
	Insert Into @RtnValue (value)
		Select Value = ltrim(rtrim(@acds))
end

select ci.Fecha, substring(convert(varchar(21),dateadd(mi,-30, ci.Fecha),121),12,5) + '' - '' + substring(convert(varchar(21),ci.Fecha,121),12,5) as [Rango],
i.descripcion [Grupo ACD], isnull(ivr.cantidad,0) [IVR], isnull([Recibidas],0) [Recibidas], isnull([Transferidas],0) [Transferidas], isnull([Atendidas],0) [Atendidas],
case when [Transferidas] > 0 then ([Atendidas] * 100)/ [Transferidas] else 0 end [% Atencion], isnull(answ_tres,0) [Ll. Atendidas < 35],
case when [Transferidas] > 0 then (answ_tres * 100)/ [Transferidas] else 0 end [% NS < 35], isnull([Abandono],0) [Abandono], isnull(abnd_tres,0) [Abandono > 20],
case when [Transferidas] > 0 then ([Abandono] * 100)/ [Transferidas] else 0 end [% Abandono], case when [Transferidas] > 0 then (tdialog + tnotes + THold)/ [Transferidas] else 0 end [TMO IN], [Thold] as [T. Retencion],
case when [Transferidas] > 0 then ([Tespera] + [TXfer] + [tring])/[Transferidas] else 0 end [ASA] ,agt.cantidad [Agentes Logeados]

 from
(select case when datepart(mi,cal_inicio)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), cal_inicio,121) + '':30:00'',121)) else convert(varchar(13), cal_inicio,121) + '':30:00'' end [Fecha]
, inb.inbound_id
,COUNT(cal_id)AS [Recibidas]
,COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS [Transferidas]
,COUNT(CASE WHEN (statuscall_id=13) THEN 1 ELSE NULL END)AS [Atendidas]
,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS [Abandono] 
,COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring>20))THEN 1 ELSE NULL END)AS abnd_tres
,COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS answ_tres
,ISNULL(SUM(cal_twait),0)AS [Tespera]
,ISNULL(SUM(cal_txfer),0)AS [TXfer]
,ISNULL(SUM(cal_tdialog),0)AS [tdialog]
,ISNULL(SUM(cal_tnotas),0)AS [tnotes]
,ISNULL(SUM(cal_tring),0)AS [tring]
,isnull(sum(cal_tmoh),0) as [THold]
,ISNULL(SUM(CASE WHEN (statuscall_id=13) THEN (cal_twait + cal_txfer + cal_tring) ELSE NULL END),0)AS tresp
FROM ccCallsIn as inb with (nolock, index(IX_ccCallsIn))
where cal_inicio >= @fecini and cal_inicio < @fecfin and  inbound_id in (select value from @RtnValue)
group by case when datepart(mi,cal_inicio)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), cal_inicio,121) + '':30:00'',121)) else convert(varchar(13), cal_inicio,121) + '':30:00'' end,inb.Inbound_id
) as CI
left join ccinbound i on (i.inbound_id = CI.inbound_id)
left join ( select fecha, inbound_id, count(user_id) Cantidad from( select distinct case when datepart(mi,cal_inicio)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), cal_inicio,121) + '':30:00'',121)) else convert(varchar(13), cal_inicio,121) + '':30:00'' end [fecha], user_id, inbound_id from cccallsin with (nolock, index(IX_ccCallsIn)) where cal_inicio >= @fecini and cal_inicio < @fecfin ) as agI group by inbound_id, fecha ) agt on (agt.inbound_id = CI.inbound_id and agt.fecha = CI.fecha)
left join (select case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) else convert(varchar(13), fecha,121) + '':30:00'' end [fecha], count(opcionIVR) cantidad, case opcionIVR when 2 then 16 when 3 then 17 else opcionIVR end [Inbound_id] from ivr.dbo.IVRLlamadasMonte where opcionIVR is not null and fecha >= @fecIni and fecha < @fecFin and opcioniVR in (2,3) group by case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) else convert(varchar(13), fecha,121) + '':30:00'' end,opcionIVR) ivr on (CI.inbound_id = ivr.inbound_id and ci.Fecha = ivr.fecha )'

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
