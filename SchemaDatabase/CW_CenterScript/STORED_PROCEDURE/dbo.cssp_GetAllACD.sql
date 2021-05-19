CREATE PROCEDURE [dbo].[cssp_GetAllACD]
				@Template_id int
			AS
			set nocount on;
				select convert(varchar(100),inbound_id) as[inbound_id] from Inbound_Campaign where Template_id = @Template_id