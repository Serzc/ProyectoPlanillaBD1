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
            if (id == null)
                return NotFound();
            try
            {
                var (empleado, resultado) = await _context.GetEmpleadoById(id.Value);

                if (empleado == null || resultado != 0)
                {
                    ModelState.AddModelError("", "No se encontró el empleado o hubo un error al obtenerlo.");
                    Empleado = new Empleado
                    {
                        Nombre = "No encontrado",
                        ValorDocumentoIdentidad = "N/A",
                        Puesto = "N/A"
                    };
                }
                else
                {
                    Empleado = empleado;
                }

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
            }

            return Page();
        }

        public async Task<IActionResult> OnPostAsync(string accion)
        {
            if (accion == "eliminar")
            {
                var resultado = await _context.EliminarEmpleado(Empleado.id);

                if (resultado == 0)
                {
                    return RedirectToPage("./Index");
                }
                else if (resultado == 50008)
                {
                    ModelState.AddModelError("", "No se encontró el empleado o ya estaba inactivo.");
                }
                else
                {
                    ModelState.AddModelError("", "Error al eliminar el empleado.");
                }

                Puestos = await _context.GetPuestos();
                Departamentos = await _context.GetDepartamentos();
                TiposDocumento = await _context.GetTiposDocumento();
                return Page();
            }

            // editar empleado============================================
            Console.WriteLine("EditModel OnPostAsync called");
            //if (!ModelState.IsValid)
            //{
            //    Puestos = await _context.GetPuestos();
            //    Departamentos = await _context.GetDepartamentos();
            //    TiposDocumento = await _context.GetTiposDocumento();
            //    return Page();
            //}

            var resultadoEdicion = await _context.EditarEmpleado(Empleado);

            if (resultadoEdicion == 0)
            {
                return RedirectToPage("./Index");
            }
            else if (resultadoEdicion == 50004)
            {
                ModelState.AddModelError("", "Empleado con ese Documento de Identidad ya existe");
            }
            else if (resultadoEdicion == 50005)
            {
                ModelState.AddModelError("", "Empleado con ese nombre ya existe");
            }
            else
            {
                ModelState.AddModelError("", "Error al actualizar el empleado");
            }

            Puestos = await _context.GetPuestos();
            Departamentos = await _context.GetDepartamentos();
            TiposDocumento = await _context.GetTiposDocumento();
            return Page();
        }
    }
}