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

     

    }
}
