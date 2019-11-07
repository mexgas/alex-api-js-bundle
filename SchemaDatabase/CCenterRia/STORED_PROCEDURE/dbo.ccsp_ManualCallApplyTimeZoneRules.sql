CREATE procedure [dbo].[ccsp_ManualCallApplyTimeZoneRules]
@campid as int, @tel varchar(15) as

set nocount on

declare @bIsDaylight bit
declare @revHorario bit
declare @country_id int
declare @iZonas int
declare @sql varchar(MAX)
declare @izonahoraria int
declare @izonahoraria_verano int
DECLARE @iZonasTable TABLE (value int)

create table #TimeZone(
cam_id int,
cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
izonahoraria int,
izonahoraria_verano int
)

/*** Revisa zona horaria incluyendo de verano ***/
select @izonahoraria = dbo.fnGetTimeZone(@tel,0)
select @izonahoraria_verano = dbo.fnGetTimeZone(@tel,1)

insert into #TimeZone
values (@campid,@tel,@izonahoraria,@izonahoraria_verano)

/*** Valida el pais y la lada configurada ***/
SELECT @country_id = valor  FROM ccSettings  WHERE setting_id = 104

select @revHorario = valor  from ccsettings  where setting_id = 112

/*** Coloca el primer dia de la semana a Lunes ***/
SET DATEFIRST 1

/*** Se revisa si es horario de verano ***/
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

INSERT INTO @iZonasTable exec ccsp_OUTcheckTimeZone @cam_id=@campid
select @iZonas=value from @iZonasTable

/*** Se revisa si la campaña tiene horarios configurados ***/
if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid) begin
	if @iZonas = 0
		begin
			SELECT 0 as CanCall,0 as CanCallLaw
			return
		end
end

set @izonahoraria = case @bIsDaylight when 1 then @izonahoraria_verano else @izonahoraria end

set @sql = 'CREATE TABLE #NEW_JOBS(
cam_id int,
cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS)

INSERT #NEW_JOBS
SELECT cam_id, ' + @tel + '
FROM #TimeZone
WHERE cam_id = ' + cast(isnull(@CAMPID,'0') as varchar(7)) + '
and (((izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+' & ' + cast(isnull(@iZonas,0) as varchar(20))+ ')>0
	or izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'=0))

if (SELECT count(*) FROM #NEW_JOBS where len(cal_telefono)>0) > 0
	begin
		select 1 as CanCall , 1 as CanCallLaw
	end
else
	begin
		select 0 as CanCall,0 as CanCallLaw
	end

DROP table #NEW_JOBS'

exec(@sql)

DROP table #TimeZone

set nocount off