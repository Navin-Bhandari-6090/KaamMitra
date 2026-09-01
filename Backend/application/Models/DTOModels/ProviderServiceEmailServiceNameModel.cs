using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class ProviderServiceEmailServiceNameModel
    {

        [Required]
        [StringLength(50)]
        public string ServiceName { get; set; } = string.Empty;

        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;


    }
}
