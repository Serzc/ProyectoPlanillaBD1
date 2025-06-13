using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using ProyectoPlanilla.Models;
using System.Data;

namespace ProyectoPlanilla.Data
{
    public partial class ApplicationDbContext
    {
        public async Task<(Usuario? usuario, int resultado)> LoginUsuarioAsync(string username, string password, string ip)
        {
            Usuario? usuario = null;
            int resultado = 0;

            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_loginUsuario";
                    command.CommandType = CommandType.StoredProcedure;

                    command.Parameters.Add(new SqlParameter("@inUsername", SqlDbType.VarChar) { Value = username });
                    command.Parameters.Add(new SqlParameter("@inPassword", SqlDbType.VarChar) { Value = password });
                    command.Parameters.Add(new SqlParameter("@inIP", SqlDbType.VarChar) { Value = ip });

                    var outResultado = new SqlParameter("@outResultado", SqlDbType.Int)
                    {
                        Direction = ParameterDirection.Output
                    };
                    command.Parameters.Add(outResultado);

                    await Database.OpenConnectionAsync();

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        if (await reader.ReadAsync())
                        {
                            usuario = new Usuario
                            {
                                id = reader.GetInt32(reader.GetOrdinal("id")),
                                Username = reader.GetString(reader.GetOrdinal("Username")),
                                Tipo = reader.GetInt32(reader.GetOrdinal("Tipo")),
                                idEmpleado = reader.IsDBNull(reader.GetOrdinal("idEmpleado")) ? null : reader.GetInt32(reader.GetOrdinal("idEmpleado"))
                            };
                        }
                    }

                    resultado = (int)(outResultado.Value ?? 0);
                }
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error al hacer login: {e.Message}");
                resultado = 50000;
            }

            return (usuario, resultado);
        }

        public async Task<int> LogoutUsuarioAsync(int idUsuario, string ip)
        {
            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_logoutUsuario";
                    command.CommandType = CommandType.StoredProcedure;

                    command.Parameters.Add(new SqlParameter("@inIdUsuario", SqlDbType.Int) { Value = idUsuario });
                    command.Parameters.Add(new SqlParameter("@inIP", SqlDbType.VarChar) { Value = ip });

                    var outResultado = new SqlParameter("@outResultado", SqlDbType.Int)
                    {
                        Direction = ParameterDirection.Output
                    };
                    command.Parameters.Add(outResultado);

                    await Database.OpenConnectionAsync();
                    await command.ExecuteNonQueryAsync();

                    return (int)(outResultado.Value ?? -1);
                }
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error en logout: {e.Message}");
                return 50000;
            }
        }

    }
}
