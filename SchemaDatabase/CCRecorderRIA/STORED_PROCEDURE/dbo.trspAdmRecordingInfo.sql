CREATE PROCEDURE  [dbo].[trspAdmRecordingInfo]
@grab_id as INT
AS
set nocount on

BEGIN
select a.Nombres + ' ' + a.ApellidoPaterno + ' ' + a.ApellidoMaterno,b.cal_id,
CASE WHEN b.tipo_llamada=1 THEN 'Inbound'ELSE 'Outbound' END,
CASE WHEN b.tipo_llamada=1 THEN c.descripcion  ELSE d.cam_descripcion END,
CASE WHEN b.tipo_llamada=1 THEN e.description ELSE f.description END,
CASE WHEN b.tipo_llamada=1 THEN b.ani ELSE b.ani END,
(select top 1 IP from ccPosicion where user_id = a.User_id order by pos_id desc),
CASE WHEN b.cal_extension IS NULL THEN 0 ELSE b.cal_extension END,
DATEADD(dd, 0, DATEDIFF(dd, 0, b.finicio)) as fecha,
RIGHT(CONVERT(DATETIME, b.finicio, 108),8),
CASE WHEN b.duracion/3600<10 THEN '0' ELSE '' END + RTRIM(b.duracion/3600) + ':' + RIGHT('0'+RTRIM((b.duracion % 3600) / 60),2) + ':' + RIGHT('0'+RTRIM((b.duracion % 3600) % 60),2)
FROM 
ccUsers a LEFT JOIN dbo.RIA_GRABACION b ON a.User_id=b.age_id 
LEFT JOIN  ccInbound c ON b.cam_id=c.Inbound_id
LEFT JOIN  ccCamps d ON b.cam_id=d.cam_id
LEFT JOIN  ccTipoCalif e ON b.calif_id=e.calif_id
LEFT JOIN  ccTipoCalifOUT f ON b.calif_id=f.calif_id 
WHERE b.grab_id=@grab_id
END