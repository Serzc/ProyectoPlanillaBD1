using Microsoft.AspNetCore.Mvc;
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

        [BindProperty(SupportsGet = true)]
        public string Filtro { get; set; } = string.Empty;
        public IList<Empleado> Empleados { get; set; } = new List<Empleado>();
        public string MensajeError { get; set; }
        [BindProperty]
        public string XmlOperacion { get; set; }
        public string MensajeProceso { get; set; }
        [BindProperty]
        public string XmlCatalogo { get; set; }
        public string MensajeCatalogo { get; set; }
        public string MensajeEliminacion { get; set; }

        public async Task OnGetAsync()
        {
            var (empleados, resultado) = await _context.ObtenerEmpleadosActivos(Filtro.Replace("-", ""));

            if (resultado == 0)
            {
                Empleados = empleados;
            }
            else
            {
                MensajeError = "Error al obtener los empleados activos. Código de error: " + resultado;
            }
        }
        public async Task<IActionResult> OnPostProcesarPlanillaAsync()
        {
            if (string.IsNullOrWhiteSpace(XmlOperacion))
            {
                MensajeProceso = "Debe ingresar un XML válido.";
                await OnGetAsync();
                return Page();
            }

            var resultado = await _context.ProcesarOperacionXMLAsync(XmlOperacion);

            if (resultado != 0)
                MensajeProceso = $"Error durante el procesamiento: {resultado}";
            else
                MensajeProceso = "Procesamiento completado con éxito";

            await OnGetAsync();
            return Page();
        }
        public async Task<IActionResult> OnPostEliminarTablasAsync()
        {
            var resultado = await _context.EliminarTablasAsync();
            if (resultado == 0)
                MensajeEliminacion = "¡Tablas eliminadas y reiniciadas correctamente!";
            else
                MensajeEliminacion = $"Error al eliminar tablas. Código: {resultado}";
            await OnGetAsync();
            return Page();
        }

        public async Task<IActionResult> OnPostCargarCatalogoAsync()
        {
            if (string.IsNullOrWhiteSpace(XmlCatalogo))
            {
                MensajeCatalogo = "Debe ingresar un XML válido para el catálogo.";
                await OnGetAsync();
                return Page();
            }

            var resultado = await _context.CargarCatalogoDesdeXMLAsync(XmlCatalogo);
            if (resultado == 0)
                MensajeCatalogo = "Catálogo cargado correctamente.";
            else
                MensajeCatalogo = $"Error al cargar catálogo. Código: {resultado}";
            await OnGetAsync();
            return Page();
        }
        public IActionResult OnPostImpersonar(int idEmpleado)
        {
            HttpContext.Session.SetInt32("idEmpleado", idEmpleado);
            HttpContext.Session.SetInt32("tipoUsuario", 1); // Se comporta como empleado

            return RedirectToPage("/Planilla/PlanillaSemanal", new { idEmpleado });
        }

    }
}