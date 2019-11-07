CREATE PROCEDURE [dbo].[ccsp_RIADialerAssignment]
@User_Id smallint,
@cam_id smallint,
@dialer_id varchar(4000),
@Type2 tinyint,
@Type tinyint
AS
set nocount on
declare @SQL as nvarchar(4000), @nUser_id as nvarchar(10), @params as nvarchar(1000)

If @Type=0--get ports
 begin
	select a.dialer_id, a.puerto, a.Descripcion, b.descrip from ccoDialers a with(index([IX_ccoDialers_I]),nolock)
	inner join cstoProvedor b with(index(PK_cstoProvedor),nolock) on a.provedor_id=b.provedor_id
	order by a.dialer_id
	return(0)
 end

If @Type=1--get cams
 begin
	SELECT a1.cam_id, cam_descripcion FROM ccCamps a1 with(nolock)
	inner join ccRIACampsGraph a2 with(nolock) on(a1.cam_id=a2.cam_id)
	inner join ccRIAGraphics a3 with(nolock) on(a2.graphic_id=a3.graphic_id)
	where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
	order by cam_descripcion
	return(0)
 end

If @Type=2--get port/cam relation
 begin
	select c.cam_id, cd.dialer_id, d.descripcion,
	d.puerto, e.descrip from ccCamps c with(nolock)
	left join ccoDialerCamp cd on cd.cam_id=c.cam_id
	left join ccoDialers d with(index(IX_ccoDialers_I),nolock) on cd.dialer_id=d.dialer_id
	inner join cstoProvedor e with(index(PK_cstoProvedor),nolock) on d.provedor_id=e.provedor_id
	where c.cam_id=@cam_id
	ORDER BY c.cam_id, cd.dialer_id
	return(0)
 end

If @Type=3--delete port/dialer relation
 begin
	If @Type2=1--Sistema
	 begin
		set @nUser_id=@User_Id
		set @sql='delete ccoDialerCamp with(rowlock) where dialer_id in(' + @dialer_id + ')'
		execute sp_executesql @sql
		return(0)
	 end

	If @Type2=2--Camp
	 begin
		delete ccoDialerCamp with(rowlock) where cam_id=@cam_id and dialer_id=@dialer_id
		return(0)
	 end
 end

If @Type=4--insert new relation
 begin
	If @Type2=1--Sistema
	 begin
		set @nUser_id=@User_Id
		set @sql='insert ccoDialerCamp(cam_id, dialer_id)
		select a.cam_id, b.dialer_id from ccCamps a, ccoDialers b where
		b.dialer_id in(' + @dialer_id + ') and not exists(
		select c.cam_id, c.dialer_id from ccoDialerCamp c
		where b.dialer_id=c.dialer_id and a.cam_id=c.cam_id)'
		execute sp_executesql @sql
		return(0)
	 end

	If @Type2=2--Camp
	 begin
		set @params='@Ncam_id int'
 		set @sql='insert ccoDialerCamp(cam_id, dialer_id) select distinct @Ncam_id,
 		dialer_id from ccCamps, ccoDialers where dialer_id not in(select dialer_id
 		from ccoDialerCamp where dialer_id in(' + @dialer_id + ')and cam_id=@Ncam_id)
		and dialer_id in(' + @dialer_id + ')'
		execute sp_executesql @sql, @params, @Ncam_id=@cam_id
		return(0)
 	 end
 end

If @Type=5--Get existance of dialers
 begin
	if exists (select c.cam_id, cd.dialer_id, d.descripcion,
			   d.puerto, e.descrip from ccCamps c with(nolock)
			   left join ccoDialerCamp cd with(nolock) on cd.cam_id=c.cam_id
			   left join ccoDialers d with(nolock) on cd.dialer_id=d.dialer_id
			   inner join cstoProvedor e with(nolock) on d.provedor_id=e.provedor_id
			   where c.cam_id = @cam_id)
		select 0 Response
	else
		select 13 Response
	return(0)
 end