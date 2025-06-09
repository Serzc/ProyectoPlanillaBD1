CREATE OR ALTER FUNCTION dbo.EsUltimoJuevesDelMes(@fecha DATE)
RETURNS BIT
AS
BEGIN
    DECLARE @ultimoDiaMes DATE = EOMONTH(@fecha);
    DECLARE @ultimoJueves DATE;
    
    -- Encontrar el último jueves del mes
    SET @ultimoJueves = CASE 
        WHEN DATEPART(WEEKDAY, @ultimoDiaMes) >= 5 THEN -- Si el último día es jueves o después
            DATEADD(DAY, 5 - DATEPART(WEEKDAY, @ultimoDiaMes), @ultimoDiaMes)
        ELSE -- Si el último día es antes de jueves, retroceder a la semana anterior
            DATEADD(DAY, 5 - DATEPART(WEEKDAY, @ultimoDiaMes) - 7, @ultimoDiaMes)
    END;
    
    RETURN CASE WHEN @fecha = @ultimoJueves THEN 1 ELSE 0 END;
END;