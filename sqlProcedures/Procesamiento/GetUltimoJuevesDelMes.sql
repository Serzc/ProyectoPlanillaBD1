CREATE OR ALTER FUNCTION dbo.GetUltimoJuevesDelMes(@fecha DATE)
RETURNS DATE
AS
BEGIN
    DECLARE @ultimoDiaMes DATE = EOMONTH(@fecha);
    DECLARE @ultimoJueves DATE = DATEADD(DAY, -((DATEPART(WEEKDAY, @ultimoDiaMes) + 2) % 7), @ultimoDiaMes);
    
    RETURN @ultimoJueves;
END;