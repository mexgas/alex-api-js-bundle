CREATE PROCEDURE [dbo].[cssp_RelationACD]
				@ACDgroups VARCHAR(2000),
				@Template_id int
			AS
			set nocount on;
				delete from Inbound_Campaign where Template_id=@Template_id
				INSERT INTO dbo.Inbound_Campaign (Template_id,inbound_id) 
				select @Template_id,Value from fn_SplitDelimited(@ACDgroups,',')