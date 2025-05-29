// Edit.cshtml.cs
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using ProyectoPlanilla.Data;
using ProyectoPlanilla.Models;

namespace ProyectoPlanilla.Pages.Empleados
{
    public class EditModel : PageModel
    {
        private readonly ApplicationDbContext _context;

        public EditModel(ApplicationDbContext context)
        {
            _context = context;
        }

        [BindProperty]
        public Empleado Empleado { get; set; }

        public List<Puesto> Puestos { get; set; }
        public List<Departamento> Departamentos { get; set; }
        public List<TipoDocumentoIdentidad> TiposDocumento { get; set; }

        public async Task<IActionResult> OnGetAsync(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            // Obtener empleado y catálogos
            Empleado = await _context.GetEmpleadoById(id.Value);
            Puestos = await _context.GetPuestos();
            Departamentos = await _context.GetDepartamentos();
            TiposDocumento = await _context.GetTiposDocumento();

            if (Empleado == null)
            {
                return NotFound();
            }

            return Page();
        }

        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }

            var resultado = await _context.ActualizarEmpleado(Empleado);

            if (resultado == 0)
            {
                return RedirectToPage("./Index");
            }
            else
            {
                ModelState.AddModelError("", "Error al actualizar el empleado");
                return Page();
            }
        }
    }
}