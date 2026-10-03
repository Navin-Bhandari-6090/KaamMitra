using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class UpdateProviderApprovalStatusDTO
    {
        [Required]
        public int BookId { get; set; }

    }
}
