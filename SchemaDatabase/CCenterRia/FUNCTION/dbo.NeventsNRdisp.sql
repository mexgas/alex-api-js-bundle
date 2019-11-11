CREATE FUNCTION dbo.NeventsNRdisp(@user_id int,@tipo_NR int,@fecha smalldatetime)
RETURNS varchar(5) AS  
BEGIN
declare @timeAcum bigint,@timeTotAcum bigint,@difAcum bigint
declare @timeEv int,@nvecesxtime int,@inicioTurno int,@resdiv int,@usadas int
declare @fStart datetime,@fEnd datetime
declare @nveces varchar(10)

select @inicioTurno=2 --Cambio de dia a las 2 de la mañana

if datepart(hh,@fecha)>@inicioTurno-1
 begin	
	set @fStart=convert(datetime,convert(varchar(11),@fecha,121)+cast(@inicioTurno as varchar)+':00',121)
	set @fEnd=dateadd(d,1,@fstart)
 end
else
 begin
	set @fEnd=convert(datetime,convert(varchar(11),@fecha,121)+cast(@inicioTurno as varchar)+':00',121)
	set @fStart=dateadd(d,-1,@fEnd)
 end

select @timeAcum=Time_Acum,@timeEv=Time_xEv from cctiponotready where tiponotready_id=@tipo_NR
if @timeEv=0 
 begin
	select @nveces = 'n'
	goto fin
 end

select @timeTotAcum=sum(tStatus) from ccRIALogAgentesNotReady with(index(IX_ccRIALogAgentesNotReady_1))
where fecha between @fStart and @fEnd and user_id = @user_id and tiponotready_id=@tipo_NR
select @timeTotAcum=isnull(@timeTotAcum,0)
if @timeAcum =0 
 begin
	select @nveces = 'n'
	goto fin
 end

select @usadas=count(tStatus) from ccRIALogAgentesNotReady with(index(IX_ccRIALogAgentesNotReady_1))
where fecha between @fStart and @fEnd and user_id=@user_id and tiponotready_id=@tipo_NR

set @nvecesxtime=(@timeTotAcum/@timeEv)

if @nvecesxtime<=@usadas
 begin
	set @nvecesxtime=@usadas
 end

set @nveces=(@timeAcum/@timeEv)-@nvecesxtime
set @resdiv=(@timeAcum%@timeEv)

if @resdiv>0
 begin
	set @nveces=convert(varchar(10),((@timeAcum/@timeEv)+1-@nvecesxtime))
 end

if isnull(@nveces,0) <= 0
	set @nveces=0

fin: 
	declare @maxTime as int
	select @maxTime = Time_Acum from ccTipoNotReady where TipoNotReady_id = @tipo_NR

	if @maxTime <> 0 begin
			declare @currentTimeNR as int
			select @currentTimeNR = sum(tStatus) from ccLogAgentesNotReady where fecha > left(getdate(),11) and User_id = @user_id and TipoNotReady_id = @tipo_NR
			if @currentTimeNR > @maxTime begin
				select @nveces = 0
			end
	end

	return @nveces
end