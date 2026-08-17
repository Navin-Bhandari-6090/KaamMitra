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

    }
}
