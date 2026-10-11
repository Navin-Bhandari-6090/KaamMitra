using application.Models.DTOModels;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class ProviderRegisterServices
    {

        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Key]
        public int ProviderServiceId { get; set; }

        [Required]
        [StringLength(50)]
        public string ServiceName { get; set; } = string.Empty;

        [Required]
        public string ServiceDocument { get; set; } = string.Empty;


        [Required]
        public string ProRegServiceDescription { get; set; } = string.Empty;

        [Required]
        public int UserNumber { get; set; }


   


    }
}
