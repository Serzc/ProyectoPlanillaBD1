using System.ComponentModel.DataAnnotations;

namespace ProyectoPlanilla.Models
{
    public class TipoDocumentoIdentidad
    {
        public int id { get; set; }

        [Required]
        public string Nombre { get; set; }
    }
    
}