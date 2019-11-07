CREATE PROCEDURE [dbo].[trsp_AdmGetQualityDiferentFormats]
			@type as tinyint = 1
			AS
			BEGIN
				SET NOCOUNT ON;
				select distinct id_formato from RIA_FORMATOS where tipo=@type
			END