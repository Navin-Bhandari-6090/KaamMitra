using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class UpdateServiceResPhoto
    {

        [Required]
        public int ProviderServiceResourcesId { get; set; }

        [Required]
        public IFormFile ServicePhoto { get; set; } = null;

        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public int ProviderServiceId { get; set; }

    }
}
