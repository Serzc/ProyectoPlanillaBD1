using Microsoft.EntityFrameworkCore;
using ProyectoPlanilla.Models;
using System.Data;
using Microsoft.Data.SqlClient;
// Removed: using ProyectoPlanilla.Pages.Planilla;

namespace ProyectoPlanilla.Data
{
    public partial class ApplicationDbContext
    {

        public async Task<List<PlanillaSemanal>> GetPlanillasSemanales(int idEmpleado, int cantidad)
        {
            var planillas = new List<PlanillaSemanal>();

            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_obtenerPlanillasSemanales";
                    command.CommandType = CommandType.StoredProcedure;

                    var inIdEmpleado = new SqlParameter
                    {
                        ParameterName = "@inIdEmpleado",
                        SqlDbType = SqlDbType.Int,
                        Direction = ParameterDirection.Input,
                        Value = idEmpleado
                    };

                    var inCantidad = new SqlParameter
                    {
                        ParameterName = "@inCantidad",
                        SqlDbType = SqlDbType.Int,
                        Direction = ParameterDirection.Input,
                        Value = cantidad
                    };
                    var outResultado = new SqlParameter
                    {
                        ParameterName = "@outResultado",
                        SqlDbType = SqlDbType.Int,
                        Direction = ParameterDirection.Output
                    };

                    command.Parameters.Add(inIdEmpleado);
                    command.Parameters.Add(inCantidad);
                    command.Parameters.Add(outResultado);

                    await Database.OpenConnectionAsync();

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            var planilla = new PlanillaSemanal
                            {
                                Id = reader.GetInt32(reader.GetOrdinal("id")),
                                FechaInicio = reader.GetDateTime(reader.GetOrdinal("FechaInicio")),
                                FechaFin = reader.GetDateTime(reader.GetOrdinal("FechaFin")),
                                SalarioBruto = reader.GetDecimal(reader.GetOrdinal("SalarioBruto")),
                                TotalDeducciones = reader.GetDecimal(reader.GetOrdinal("TotalDeducciones")),
                                SalarioNeto = reader.GetDecimal(reader.GetOrdinal("SalarioNeto")),
                                HorasOrdinarias = reader.GetInt32(reader.GetOrdinal("HorasOrdinarias")),
                                HorasExtrasNormales = reader.GetInt32(reader.GetOrdinal("HorasExtrasNormales")),
                                HorasExtrasDobles = reader.GetInt32(reader.GetOrdinal("HorasExtrasDobles"))
                            };
                            planillas.Add(planilla);
                        }
                    }
                }
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error al obtener planillas semanales: {e.Message}");
            }

            return planillas;
        }
        public async Task<List<DetalleDeduccion>> GetDetalleDeducciones(int idPlanilla)
        {
            var detalleDeducciones = new List<DetalleDeduccion>();

            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_obtenerDetalleDeducciones";
                    command.CommandType = CommandType.StoredProcedure;

                    var inIdPlanilla = new SqlParameter
                    {
                        ParameterName = "@inIdPlanilla",
                        SqlDbType = SqlDbType.Int,
                        Direction = ParameterDirection.Input,
                        Value = idPlanilla
                    };

                    command.Parameters.Add(inIdPlanilla);

                    await Database.OpenConnectionAsync();

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            var deduccion = new DetalleDeduccion
                            {
                                Nombre = reader.GetString(reader.GetOrdinal("Nombre")),
                                Porcentaje = reader.IsDBNull(reader.GetOrdinal("Porcentaje")) ? null : reader.GetDecimal(reader.GetOrdinal("Porcentaje")),
                                Monto = reader.GetDecimal(reader.GetOrdinal("Monto"))
                            };
                            detalleDeducciones.Add(deduccion);
                        }
                    }
                }
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error al obtener detalle de deducciones: {e.Message}");
            }

            return detalleDeducciones;
        }
        public async Task<List<DetalleMovimiento>> GetDetalleMovimientos(int idPlanilla)
        {
            var detalleMovimientos = new List<DetalleMovimiento>();

            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_obtenerDetalleMovimientos";
                    command.CommandType = CommandType.StoredProcedure;

                    var inIdPlanilla = new SqlParameter
                    {
                        ParameterName = "@inIdPlanilla",
                        SqlDbType = SqlDbType.Int,
                        Direction = ParameterDirection.Input,
                        Value = idPlanilla
                    };

                    command.Parameters.Add(inIdPlanilla);

                    await Database.OpenConnectionAsync();

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            var movimiento = new DetalleMovimiento
                            {
                                Nombre = reader.GetString(reader.GetOrdinal("Nombre")),
                                Monto = reader.GetDecimal(reader.GetOrdinal("Monto")),
                                Fecha = reader.GetDateTime(reader.GetOrdinal("Fecha"))
                            };
                            detalleMovimientos.Add(movimiento);
                        }
                    }
                }
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error al obtener detalle de movimientos: {e.Message}");
            }

            return detalleMovimientos;
        }
        public async Task<List<PlanillaMensual>> GetPlanillasMensuales(int idEmpleado, int cantidad)
        {
            var planillas = new List<PlanillaMensual>();

            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_obtenerPlanillasMensuales";
                    command.CommandType = CommandType.StoredProcedure;

                    var inIdEmpleado = new SqlParameter
                    {
                        ParameterName = "@inIdEmpleado",
                        SqlDbType = SqlDbType.Int,
                        Direction = ParameterDirection.Input,
                        Value = idEmpleado
                    };

                    var inCantidad = new SqlParameter
                    {
                        ParameterName = "@inCantidad",
                        SqlDbType = SqlDbType.Int,
                        Direction = ParameterDirection.Input,
                        Value = cantidad
                    };

                    command.Parameters.Add(inIdEmpleado);
                    command.Parameters.Add(inCantidad);

                    await Database.OpenConnectionAsync();

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            var planilla = new PlanillaMensual
                            {
                                id = reader.GetInt32(reader.GetOrdinal("id")),
                                FechaInicio = reader.GetDateTime(reader.GetOrdinal("FechaInicio")),
                                FechaFin = reader.GetDateTime(reader.GetOrdinal("FechaFin")),
                                SalarioBruto = reader.GetDecimal(reader.GetOrdinal("SalarioBruto")),
                                TotalDeducciones = reader.GetDecimal(reader.GetOrdinal("TotalDeducciones")),
                                SalarioNeto = reader.GetDecimal(reader.GetOrdinal("SalarioNeto"))
                            };
                            planillas.Add(planilla);
                        }
                    }
                }
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error al obtener planillas mensuales: {e.Message}");
            }

            return planillas;
        }
        public async Task<List<DetalleDeduccion>> GetDetalleDeduccionesMensuales(int idPlanilla)
        {
            var detalleDeducciones = new List<DetalleDeduccion>();

            try
            {
                using (var command = Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = "sp_obtenerDetalleDeduccionesMensuales";
                    command.CommandType = CommandType.StoredProcedure;

                    var inIdPlanilla = new SqlParameter
                    {
                        ParameterName = "@inIdPlanilla",
                        SqlDbType = SqlDbType.Int,
                        Direction = ParameterDirection.Input,
                        Value = idPlanilla
                    };

                    command.Parameters.Add(inIdPlanilla);

                    await Database.OpenConnectionAsync();

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            var deduccion = new DetalleDeduccion
                            {
                                Nombre = reader.GetString(reader.GetOrdinal("Nombre")),
                                Porcentaje = reader.IsDBNull(reader.GetOrdinal("Porcentaje")) ? null : reader.GetDecimal(reader.GetOrdinal("Porcentaje")),
                                Monto = reader.GetDecimal(reader.GetOrdinal("Monto"))
                            };
                            detalleDeducciones.Add(deduccion);
                        }
                    }
                }
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error al obtener detalle de deducciones mensuales: {e.Message}");
            }

            return detalleDeducciones;
        }
    }
}