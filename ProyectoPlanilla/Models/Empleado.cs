using System.ComponentModel.DataAnnotations;

namespace ProyectoPlanilla.Models
{
    public class Empleado
    {
        public int Id { get; set; }

        [Required]
        public string Nombre { get; set; }

        [Required]
        public string ValorDocumentoIdentidad { get; set; }

        public int PuestoId { get; set; }
        public Puesto Puesto { get; set; }

        public bool Activo { get; set; } = true;
    }
}