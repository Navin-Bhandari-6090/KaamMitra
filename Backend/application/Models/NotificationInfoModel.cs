using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class NotificationInfoModel
    {

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int NotId { get; set; }

        [Required]
        public int ReceiverNumber { get; set; }

        [Required]
        public string Message { get; set; }

       
        public DateTime Date { get; set; }


    }
}
