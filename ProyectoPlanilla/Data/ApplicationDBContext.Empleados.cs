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
        public async Task<Empleado> GetEmpleadoById(int id)
        {
            Empleado empleado = null;

            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_obtenerEmpleadoPorId";
                    command.CommandType = CommandType.StoredProcedure;

                    var inId = new SqlParameter
                    {
                        ParameterName = "@inId",
                        SqlDbType = SqlDbType.Int,
                        Direction = ParameterDirection.Input,
                        Value = id
                    };

                    command.Parameters.Add(inId);

                    await Database.OpenConnectionAsync();

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        if (await reader.ReadAsync())
                        {
                            empleado = new Empleado
                            {
                                id = reader.GetInt32(reader.GetOrdinal("id")),
                                ValorDocumentoIdentidad = reader.GetString(reader.GetOrdinal("ValorDocumentoIdentidad")),
                                Nombre = reader.GetString(reader.GetOrdinal("Nombre")),
                                Puesto = reader.GetString(reader.GetOrdinal("Puesto")),
                                // Otros campos...
                            };
                        }
                    }
                }
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error al obtener empleado por ID: {e.Message}");
            }

            return empleado;
        }
        public async Task<int> ActualizarEmpleado(Empleado empleado)
        {
            int resultado = 0;

            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_actualizarEmpleado";
                    command.CommandType = CommandType.StoredProcedure;

                    var inId = new SqlParameter
                    {
                        ParameterName = "@inId",
                        SqlDbType = SqlDbType.Int,
                        Direction = ParameterDirection.Input,
                        Value = empleado.id
                    };
                    var inNombre = new SqlParameter
                    {
                        ParameterName = "@inNombre",
                        SqlDbType = SqlDbType.VarChar,
                        Direction = ParameterDirection.Input,
                        Value = empleado.Nombre ?? (object)DBNull.Value
                    };
                    // Otros parámetros...

                    var outResultado = new SqlParameter
                    {
                        ParameterName = "@outResultado",
                        SqlDbType = SqlDbType.Int,
                        Direction = ParameterDirection.Output
                    };

                    command.Parameters.Add(inId);
                    command.Parameters.Add(inNombre);
                    // Otros parámetros...
                    command.Parameters.Add(outResultado);

                    await Database.OpenConnectionAsync();

                    await command.ExecuteNonQueryAsync();

                    resultado = outResultado.Value != DBNull.Value ? (int)outResultado.Value : 0;
                }
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error al actualizar empleado: {e.Message}");
                resultado = 50000;
            }

            return resultado;
        }

        public async Task<int> InsertarEmpleado(Empleado empleado)
        {
            int resultado = 0;

            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_insertarEmpleado";
                    command.CommandType = CommandType.StoredProcedure;

                    var inNombre = new SqlParameter
                    {
                        ParameterName = "@inNombre",
                        SqlDbType = SqlDbType.VarChar,
                        Direction = ParameterDirection.Input,
                        Value = empleado.Nombre ?? (object)DBNull.Value
                    };
                    var inValorDocumentoIdentidad = new SqlParameter
                    {
                        ParameterName = "@inValorDocumentoIdentidad",
                        SqlDbType = SqlDbType.VarChar,
                        Direction = ParameterDirection.Input,
                        Value = empleado.ValorDocumentoIdentidad ?? (object)DBNull.Value
                    };
                    // Otros parámetros...

                    var outResultado = new SqlParameter
                    {
                        ParameterName = "@outResultado",
                        SqlDbType = SqlDbType.Int,
                        Direction = ParameterDirection.Output
                    };

                    command.Parameters.Add(inNombre);
                    command.Parameters.Add(inValorDocumentoIdentidad);
                    // Otros parámetros...
                    command.Parameters.Add(outResultado);

                    await Database.OpenConnectionAsync();

                    await command.ExecuteNonQueryAsync();

                    resultado = outResultado.Value != DBNull.Value ? (int)outResultado.Value : 0;
                }
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error al insertar empleado: {e.Message}");
                resultado = 50000;
            }

            return resultado;
        }
    }
}