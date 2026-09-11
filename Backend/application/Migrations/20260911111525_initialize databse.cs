using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace application.Migrations
{
    /// <inheritdoc />
    public partial class initializedatabse : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "RatingInfos",
                columns: table => new
                {
                    RtingId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    RatingReceiver = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    RatingGiver = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    RatingValue = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RatingInfos", x => x.RtingId);
                });

            migrationBuilder.CreateTable(
                name: "ServiceInfos",
                columns: table => new
                {
                    ServiceId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ServiceName = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ServiceDescription = table.Column<string>(type: "text", nullable: false),
                    DomesticPrice = table.Column<int>(type: "integer", nullable: false),
                    DomesticPriceDiscount = table.Column<int>(type: "integer", nullable: false),
                    InternationalPrice = table.Column<int>(type: "integer", nullable: false),
                    InternationalPriceDiscount = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ServiceInfos", x => x.ServiceId);
                });

            migrationBuilder.CreateTable(
                name: "UserInfos",
                columns: table => new
                {
                    UserNumber = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    FirstName = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    LastName = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Email = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    PhoneNumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    WhatsappPhoneNumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Password = table.Column<string>(type: "text", nullable: false),
                    Latitude = table.Column<double>(type: "double precision", nullable: false),
                    Longitude = table.Column<double>(type: "double precision", nullable: false),
                    Photo = table.Column<string>(type: "text", nullable: false),
                    Role = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    LoginAccess = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserInfos", x => x.UserNumber);
                });

            migrationBuilder.CreateTable(
                name: "ProviderServiceInfo",
                columns: table => new
                {
                    ProviderServiceId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ServiceName = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ServiceDocument = table.Column<string>(type: "text", nullable: false),
                    Email = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    UserNumber = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProviderServiceInfo", x => x.ProviderServiceId);
                    table.ForeignKey(
                        name: "FK_ProviderServiceInfo_UserInfos_UserNumber",
                        column: x => x.UserNumber,
                        principalTable: "UserInfos",
                        principalColumn: "UserNumber",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ProviderServiceResourcesInfo",
                columns: table => new
                {
                    ProviderServiceResourcesId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ServicePhoto = table.Column<string>(type: "text", nullable: false),
                    ServiceVideo = table.Column<string>(type: "text", nullable: false),
                    ProviderServiceId = table.Column<int>(type: "integer", nullable: false),
                    Email = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    UserNumber = table.Column<int>(type: "integer", nullable: false)
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
                        name: "FK_ProviderServiceResourcesInfo_UserInfos_UserNumber",
                        column: x => x.UserNumber,
                        principalTable: "UserInfos",
                        principalColumn: "UserNumber",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ProviderServiceInfo_UserNumber",
                table: "ProviderServiceInfo",
                column: "UserNumber");

            migrationBuilder.CreateIndex(
                name: "IX_ProviderServiceResourcesInfo_ProviderServiceId",
                table: "ProviderServiceResourcesInfo",
                column: "ProviderServiceId");

            migrationBuilder.CreateIndex(
                name: "IX_ProviderServiceResourcesInfo_UserNumber",
                table: "ProviderServiceResourcesInfo",
                column: "UserNumber");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ProviderServiceResourcesInfo");

            migrationBuilder.DropTable(
                name: "RatingInfos");

            migrationBuilder.DropTable(
                name: "ServiceInfos");

            migrationBuilder.DropTable(
                name: "ProviderServiceInfo");

            migrationBuilder.DropTable(
                name: "UserInfos");
        }
    }
}
