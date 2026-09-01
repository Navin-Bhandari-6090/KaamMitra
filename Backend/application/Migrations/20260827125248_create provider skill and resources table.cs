using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace application.Migrations
{
    /// <inheritdoc />
    public partial class createproviderskillandresourcestable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ProviderServiceInfo",
                columns: table => new
                {
                    ProviderServiceId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ServiceName = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ServiceDocument = table.Column<string>(type: "text", nullable: false),
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
                name: "ProviderServiceResources",
                columns: table => new
                {
                    ProviderServiceResourcesId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ServicePhoto = table.Column<string>(type: "text", nullable: false),
                    ServiceVideo = table.Column<string>(type: "text", nullable: false),
                    ProviderServiceId = table.Column<int>(type: "integer", nullable: false),
                    Email = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProviderServiceResources", x => x.ProviderServiceResourcesId);
                    table.ForeignKey(
                        name: "FK_ProviderServiceResources_ProviderServiceInfo_ProviderServic~",
                        column: x => x.ProviderServiceId,
                        principalTable: "ProviderServiceInfo",
                        principalColumn: "ProviderServiceId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ProviderServiceResources_UserInfos_Email",
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
                name: "IX_ProviderServiceResources_Email",
                table: "ProviderServiceResources",
                column: "Email");

            migrationBuilder.CreateIndex(
                name: "IX_ProviderServiceResources_ProviderServiceId",
                table: "ProviderServiceResources",
                column: "ProviderServiceId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ProviderServiceResources");

            migrationBuilder.DropTable(
                name: "ProviderServiceInfo");
        }
    }
}
