CREATE PROCEDURE [dbo].[trsp_AdmRecSearchNodeWorkgroup]
			@User_id int,
			@WG_id int = 0
			AS
			BEGIN
					SET NOCOUNT ON;

					if @User_id = 0
					begin
						select IDWG,WGName from ccRIACat_WorkGroup nolock
					end
					else
					if @WG_id = 0
					begin
						select distinct IDWG,WGName from (
						select b.IDWG, c.WGName from ccusers a inner join ccRIAWorkGroupUsersConsulta b
						on b.user_id = @User_id inner join ccRIACat_WorkGroup c on c.IDWG = b.IDWG /*and c.StatusWorkGroup = 1*/
						where a.user_id = @User_id
						union --camp history
						select distinct a.IDWG,WGName
						from ccRIACampEspWGConsulta a inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG where cast(a.IdCampEsp as varchar(6))+'&'+cast(a.Tipo as varchar(6)) in (
						select distinct cast(a.IdCampEsp as varchar(6))+'&'+cast(a.Tipo as varchar(6)) from ccRIACampEspWGConsulta a
						inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = @User_id and a.IDWG = b.IDWG)
						union --user history
						select distinct a.IDWG,WGName
						from ccRIAWorkGroupUsersConsulta a inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG where user_id in (
						select user_id from ccRIAWorkGroupUsersConsulta where IDWG in (
						select distinct a.IDWG from ccRIACampEspWGConsulta a
						inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = @User_id and a.IDWG = b.IDWG))
						)x
						order by 1
					end
					else
						select IDWG,WGName from ccRIACat_WorkGroup nolock where IDWG = @WG_id
				END