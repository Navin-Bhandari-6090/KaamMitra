using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class ResourcesNumber
    {

        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Key]
        public int ResourcesNumberId { get; set; }

        [Required]
        public int NoOfRes { get; set; }

        [Required]
        public string ServiceName { get; set; } = string.Empty;


        [Required]
        public int UserNumber { get; set; }

    }
}
