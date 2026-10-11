using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models.DTOModels
{
    public class ProviderServicesDTO

    {
   
        public int ProviderServiceId { get; set; }

        [Required]
        [StringLength(50)]
        public string ServiceName { get; set; } = string.Empty;

        [Required]
        public IFormFile ServiceDocument { get; set; }

        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string ProRegServiceDescription { get; set; } = string.Empty;


    }
}
