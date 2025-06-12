# ProyectoPlanillaBD1

bash commands:
dotnet new webapp -n PlanillaObrera
cd ProyectoPlanilla
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet add package DotNetEnv


dotnet new page -n Empleados -o Pages/Empleados 


La BD física para implementar la solución del problema.
El código del trigger que asocia un nuevo empleado con las deducciones obligatorias.
El código de una vista que haga la abstracción de una consulta.
El script para para llenado de catálogos.
    cambiar la implementación de empleados
El script que hace la simulación y su corrida.
    por implementar
El código en capa lógica para el sitio web ya sea que el susuario es administrador o empleado.
El código de los SP para realizar los crud, las simulaciones y todas las consultas.


usar vista para facilitar varios joints para facilitar la consulta.


Flujo:
1. sp_InicializarPlanilla
2. cargar catalogos
3.  DECLARE @xmlOperacion XML = '...'; -- Tu XML aquí
    DECLARE @resultado INT;

    EXEC sp_procesarOperacionXML @xmlOperacion, @outResultado = @resultado OUTPUT;

    IF @resultado <> 0
        PRINT 'Error durante el procesamiento: ' + CAST(@resultado AS VARCHAR);
    ELSE
        PRINT 'Procesamiento completado con éxito';


TODO: se debe poder ver el detalle de cada movimiento o qué lo originó.
TODO: ERROR: procedimiento bien hasta 06-28, luego el 06-29 abre la semana 5 vinculada a mes 1, el 29 no debería abrir esta semana, debería abrirla el 06-30