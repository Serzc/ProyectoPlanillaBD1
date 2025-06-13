// PlanillaMensual.cshtml.cs
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using ProyectoPlanilla.Data;
using ProyectoPlanilla.Models;

namespace ProyectoPlanilla.Pages.Planilla
{
    public class PlanillaMensualModel : PageModel
    {
        private readonly ApplicationDbContext _context;

        public PlanillaMensualModel(ApplicationDbContext context)
        {
            _context = context;
        }

        public List<PlanillaMensual> Planillas { get; set; } = new List<PlanillaMensual>();
        public List<DetalleDeduccion> DetalleDeducciones { get; set; } = new List<DetalleDeduccion>();

        [BindProperty(SupportsGet = true)]
        public int? IdPlanillaSeleccionada { get; set; }

        public async Task OnGetAsync(int? idEmpleado)
        {
            try
            {
                if (idEmpleado == null || idEmpleado == 0)
                {
                    idEmpleado = HttpContext.Session.GetInt32("idEmpleado");
                }

                if (idEmpleado == null || idEmpleado == 0)
                {
                    ModelState.AddModelError("", "No se encontró el ID del empleado en sesión ni en la URL.");
                    return;
                }

                Console.WriteLine($"PlanillaMensualModel OnGetAsync called with idEmpleado: {idEmpleado}");

                Planillas = await _context.GetPlanillasMensuales(idEmpleado.Value, 12);

                if (IdPlanillaSeleccionada.HasValue)
                {
                    DetalleDeducciones = await _context.GetDetalleDeduccionesMensuales(IdPlanillaSeleccionada.Value);
                }
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("", $"Error al cargar las planillas mensuales: {ex.Message}");
                Planillas = new List<PlanillaMensual>();
                DetalleDeducciones = new List<DetalleDeduccion>();
            }
        }

    }

    
}