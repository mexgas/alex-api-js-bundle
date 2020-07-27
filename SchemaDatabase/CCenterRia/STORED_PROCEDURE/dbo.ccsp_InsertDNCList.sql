CREATE PROCEDURE [dbo].[ccsp_InsertDNCList]
 
@telephone as varchar(30),
@ln_id as integer,
@hashCalKey bigint=null
AS

declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)

insert into cclistanegra(telefono,idtipolista,HashKey) values(@telephone, @ln_id,@hashCalKey)

CREATE TABLE [dbo].[#mycamps] (
	[campsid] [int] NULL
	)

CREATE UNIQUE INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 
--En #mycamps se guardan los id de campañas ligadas a la lista negra
insert #mycamps
select distinct cam_id from Camplistanegra where idtipolista = @ln_id

CREATE TABLE [dbo].[#myprincipaltemp](
	[callout_id] [int] NULL, 
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL,
	[cal_telefono] [varchar] (15) NULL ,
	[cal_telefono2] [varchar] (15) NULL ,
	[cal_telefono3] [varchar] (15) NULL ,
	[cal_telefono4] [varchar] (15) NULL ,
	[cal_telefono5] [varchar] (15) NULL
	)

CREATE UNIQUE INDEX [IX_myprincipaltemp] ON  [dbo].[#myprincipaltemp]([callout_id]) 

CREATE NONCLUSTERED INDEX [IX_myprincipaltemp2] 
ON [dbo].[#myprincipaltemp]([callout_id])
INCLUDE ([cal_telefono], [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]); 

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @tel = dbo.completa(@telephone, @pais, @ld)
--select @tel = @telephone
declare @Sql nvarchar(max)

if @hashCalKey is not null or @hashCalKey > 0
begin
	--Inserta en #myPrincipaltemp los registros que trae ccoCallsOutSource y que estan ligados a las campañas de la lisa negra.
	--si trae hashcalkey
	set @Sql = 'insert into [#myprincipaltemp] 
	SELECT callout_id as callout_id, cam_id,''3'',@lnId as idtipolista , [cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5] 
	FROM [ccoCallsOutSource] a with(nolock) inner join #mycamps b on a.cam_id = b.campsid 
	WHERE @telefono IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) and 
	dbo.hashList(cal_key) = @hashCal and
	cal_fechadial > dateadd(dd,-30,getdate())'

	EXECUTE sp_executesql  @sql,N'@lnId integer, @telefono varchar(30), @hashCal bigint', @lnId = @ln_id, @hashCal = @hashCalKey, @telefono = @tel;

end
else begin
	--Inserta en #myPrincipaltemp los registros que trae ccoCallsOutSource y que estan ligados a las campañas de la lisa negra.
	--si NO trae hashcalkey
	set @Sql = 'insert into [#myprincipaltemp]  
	SELECT callout_id as callout_id, cam_id,''3'',@lnId as idtipolista , [cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5] 
	FROM [ccoCallsOutSource] a with(nolock) inner join #mycamps b on a.cam_id = b.campsid
	WHERE @telefono IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) and
	cal_fechadial > dateadd(dd,-30,getdate())'

	EXECUTE sp_executesql  @sql,N'@lnId integer, @telefono varchar(30)',@lnId = @ln_id, @telefono = @tel;

end

		if exists(select * from #myprincipaltemp )
		begin

			   update pt 
				set 
				pt.cal_telefono =  case	when pt.cal_telefono = @tel then '' else pt.cal_telefono  end,
				pt.cal_telefono2 = CASE when pt.cal_telefono2 = @tel then '' ELSE pt.cal_telefono2 END,			
				pt.cal_telefono3 = CASE when pt.cal_telefono3 = @tel then '' ELSE pt.cal_telefono3 END,			
				pt.cal_telefono4 = CASE when pt.cal_telefono4 = @tel then '' ELSE pt.cal_telefono4 END,			
				pt.cal_telefono5 = CASE when pt.cal_telefono5 = @tel then '' ELSE pt.cal_telefono5 END
				from #myprincipaltemp pt
				
				if exists(select * from #myprincipaltemp cs where cs.cal_telefono = '' and cs.cal_telefono2 = '' and cs.cal_telefono3 = '' and cs.cal_telefono4 = '' and cs.cal_telefono5 = '')
				begin
				--Si en callsOut todos los tel están vacíos

				--borra el registro de workingTable
					delete wt with(rowlock)
					from ccoWOrkingTable wt 					
					inner join #myprincipaltemp t on wt.callout_id = t.callout_id
					where t.cal_telefono = '' and t.cal_telefono2 = '' and t.cal_telefono3 = '' and t.cal_telefono4 = '' and t.cal_telefono5 = ''

					--borra el registro de callsOut
					delete cs with(rowlock)
					from ccoCallsOutSource cs inner join #myprincipaltemp t on cs.callout_id = t.callout_id
					where t.cal_telefono = '' and t.cal_telefono2 = '' and t.cal_telefono3 = '' and t.cal_telefono4 = '' and t.cal_telefono5 = ''
					---insertar el historial
					--insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
					--select callout_id, @tel, cam_id, idtipomov, idtipolista 
					--from #myprincipaltemp 
					--where pt.cal_telefono = '' and pt.cal_telefono2 = '' and pt.cal_telefono3 = '' and pt.cal_telefono4 = '' and pt.cal_telefono5 = ''

					--borra el registro de tabla temporal
					delete pt from #myprincipaltemp pt where pt.cal_telefono = '' and pt.cal_telefono2 = '' and pt.cal_telefono3 = '' and pt.cal_telefono4 = '' and pt.cal_telefono5 = ''
				end
					
				update ccoWOrkingTable 
				set cal_telefono = rtrim(left(ltrim(pt.cal_telefono2 + '         '
												+ pt.cal_telefono3 + '         '
												+ pt.cal_telefono4 + '         '
												+ pt.cal_telefono5 + '         '),13))
				from ccoWorkingTable wt
				inner join #myprincipaltemp pt on wt.callout_id = pt.callout_id


				update cs set 
				cs.cal_telefono =t.cal_telefono,
				cs.cal_telefono2 =t.cal_telefono2,
				cs.cal_telefono3= t.cal_telefono3,
				cs.cal_telefono4= t.cal_telefono4,
				cs.cal_telefono5= t.cal_telefono5
				from ccoCallsOutSource cs 
				inner join #myprincipaltemp t on cs.callout_id = t.callout_id




		End

drop table [#myprincipaltemp]
drop table [#mycamps]