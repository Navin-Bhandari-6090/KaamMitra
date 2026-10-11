using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class ProServDescpDTO
    {
        [Required]
        public int ProviderServiceId { get; set; }

        [Required]
        public string ProRegServiceDescription { get; set; } = string.Empty;

    }

}
