using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class ResIdTitleDTO
    {

        [Required]
        public int ProviderServiceResourcesId { get; set; }

        [Required]
        public string ServiceTitle { get; set; } = null;
    }
}
