CREATE OR ALTER VIEW vw_DetalleMovimientosXHora AS
SELECT
	A.idEmpleado as idEmpleado,
	E.ValorDocumentoIdentidad as EmpleadoDocId,
    MXH.id AS IdMovimientoXHora,
    A.Fecha AS FechaAsistencia,
    A.HoraEntrada,
    A.HoraSalida,
    MXH.CantidadHoras AS QHoras,
    MP.Monto,
    TM.Nombre AS TipoMovimiento,
	MP.idPlanillaSemXEmpleado AS SemanaPlanillaXEmpleado
FROM dbo.MovimientoXHora MXH
INNER JOIN dbo.MovimientoPlanilla AS MP ON MXH.idMovimiento = MP.id
INNER JOIN dbo.Asistencia AS A ON MXH.idAsistencia = A.id
INNER JOIN dbo.TipoMovimiento AS TM ON MP.idTipoMovimiento = TM.id
INNER JOIN dbo.Empleado AS E ON A.idEmpleado = E.id;
