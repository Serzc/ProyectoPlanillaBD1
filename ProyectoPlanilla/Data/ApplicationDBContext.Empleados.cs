using Microsoft.EntityFrameworkCore;
using ProyectoPlanilla.Models;
using System.Data;
using Microsoft.Data.SqlClient;

namespace ProyectoPlanilla.Data
{
    public partial class ApplicationDbContext
    {
        public async Task<(List<Empleado>, int)> ObtenerEmpleadosActivos(string filtro)
        {
            var empleados = new List<Empleado>();
            int resultado = 0;

            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_obtenerEmpleadosFiltro";
                    command.CommandType = CommandType.StoredProcedure;

                    var inFiltro = new SqlParameter
                    {
                        ParameterName = "@inFiltro",
                        SqlDbType = SqlDbType.VarChar,
                        Direction = ParameterDirection.Input,
                        Value = (object)filtro ?? DBNull.Value
                    };

                    var outResultado = new SqlParameter
                    {
                        ParameterName = "@outResultado",
                        SqlDbType = SqlDbType.Int,
                        Direction = ParameterDirection.Output
                    };

                    command.Parameters.Add(inFiltro);
                    command.Parameters.Add(outResultado);

                    await Database.OpenConnectionAsync();

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        
                        while (await reader.ReadAsync())
                        {
                            var empleado = new Empleado
                            {
                                id = reader.GetInt32(reader.GetOrdinal("id")),
                                ValorDocumentoIdentidad = reader.GetString(reader.GetOrdinal("ValorDocumentoIdentidad")),
                                Nombre = reader.GetString(reader.GetOrdinal("Nombre")),
                                Puesto = reader.GetString(reader.GetOrdinal("Puesto")),
                                                            
                                
                            };
                            empleados.Add(empleado);
                        }
                    }

                    resultado = outResultado.Value != DBNull.Value ? (int)outResultado.Value : 0;
                }
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error al obtener empleados: {e.Message}");
                resultado = 50000;
            }

            return (empleados, resultado);
        }
    }
}