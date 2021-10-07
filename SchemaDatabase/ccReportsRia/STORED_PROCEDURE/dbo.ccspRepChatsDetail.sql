CREATE PROCEDURE [dbo].[ccspRepChatsDetail]
				@action as tinyint,
				@from as datetime = null,
				@to as datetime = null
				AS

				if @from is null
					select @from = convert(datetime,convert(varchar(11),getdate()))
				if @to is null
					select @to = getdate()

				if @action = 1 
					begin
		
						delete from RepChatsDetail with(rowlock)
						where date >= @from AND date < @to
	
						insert into RepChatsDetail
							select requestDate,
							inboundId, b.descripcion, chatstatus, c.description, disposition, isnull(d.description,''),
							subDisposition, isnull(califSubDesc,''), domain, userid, isnull(f.login,''), clientName, tqueue,
							0 as txfer, tchatting, 
							isnull(nombres + ' ' + ApellidoPaterno + ' ' + ApellidoMaterno,'') as Nombre,
							datepart(yyyy,CONVERT(varchar(20), requestDate, 120)) as [year],
							datepart(mm,CONVERT(varchar(20), requestDate, 120)) as [month],
							datepart(dd,CONVERT(varchar(20), requestDate, 120)) as [day],
							datepart(hh,CONVERT(varchar(20), requestDate, 120)) as [hour],
							datepart(mi,CONVERT(varchar(20), requestDate, 120)) as [minutes],
							chatId
							from ccRIAChats
							left join ccInbound b on (inboundId = inbound_id)
							left join ccRIAChatStatus c on (chatstatus = id)
							left join ccTipoCalif d on (calif_id = disposition)
							left join ccTipoCalifSub e on (califSub_id = subDisposition)
							left join ccUserView f on (User_id = userid)
							where requestDate >= @from and requestDate < @to
			
							select isnull(datediff(ss,requestDate,chatdate) - tqueue,0) as xferTime, requestDate as date
							into #tmpxferTime
							from ccRIAChats where chatstatus = 4
			
							update RepChatsDetail set xferTime = b.xferTime
							from RepChatsDetail a, #tmpxferTime b where a.date = b.date 
			
							drop table #tmpxferTime
					end