namespace application.Models.DTOModels
{
    public class TaskCompletePaymentInfoDTO
    {
        public int TaskCompletePaymentId { get; set; }
        public double PaymentAmount { get; set; }
        public DateTime PaymentDate { get; set; }
        public int BookId { get; set; }
        public string PaymentMethod { get; set; } = string.Empty;
        public string PaymentPhoto { get; set; } = string.Empty;
    }
}
