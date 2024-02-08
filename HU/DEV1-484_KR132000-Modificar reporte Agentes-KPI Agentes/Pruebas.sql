exec ccspRepAgentKPI @action=1,@from='2024-01-01',@to='2024-01-03'
--select * from RepAgentKPI

--select * from CCenterRIA..ccTipoStatusAgente

select A.User_id,convert(date,fecha) date
,sum(case when A.TipoStatusAge_id=1 then tStatus else 0 end) tunknown
,sum(case when A.TipoStatusAge_id in(3,31) then tStatus else 0 end) tready
,sum(case when A.TipoStatusAge_id=2 then tStatus else 0 end) tnotready
--,sum(case when A.TipoStatusAge_id=7 then tStatus else 0 end) tother
,sum(case when A.TipoStatusAge_id in(11,25,26,30) then tStatus else 0 end) tproblem
,sum(case when A.TipoStatusAge_id=21 then tStatus else 0 end) tmanualCall
,sum(case when A.TipoStatusAge_id in (23,24) then tStatus else 0 end) tchat
,sum(case when A.TipoStatusAge_id in (32) then tStatus else 0 end) tPreview
,sum(case when A.TipoStatusAge_id in (33) then tStatus else 0 end) tAssisted
,sum(case when A.TipoStatusAge_id in (34) then tStatus else 0 end) tWhatsappDialog
,sum(case when A.TipoStatusAge_id in (35) then tStatus else 0 end) tIdle
,sum(case when A.TipoStatusAge_id in (36) then tStatus else 0 end) tEmailDialog
,sum(case when A.TipoStatusAge_id in (37) then tStatus else 0 end) tTransferDialog
from ccLogAgentesDia A
where User_id=146 and fecha between '2024-01-02' and '2024-01-03'
group by A.User_id,convert(date,fecha)

--select dateadd(ss,-27.1239278,'2024-01-02 14:46:36.803'),dateadd(ss,-15.2166371,'2024-01-02 14:46:55.553')
--select datediff(ms,'2024-01-02 14:46:09.803','2024-01-02 14:46:40.553')/1000.0