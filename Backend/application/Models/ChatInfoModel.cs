using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace application.Models
{
    // Status only moves forward: Sent -> Delivered -> Read.
    public static class ChatMessageStatus
    {
        public const int Sent = 1;       // saved on server (single grey tick)
        public const int Delivered = 2;  // receiver connected, not on this chat screen (double grey tick)
        public const int Read = 3;       // receiver is on this chat screen (double blue tick)
    }

    [Index(nameof(ReceiverNumber), nameof(Status))]
    [Index(nameof(SenderNumber), nameof(ReceiverNumber), nameof(StoreAt))]
    public class ChatInfoModel
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int ChatId { get; set; }

        [Required]
        public string Message { get; set; } = string.Empty;

        public DateTime StoreAt { get; set; } = DateTime.UtcNow;

        [Required]
        public int SenderNumber { get; set; }

        [Required]
        public int ReceiverNumber { get; set; }

        // 1 = Sent, 2 = Delivered, 3 = Read (see ChatMessageStatus).
        public int Status { get; set; } = ChatMessageStatus.Sent;

        // When the receiver's app got the message (null while only Sent).
        public DateTime? DeliveredAt { get; set; }

        // When the receiver read it (null until Read).
        public DateTime? ReadAt { get; set; }

        // Kept only so existing code keeps compiling while we migrate.
        // It follows Status, so never set it directly.
        [NotMapped]
        public bool IsRead => Status == ChatMessageStatus.Read;
    }
}