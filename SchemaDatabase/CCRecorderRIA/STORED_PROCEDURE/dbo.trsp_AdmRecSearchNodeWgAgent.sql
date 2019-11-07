Create PROCEDURE [dbo].[trsp_AdmRecSearchNodeWgAgent] 
@User_id int AS
BEGIN

	SET NOCOUNT ON

	select b.IDWG, c.WGName
	into #nodeWorkgroup
	from ccusers a 
	inner join ccRIAWorkGroupUsersConsulta b on b.user_id = @User_id
	inner join ccRIACat_WorkGroup c on c.IDWG = b.IDWG and c.StatusWorkGroup = 1
	where a.user_id = @User_id
	order by b.IDWG

	select a.User_id, a.Nombres + ' ' +  a.ApellidoPaterno+ ' ' +  a.ApellidoMaterno as [Nombres], b.IDWG 
	from ccUsers a
	inner join ccRIAWorkGroupUsersConsulta b on a.User_id = b.User_id
	left outer join #nodeWorkgroup c on b.IDWG = c.IDWG
	where a.TipoUser_id = 1
	union 
	select a.User_id, a.Nombres + ' ' +  a.ApellidoPaterno+ ' ' +  a.ApellidoMaterno as [Nombres], b.IDWG 
	from ccUsers a
	inner join ccRIAWorkGroupUsers b on a.User_id = b.User_id
	left outer join #nodeWorkgroup c on b.IDWG = c.IDWG
	where a.TipoUser_id = 1
	order by IDWG, User_id

	drop table #nodeWorkgroup

END