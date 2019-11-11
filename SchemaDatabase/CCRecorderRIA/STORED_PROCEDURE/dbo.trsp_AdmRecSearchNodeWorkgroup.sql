CREATE PROCEDURE [dbo].[trsp_AdmRecSearchNodeWorkgroup]
							@User_id int
							AS
							BEGIN
									SET NOCOUNT ON;
									select b.IDWG, c.WGName from ccusers a inner join ccRIAWorkGroupUsersConsulta b
									on b.user_id = @User_id inner join ccRIACat_WorkGroup c on c.IDWG = b.IDWG and c.StatusWorkGroup = 1
									where a.user_id = @User_id order by 1
								END