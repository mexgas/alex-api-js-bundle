set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 82
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
begin
	begin tran
	begin try

    set @process = 'CW-5046 Alter SP CW_trsp_AdmRecSearchAllRecs'
		set @Sql = '
ALTER PROCEDURE [dbo].[CW_trsp_AdmRecSearchAllRecs]

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
		@SubdispositionList varchar(MAX) =null,
		@GrabId bigInt = null

AS
		declare @encrypted bit
		select @encrypted = par_valor from TREC_PARAMETROS where par_id = 15
;
WITH userAgent (UserId)
AS
(
select distinct User_id as UserId from ccRIAWorkGroupUsersConsulta where IDWG in(
	select distinct IDWG from ccRIAWorkGroupUsersConsulta where User_id = @Sup_id
))


select cal_id,tipo_llamada,A.cam_id,
case when a.tipo_llamada=2 then  campOut.cam_descripcion else campIn.descripcion end  AS campDescription,
A.calif_id,duracion,id_nivel_grito,age_id as user_id, U.login as [username],
	U.Nombres + '' '' +  U.ApellidoPaterno+ '' '' +  U.ApellidoMaterno as [FullName],
finicio,A.ani,dni,cal_key,cal_manual,
isnull(P.pos_id,0) as posicion,P.computer,isnull (z.total_forma,0) as total_forma, A.id_repositorio,
case when a.tipo_llamada=2 then  isnull (dispOut.[Description],'''') else isnull (dispIn.[Description],'''') end  AS score,
convert(varchar(8),DATEADD(ss, duracion, 0),114) as formato_duracion,A.grab_id,
isnull(a.IDWG,0) as IDWG,
case when a.tipo_llamada=2 then  isnull( subOut.califSubDesc ,'''') else isnull( subIn.califSubDesc ,'''') end  AS califSub_id,
a.cal_tMoh as cal_tMoh,repositorios.ruta_repositorio,
@encrypted as IsEncrypted, A.Prefijo as Prefix
from RIA_GRABACION A
inner join userAgent on userAgent.userId=A.age_id
inner join trec_repositorios repositorios on repositorios.id_repositorio=A.id_repositorio
left join ccPosicion P on A.cal_extension * -1 =P.pos_id
left join (select id_grabacion,avg(total_forma) as total_forma from ria_formacalif group by id_grabacion) Z on A.grab_id=Z.id_grabacion
left join cctipocalifout AS dispOut ON A.calif_id = dispOut.calif_id and a.tipo_llamada=2
left join cctipocalifsubout subOut on subOut.califSub_id=a.califSub_id and a.tipo_llamada=2
left join cctipocalif AS dispIn ON A.calif_id = dispIn.calif_id and a.tipo_llamada=1
left join cctipocalifsub subIn on subIn.califSub_id=a.califSub_id and a.tipo_llamada=1
left join cccamps campOut on campOut.cam_id=a.cam_id and a.tipo_llamada=2
left join ccinbound campIn on campIn.Inbound_id=a.cam_id and a.tipo_llamada=1
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
and (
	@GrabId is null or @GrabId = 0 or
		A.grab_id > @GrabId
)
union all
select cal_id,tipo_llamada,A.cam_id,
case when a.tipo_llamada=2 then  campOut.cam_descripcion else campIn.descripcion end  AS campDescription,
A.calif_id,duracion,id_nivel_grito,age_id as user_id, U.login as [username],
	U.Nombres + '' '' +  U.ApellidoPaterno+ '' '' +  U.ApellidoMaterno as [FullName],
finicio,A.ani,dni,cal_key,cal_manual,
isnull(P.pos_id,0) posicion,P.computer,isnull (z.total_forma,0) as total_forma, A.id_repositorio,
case when a.tipo_llamada=2 then  isnull (dispOut.[Description],'''') else isnull (dispIn.[Description],'''') end  AS score,
convert(varchar(8),DATEADD(ss, duracion, 0),114) as formato_duracion,A.grab_id,
isnull(a.IDWG,0) as IDWG,
case when a.tipo_llamada=2 then  isnull( subOut.califSubDesc ,'''') else isnull( subIn.califSubDesc ,'''') end  AS califSub_id,
a.cal_tMoh as cal_tMoh,repositorios.ruta_repositorio,
@encrypted as IsEncrypted, A.Prefijo as Prefix
from RIA_GRABACIONConsulta A
inner join userAgent on userAgent.userId=A.age_id
inner join trec_repositorios repositorios on repositorios.id_repositorio=A.id_repositorio
left join ccPosicion P on A.cal_extension * -1 =P.pos_id
left join (select id_grabacion,avg(total_forma) as total_forma from ria_formacalif group by id_grabacion) Z on A.grab_id=Z.id_grabacion
left join cctipocalifout AS dispOut ON A.calif_id = dispOut.calif_id and a.tipo_llamada=2
left join cctipocalifsubout subOut on subOut.califSub_id=a.califSub_id and a.tipo_llamada=2
left join cctipocalif AS dispIn ON A.calif_id = dispIn.calif_id and a.tipo_llamada=1
left join cctipocalifsub subIn on subIn.califSub_id=a.califSub_id and a.tipo_llamada=1
left join cccamps campOut on campOut.cam_id=a.cam_id and a.tipo_llamada=2
left join ccinbound campIn on campIn.Inbound_id=a.cam_id and a.tipo_llamada=1
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
and (
	@GrabId is null or @GrabId = 0 or
		A.grab_id > @GrabId
)
order by finicio'
		EXEC(@Sql)



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
