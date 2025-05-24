using Microsoft.AspNetCore.Mvc.RazorPages;
using ProyectoPlanilla.Data;
using ProyectoPlanilla.Models;

namespace ProyectoPlanilla.Pages.Empleados
{
    public class IndexModel : PageModel
    {
        private readonly ApplicationDbContext _context;

        public IndexModel(ApplicationDbContext context)
        {
            _context = context;
        }

        public IList<Empleado> Empleados { get; set; } = new List<Empleado>();
        public string MensajeError { get; set; }

        public async Task OnGetAsync()
        {
            var (empleados, resultado) = await _context.ObtenerEmpleadosActivos();

            if (resultado == 0)
            {
                Empleados = empleados;
            }
            else
            {
                MensajeError = "Error al obtener los empleados activos. Código de error: " + resultado;
                // Aquí podrías loguear el error o manejarlo de otra manera
            }
        }
    }
}