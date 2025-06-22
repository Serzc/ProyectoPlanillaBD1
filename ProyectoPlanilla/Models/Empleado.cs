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
        public int idTipoDocumento { get; set; }
        public int idPuesto { get; set; }
        public string Puesto { get; set; }

        public string FechaNacimiento { get; set; }

        public bool Activo { get; set; } = true;
        public int idDepartamento { get; set; }
        public string FechaContratacion { get; set; } = DateTime.Now.ToString("yyyy-MM-dd");
        public string Usuario { get; set; }
        public string Password { get; set; }
        
    }
}