using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class NewNotificationInfoModel
    {

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int NewNotId { get; set; }

        [Required]
        public int ReceiverNumber { get; set; }

        [Required]
        public bool Status { get; set; }

    }
}
