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
            Console.WriteLine($"EditModel OnGetAsync called with id: {id}");
            try
            {
                Empleado = await _context.GetEmpleadoById(id.Value) ?? new Empleado
                {
                    Nombre = "No encontrado",
                    ValorDocumentoIdentidad = "N/A",
                    Puesto = "N/A"
                };
                Puestos = await _context.GetPuestos() ?? new List<Puesto>();
                Departamentos = await _context.GetDepartamentos() ?? new List<Departamento>();
                TiposDocumento = await _context.GetTiposDocumento() ?? new List<TipoDocumentoIdentidad>();
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("", $"Error al cargar los datos del empleado: {ex.Message}");
                Empleado = new Empleado
                {
                    Nombre = "No encontrado",
                    ValorDocumentoIdentidad = "N/A",
                    Puesto = "N/A"
                };
                Puestos = new List<Puesto>();
                Departamentos = new List<Departamento>();
                TiposDocumento = new List<TipoDocumentoIdentidad>();
                return Page();
            }
            //if (id == null)
            //{
            //    return NotFound();
            //}

            // Obtener empleado y catálogos

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