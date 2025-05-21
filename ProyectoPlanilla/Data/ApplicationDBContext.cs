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

        
    }
}