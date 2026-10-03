using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class ProviderServiceIdDTO
    {

        [Required]
        public int ProviderServiceId { get; set; }

        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

    }
}
