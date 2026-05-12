use CCenterRIA

if not exists(select top 1 1 from cctipoResultadodial where tipoResDial_id=15)
begin
insert cctipoResultadodial (tipoResDial_id,
descripcion,
descTranslate) values (15, 'Máquina/Buzón (post‑conexión)', 'systemTranslated_QuantumVoicemail')
end