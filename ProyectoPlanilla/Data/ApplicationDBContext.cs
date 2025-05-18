using Microsoft.EntityFrameworkCore;
using ProyectoPlanilla.Models;

namespace ProyectoPlanilla.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options) { }

        public DbSet<Empleado> Empleados { get; set; }
        public DbSet<Puesto> Puestos { get; set; }
    }
}