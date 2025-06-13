using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using ProyectoPlanilla.Data;

namespace ProyectoPlanilla.Pages
{
    public class LogoutModel : PageModel
    {
        private readonly ApplicationDbContext _context;

        public LogoutModel(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> OnGet()
        {
            var idUsuario = HttpContext.Session.GetInt32("idUsuario") ?? 0;
            var ip = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "localhost";

            if (idUsuario != 0)
            {
                await _context.LogoutUsuarioAsync(idUsuario, ip);
            }

            HttpContext.Session.Clear();

            return RedirectToPage("/login/login");
        }
    }
}
