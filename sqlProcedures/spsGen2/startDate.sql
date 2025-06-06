DECLARE @primerJueves DATE = '2023-06-01'; -- Primer jueves del mes
DECLARE @ultimoJueves DATE = '2023-06-29'; -- Último jueves del mes

INSERT INTO MesPlanilla (Anio, Mes, FechaInicio, FechaFin, Cerrado)
VALUES (2025, 6, @primerJueves, @ultimoJueves, 0);

DECLARE @idMesPlanilla INT = SCOPE_IDENTITY();

-- Crear semanas para este mes (ejemplo: 4 semanas)
INSERT INTO SemanaPlanilla (idMesPlanilla, Semana, FechaInicio, FechaFin, Cerrado)
VALUES 
(@idMesPlanilla, 1, '2023-05-26', '2023-06-01', 0), -- Semana que inicia el viernes anterior
(@idMesPlanilla, 2, '2023-06-02', '2023-06-08', 0),
(@idMesPlanilla, 3, '2023-06-09', '2023-06-15', 0),
(@idMesPlanilla, 4, '2023-06-16', '2023-06-22', 0),
(@idMesPlanilla, 5, '2023-06-23', '2023-06-29', 0);