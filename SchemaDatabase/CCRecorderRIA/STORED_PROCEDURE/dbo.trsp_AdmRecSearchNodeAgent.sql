CREATE PROCEDURE [dbo].[trsp_AdmRecSearchNodeAgent] 

            @Workgroup int
            AS
            BEGIN

            SET NOCOUNT ON;
			if @Workgroup = 0
			begin
				select a.User_id, a.Nombres + ' ' +  a.ApellidoPaterno+ ' ' +  a.ApellidoMaterno as [Nombres], 0 IDWG from ccUsers a
			end
			else
			begin
				select a.User_id, a.Nombres + ' ' +  a.ApellidoPaterno+ ' ' +  a.ApellidoMaterno as [Nombres], b.IDWG from ccUsers a
				inner join ccRIAWorkGroupUsersConsulta b
				on b.IDWG = @Workgroup
				where a.User_id = b.User_id and a.TipoUser_id = 1
				union 
				select a.User_id, a.Nombres + ' ' +  a.ApellidoPaterno+ ' ' +  a.ApellidoMaterno as [Nombres], b.IDWG from ccUsers a
				inner join ccRIAWorkGroupUsers b
				on b.IDWG = @Workgroup
				where a.User_id = b.User_id and a.TipoUser_id = 1
			end
           END