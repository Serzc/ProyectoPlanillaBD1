using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using ProyectoPlanilla.Data;
using ProyectoPlanilla.Models;

namespace ProyectoPlanilla.Pages.login
{
    public class loginModel : PageModel
    {
        private readonly ApplicationDbContext _context;

        public loginModel(ApplicationDbContext context)
        {
            _context = context;
        }

        [BindProperty]
        public LoginViewModel Login { get; set; } = new();

        public string? ErrorMessage { get; set; }

        public IActionResult OnGet()
        {
            if (HttpContext.Session.GetInt32("idUsuario") != null)
            {
                var tipo = HttpContext.Session.GetInt32("tipoUsuario");
                if (tipo == 1)
                    return RedirectToPage("/Empleados/index"); // Admin
                if (tipo == 2)
                    return RedirectToPage("/Planilla/PlanillaSemanal"); // Empleado
            }

            return Page();
        }

        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
                return Page();

            var ip = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "localhost";
            var (usuario, resultado) = await _context.LoginUsuarioAsync(Login.Username, Login.Password, ip);

            if (resultado == 1 && usuario != null)
            {
                HttpContext.Session.SetInt32("idUsuario", usuario.id);
                HttpContext.Session.SetString("username", usuario.Username);
                HttpContext.Session.SetInt32("tipoUsuario", usuario.Tipo);
                if (usuario.idEmpleado.HasValue)
                    HttpContext.Session.SetInt32("idEmpleado", usuario.idEmpleado.Value);

                if (usuario.Tipo == 1)
                    return RedirectToPage("/Empleados/index");

                if (usuario.Tipo == 2)
                    return RedirectToPage("/Planilla/PlanillaSemanal");

                return RedirectToPage("/login/login");
            }

            ErrorMessage = "Usuario o contraseña incorrectos.";
            return Page();
        }
    }
}
