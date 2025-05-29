namespace ProyectoPlanilla.Models
{
    public class DetalleMovimiento
    {
        public string Nombre { get; set; }
        public decimal? Porcentaje { get; set; }
        public decimal Monto { get; set; }
        public DateTime Fecha { get; set; }
        public TimeSpan HoraEntrada { get; set; }
        public TimeSpan HoraSalida { get; set; }
        public int HorasOrdinarias { get; set; }
        public decimal MontoOrdinario { get; set; }
        public int HorasExtrasNormales { get; set; }
        public decimal MontoExtrasNormales { get; set; }
        public int HorasExtrasDobles { get; set; }
        public decimal MontoExtrasDobles { get; set; }
    }
}