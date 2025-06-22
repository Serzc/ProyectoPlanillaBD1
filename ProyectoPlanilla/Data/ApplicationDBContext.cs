using Microsoft.EntityFrameworkCore;
using ProyectoPlanilla.Models;
using System.Data;
using Microsoft.Data.SqlClient;

namespace ProyectoPlanilla.Data
{
    public partial class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options) { }

        public DbSet<Empleado> Empleados { get; set; }
        public DbSet<Puesto> Puestos { get; set; }
        public DbSet<Departamento> Departamentos { get; set; }
        public DbSet<TipoDocumentoIdentidad> TiposDocumento { get; set; }

        public async Task<List<Puesto>> GetPuestos()
        {
            var puestos = new List<Puesto>();
            
            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_obtenerPuestos";
                    command.CommandType = CommandType.StoredProcedure;
                    var outResultado = new SqlParameter("@outResultado", System.Data.SqlDbType.Int)
                    {
                        Direction = System.Data.ParameterDirection.Output
                    };
                    command.Parameters.Add(outResultado);
                    await Database.OpenConnectionAsync();

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            var puesto = new Puesto
                            {
                                id = reader.GetInt32(reader.GetOrdinal("id")),
                                Nombre = reader.GetString(reader.GetOrdinal("Nombre")),
                                SalarioXHora = reader.GetDecimal(reader.GetOrdinal("SalarioXHora"))
                            };
                            puestos.Add(puesto);
                        }
                    }
                }
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error al obtener puestos: {e.Message}");
            }

            return puestos;
        }

        public async Task<List<Departamento>> GetDepartamentos()
        {
            var departamentos = new List<Departamento>();

            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_obtenerDepartamentos";
                    command.CommandType = CommandType.StoredProcedure;
                    var outResultado = new SqlParameter("@outResultado", System.Data.SqlDbType.Int)
                    {
                        Direction = System.Data.ParameterDirection.Output
                    };
                    command.Parameters.Add(outResultado);
                    await Database.OpenConnectionAsync();

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            var departamento = new Departamento
                            {
                                id = reader.GetInt32(reader.GetOrdinal("id")),
                                Nombre = reader.GetString(reader.GetOrdinal("Nombre"))
                            };
                            departamentos.Add(departamento);
                        }
                    }
                }
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error al obtener departamentos: {e.Message}");
            }

            return departamentos;
        }

        public async Task<List<TipoDocumentoIdentidad>> GetTiposDocumento()
        {
            var tipos = new List<TipoDocumentoIdentidad>();

            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_obtenerTiposDocumentoIdentidad";
                    command.CommandType = CommandType.StoredProcedure;
                    var outResultado = new SqlParameter("@outResultado", System.Data.SqlDbType.Int)
                    {
                        Direction = System.Data.ParameterDirection.Output
                    };
                    command.Parameters.Add(outResultado);
                    await Database.OpenConnectionAsync();

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            var tipo = new TipoDocumentoIdentidad
                            {
                                id = reader.GetInt32(reader.GetOrdinal("id")),
                                Nombre = reader.GetString(reader.GetOrdinal("Nombre"))
                            };
                            tipos.Add(tipo);
                        }
                    }
                }
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error al obtener tipos de documento: {e.Message}");
            }

            return tipos;
        }
        public async Task<int> EliminarTablasAsync()
        {
            int resultado = 0;
            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_borrarTablas";
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    var outResultado = new SqlParameter("@outResultado", System.Data.SqlDbType.Int)
                    {
                        Direction = System.Data.ParameterDirection.Output
                    };
                    command.Parameters.Add(outResultado);
                    await Database.OpenConnectionAsync();
                    await command.ExecuteNonQueryAsync();
                    resultado = 0;
                }
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error al eliminar tablas: {e.Message}");
                resultado = 50008;
            }
            return resultado;
        }

        public async Task<int> CargarCatalogoDesdeXMLAsync(string xmlCatalogo)
        {
            int resultado = 0;
            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_CargarCatalogoDesdeXML";
                    command.CommandType = System.Data.CommandType.StoredProcedure;

                    var paramXml = new SqlParameter("@inXmlData", System.Data.SqlDbType.Xml)
                    {
                        Value = xmlCatalogo
                    };
                    var paramOut = new SqlParameter("@outResultado", System.Data.SqlDbType.Int)
                    {
                        Direction = System.Data.ParameterDirection.Output
                    };

                    command.Parameters.Add(paramXml);
                    command.Parameters.Add(paramOut);

                    await Database.OpenConnectionAsync();
                    await command.ExecuteNonQueryAsync();

                    resultado = (int)(paramOut.Value ?? -1);
                }
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error al cargar catálogo desde XML: {e.Message}");
                resultado = 50008;
            }
            return resultado;
        }
    }
}