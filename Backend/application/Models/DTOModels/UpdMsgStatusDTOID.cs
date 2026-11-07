using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class UpdMsgStatusDTOID
    {

        [Required]
        public int MessageReceiverNumber { get; set; }

    }
}
