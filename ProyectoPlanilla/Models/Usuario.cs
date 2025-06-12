using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ProyectoPlanilla.Models
{
    public class Usuario
    {
        [Key]
        public int id { get; set; }

        [Required]
        [StringLength(50)]
        public string Username { get; set; } = string.Empty;

        [Required]
        [StringLength(100)]
        public string Password { get; set; } = string.Empty;

        [Required]
        public int Tipo { get; set; }  // 1 = Administrador, 2 = Empleado

        public int? idEmpleado { get; set; }  // Solo para empleados

        [NotMapped]
        public bool EsAdministrador => Tipo == 1;

        [NotMapped]
        public bool EsEmpleado => Tipo == 2;
    }
}
