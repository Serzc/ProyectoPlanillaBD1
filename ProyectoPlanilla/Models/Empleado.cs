using System.ComponentModel.DataAnnotations;

namespace ProyectoPlanilla.Models
{
    public class Empleado
    {
        public int id { get; set; }

        [Required]
        public string Nombre { get; set; }

        [Required]
        public string ValorDocumentoIdentidad { get; set; }

        public int idPuesto { get; set; }
        public string Puesto { get; set; }
        
    

        public bool Activo { get; set; } = true;
    }
}