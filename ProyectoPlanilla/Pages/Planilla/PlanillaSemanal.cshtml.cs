// PlanillaSemanal.cshtml.cs
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using ProyectoPlanilla.Data;
using ProyectoPlanilla.Models;


namespace ProyectoPlanilla.Pages.Planilla
{
    public class PlanillaSemanalModel : PageModel
    {
        private readonly ApplicationDbContext _context;

        public PlanillaSemanalModel(ApplicationDbContext context)
        {
            _context = context;
        }

        public List<Models.PlanillaSemanal> Planillas { get; set; } = new List<Models.PlanillaSemanal>();
        public List<Models.DetalleDeduccion> DetalleDeducciones { get; set; } = new List<Models.DetalleDeduccion>();
        public List<Models.DetalleMovimiento> DetalleMovimientos { get; set; } = new List<Models.DetalleMovimiento>();

        [BindProperty(SupportsGet = true)]
        public int? IdPlanillaSeleccionada { get; set; }

        [BindProperty(SupportsGet = true)]
        public string TipoDetalle { get; set; } // "deducciones" o "movimientos"
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

                Console.WriteLine($"PlanillaSemanalModel OnGetAsync called with idEmpleado: {idEmpleado}");

                Planillas = await _context.GetPlanillasSemanales(idEmpleado.Value, 15);

                if (IdPlanillaSeleccionada.HasValue)
                {
                    if (TipoDetalle == "deducciones")
                    {
                        DetalleDeducciones = await _context.GetDetalleDeducciones(IdPlanillaSeleccionada.Value);
                    }
                    else if (TipoDetalle == "movimientos")
                    {
                        DetalleMovimientos = await _context.GetDetalleMovimientos(IdPlanillaSeleccionada.Value);
                    }
                }
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("", $"Error al cargar las planillas semanales: {ex.Message}");
                Planillas = new List<Models.PlanillaSemanal>();
                DetalleDeducciones = new List<Models.DetalleDeduccion>();
                DetalleMovimientos = new List<Models.DetalleMovimiento>();
            }
        }

    }
}
