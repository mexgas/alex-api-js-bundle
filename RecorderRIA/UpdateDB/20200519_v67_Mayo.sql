set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 67
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

SET @process = 'CW-4071 drop CW_trsp_AdmRecSearchAllRecs'
		SET @sql = 'if exists (select * from sys.procedures where name = N''CW_trsp_AdmRecSearchAllRecs'')
    				begin
        				DROP PROCEDURE CW_trsp_AdmRecSearchAllRecs;
    				end'
    	EXEC (@sql)


    	SET @process = 'CW-4071 create CW_trsp_AdmRecSearchAllRecs'
		SET @sql = 'CREATE PROCEDURE CW_trsp_AdmRecSearchAllRecs

								@Sup_id int,
								@dateStart datetime,
								@dateEnd datetime,
								@IdCallList varchar(MAX) =null,
								@UserList varchar(MAX) =null,
								@IDWGList varchar(MAX) =null,
								@TypeCall int = null,
								@CampaingsList varchar(MAX) =null,
								@ACDList varchar(MAX) =null,
								@DispositionList varchar(MAX) =null,
								@SubdispositionList varchar(MAX) =null
					AS
					;	
					WITH userAgent (UserId)
					AS
					(
					select distinct User_id as UserId from ccRIAWorkGroupUsers where IDWG in(
						select distinct IDWG from ccRIAWorkGroupUsers where User_id = @Sup_id
					))


					select cal_id,tipo_llamada,A.cam_id,
					case when a.tipo_llamada=2 then  campOut.cam_descripcion else campIn.descripcion end  AS campDescription,
					A.calif_id,duracion,id_nivel_grito,age_id as user_id, U.login as [username],
					 U.Nombres + '' '' +  U.ApellidoPaterno+ '' '' +  U.ApellidoMaterno as [FullName],
					finicio,A.ani,dni,cal_key,cal_manual,
					P.pos_id posicion,P.computer,isnull (z.total_forma,0) as total_forma, A.id_repositorio,  
					case when a.tipo_llamada=2 then  isnull (dispOut.[Description],'''') else isnull (dispIn.[Description],'''') end  AS score,
					convert(varchar(8),DATEADD(ss, duracion, 0),114) as formato_duracion,A.grab_id,
					isnull(a.IDWG,0) as IDWG,
					case when a.tipo_llamada=2 then  isnull( subOut.califSubDesc ,'''') else isnull( subIn.califSubDesc ,'''') end  AS califSub_id,
					a.cal_tMoh as cal_tMoh,repositorios.ruta_repositorio
					from RIA_GRABACION A
					inner join userAgent on userAgent.userId=A.age_id
					inner join trec_repositorios repositorios on repositorios.id_repositorio=A.id_repositorio
					left join ccPosicion P on A.cal_extension * -1 =P.pos_id
					left join (select id_grabacion,avg(total_forma) as total_forma from ria_formacalif group by id_grabacion) Z on A.grab_id=Z.id_grabacion
					left join cctipocalifout AS dispOut ON A.calif_id = dispOut.calif_id
					left join cctipocalifsubout subOut on subOut.califSub_id=a.califSub_id
					left join cctipocalif AS dispIn ON A.calif_id = dispIn.calif_id
					left join cctipocalifsub subIn on subIn.califSub_id=a.califSub_id
					left join cccamps campOut on campOut.cam_id=a.cam_id
					left join ccinbound campIn on campIn.cam_id=a.cam_id
					left join ccUsers U on A.age_id=U.user_id
					where A.finicio between @dateStart and @dateEnd
					and ( 
						@IdCallList is null or @IdCallList ='''' or 
						 A.cal_id in (select Value from dbo.fn_RIASplitDelimited(@IdCallList,'','')) 
					)
					and ( 
						@UserList is null or @UserList ='''' or 
						 A.age_id in (select Value from dbo.fn_RIASplitDelimited(@UserList,'','')) 
					)
					and ( 
						@TypeCall is null or a.tipo_llamada=@TypeCall
					)
					and ( 
						@CampaingsList is null or @CampaingsList ='''' or 
						( A.cam_id in (select Value from dbo.fn_RIASplitDelimited(@CampaingsList,'','')) and a.tipo_llamada=2 )
					)
					and ( 
						@ACDList is null or @ACDList ='''' or 
						( A.cam_id in (select Value from dbo.fn_RIASplitDelimited(@ACDList,'','')) and a.tipo_llamada=1 )
					)
					and ( 
						@DispositionList is null or @DispositionList ='''' or 
						( A.calif_id in (select Value from dbo.fn_RIASplitDelimited(@DispositionList,'','')) )
					)
					and ( 
						@SubdispositionList is null or @SubdispositionList ='''' or 
						( A.califSub_id in (select Value from dbo.fn_RIASplitDelimited(@SubdispositionList,'','')) )
					)
					union all
					select cal_id,tipo_llamada,A.cam_id,
					case when a.tipo_llamada=2 then  campOut.cam_descripcion else campIn.descripcion end  AS campDescription,
					A.calif_id,duracion,id_nivel_grito,age_id as user_id, U.login as [username],
					 U.Nombres + '' '' +  U.ApellidoPaterno+ '' '' +  U.ApellidoMaterno as [FullName],
					finicio,A.ani,dni,cal_key,cal_manual,
					P.pos_id posicion,P.computer,isnull (z.total_forma,0) as total_forma, A.id_repositorio,  
					case when a.tipo_llamada=2 then  isnull (dispOut.[Description],'''') else isnull (dispIn.[Description],'''') end  AS score,
					convert(varchar(8),DATEADD(ss, duracion, 0),114) as formato_duracion,A.grab_id,
					isnull(a.IDWG,0) as IDWG,
					case when a.tipo_llamada=2 then  isnull( subOut.califSubDesc ,'''') else isnull( subIn.califSubDesc ,'''') end  AS califSub_id,
					a.cal_tMoh as cal_tMoh,repositorios.ruta_repositorio
					from RIA_GRABACIONConsulta A
					inner join userAgent on userAgent.userId=A.age_id
					inner join trec_repositorios repositorios on repositorios.id_repositorio=A.id_repositorio
					left join ccPosicion P on A.cal_extension * -1 =P.pos_id
					left join (select id_grabacion,avg(total_forma) as total_forma from ria_formacalif group by id_grabacion) Z on A.grab_id=Z.id_grabacion
					left join cctipocalifout AS dispOut ON A.calif_id = dispOut.calif_id
					left join cctipocalifsubout subOut on subOut.califSub_id=a.califSub_id
					left join cctipocalif AS dispIn ON A.calif_id = dispIn.calif_id
					left join cctipocalifsub subIn on subIn.califSub_id=a.califSub_id
					left join cccamps campOut on campOut.cam_id=a.cam_id
					left join ccinbound campIn on campIn.cam_id=a.cam_id
					left join ccUsers U on A.age_id=U.user_id
					where A.finicio between @dateStart and @dateEnd
					and ( 
						@IdCallList is null or @IdCallList ='''' or 
						 A.cal_id in (select Value from dbo.fn_RIASplitDelimited(@IdCallList,'','')) 
					)
					and ( 
						@UserList is null or @UserList ='''' or 
						 A.age_id in (select Value from dbo.fn_RIASplitDelimited(@UserList,'','')) 
					)
					and ( 
						@TypeCall is null or a.tipo_llamada=@TypeCall
					)
					and ( 
						@CampaingsList is null or @CampaingsList ='''' or 
						( A.cam_id in (select Value from dbo.fn_RIASplitDelimited(@CampaingsList,'','')) and a.tipo_llamada=2 )
					)
					and ( 
						@ACDList is null or @ACDList ='''' or 
						( A.cam_id in (select Value from dbo.fn_RIASplitDelimited(@ACDList,'','')) and a.tipo_llamada=1 )
					)
					and ( 
						@DispositionList is null or @DispositionList ='''' or 
						( A.calif_id in (select Value from dbo.fn_RIASplitDelimited(@DispositionList,'','')) )
					)
					and ( 
						@SubdispositionList is null or @SubdispositionList ='''' or 
						( A.califSub_id in (select Value from dbo.fn_RIASplitDelimited(@SubdispositionList,'','')) )
					)
					order by finicio'

		EXEC (@sql)
		
		SET @process = 'CW-4088 Add Column RIA_GRABACIONCONSULTA.Prefijo'
		SET @sql = 'if not exists (select * from sys.columns where name = N''Prefijo'' and Object_ID = Object_ID(N''RIA_GRABACIONCONSULTA''))
	    begin
			alter table [RIA_GRABACIONCONSULTA] add  Prefijo varchar(max) null
		end'
		EXEC (@sql)

		SET @process = 'CW-4088 drop function escapeXml'
		SET @sql = 'if exists (select * from sys.objects where object_id = OBJECT_ID(N''escapeXml'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
    begin
        drop function escapeXml
    end'
		EXEC (@sql)

		SET @process = 'CW-4088 CREATE FUNCTION escapeXml'
		SET @sql = 'CREATE FUNCTION escapeXml 
(@xml nvarchar(4000))
RETURNS nvarchar(4000)
AS
BEGIN
    declare @return nvarchar(4000)
    select @return = 
    REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(@xml,''&'', ''&amp;'')
                ,''<'', ''&lt;'')
            ,''>'', ''&gt;'')
        ,''"'', ''&quot;'')
    ,'''''''', ''&#39;'')

return @return
end'
		EXEC (@sql)

		SET @process = 'CW-4088 ALTER SP trsp_muevegrabaciones'
		SET @sql = 'ALTER PROCEDURE [dbo].[trsp_muevegrabaciones]
AS
BEGIN
declare @fecha datetime
declare @Integrado as int

select @integrado = par_valor from trec_parametros where par_id = 29
set @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)
declare @top int
set @top=3000

--AVRS XION
if (@integrado = 2) BEGIN       

       	INSERT INTO [RIA_GRABACIONCONSULTA] (grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
			info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
			cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG,califSub_id,cal_tMoh,Prefijo)												
		SELECT top(@top) grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
			info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
			cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG,califSub_id,cal_tMoh,Prefijo
		FROM [RIA_GRABACION] with(nolock, index(IX_RIA_GRABACION_3)) WHERE [finicio] < @fecha;		

		DELETE top(@top) RIA_GRABACION WHERE [finicio] < @fecha;
END
else BEGIN  --AVRS Integrada ó AVRS Stand Alone
       SET IDENTITY_INSERT TREC_GRABACIONCONSULTA ON

       INSERT INTO [TREC_GRABACIONCONSULTA] (grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
			info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
			cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG)
       SELECT grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
			info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
			cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG
       FROM [TREC_GRABACION] with(nolock, index(IX_TREC_GRABACION_3)) WHERE [finicio] < @fecha;

       SET IDENTITY_INSERT TREC_GRABACIONCONSULTA OFF

       DELETE TREC_GRABACION with(rowlock) WHERE [finicio] < @fecha;
END
END'
		EXEC (@sql)

		
	------------------ fin SCRIPT @Sql ------------------

	-- Updating DB Version

 	update trec_parametros set par_valor = @Version where par_id = 30
 	set @Version_Actual=@Version_Actual+1

	select par_valor from trec_parametros where par_id = 30

	commit tran

	end try
	begin catch
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end
 else begin
	select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end
