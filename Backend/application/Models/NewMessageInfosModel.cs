using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class NewMessageInfosModel
    {

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int NewMsgId { get; set; }

        [Required]
        public int MessageReceiverNumber { get; set; }

        [Required]
        public bool Status { get; set; }

    }
}
