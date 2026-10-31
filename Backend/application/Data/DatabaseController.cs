using application.Models;
using application.Models.DTOModels;
using Microsoft.EntityFrameworkCore;

namespace application.Data
{
    public class DatabaseController : DbContext
    {

        public DatabaseController(DbContextOptions<DatabaseController> options) : base(options)
        {


        }

        public DbSet<UserInfo> UserInfos { get; set; }

        public DbSet<ProviderRegisterServices> ProviderServiceInfo { get; set; }

        public DbSet<ProviderRegisterServiceResources> ProviderServiceResourcesInfo { get; set; }

        public DbSet<ServiceInfoModel> ServiceInfos { get; set; }

        public DbSet<RatingInfoModel> RatingInfos { get; set; }

        public DbSet<BookinInfoModel> BookingInfos { get; set; }
        public DbSet<NotificationInfoModel> NotificationInfos { get; set; }
        public DbSet<NewNotificationInfoModel> NewNotificationInfos { get; set; }

        public DbSet<AdvancePaymentInfoModel> AdvancePaymentInfos { get; set; }

        public DbSet<AdvancePaymentQrInfoModel> AdvancePaymentQrInfos { get; set; }

        public DbSet<AdvertisementInfoModel> AdvertisementInfos { get; set; }

        public DbSet<ProTaskCompletePaymentInfos> ProTaskCompletePaymentInfos { get; set; }

        public DbSet<AdminQRPhotoModel> AdminQRPhotoInfos { get; set; }

        public DbSet<FooterInfoModel> FooterInfos { get; set; }

        public DbSet<ChatInfoModel> ChatInfos { get; set; }

        public DbSet<NewMessageInfosModel> NewMessageStatusInfos { get; set; }

        public DbSet<SharedMediaModel> SharedMediaInfos { get; set; }

   
    }
}
