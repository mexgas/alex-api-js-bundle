CREATE PROCEDURE [dbo].[ccspRepOutCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to  is null
	select @to = getdate()

	IF OBJECT_ID(N'tempdb..#tempTime', N'U') IS NOT NULL  drop table #tempTime
	IF OBJECT_ID(N'tempdb..#tempRepOutCalls', N'U') IS NOT NULL  drop table #tempRepOutCalls


if @action = 1
begin

	
	 select ROW_NUMBER() OVER(Order by row) as id,
		  A.row, A.timegroup as [date],isnull(B.IDArea,0) as areaId,isnull(C.AreaName, '') as area
		 ,A.idwg as workgroupid,isnull(WG.WGName, '') as workgroup
		 ,A.cam_id as campaignid,isnull(B.cam_descripcion,'') as campaign
		 ,A.[User_id] as userId,isnull(userView.[Login],'') as [user]
		 ,ntotal, nxfer, nno_agent, nanswer, nno_answer, nlost, nabnd_xfer, nabnd_ring, nabnd_dialog
		 ,1 as pos_tot,
		 tmp.tlog as  pos_time,  ---falta restar tnot_av + tprob + tother
		 
		 nhangup, (tdialog + tnotes) as  tatencion
		 ,datepart(yy,convert(datetime,A.timegroup)) as [year]
		 ,datepart(mm,convert(datetime,A.timegroup)) as [mounth]
		 ,datepart(dd,convert(datetime,A.timegroup)) as [day]
		 ,datepart(hh,convert(datetime,A.timegroup)) as [hour]
		 ,datepart(mi,convert(datetime,A.timegroup)) as [minutes]
		 ,cal_id,phone_out,dateStartDetail
		 into #tempRepOutCalls
		 from tmpTimesOutboundData A
		 left join ccUserView userView on A.User_id=userView.User_id
		 left join cccamps B on A.cam_id=B.cam_id
		 left join ccriacat_areas C on B.IDArea=C.IDArea
		 left join ccriacat_workgroup WG on Wg.IDWG=A.idwg
		 left join TmpSessionTimeGroup  tmp ON tmp.timegroup=A.timegroup and tmp.user_id=A.User_id
		 where A.User_id>0 AND B.IDArea IS NOT NULL AND B.IDArea>0
		 and cal_manual in (0,2,3)
		 

	 SELECT
      RANK() OVER(PARTITION BY row ORDER by id) as [rank],
      ROW_NUMBER() OVER(Order by id) as rowNumber,
      id
      into #tempTime
      FROM #tempRepOutCalls
      where row in
            (select row from #tempRepOutCalls temp GROUP BY temp.row HAVING Count(*) > 1 )

       update t
            set ntotal=0,nxfer=0,nno_agent=0,nanswer=0,nno_answer=0,nlost=0,nabnd_xfer=0,nabnd_ring=0,nabnd_dialog=0,tatencion=0
            from #tempRepOutCalls t
            inner join #tempTime temp on t.id = temp.id
            where [rank]>1

    	
	delete #tempTime

    insert into #tempTime([rank],rowNumber,id)
    SELECT
      RANK() OVER(PARTITION BY cal_id ORDER by id) as [rank],
      ROW_NUMBER() OVER(Order by id) as rowNumber,
      id
      FROM #tempRepOutCalls
      where cal_id in
            (select cal_id from #tempRepOutCalls temp GROUP BY temp.cal_id HAVING Count(*) > 1 )

       update t
            set pos_tot=0
            from #tempRepOutCalls t
            inner join #tempTime temp on t.id = temp.id
            where [rank]>1

    --Borrar lo que esta para no repetir
	delete from RepOutCalls with(rowlock)
	where date >= @from AND date < @to

     insert into RepOutCalls
		select date,areaId,area,workgroupid,workgroup,campaignid,campaign,userId,[user],ntotal,nxfer,nno_agent,nanswer,nno_answer,nlost,nabnd_xfer,nabnd_ring,nabnd_dialog
		,isnull(pos_tot,0),isnull(pos_time,0),nhangup,tatencion,year,mounth,day,hour,minutes,cal_id,phone_out,dateStartDetail
		from #tempRepOutCalls order by cal_id	


	IF OBJECT_ID(N'tempdb..#tempTime', N'U') IS NOT NULL  drop table #tempTime
	IF OBJECT_ID(N'tempdb..#tempRepOutCalls', N'U') IS NOT NULL  drop table #tempRepOutCalls	

end