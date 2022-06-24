-- Create new message in table ccMsgFiles
exec ccsp_RIACATMessages @command='2',@msgFile='TestIvan2',@Description='Prueba de Ivan 2'    

-- Register Log
exec ccsp_RIA_ABCLog @option=2,@areaName='test000011',@operationType=1,@login='jesusAdmin',@moduleId=23,@value='',@target='Prueba de Ivan 2'  

-- Return Messages list
exec ccsp_RIACATMessages @Command='1'

-- Return outbound campaigns by admin id
exec ccsp_RIALoadCamps @option=3,@AreaId=0,@Sup=7

--Para enviar los archivos el Engines
exec ccsp_RIAEnginesPosition  

--Relacion de mensajes con la campaña de salida
exec ccsp_RIAADMCampMsgs @Command=1,@cam_id=1 

-- Inbound campaign list
exec ccsp_RIALoadACDGroups @option=9,@AreaId=0,@Sup=7,@inbound_id=0,@tipoModalidad=0 

--Relacion de mensajes con la campaña de entrada
exec ccsp_RIAADMInboundMsgs @Command=1,@Inbound_id=39

select * from ccMsgFiles
select * from ccCampsMsgs
