using application.Models.DTOModels;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class ProviderRegisterServiceResources
    {
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Key]
        public int ProviderServiceResourcesId { get; set; }

        [Required]
        public string ServiceTitle { get; set; } = string.Empty;


        public string ServicePhoto { get; set; } = string.Empty;

      
        public string ServiceVideo { get; set; } = string.Empty;

        [Required]
        public string ServiceFile { get; set; } = string.Empty;

        [Required]
        public int ProviderServiceId { get; set; }


        [Required]
        public int UserNumber { get; set; }

    }
}
