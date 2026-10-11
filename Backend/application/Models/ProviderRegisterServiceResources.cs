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
        public string ServicePhoto { get; set; } = string.Empty;

        [Required]
        public string ServiceVideo { get; set; } = string.Empty;

        [Required]
        public int ProviderServiceId { get; set; }


        [Required]
        public int UserNumber { get; set; }




    }
}
