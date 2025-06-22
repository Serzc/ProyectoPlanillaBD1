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

        public List<Puesto> Puestos { get; set; } = new List<Puesto>();
        public List<Departamento> Departamentos { get; set; } = new List<Departamento>();
        public List<TipoDocumentoIdentidad> TiposDocumento { get; set; } = new List<TipoDocumentoIdentidad>();

        public async Task OnGetAsync()
        {
            // Obtener catálogos
            Puestos = await _context.GetPuestos();
            Departamentos = await _context.GetDepartamentos();
            TiposDocumento = await _context.GetTiposDocumento();
        }

        public async Task<IActionResult> OnPostAsync()
        {
            Empleado.FechaContratacion = DateTime.Today.ToString("yyyy-MM-dd");
            Empleado.Activo = true;
            Console.WriteLine("Entrando a OnPostAsync");
            //if (!ModelState.IsValid)
            //{
            //    // Recarga catálogos para la vista
            //    Puestos = await _context.GetPuestos();
            //    Departamentos = await _context.GetDepartamentos();
            //    TiposDocumento = await _context.GetTiposDocumento();
            //    return Page();
            //}
            // Validación adicional por si acaso
            Console.WriteLine($"Empleado: {Empleado.Nombre}, Documento: {Empleado.ValorDocumentoIdentidad}, Usuario: {Empleado.Usuario}");
            if (string.IsNullOrWhiteSpace(Empleado.Usuario) || string.IsNullOrWhiteSpace(Empleado.Password))
            {
                ModelState.AddModelError("", "Debe ingresar nombre de usuario y contraseña.");
                Puestos = await _context.GetPuestos();
                Departamentos = await _context.GetDepartamentos();
                TiposDocumento = await _context.GetTiposDocumento();
                return Page();
            }
            

            var resultado = await _context.InsertarEmpleado(Empleado, HttpContext.Session.GetInt32("idUsuario") ?? 0);

            if (resultado == 0)
            {
                return RedirectToPage("./Index");
            }
            else if (resultado == 50004)
            {
                ModelState.AddModelError("", "Empleado con ese Documento de Identidad ya existe");
            }
            else if (resultado == 50005)
            {
                ModelState.AddModelError("", "Empleado/Usuario con ese nombre ya existe");
            }
            else
            {
                ModelState.AddModelError("", "Error al crear el empleado");
            }
            Puestos = await _context.GetPuestos();
            Departamentos = await _context.GetDepartamentos();
            TiposDocumento = await _context.GetTiposDocumento();
            return Page();
        }
    }
}