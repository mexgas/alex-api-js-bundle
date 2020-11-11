create procedure [dbo].[ccsp_OUTgetTimeZone]
						@phone varchar(20)
						AS
						set nocount on
						declare @bIsDaylight int, @country_id int
						
						SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
						select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())
						select dbo.fnGetTimeZone(@phone,@bIsDaylight)