using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class UpdateProviderApprovalStatusDTO
    {
        [Required]
        public int BookId { get; set; }

        [Required]
        [EmailAddress]
        [StringLength(200)]
        public string UserEmail { get; set; }

    }
}
