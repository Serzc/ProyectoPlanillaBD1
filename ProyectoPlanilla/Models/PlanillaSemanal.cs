using System;

namespace ProyectoPlanilla.Models
{
    public class PlanillaSemanal
    {
        public int Id { get; set; }
        public DateTime FechaInicio { get; set; }
        public DateTime FechaFin { get; set; }
        public decimal SalarioBruto { get; set; }
        public decimal TotalDeducciones { get; set; }
        public decimal SalarioNeto { get; set; }
        public decimal HorasOrdinarias { get; set; }
        public decimal HorasExtrasNormales { get; set; }
        public decimal HorasExtrasDobles { get; set; }
    }
}