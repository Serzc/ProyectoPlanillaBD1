using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
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

        public IList<Empleado> Empleados { get; set; }

        public async Task OnGetAsync()
        {
            Empleados = await _context.Empleados
                            .Include(e => e.Puesto)
                            .Where(e => e.Activo)
                            .OrderBy(e => e.Nombre)
                            .ToListAsync();
        }
    }
}