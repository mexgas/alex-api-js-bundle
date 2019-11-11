CREATE PROCEDURE [dbo].[trsp_SaveAVRSExportParameters]
@export_mode AS INT,
@netcred_id AS INT = -1,
@net_user AS VARCHAR(100) = '',
@net_password AS VARCHAR(100) = '',
@net_sever AS VARCHAR(max) = '',
@net_path AS VARCHAR(max) = '',
@ftp_user AS VARCHAR(100) = '',
@ftp_password AS VARCHAR(100) = '',
@ftp_sever AS VARCHAR(max) = '',
@ftp_path AS VARCHAR(max) = '',
@ftp_port AS INT = -1,
@ftp_protocol AS INT = -1,
@time_export AS VARCHAR(20) = '',
@grabid_start AS INT = -1,
@csv_log AS INT = -1,
@delete_rec AS INT = -1,
@export_format AS INT = 1,
@export_encrypted AS BIT = 0,
@file_encrypted AS Bit
AS
BEGIN

DECLARE @repo_Id AS INT

	-- Update FTP Parameters

	IF @export_mode = 1
		BEGIN

			UPDATE TREC_PARAMETROS
			SET par_valor = @export_format
			WHERE
			par_id = 35

			UPDATE TREC_PARAMETROS
			SET par_valor = @ftp_path
			WHERE
			par_id = 41

			UPDATE TREC_PARAMETROS
			SET par_valor = @ftp_protocol
			WHERE
			par_id = 42

			UPDATE TREC_PARAMETROS
			SET par_valor = @ftp_sever
			WHERE
			par_id = 43

			UPDATE TREC_PARAMETROS
			SET par_valor = @ftp_user
			WHERE
			par_id = 44

			UPDATE TREC_PARAMETROS
			SET par_valor = @ftp_password
			WHERE
			par_id = 45

			UPDATE TREC_PARAMETROS
			SET par_valor = @ftp_port
			WHERE
			par_id = 46

			UPDATE TREC_PARAMETROS
			SET par_valor = @csv_log
			WHERE
			par_id = 50

			UPDATE TREC_PARAMETROS
			SET par_valor = @export_mode
			WHERE
			par_id = 51

			UPDATE TREC_PARAMETROS
			SET par_valor = @delete_rec
			WHERE
			par_id = 57

			UPDATE TREC_PARAMETROS
			SET par_valor = @file_encrypted
			WHERE
			par_id = 61

			UPDATE TREC_PARAMETROS
			SET par_valor = @export_encrypted
			WHERE
			par_id = 62

			IF LEN( @time_export) > 0
				BEGIN
					UPDATE TREC_PARAMETROS
					SET par_valor = @time_export
					WHERE
					par_id = 33
				END

			IF @grabid_start <> -1
				BEGIN
					UPDATE TREC_PARAMETROS
					SET par_valor = @grabid_start
					WHERE
					par_id = 40

				END
		END
	ELSE
		BEGIN

			-- Update NetBios parameters
			declare @avrs_enviroment as int
			SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

			IF @avrs_enviroment = 2
				BEGIN

					UPDATE RIA_NETWORKCREDENTIALS
					SET
					[domain] = @net_sever,
					[user] = @net_user,
					[password] = @net_password
					WHERE
					id = @netcred_id

				END
			ELSE
				BEGIN

					UPDATE TREC_NETWORKCREDENTIALS
					SET
					[domain] = @net_sever,
					[user] = @net_user,
					[password] = @net_password
					WHERE
					id = @netcred_id

				END

			UPDATE TREC_PARAMETROS
			SET par_valor = @export_format
			WHERE
			par_id = 35

			UPDATE TREC_PARAMETROS
			SET par_valor = @net_path
			WHERE
			par_id = 36

			IF LEN( @time_export) > 0
				BEGIN
					UPDATE TREC_PARAMETROS
					SET par_valor = @time_export
					WHERE
					par_id = 33
				END

			IF @grabid_start <> -1
				BEGIN
					UPDATE TREC_PARAMETROS
					SET par_valor = @grabid_start
					WHERE
					par_id = 40
				END

			UPDATE TREC_PARAMETROS
			SET par_valor = @csv_log
			WHERE
			par_id = 50

			UPDATE TREC_PARAMETROS
			SET par_valor = @export_mode
			WHERE
			par_id = 51

			UPDATE TREC_PARAMETROS
			SET par_valor = @delete_rec
			WHERE
			par_id = 57

			UPDATE TREC_PARAMETROS
			SET par_valor = @file_encrypted
			WHERE
			par_id = 61

			UPDATE TREC_PARAMETROS
			SET par_valor = @export_encrypted
			WHERE
			par_id = 62

		END
END