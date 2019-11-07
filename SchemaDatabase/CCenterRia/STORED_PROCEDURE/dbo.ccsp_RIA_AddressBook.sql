CREATE PROCEDURE [dbo].[ccsp_RIA_AddressBook]
			@action smallint,
			@Email varchar(100) = '',
			@Name varchar(100) = '',
			@Organization varchar(100) = '',
			@Department varchar(100) = '',
			@Title varchar(100) = '',
			@IDArea smallint = NULL,
			@IDAddr smallint = NULL
			AS

			set nocount on

			if @action = 0 begin --Selected Address
				select addr_id,name,email,organization,department,job_title from ccRIACat_AddressBook nolock where area_id=@IDArea order by Name
				return(0)
			end
			else if @action=2 begin --Insert Address
				Insert into ccRIACat_AddressBook (email,name,organization,department,job_title,area_Id) values (@Email,@Name,@Organization,@Department,@Title,@IDArea)
				select 1, scope_identity()--, Address Insertada
				return(0)
			end
			else if @action=3 begin--Update Address
				update ccRIACat_AddressBook set email=@Email,name=@Name,organization=@Organization,department=@Department,job_title=@Title where addr_id = @IDAddr
				return(0)
			end
			else if @action=4 begin --Delete Address
				delete ccRIACat_AddressBook where addr_id = @IDAddr
				return(0)
			end