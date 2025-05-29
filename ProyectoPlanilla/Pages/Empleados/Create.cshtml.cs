// Create.cshtml.cs
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using ProyectoPlanilla.Data;
using ProyectoPlanilla.Models;

namespace ProyectoPlanilla.Pages.Empleados
{
    public class CreateModel : PageModel
    {
        private readonly ApplicationDbContext _context;

        public CreateModel(ApplicationDbContext context)
        {
            _context = context;
        }

        [BindProperty]
        public Empleado Empleado { get; set; }

        public List<Puesto> Puestos { get; set; }
        public List<Departamento> Departamentos { get; set; }
        public List<TipoDocumentoIdentidad> TiposDocumento { get; set; }

        public async Task OnGetAsync()
        {
            // Obtener catálogos
            Puestos = await _context.GetPuestos();
            Departamentos = await _context.GetDepartamentos();
            TiposDocumento = await _context.GetTiposDocumento();
        }

        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }

            Empleado.FechaContratacion = DateTime.Today.ToString("yyyy-MM-dd");
            Empleado.Activo = true;

            var resultado = await _context.InsertarEmpleado(Empleado);

            if (resultado == 0)
            {
                return RedirectToPage("./Index");
            }
            else
            {
                ModelState.AddModelError("", "Error al crear el empleado");
                return Page();
            }
        }
    }
}