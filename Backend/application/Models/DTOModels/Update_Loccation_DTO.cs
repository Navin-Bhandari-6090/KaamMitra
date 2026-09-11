using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class Update_Loccation_DTO
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; }

        [Required]
        public double Latitude { get; set; }

        [Required]
        public double Longitude { get; set; }

    }
}
