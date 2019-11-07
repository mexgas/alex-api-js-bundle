create procedure addPosicionIpManual
@pos varchar(40),
@ip varchar(40)
as
insert into ccMonitorExt values (@ip,1,1)
insert into ccposicion ( computer,ext_id, user_id, status, tipoConexion, ip)
values (@pos, scope_identity(),0,1,0,'')

update ccsettings set valor ='2' where setting_id = 71 -- posicion
update ccsettings set valor ='1' where setting_id = 83  -- extmanual