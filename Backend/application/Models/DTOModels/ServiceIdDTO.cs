using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class ServiceIdDTO
    {
        [Required]
        public int ServiceId { get; set; }
    }
}
