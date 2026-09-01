using application.Models;
using Microsoft.EntityFrameworkCore;

namespace application.Data
{
    public class DatabaseController : DbContext
    {

        public DatabaseController(DbContextOptions<DatabaseController> options) : base(options)
        {


        }

        public DbSet<UserInfo> UserInfos { get; set; }

        public DbSet<ProviderServices> ProviderServiceInfo { get; set; }

        public DbSet<ProviderServiceResources> ProviderServiceResourcesInfo { get; set; }

        public DbSet<ServiceInfoModel> ServiceInfos { get; set; }

      

        public object ProviderServices { get; internal set; }

    }
}
