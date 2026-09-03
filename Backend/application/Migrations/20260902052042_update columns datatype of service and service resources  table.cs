using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace application.Migrations
{
    /// <inheritdoc />
    public partial class updatecolumnsdatatypeofserviceandserviceresourcestable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ServiceInfos",
                columns: table => new
                {
                    ServiceId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ServiceName = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ServiceDescription = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ServiceInfos", x => x.ServiceId);
                });

            migrationBuilder.CreateTable(
                name: "UserInfos",
                columns: table => new
                {
                    Email = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    UserNumber = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    FirstName = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    LastName = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    PhoneNumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    WhatsappPhoneNumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Password = table.Column<string>(type: "text", nullable: false),
                    Latitude = table.Column<double>(type: "double precision", nullable: false),
                    Longitude = table.Column<double>(type: "double precision", nullable: false),
                    Photo = table.Column<string>(type: "text", nullable: false),
                    Role = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserInfos", x => x.Email);
                });

            migrationBuilder.CreateTable(
                name: "ProviderServiceInfo",
                columns: table => new
                {
                    ProviderServiceId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ServiceName = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ServiceDocument = table.Column<byte[]>(type: "bytea", nullable: false),
                    Email = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProviderServiceInfo", x => x.ProviderServiceId);
                    table.ForeignKey(
                        name: "FK_ProviderServiceInfo_UserInfos_Email",
                        column: x => x.Email,
                        principalTable: "UserInfos",
                        principalColumn: "Email",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ProviderServiceResourcesInfo",
                columns: table => new
                {
                    ProviderServiceResourcesId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ServicePhoto = table.Column<byte[]>(type: "bytea", nullable: false),
                    ServiceVideo = table.Column<byte[]>(type: "bytea", nullable: false),
                    ProviderServiceId = table.Column<int>(type: "integer", nullable: false),
                    Email = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProviderServiceResourcesInfo", x => x.ProviderServiceResourcesId);
                    table.ForeignKey(
                        name: "FK_ProviderServiceResourcesInfo_ProviderServiceInfo_ProviderSe~",
                        column: x => x.ProviderServiceId,
                        principalTable: "ProviderServiceInfo",
                        principalColumn: "ProviderServiceId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ProviderServiceResourcesInfo_UserInfos_Email",
                        column: x => x.Email,
                        principalTable: "UserInfos",
                        principalColumn: "Email",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ProviderServiceInfo_Email",
                table: "ProviderServiceInfo",
                column: "Email");

            migrationBuilder.CreateIndex(
                name: "IX_ProviderServiceResourcesInfo_Email",
                table: "ProviderServiceResourcesInfo",
                column: "Email");

            migrationBuilder.CreateIndex(
                name: "IX_ProviderServiceResourcesInfo_ProviderServiceId",
                table: "ProviderServiceResourcesInfo",
                column: "ProviderServiceId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ProviderServiceResourcesInfo");

            migrationBuilder.DropTable(
                name: "ServiceInfos");

            migrationBuilder.DropTable(
                name: "ProviderServiceInfo");

            migrationBuilder.DropTable(
                name: "UserInfos");
        }
    }
}
