using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class AdminQRPhotoModel
    {

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int AdminQRID { get; set; }

       
        public string? DomesticQRPhoto { get; set; }

        public string? InternationalQRPhoto { get; set; }


    }
}
