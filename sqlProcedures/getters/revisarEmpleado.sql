declare @testid INT = 49;
Select 
	E.id as idEmpleado
	,E.ValorDocumentoIdentidad as docId
	,E.Activo as Activo
	,PSE.SalarioBruto as Bruto
	,PSE.TotalDeducciones as Deducciones
	,PSE.SalarioNeto as Neto
	,MP.Descripcion as DescMov
	,MP.Monto as MontoMov
	,MH.CantidadHoras as CantidadH
	,A.Fecha as FechaAsistencia
	,F.Nombre as Feriado
	,DATEPART(WEEKDAY,A.Fecha) as 'Weekday'
	,A.HoraEntrada as HoraEntrada
	,A.HoraSalida as HoraSalida
	,SP.FechaInicio as InicioSemana
	,SP.FechaFin as FinSemana
	,JE.idTipoJornada as TipoJornada
	,JE.FechaInicio as InicioJornada
	,JE.FechaFin as FinJornada
	
From dbo.PlanillaSemXEmpleado PSE
full Outer Join dbo.MovimientoPlanilla MP ON PSE.id=MP.idPlanillaSemXEmpleado
left outer join dbo.MovimientoXHora MH on mh.idMovimiento = mp.id
left outer join dbo.Asistencia A on A.id=MH.idAsistencia
left outer join dbo.Empleado E on e.id=@testid
left join dbo.SemanaPlanilla SP on SP.id = PSE.idSemanaPlanilla
left join dbo.JornadaEmpleado JE on JE.idEmpleado = @testid and JE.FechaInicio = SP.FechaInicio
left Join dbo.Feriado F on F.Fecha = A.Fecha
Where PSE.idEmpleado=@testid;