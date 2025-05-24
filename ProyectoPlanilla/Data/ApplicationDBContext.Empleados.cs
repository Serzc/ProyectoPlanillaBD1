using Microsoft.EntityFrameworkCore;
using ProyectoPlanilla.Models;
using System.Data;
using Microsoft.Data.SqlClient;

namespace ProyectoPlanilla.Data
{
    public partial class ApplicationDbContext
    {
        public async Task<(List<Empleado>, int)> ObtenerEmpleadosActivos()
        {
            var empleados = new List<Empleado>();
            int resultado = 0;

            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_ObtenerEmpleadosActivos";
                    command.CommandType = CommandType.StoredProcedure;

                    // Parámetros de salida
                    var outResultado = new SqlParameter
                    {
                        ParameterName = "@outResultado",
                        SqlDbType = SqlDbType.Int,
                        Direction = ParameterDirection.Output
                    };
                   
                    command.Parameters.Add(outResultado);
                    
                    await Database.OpenConnectionAsync();

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            var empleado = new Empleado
                            {
                                Id = reader.GetInt32(0),
                                Nombre = reader.GetString(1),
                                ValorDocumentoIdentidad = reader.GetString(2),
                                Activo = reader.GetBoolean(3),
                                Puesto = new Puesto
                                {
                                    Id = reader.GetInt32(4),
                                    Nombre = reader.GetString(5),
                                    SalarioXHora = reader.GetDecimal(6)
                                }
                            };
                            empleados.Add(empleado);
                        }
                    }

                    resultado = (int)outResultado.Value;                    
                }
            }
            catch (Exception ex)
            {
                resultado = 50000;
                            }

            return (empleados, resultado);
        }


    }
}