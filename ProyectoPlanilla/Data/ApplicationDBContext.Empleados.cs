using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
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
        public async Task<(Empleado, int)> GetEmpleadoById(int id)
        {
            Empleado empleado = null;
            int resultado = 0;

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

                    var outResultado = new SqlParameter
                    {
                        ParameterName = "@outResultado",
                        SqlDbType = SqlDbType.Int,
                        Direction = ParameterDirection.Output
                    };

                    command.Parameters.Add(inId);
                    command.Parameters.Add(outResultado);

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
                                idPuesto = reader.GetInt32(reader.GetOrdinal("idPuesto")),
                                Puesto = reader.GetString(reader.GetOrdinal("Puesto")),
                                FechaContratacion = reader.IsDBNull(reader.GetOrdinal("FechaContratacion")) ? null : reader.GetDateTime(reader.GetOrdinal("FechaContratacion")).ToString("yyyy-MM-dd"),
                                FechaNacimiento = reader.IsDBNull(reader.GetOrdinal("FechaNacimiento")) ? null : reader.GetDateTime(reader.GetOrdinal("FechaNacimiento")).ToString("yyyy-MM-dd"),
                                Activo = reader.GetBoolean(reader.GetOrdinal("Activo")),
                                idDepartamento = reader.GetInt32(reader.GetOrdinal("idDepartamento")),
                                Departamento = reader.GetString(reader.GetOrdinal("Departamento"))
                            };
                        }
                    }

                    resultado = outResultado.Value != DBNull.Value ? (int)outResultado.Value : 0;
                }
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error al obtener empleado por ID: {e.Message}");
                resultado = 50000;
            }

            return (empleado, resultado);
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
        public async Task<int> InsertarEmpleado(Empleado empleado, int idUsuarioOp = 0)
        {
            int resultado = 0;

            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_InsertarEmpleado";
                    command.CommandType = CommandType.StoredProcedure;

                    command.Parameters.Add(new SqlParameter("@inNombre", empleado.Nombre ?? (object)DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@inIdTipoDocumento", empleado.idTipoDocumento));
                    command.Parameters.Add(new SqlParameter("@inValorTipoDocumento", empleado.ValorDocumentoIdentidad ?? (object)DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@inIdDepartamento", empleado.idDepartamento));
                    command.Parameters.Add(new SqlParameter("@inNombrePuesto", empleado.Puesto ?? (object)DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@inUsuario", empleado.Usuario ?? (object)DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@inPassword", empleado.Password ?? (object)DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@inFecha", DateTime.Now));
                    command.Parameters.Add(new SqlParameter("@inFechaNacimiento", string.IsNullOrEmpty(empleado.FechaNacimiento) ? (object)DBNull.Value : DateTime.Parse(empleado.FechaNacimiento)));
                    command.Parameters.Add(new SqlParameter("@inIdUsuarioOp", idUsuarioOp));

                    var outResultado = new SqlParameter("@outResultado", SqlDbType.Int)
                    {
                        Direction = ParameterDirection.Output
                    };
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
        public async Task<int> EditarEmpleado(Empleado empleado)
        {
            int resultado = 0;
            Console.WriteLine($"Editando empleado: {empleado.id}, Nombre: {empleado.Nombre}, TipoDoc: {empleado.idTipoDocumento}, ValorDoc: {empleado.ValorDocumentoIdentidad}, FechaNac: {empleado.FechaNacimiento}, Puesto: {empleado.idPuesto}, Departamento: {empleado.idDepartamento}");
            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_EditarEmpleado";
                    command.CommandType = CommandType.StoredProcedure;

                    command.Parameters.Add(new SqlParameter("@inId", empleado.id));
                    command.Parameters.Add(new SqlParameter("@inNombre", empleado.Nombre ?? (object)DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@inIdTipoDocumento", empleado.idTipoDocumento));
                    command.Parameters.Add(new SqlParameter("@inValorDocumentoIdentidad", empleado.ValorDocumentoIdentidad ?? (object)DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@inFechaNacimiento", string.IsNullOrEmpty(empleado.FechaNacimiento) ? (object)DBNull.Value : DateTime.Parse(empleado.FechaNacimiento)));
                    command.Parameters.Add(new SqlParameter("@inIdPuesto", empleado.idPuesto));
                    command.Parameters.Add(new SqlParameter("@inIdDepartamento", empleado.idDepartamento));

                    var outResultado = new SqlParameter("@outResultado", SqlDbType.Int)
                    {
                        Direction = ParameterDirection.Output
                    };
                    command.Parameters.Add(outResultado);

                    await Database.OpenConnectionAsync();
                    await command.ExecuteNonQueryAsync();

                    resultado = outResultado.Value != DBNull.Value ? (int)outResultado.Value : 0;
                }
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error al editar empleado: {e.Message}");
                resultado = 50000;
            }

            return resultado;
        }
        public async Task<int> EliminarEmpleado(int id)
        {
            int resultado = 0;

            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_EliminarEmpleado";
                    command.CommandType = CommandType.StoredProcedure;

                    command.Parameters.Add(new SqlParameter("@inId", id));
                    command.Parameters.Add(new SqlParameter("@inFecha", DateTime.Now));

                    var outResultado = new SqlParameter("@outResultado", SqlDbType.Int)
                    {
                        Direction = ParameterDirection.Output
                    };
                    command.Parameters.Add(outResultado);

                    await Database.OpenConnectionAsync();
                    await command.ExecuteNonQueryAsync();

                    resultado = outResultado.Value != DBNull.Value ? (int)outResultado.Value : 0;
                }
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error al eliminar empleado: {e.Message}");
                resultado = 50000;
            }

            return resultado;
        }
    }
}