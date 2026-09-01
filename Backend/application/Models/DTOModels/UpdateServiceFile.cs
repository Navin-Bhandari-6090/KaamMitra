using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class UpdateServiceFile
    {

        [Required]
        public int ProviderServiceId { get; set; }

        [Required]
        public string ServiceDocument { get; set; } = string.Empty;

        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;


    }
}
