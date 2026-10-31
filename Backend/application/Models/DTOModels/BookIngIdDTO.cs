using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class BookIngIdDTO
    {

        [Required]
        public int BookId { get; set; }

        [EmailAddress]
        [StringLength(200)]
        public string UserEmail { get; set; }


    }
}
